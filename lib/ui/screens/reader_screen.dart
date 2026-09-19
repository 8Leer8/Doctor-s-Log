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
import '../widgets/reader/reader_item.dart';
import '../widgets/reader/reader_scroll_anchor.dart';
import '../widgets/reader/reader_visible_items.dart';
import '../widgets/reader/reader_item_builder.dart';
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

class _ReaderScreenState extends State<ReaderScreen> {
  final _dataSource = StoryDataSource();
  final _itemScrollController = ItemScrollController();
  final _itemPositionsListener = ItemPositionsListener.create();

  // --- Lazy-loading state -----------------------------------------------
  final Set<int> _loadedParts = {};
  final Map<int, String> _missingParts = {};
  final Set<int> _loadingParts = {};
  final Map<int, List<StoryElement>> _contentCache = {};

  int? _lo;
  int? _hi;

  bool _restoringScroll = false;

  String? _fatalError;

  /// Part currently being fetched on scroll-approach. Drives the orange
  /// "pending" divider. Held for [_kSettleDelay] after the fetch resolves
  /// so the transition reads as a smooth beat rather than a snap.
  int? _pendingPartIndex;

  static const Duration _kSettleDelay = Duration(milliseconds: 300);

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
      } else if (atTop is DialogueGroupItem) {
        _currentElementIndexInPart = atTop.firstElementIndexInPart;
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

  void _evaluateLoadTriggers(Iterable<ItemPosition> positions) {
    if (_lo == null) {
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

  ScrollAnchor? _captureScrollAnchor() {
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
      return ScrollAnchor.content(
        item.partIndexInList,
        item.elementIndexInPart,
        alignment,
      );
    } else if (item is DialogueGroupItem) {
      return ScrollAnchor.content(
        item.partIndexInList,
        item.firstElementIndexInPart,
        alignment,
      );
    } else if (item is TransitionItem) {
      return ScrollAnchor.transition(item.partIndexInList, alignment);
    } else if (item is LockedSectionItem) {
      return ScrollAnchor.locked(
        item.partIndexInList,
        item.gateChoiceId,
        alignment,
      );
    } else if (item is EndOfChapterMarker) {
      return ScrollAnchor.endMarker(alignment);
    }
    return null;
  }

  int? _resolveAnchorIndex(ScrollAnchor anchor, List<ReaderItem> items) {
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      switch (anchor.kind) {
        case AnchorKind.content:
          if (item is ContentItem &&
              item.partIndexInList == anchor.partIndexInList &&
              item.elementIndexInPart == anchor.elementIndexInPart) {
            return i;
          }
          if (item is DialogueGroupItem &&
              item.partIndexInList == anchor.partIndexInList &&
              item.firstElementIndexInPart == anchor.elementIndexInPart) {
            return i;
          }
          break;
        case AnchorKind.transition:
          if (item is TransitionItem &&
              item.partIndexInList == anchor.partIndexInList) {
            return i;
          }
          break;
        case AnchorKind.locked:
          if (item is LockedSectionItem &&
              item.partIndexInList == anchor.partIndexInList &&
              item.gateChoiceId == anchor.gateChoiceId) {
            return i;
          }
          break;
        case AnchorKind.endMarker:
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

      var targetIndex = dividerIndex;
      final items = _lastVisibleItems;
      if (items != null && dividerIndex + 1 < items.length) {
        final next = items[dividerIndex + 1];
        final belongsToTargetPart =
            (next is ContentItem && next.partIndexInList == partIndexInList) ||
            (next is DialogueGroupItem &&
                next.partIndexInList == partIndexInList) ||
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

    // Enter the pending (orange) state immediately.
    setState(() {
      _loadingParts.add(partIndexInList);
      _pendingPartIndex = partIndexInList;
      _missingParts.remove(partIndexInList);
    });

    final reasonOut = <String>[];
    final raw = await _loadPartRaw(partIndexInList, reasonOut);

    if (!mounted) return;

    // Hold the pending visual for the settle duration so the transition
    // reads as a smooth beat rather than an instant snap.
    await Future.delayed(_kSettleDelay);

    if (!mounted) return;

    if (raw == null) {
      final reason = reasonOut.isEmpty ? 'unknown' : reasonOut.first;
      setState(() {
        _loadingParts.remove(partIndexInList);
        _pendingPartIndex = null;
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
        _pendingPartIndex = null;
        _fatalError = e.toString();
      });
      return;
    }

    final isBackwardLoad = _lo != null && partIndexInList < _lo!;
    final anchor = isBackwardLoad ? _captureScrollAnchor() : null;

    final isInitialStartAtLoad =
        _lo == null && partIndexInList == widget.startAt;

    if (anchor != null || isInitialStartAtLoad) {
      _restoringScroll = true;
    }

    setState(() {
      _loadingParts.remove(partIndexInList);
      _pendingPartIndex = null;
      _contentCache[partIndexInList] = elements;
      _loadedParts.add(partIndexInList);
      _lo = (_lo == null || partIndexInList < _lo!) ? partIndexInList : _lo;
      _hi = (_hi == null || partIndexInList > _hi!) ? partIndexInList : _hi;
    });

    if (anchor != null) {
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

  /// Wrapper around the extracted builder that also updates the reader's
  /// internal index maps after each build.
  List<ReaderItem> _buildVisibleItems() {
    // Determine which side the pending part sits on so we can hand the
    // correct flag to the builder.
    int? pendingBackward;
    int? pendingForward;
    if (_pendingPartIndex != null) {
      if (_lo != null && _pendingPartIndex! < _lo!) {
        pendingBackward = _pendingPartIndex;
      } else if (_hi != null && _pendingPartIndex! > _hi!) {
        pendingForward = _pendingPartIndex;
      } else if (_lo == null) {
        // Nothing loaded yet — treat as forward.
        pendingForward = _pendingPartIndex;
      }
    }

    final result = buildReaderVisibleItems(
      readerParts: widget.readerParts,
      startAt: widget.startAt,
      lo: _lo,
      hi: _hi,
      loadedParts: _loadedParts,
      missingParts: _missingParts,
      loadingParts: _loadingParts,
      contentCache: _contentCache,
      selections: _selections,
      frontierPartIndexInList: _frontierPartIndexInList,
      pendingBackwardPartIndex: pendingBackward,
      pendingForwardPartIndex: pendingForward,
    );

    _partListIndex = result.partListIndex;
    _choiceListIndex = result.choiceListIndex;
    _endMarkerListIndex = result.endMarkerListIndex;
    _leadingDividerListIndex = result.leadingDividerListIndex;
    _trailingDividerListIndex = result.trailingDividerListIndex;

    _lastVisibleItems = result.items;
    return result.items;
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
          if (item is DialogueGroupItem &&
              item.partIndexInList == listIndex &&
              item.firstElementIndexInPart >= resumeElement) {
            return i;
          }
        }
      }
    }
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

    final itemBuilder = ReaderItemBuilder(
      settings: _settings,
      selections: _selections,
      missingParts: _missingParts,
      loadingParts: _loadingParts,
      onRetryBackward: _retryPart,
      onRetryForward: _retryPart,
      onGoToChoice: _goToChoice,
      onChoiceSelected: (partIndex, choiceId, value) {
        setState(() => _selections['$partIndex-$choiceId'] = value);
        _persistProgress();
      },
    );

    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      initialScrollIndex: initialIndex,
      itemCount: visibleItems.length,
      itemBuilder: (context, index) {
        final item = visibleItems[index];
        final isFirst = index == 0;
        final isLast = index == visibleItems.length - 1;

        final child = itemBuilder.build(context, item);

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
