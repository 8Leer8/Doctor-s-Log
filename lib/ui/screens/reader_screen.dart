import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../theme/app_theme.dart';
import '../../models/reader_part.dart';
import '../../models/story_element.dart';
import '../../models/reader_settings.dart';
import '../../data/remote/story_data_source.dart';
import '../../data/parser/story_parser.dart';
import '../../data/local/reading_progress_store.dart';
import '../../data/local/download_store.dart';
import '../widgets/chapter_transition_widget.dart';
import '../widgets/reader/reader_item.dart';
import '../widgets/reader/story_line_widget.dart';
import '../widgets/reader/choice_widget.dart';
import '../widgets/reader/end_of_chapter_widget.dart';
import '../widgets/reader/locked_section_widget.dart';
import '../widgets/reader/reader_top_bar.dart';
import '../widgets/reader/reader_bottom_bar.dart';
import '../widgets/reader/reader_settings_sheet.dart';
import '../widgets/reader/reader_toc_sheet.dart';
import '../widgets/common/app_toast.dart';

class ReaderScreen extends StatefulWidget {
  final String chapterId;
  final String chapterTitle;
  final List<ReaderPart> readerParts;
  final int startAt;
  final Map<String, String> initialChoices;
  final int? resumePartOriginalIndex;
  final int? resumeElementIndex;

  const ReaderScreen({
    super.key,
    required this.chapterId,
    required this.chapterTitle,
    required this.readerParts,
    this.startAt = 0,
    this.initialChoices = const {},
    this.resumePartOriginalIndex,
    this.resumeElementIndex,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

/// Identifies which kind of [ReaderItem] a [_ScrollAnchor] points at.
enum _AnchorKind { content, transition, locked, endMarker }

/// A stable reference to "the item currently anchoring the viewport",
/// captured right before a backward part load mutates state.
///
/// Backward loads prepend a new divider + that part's content *before*
/// everything currently on screen. That shifts every existing item to a
/// new list index, which `ScrollablePositionedList` has no way to know
/// about on its own — left alone, the viewport silently snaps toward the
/// newly-inserted content instead of staying where the reader left it.
///
/// An anchor lets us find the *same* item again after the rebuild (by
/// content identity, not by index) and jump straight back to it, so the
/// prepend is invisible to the reader instead of yanking the screen
/// backward and potentially re-triggering another backward load.
class _ScrollAnchor {
  final _AnchorKind kind;
  final int? partIndexInList;
  final int? elementIndexInPart;
  final int? gateChoiceId;

  /// The anchor item's leading-edge fraction within the viewport at
  /// capture time (0 = top, 1 = bottom), so restoration doesn't just put
  /// the item on screen somewhere, but back at the same visual offset.
  final double alignment;

  _ScrollAnchor.content(
    this.partIndexInList,
    this.elementIndexInPart,
    this.alignment,
  ) : kind = _AnchorKind.content,
      gateChoiceId = null;

  _ScrollAnchor.transition(this.partIndexInList, this.alignment)
    : kind = _AnchorKind.transition,
      elementIndexInPart = null,
      gateChoiceId = null;

  _ScrollAnchor.locked(this.partIndexInList, this.gateChoiceId, this.alignment)
    : kind = _AnchorKind.locked,
      elementIndexInPart = null;

  _ScrollAnchor.endMarker(this.alignment)
    : kind = _AnchorKind.endMarker,
      partIndexInList = null,
      elementIndexInPart = null,
      gateChoiceId = null;
}

class _ReaderScreenState extends State<ReaderScreen> {
  final _dataSource = StoryDataSource();
  final _itemScrollController = ItemScrollController();
  final _itemPositionsListener = ItemPositionsListener.create();

  // --- Lazy-loading state -----------------------------------------------
  // Session cache: once a part loads, it stays loaded for the life of this
  // screen. Loading is strictly one part at a time per direction — no
  // cascades, no bulk fetching.
  final Set<int> _loadedParts = {};
  final Map<int, String> _missingParts = {}; // partIndex -> reason
  final Set<int> _loadingParts = {};
  final Map<int, List<StoryElement>> _contentCache = {};

  /// Bounds of the contiguous window of loaded parts. Null when nothing has
  /// loaded yet.
  int? _lo;
  int? _hi;

  /// True for the brief window between a load that requires a scroll
  /// correction (a backward prepend, or the one-time "land on real content
  /// instead of the divider" jump) and that correction actually landing.
  ///
  /// The list rebuild happens a frame before we get to call `jumpTo`, so
  /// for one frame the viewport shows a transient, uncorrected layout. If
  /// [_onPositionsChanged] is allowed to react to that frame, it can both
  /// mis-track reading progress and — worse — decide the *new* divider is
  /// within the load-trigger zone and kick off another load before we've
  /// restored the position, which is what produced the visible "loads its
  /// neighbors too" flicker. While this is true, position updates are
  /// ignored entirely.
  bool _restoringScroll = false;

  /// Set only when parsing/other non-network content produces an
  /// unrecoverable error (distinct from a per-part network miss, which is
  /// tracked in [_missingParts] and is retryable per-part).
  String? _fatalError;

  final Map<String, String> _selections = {};

  int _frontierPartIndexInList = 0;
  int _currentPartIndexInList = 0;
  int _currentElementIndexInPart = 0;

  int? _confirmedReadOriginalIndex;

  bool _showControls = false;
  ReaderSettings _settings = const ReaderSettings();

  Map<int, int> _partListIndex = {};
  Map<String, int> _choiceListIndex = {};
  int? _endMarkerListIndex;
  int? _leadingDividerListIndex;
  int? _trailingDividerListIndex;

  List<ReaderItem>? _lastVisibleItems;

  // Scroll thresholds (fraction of viewport, matching ItemPosition's
  // leading/trailing edge convention where 0 = top of viewport, 1 = bottom).
  static const double _kForwardTriggerEdge = 0.85;
  static const double _kBackwardTriggerEdge = 0.15;

  @override
  void initState() {
    super.initState();
    _currentPartIndexInList = widget.startAt;
    _frontierPartIndexInList = widget.startAt;
    _itemPositionsListener.itemPositions.addListener(_onPositionsChanged);
    _seedInitialSelections();
    _loadPart(widget.startAt);
    if (_settings.keepScreenAwake) {
      WakelockPlus.enable();
    }
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onPositionsChanged);
    _persistProgress();
    WakelockPlus.disable();
    super.dispose();
  }

  void _seedInitialSelections() {
    widget.initialChoices.forEach((key, value) {
      final parts = key.split('-');
      if (parts.length != 2) return;
      final originalIndex = int.tryParse(parts[0]);
      final choiceId = parts[1];
      if (originalIndex == null) return;
      final listIndex = widget.readerParts.indexWhere(
        (rp) => rp.originalIndex == originalIndex,
      );
      if (listIndex == -1) return;
      _selections['$listIndex-$choiceId'] = value;
    });
  }

  Future<void> _persistProgress() async {
    final choicesToSave = <String, String>{};
    _selections.forEach((key, value) {
      final dashIndex = key.indexOf('-');
      if (dashIndex == -1) return;
      final listIndex = int.tryParse(key.substring(0, dashIndex));
      final choiceId = key.substring(dashIndex + 1);
      if (listIndex == null || listIndex >= widget.readerParts.length) return;
      final originalIndex = widget.readerParts[listIndex].originalIndex;
      choicesToSave['$originalIndex-$choiceId'] = value;
    });
    await ReadingProgressStore.setChoices(widget.chapterId, choicesToSave);

    if (_currentPartIndexInList < widget.readerParts.length) {
      final originalIndex =
          widget.readerParts[_currentPartIndexInList].originalIndex;
      await ReadingProgressStore.setResumePosition(
        widget.chapterId,
        originalIndex,
        _currentElementIndexInPart,
      );
    }
  }

  void _onPositionsChanged() {
    // A correction is already queued for the next frame — whatever this
    // report says is a transient artifact of the layout mid-prepend, not
    // where the reader actually is. Ignore it entirely rather than acting
    // on it (see [_restoringScroll]).
    if (_restoringScroll) return;

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final sorted = positions.toList()
      ..sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
    final topVisible = sorted.firstWhere(
      (p) => p.itemLeadingEdge >= -0.1,
      orElse: () => sorted.first,
    );
    final visibleListIndex = topVisible.index;

    int? bestPart;
    _partListIndex.forEach((partIndex, listIndex) {
      if (listIndex <= visibleListIndex) {
        if (bestPart == null || partIndex > bestPart!) bestPart = partIndex;
      }
    });

    if (bestPart != null) {
      if (bestPart! > 0) {
        final justBeforeOriginal =
            widget.readerParts[bestPart! - 1].originalIndex;
        if (_confirmedReadOriginalIndex == null ||
            justBeforeOriginal > _confirmedReadOriginalIndex!) {
          _confirmedReadOriginalIndex = justBeforeOriginal;
        }
      }
      if (bestPart != _currentPartIndexInList) {
        setState(() => _currentPartIndexInList = bestPart!);
      }
    }

    final visible = _lastVisibleItems;
    if (visible != null && visibleListIndex < visible.length) {
      final atTop = visible[visibleListIndex];
      if (atTop is ContentItem) {
        _currentElementIndexInPart = atTop.elementIndexInPart;
      }
    }

    if (_endMarkerListIndex != null &&
        positions.any((p) => p.index == _endMarkerListIndex)) {
      final lastOriginal = widget.readerParts.last.originalIndex;
      if (_confirmedReadOriginalIndex == null ||
          lastOriginal > _confirmedReadOriginalIndex!) {
        _confirmedReadOriginalIndex = lastOriginal;
      }
    }

    _evaluateLoadTriggers(positions);
  }

  /// Checks whether the leading/trailing divider has crossed its own
  /// independent scroll threshold, and if so kicks off loading exactly one
  /// part in that direction. Each direction has its own trigger and its own
  /// state, so they never interfere with each other.
  void _evaluateLoadTriggers(Iterable<ItemPosition> positions) {
    if (_lo == null) {
      // Nothing loaded yet — the only thing to load is startAt itself.
      // (initState already kicks this off; this is just a defensive
      // fallback so a rebuild without a fresh initState still recovers.)
      if (!_loadedParts.contains(widget.startAt) &&
          !_loadingParts.contains(widget.startAt) &&
          !_missingParts.containsKey(widget.startAt)) {
        _loadPart(widget.startAt);
      }
      return;
    }

    final lo = _lo!;
    final hi = _hi!;

    if (hi < widget.readerParts.length - 1 &&
        !_loadingParts.contains(hi + 1) &&
        !_missingParts.containsKey(hi + 1)) {
      final trailingIndex = _trailingDividerListIndex;
      if (trailingIndex != null) {
        for (final p in positions) {
          if (p.index == trailingIndex &&
              p.itemLeadingEdge <= _kForwardTriggerEdge) {
            _loadPart(hi + 1);
            break;
          }
        }
      }
    }

    if (lo > 0 &&
        !_loadingParts.contains(lo - 1) &&
        !_missingParts.containsKey(lo - 1)) {
      final leadingIndex = _leadingDividerListIndex;
      if (leadingIndex != null) {
        for (final p in positions) {
          if (p.index == leadingIndex &&
              p.itemTrailingEdge >= _kBackwardTriggerEdge) {
            _loadPart(lo - 1);
            break;
          }
        }
      }
    }
  }

  /// Captures a stable reference to whichever item is currently anchoring
  /// the viewport (same "topmost visible item" logic as
  /// [_onPositionsChanged]), so it can be relocated and re-pinned after a
  /// backward load prepends new items ahead of it.
  ///
  /// Returns null if there's nothing to anchor to yet (e.g. before the
  /// first layout) — callers should simply skip restoration in that case.
  _ScrollAnchor? _captureScrollAnchor() {
    final items = _lastVisibleItems;
    final positions = _itemPositionsListener.itemPositions.value;
    if (items == null || items.isEmpty || positions.isEmpty) return null;

    final sorted = positions.toList()
      ..sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
    final top = sorted.firstWhere(
      (p) => p.itemLeadingEdge >= -0.1,
      orElse: () => sorted.first,
    );
    if (top.index < 0 || top.index >= items.length) return null;

    final alignment = top.itemLeadingEdge.clamp(0.0, 1.0);
    final item = items[top.index];

    if (item is ContentItem) {
      return _ScrollAnchor.content(
        item.partIndexInList,
        item.elementIndexInPart,
        alignment,
      );
    } else if (item is TransitionItem) {
      return _ScrollAnchor.transition(item.partIndexInList, alignment);
    } else if (item is LockedSectionItem) {
      return _ScrollAnchor.locked(
        item.partIndexInList,
        item.gateChoiceId,
        alignment,
      );
    } else if (item is EndOfChapterMarker) {
      return _ScrollAnchor.endMarker(alignment);
    }
    return null;
  }

  /// Finds the anchor's new index in a freshly-rebuilt visible list, by
  /// content identity rather than by the (now-invalidated) old index.
  int? _resolveAnchorIndex(_ScrollAnchor anchor, List<ReaderItem> items) {
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      switch (anchor.kind) {
        case _AnchorKind.content:
          if (item is ContentItem &&
              item.partIndexInList == anchor.partIndexInList &&
              item.elementIndexInPart == anchor.elementIndexInPart) {
            return i;
          }
          break;
        case _AnchorKind.transition:
          if (item is TransitionItem &&
              item.partIndexInList == anchor.partIndexInList) {
            return i;
          }
          break;
        case _AnchorKind.locked:
          if (item is LockedSectionItem &&
              item.partIndexInList == anchor.partIndexInList &&
              item.gateChoiceId == anchor.gateChoiceId) {
            return i;
          }
          break;
        case _AnchorKind.endMarker:
          if (item is EndOfChapterMarker) return i;
          break;
      }
    }
    return null;
  }

  void _scrollToIndex(int index, {bool animate = true}) {
    if (animate) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _itemScrollController.jumpTo(index: index);
    }
  }

  void _jumpToPart(int partIndexInList) {
    if (partIndexInList > _frontierPartIndexInList) {
      setState(() => _frontierPartIndexInList = partIndexInList);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dividerIndex = _partListIndex[partIndexInList];
      if (dividerIndex == null) return;

      // Same principle as the initial-open positioning: if this part's
      // content is already loaded, land on its first item (content or
      // locked-section card) rather than on its divider. If it isn't
      // loaded yet, stay on the divider — it's the only thing there,
      // and it's carrying that part's loading/error state.
      var targetIndex = dividerIndex;
      final items = _lastVisibleItems;
      if (items != null && dividerIndex + 1 < items.length) {
        final next = items[dividerIndex + 1];
        final belongsToTargetPart =
            (next is ContentItem && next.partIndexInList == partIndexInList) ||
            (next is LockedSectionItem &&
                next.partIndexInList == partIndexInList);
        if (belongsToTargetPart) targetIndex = dividerIndex + 1;
      }
      _scrollToIndex(targetIndex);
    });
  }

  void _goToChoice(int partIndexInList, int choiceId) {
    final listIndex = _choiceListIndex['$partIndexInList-$choiceId'];
    if (listIndex == null) return;
    _scrollToIndex(listIndex);
  }

  bool get _canGoPrev => _currentPartIndexInList > 0;
  bool get _canGoNext =>
      _currentPartIndexInList < widget.readerParts.length - 1;

  void _goPrev() {
    if (!_canGoPrev) return;
    _jumpToPart(_currentPartIndexInList - 1);
  }

  void _goNext() {
    if (!_canGoNext) return;
    _jumpToPart(_currentPartIndexInList + 1);
  }

  String get _currentPartTitle {
    if (widget.readerParts.isEmpty) return widget.chapterTitle;
    final index = _currentPartIndexInList.clamp(
      0,
      widget.readerParts.length - 1,
    );
    return widget.readerParts[index].part.title;
  }

  String? get _currentPartSubtitle {
    if (widget.readerParts.isEmpty) return null;
    final index = _currentPartIndexInList.clamp(
      0,
      widget.readerParts.length - 1,
    );
    return widget.readerParts[index].part.avgTag;
  }

  String _classifyError(Object e) {
    final s = e.toString().toLowerCase();
    final isNet =
        s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('connection') ||
        s.contains('no address associated') ||
        s.contains('connection error');
    return isNet ? 'no_internet' : 'unknown';
  }

  Future<String?> _loadPartRaw(
    int partIndexInList,
    List<String> reasonOut,
  ) async {
    final filename = widget.readerParts[partIndexInList].part.filename!;

    try {
      final cached = await DownloadStore.getContent(filename);
      if (cached != null && cached.isNotEmpty) return cached;
    } catch (_) {}

    try {
      return await _dataSource.fetchRawStory(filename);
    } catch (e) {
      reasonOut.add(_classifyError(e));
      return null;
    }
  }

  /// Loads exactly one part. Safe to call repeatedly — it's a no-op if the
  /// part is already loaded or already in flight. Never fetches more than
  /// the single requested part, and never cascades into neighbors.
  Future<void> _loadPart(
    int partIndexInList, {
    bool isManualRetry = false,
  }) async {
    if (partIndexInList < 0 || partIndexInList >= widget.readerParts.length) {
      return;
    }
    if (_loadedParts.contains(partIndexInList) ||
        _loadingParts.contains(partIndexInList)) {
      return;
    }

    setState(() {
      _loadingParts.add(partIndexInList);
      _missingParts.remove(partIndexInList);
    });

    final reasonOut = <String>[];
    final raw = await _loadPartRaw(partIndexInList, reasonOut);

    if (!mounted) return;

    if (raw == null) {
      final reason = reasonOut.isEmpty ? 'unknown' : reasonOut.first;
      setState(() {
        _loadingParts.remove(partIndexInList);
        _missingParts[partIndexInList] = reason;
      });
      if (isManualRetry) {
        AppToast.show(
          context,
          reason == 'no_internet'
              ? 'Still offline · No internet'
              : 'Could not load this part',
          icon: Icons.wifi_off_rounded,
          accent: Colors.redAccent,
        );
      }
      return;
    }

    List<StoryElement> elements;
    try {
      elements = StoryParser.parse(raw);
    } catch (e) {
      setState(() {
        _loadingParts.remove(partIndexInList);
        _fatalError = e.toString();
      });
      return;
    }

    // A backward load (this part sits *before* the current window) will
    // prepend items to the visible list, shifting every existing item to a
    // new index. Capture what's anchoring the viewport right now — while
    // `_lo` and `_lastVisibleItems` still reflect the pre-load state — so
    // we can put the viewport back where the reader left it once the
    // rebuild happens below. Forward loads only append at the tail, which
    // never shifts anything already on screen, so they need no correction.
    final isBackwardLoad = _lo != null && partIndexInList < _lo!;
    final anchor = isBackwardLoad ? _captureScrollAnchor() : null;

    // The very first part ever loaded (startAt) also needs a one-time
    // correction: `initialScrollIndex` can only point at startAt's divider,
    // since that divider is the *only* item that exists before any content
    // has loaded. Once real content lands, jump past that divider onto the
    // first actual line (see `_computeInitialScrollIndex`).
    final isInitialStartAtLoad =
        _lo == null && partIndexInList == widget.startAt;

    // Either correction needs a frame to happen (the rebuild below has to
    // land first), so block `_onPositionsChanged` from reacting to the
    // transient, uncorrected layout in between — otherwise it can decide
    // the newly-prepended divider is itself within the load-trigger zone
    // and kick off a load for the *next* part over before we've restored
    // the position, which is what caused loading to spill into neighboring
    // parts instead of staying to just the one part being opened.
    if (anchor != null || isInitialStartAtLoad) {
      _restoringScroll = true;
    }

    setState(() {
      _loadingParts.remove(partIndexInList);
      _contentCache[partIndexInList] = elements;
      _loadedParts.add(partIndexInList);
      _lo = (_lo == null || partIndexInList < _lo!) ? partIndexInList : _lo;
      _hi = (_hi == null || partIndexInList > _hi!) ? partIndexInList : _hi;
    });

    if (anchor != null) {
      // Wait for the rebuild triggered by the setState above to finish —
      // only then does `_lastVisibleItems` reflect the new, prepended list
      // we need to search.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final items = _lastVisibleItems;
        if (items != null) {
          final newIndex = _resolveAnchorIndex(anchor, items);
          if (newIndex != null) {
            _itemScrollController.jumpTo(
              index: newIndex,
              alignment: anchor.alignment,
            );
          }
        }
        // Only now does the viewport reflect a position `_onPositionsChanged`
        // can trust again.
        _restoringScroll = false;
      });
    } else if (isInitialStartAtLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final items = _lastVisibleItems;
        if (items != null) {
          _itemScrollController.jumpTo(
            index: _computeInitialScrollIndex(items),
          );
        }
        _restoringScroll = false;
      });
    }
  }

  /// Retries loading a single part on user request (tapping RETRY). Only
  /// ever loads that one part.
  Future<void> _retryPart(int partIndexInList) =>
      _loadPart(partIndexInList, isManualRetry: true);

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _openSettings() {
    ReaderSettingsSheet.show(context, _settings, (updated) {
      final wakelockChanged =
          updated.keepScreenAwake != _settings.keepScreenAwake;
      setState(() => _settings = updated);
      if (wakelockChanged) {
        if (updated.keepScreenAwake) {
          WakelockPlus.enable();
        } else {
          WakelockPlus.disable();
        }
      }
    });
  }

  void _openToc() {
    ReaderTocSheet.show(context, widget.readerParts, _currentPartIndexInList, (
      index,
    ) {
      _jumpToPart(index);
    });
  }

  /// Builds the currently visible item list from the loaded-window state.
  ///
  /// At most two "attempt" dividers exist at any time: a leading divider
  /// (entry into the first loaded part, carrying a backward error/loading
  /// state for the part before it) and a trailing divider (carrying a
  /// forward error/loading state for the part after the loaded window).
  /// Between two already-loaded parts, only a plain divider (no error
  /// slots) is shown — never a duplicate.
  List<ReaderItem> _buildVisibleItems() {
    final visible = <ReaderItem>[];
    final partIndexMap = <int, int>{};
    final choiceIndexMap = <String, int>{};

    _endMarkerListIndex = null;
    _leadingDividerListIndex = null;
    _trailingDividerListIndex = null;

    if (_lo == null) {
      // Nothing loaded yet: a single forward-flagged divider for startAt,
      // no backward slot (backward loading only begins once the window is
      // non-empty).
      partIndexMap[widget.startAt] = visible.length;
      visible.add(
        TransitionItem(
          previousTitle: null,
          currentTitle: widget.readerParts[widget.startAt].part.title,
          partIndexInList: widget.startAt,
          forwardMissingReason: _missingParts[widget.startAt],
          isLoadingForward: _loadingParts.contains(widget.startAt),
        ),
      );
      _trailingDividerListIndex = visible.length - 1;

      _partListIndex = partIndexMap;
      _choiceListIndex = choiceIndexMap;
      _lastVisibleItems = visible;
      return visible;
    }

    final lo = _lo!;
    final hi = _hi!;

    // Leading divider: entry into `lo`. May carry a backward error/loading
    // state for part lo-1.
    partIndexMap[lo] = visible.length;
    visible.add(
      TransitionItem(
        previousTitle: lo > 0 ? widget.readerParts[lo - 1].part.title : null,
        currentTitle: widget.readerParts[lo].part.title,
        partIndexInList: lo,
        backwardMissingReason: lo > 0 ? _missingParts[lo - 1] : null,
        isLoadingBackward: lo > 0 && _loadingParts.contains(lo - 1),
      ),
    );
    _leadingDividerListIndex = visible.length - 1;

    int? lockedItemIndex;
    bool cascadeStopped = false;

    for (int i = lo; i <= hi; i++) {
      if (i > lo) {
        // Plain boundary between two already-loaded parts — no error
        // slots, just the navigational chapter marker.
        partIndexMap[i] = visible.length;
        visible.add(
          TransitionItem(
            previousTitle: widget.readerParts[i - 1].part.title,
            currentTitle: widget.readerParts[i].part.title,
            partIndexInList: i,
          ),
        );
        lockedItemIndex = null;
      }

      final elements = _contentCache[i] ?? const <StoryElement>[];
      final isPast = i < _frontierPartIndexInList;

      for (int e = 0; e < elements.length; e++) {
        final el = elements[e];
        final item = ContentItem(el, i, e);

        if (el.requiredValue == null) {
          lockedItemIndex = null;
          visible.add(item);
          if (el is StoryChoiceElement) {
            choiceIndexMap['$i-${el.id}'] = visible.length - 1;
          }
          continue;
        }

        final key = '$i-${el.gateChoiceId}';
        final chosen = _selections[key];

        if (chosen != null) {
          final matches = el.requiredValue!
              .split(';')
              .map((s) => s.trim())
              .contains(chosen);
          if (matches) {
            lockedItemIndex = null;
            visible.add(item);
            if (el is StoryChoiceElement) {
              choiceIndexMap['$i-${el.id}'] = visible.length - 1;
            }
          }
          continue;
        }

        if (isPast) {
          continue;
        }

        final gateChoiceId = el.gateChoiceId;
        final lastVisible = visible.isNotEmpty ? visible.last : null;
        final immediatelyAfterOwnChoice =
            lastVisible is ContentItem &&
            lastVisible.element is StoryChoiceElement &&
            (lastVisible.element as StoryChoiceElement).id == gateChoiceId;

        if (!immediatelyAfterOwnChoice) {
          final lockedItem = LockedSectionItem(
            partIndexInList: i,
            gateChoiceId: gateChoiceId!,
          );
          if (lockedItemIndex != null) {
            visible[lockedItemIndex] = lockedItem;
          } else {
            visible.add(lockedItem);
            lockedItemIndex = visible.length - 1;
          }
        }

        cascadeStopped = true;
        break;
      }

      if (cascadeStopped) break;
    }

    if (!cascadeStopped) {
      if (hi == widget.readerParts.length - 1) {
        visible.add(EndOfChapterMarker());
        _endMarkerListIndex = visible.length - 1;
      } else {
        // Trailing divider: attempt into hi+1. Forward slot only — the
        // part just before it (hi) is loaded fine.
        partIndexMap[hi + 1] = visible.length;
        visible.add(
          TransitionItem(
            previousTitle: widget.readerParts[hi].part.title,
            currentTitle: widget.readerParts[hi + 1].part.title,
            partIndexInList: hi + 1,
            forwardMissingReason: _missingParts[hi + 1],
            isLoadingForward: _loadingParts.contains(hi + 1),
          ),
        );
        _trailingDividerListIndex = visible.length - 1;
      }
    }

    _partListIndex = partIndexMap;
    _choiceListIndex = choiceIndexMap;
    _lastVisibleItems = visible;
    return visible;
  }

  int _computeInitialScrollIndex(List<ReaderItem> visibleItems) {
    final resumePart = widget.resumePartOriginalIndex;
    final resumeElement = widget.resumeElementIndex;
    if (resumePart != null && resumeElement != null) {
      final listIndex = widget.readerParts.indexWhere(
        (rp) => rp.originalIndex == resumePart,
      );
      if (listIndex != -1) {
        for (int i = 0; i < visibleItems.length; i++) {
          final item = visibleItems[i];
          if (item is ContentItem &&
              item.partIndexInList == listIndex &&
              item.elementIndexInPart >= resumeElement) {
            return i;
          }
        }
      }
    }
    // No mid-part resume position to honor (a fresh part, or the saved
    // position is for a part that isn't loaded/visible yet). Land right
    // after startAt's divider — on its first real line, or its locked-
    // section card if it opens gated — instead of on the divider itself,
    // so the reader sees story content immediately rather than a
    // chapter-title card. Only startAt's own divider is skipped this way;
    // dividers reached by scrolling stay fully visible as intended.
    final dividerIndex = _partListIndex[widget.startAt];
    if (dividerIndex != null && dividerIndex + 1 < visibleItems.length) {
      return dividerIndex + 1;
    }
    return dividerIndex ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _persistProgress();
        Navigator.of(context).pop(_confirmedReadOriginalIndex);
      },
      child: Scaffold(
        backgroundColor: _settings.colors.background,
        body: SafeArea(
          child: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _toggleControls,
                child: _buildBody(),
              ),
              ReaderTopBar(
                visible: _showControls,
                title: _currentPartTitle,
                subtitle: _currentPartSubtitle,
                onBack: () {
                  _persistProgress();
                  Navigator.of(context).pop(_confirmedReadOriginalIndex);
                },
                onSettingsTap: _openSettings,
                onTocTap: _openToc,
              ),
              ReaderBottomBar(
                visible: _showControls,
                currentPart: _currentPartIndexInList + 1,
                totalParts: widget.readerParts.length,
                canGoPrev: _canGoPrev,
                canGoNext: _canGoNext,
                onPrev: _goPrev,
                onNext: _goNext,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// True only while startAt itself has never resolved (neither loaded nor
  /// marked missing). Once it resolves either way, the list is shown — a
  /// missing startAt renders as the single divider's own retry UI rather
  /// than a permanent full-screen spinner.
  bool get _showFullScreenLoader =>
      _lo == null && !_missingParts.containsKey(widget.startAt);

  Widget _buildBody() {
    if (_fatalError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Failed to load:\n$_fatalError',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }
    if (_showFullScreenLoader) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.amber),
      );
    }

    final visibleItems = _buildVisibleItems();
    final initialIndex = _computeInitialScrollIndex(visibleItems);

    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      initialScrollIndex: initialIndex,
      itemCount: visibleItems.length,
      itemBuilder: (context, index) {
        final item = visibleItems[index];
        final isFirst = index == 0;
        final isLast = index == visibleItems.length - 1;

        Widget child;
        if (item is TransitionItem) {
          child = ChapterTransitionWidget(
            previousTitle: item.previousTitle,
            currentTitle: item.currentTitle,
            settings: _settings,
            backwardMissingReason: item.backwardMissingReason,
            forwardMissingReason: item.forwardMissingReason,
            isLoadingBackward: item.isLoadingBackward,
            isLoadingForward: item.isLoadingForward,
            onRetryBackward: item.backwardMissingReason != null
                ? () => _retryPart(item.partIndexInList - 1)
                : null,
            onRetryForward: item.forwardMissingReason != null
                ? () => _retryPart(item.partIndexInList)
                : null,
          );
        } else if (item is EndOfChapterMarker) {
          child = EndOfChapterWidget(settings: _settings);
        } else if (item is LockedSectionItem) {
          child = LockedSectionWidget(
            settings: _settings,
            onGoToChoice: () =>
                _goToChoice(item.partIndexInList, item.gateChoiceId),
          );
        } else if (item is ContentItem) {
          final el = item.element;
          final selectionKey = '${item.partIndexInList}-';
          if (el is StoryChoiceElement) {
            child = ChoiceWidget(
              element: el,
              selectedValue: _selections['$selectionKey${el.id}'],
              onSelect: (value) {
                setState(() => _selections['$selectionKey${el.id}'] = value);
                _persistProgress();
              },
              settings: _settings,
            );
          } else if (el is StoryLineElement) {
            child = StoryLineWidget(line: el, settings: _settings);
          } else {
            child = const SizedBox.shrink();
          }
        } else {
          child = const SizedBox.shrink();
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            isFirst ? 70 : 0,
            20,
            isLast ? 90 : 0,
          ),
          child: child,
        );
      },
    );
  }
}
