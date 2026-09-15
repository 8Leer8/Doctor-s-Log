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

class _ReaderScreenState extends State<ReaderScreen> {
  final _dataSource = StoryDataSource();
  final _itemScrollController = ItemScrollController();
  final _itemPositionsListener = ItemPositionsListener.create();

  List<ReaderItem>? _rawItems;

  final Map<String, String> _selections = {};
  final Map<int, String> _missingParts = {};

  int _frontierPartIndexInList = 0;
  int _currentPartIndexInList = 0;
  int _currentElementIndexInPart = 0;

  int? _confirmedReadOriginalIndex;

  String? _error;
  bool _loading = true;
  bool _showControls = false;
  ReaderSettings _settings = const ReaderSettings();

  Map<int, int> _partListIndex = {};
  Map<String, int> _choiceListIndex = {};
  int? _endMarkerListIndex;

  @override
  void initState() {
    super.initState();
    _currentPartIndexInList = widget.startAt;
    _frontierPartIndexInList = widget.startAt;
    _itemPositionsListener.itemPositions.addListener(_onPositionsChanged);
    _seedInitialSelections();
    _fetchAll();
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

    final items = _rawItems;
    if (items != null) {
      final visible = _lastVisibleItems;
      if (visible != null && visibleListIndex < visible.length) {
        final atTop = visible[visibleListIndex];
        if (atTop is ContentItem) {
          _currentElementIndexInPart = atTop.elementIndexInPart;
        }
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
  }

  List<ReaderItem>? _lastVisibleItems;

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
      final listIndex = _partListIndex[partIndexInList];
      if (listIndex == null) return;
      _scrollToIndex(listIndex);
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

  Future<void> _fetchAll() async {
    try {
      final items = <ReaderItem>[];
      bool cascadeStopped = false;
      _missingParts.clear();

      for (int i = 0; i < widget.readerParts.length; i++) {
        final readerPart = widget.readerParts[i];

        items.add(
          TransitionItem(
            previousTitle: i == 0 ? null : widget.readerParts[i - 1].part.title,
            currentTitle: readerPart.part.title,
            partIndexInList: i,
          ),
        );

        if (cascadeStopped) continue;

        final reasonOut = <String>[];
        final raw = await _loadPartRaw(i, reasonOut);

        if (raw == null) {
          _missingParts[i] = reasonOut.isEmpty ? 'unknown' : reasonOut.first;
          cascadeStopped = true;
          continue;
        }

        final elements = StoryParser.parse(raw);
        for (int e = 0; e < elements.length; e++) {
          items.add(ContentItem(elements[e], i, e));
        }
      }

      setState(() {
        _rawItems = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Retries loading from [partIndexInList] onward, inserting content
  /// after each part's TransitionItem. Cascades forward through ALL
  /// subsequent parts (not just ones marked missing) so that parts
  /// that were never attempted during the initial fetch get loaded
  /// too. Stops only if a part genuinely fails to load.
  Future<void> _retryPart(int partIndexInList) async {
    for (int i = partIndexInList; i < widget.readerParts.length; i++) {
      // Skip parts whose content is already loaded.
      if (!_missingParts.containsKey(i) && _hasContentFor(i)) {
        continue;
      }

      final reasonOut = <String>[];
      final raw = await _loadPartRaw(i, reasonOut);

      if (raw == null) {
        // This part genuinely failed — update its reason and stop.
        if (!mounted) return;
        setState(() {
          _missingParts[i] = reasonOut.isEmpty ? 'unknown' : reasonOut.first;
        });
        AppToast.show(
          context,
          reasonOut.isNotEmpty && reasonOut.first == 'no_internet'
              ? 'Still offline · No internet'
              : 'Could not load this part',
          icon: Icons.wifi_off_rounded,
          accent: Colors.redAccent,
        );
        return;
      }

      // Success — parse and insert after this part's TransitionItem.
      final elements = StoryParser.parse(raw);
      final newContent = <ReaderItem>[];
      for (int e = 0; e < elements.length; e++) {
        newContent.add(ContentItem(elements[e], i, e));
      }

      if (!mounted) return;
      setState(() {
        _missingParts.remove(i);
        final items = _rawItems;
        if (items == null) return;
        final idx = items.indexWhere(
          (it) => it is TransitionItem && it.partIndexInList == i,
        );
        if (idx != -1) {
          // Only insert if not already present.
          if (!_hasContentFor(i)) {
            items.insertAll(idx + 1, newContent);
          }
        }
      });
    }
  }

  /// Returns true if _rawItems already has ContentItems belonging to
  /// the given part.
  bool _hasContentFor(int partIndexInList) {
    final items = _rawItems;
    if (items == null) return false;
    return items.any(
      (it) => it is ContentItem && it.partIndexInList == partIndexInList,
    );
  }

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

  List<ReaderItem> _buildVisibleItems() {
    final all = _rawItems ?? [];
    final visible = <ReaderItem>[];
    final partIndexMap = <int, int>{};
    final choiceIndexMap = <String, int>{};

    int? lockedItemIndex;
    bool cascadeStopped = false;

    for (final item in all) {
      if (cascadeStopped) {
        break;
      }

      if (item is TransitionItem) {
        partIndexMap[item.partIndexInList] = visible.length;
        visible.add(item);
        lockedItemIndex = null;

        if (_missingParts.containsKey(item.partIndexInList)) {
          cascadeStopped = true;
        }
        continue;
      }

      if (item is ContentItem) {
        final partIndex = item.partIndexInList;
        final isPast = partIndex < _frontierPartIndexInList;
        final el = item.element;

        if (el.requiredValue == null) {
          lockedItemIndex = null;
          visible.add(item);
          if (el is StoryChoiceElement) {
            choiceIndexMap['$partIndex-${el.id}'] = visible.length - 1;
          }
          continue;
        }

        final key = '$partIndex-${el.gateChoiceId}';
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
              choiceIndexMap['$partIndex-${el.id}'] = visible.length - 1;
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
            partIndexInList: partIndex,
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
        continue;
      }
    }

    if (!cascadeStopped) {
      visible.add(EndOfChapterMarker());
      _endMarkerListIndex = visible.length - 1;
    } else {
      _endMarkerListIndex = null;
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
    return _partListIndex[widget.startAt] ?? 0;
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

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.amber),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Failed to load:\n$_error',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
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
          final reason = _missingParts[item.partIndexInList];
          child = ChapterTransitionWidget(
            previousTitle: item.previousTitle,
            currentTitle: item.currentTitle,
            settings: _settings,
            missingReason: reason,
            onRetry: reason != null
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
