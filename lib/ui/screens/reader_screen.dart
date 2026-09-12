import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../theme/app_theme.dart';
import '../../models/reader_part.dart';
import '../../models/story_element.dart';
import '../../models/reader_settings.dart';
import '../../data/remote/story_data_source.dart';
import '../../data/parser/story_parser.dart';
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

class ReaderScreen extends StatefulWidget {
  final String chapterTitle;
  final List<ReaderPart> readerParts;
  final int startAt;

  const ReaderScreen({
    super.key,
    required this.chapterTitle,
    required this.readerParts,
    this.startAt = 0,
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

  // Governs CONTENT GENERATION (choice gating / past-vs-cascading zone).
  // Grows only via explicit jump (TOC, prev/next). Parts before this are
  // "the past" — rendered in full regardless of their own unanswered
  // choices, and never stop later past-zone parts from rendering.
  int _frontierPartIndexInList = 0;

  // Which part is currently at/near the top of the viewport — drives the
  // title bar, part counter, and prev/next buttons.
  int _currentPartIndexInList = 0;

  // Governs what gets reported back as "read" when the screen closes.
  // Starts null. Only advances when the reader has GENUINELY scrolled
  // past a part boundary, or reached the true end of the chapter —
  // completely independent from the frontier above, so simply opening a
  // part (even one reached via jump) never marks it read on its own.
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
    _fetchAll();
    if (_settings.keepScreenAwake) {
      WakelockPlus.enable();
    }
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onPositionsChanged);
    WakelockPlus.disable();
    super.dispose();
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
      // The part just before whatever is now at the top has genuinely
      // been scrolled past — confirm it (and transitively everything
      // before it) as read. Only ever moves forward, never resets on
      // scrolling back up.
      if (bestPart! > 0) {
        final justBeforeOriginal = widget.readerParts[bestPart! - 1].originalIndex;
        if (_confirmedReadOriginalIndex == null || justBeforeOriginal > _confirmedReadOriginalIndex!) {
          _confirmedReadOriginalIndex = justBeforeOriginal;
        }
      }

      if (bestPart != _currentPartIndexInList) {
        setState(() => _currentPartIndexInList = bestPart!);
      }
    }

    if (_endMarkerListIndex != null &&
        positions.any((p) => p.index == _endMarkerListIndex)) {
      // Reached the true end of everything currently loaded — the last
      // part itself is now confirmed read too.
      final lastOriginal = widget.readerParts.last.originalIndex;
      if (_confirmedReadOriginalIndex == null || lastOriginal > _confirmedReadOriginalIndex!) {
        _confirmedReadOriginalIndex = lastOriginal;
      }
    }
  }

  void _scrollToIndex(int index) {
    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
  bool get _canGoNext => _currentPartIndexInList < widget.readerParts.length - 1;

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
    final index = _currentPartIndexInList.clamp(0, widget.readerParts.length - 1);
    return widget.readerParts[index].part.title;
  }

  String? get _currentPartSubtitle {
    if (widget.readerParts.isEmpty) return null;
    final index = _currentPartIndexInList.clamp(0, widget.readerParts.length - 1);
    return widget.readerParts[index].part.avgTag;
  }

  Future<void> _fetchAll() async {
    try {
      final items = <ReaderItem>[];
      for (int i = 0; i < widget.readerParts.length; i++) {
        final readerPart = widget.readerParts[i];

        items.add(TransitionItem(
          previousTitle: i == 0 ? null : widget.readerParts[i - 1].part.title,
          currentTitle: readerPart.part.title,
          partIndexInList: i,
        ));

        final raw = await _dataSource.fetchRawStory(readerPart.part.filename!);
        final elements = StoryParser.parse(raw);
        for (final el in elements) {
          items.add(ContentItem(el, i));
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

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _openSettings() {
    ReaderSettingsSheet.show(context, _settings, (updated) {
      final wakelockChanged = updated.keepScreenAwake != _settings.keepScreenAwake;
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
    ReaderTocSheet.show(context, widget.readerParts, _currentPartIndexInList, (index) {
      _jumpToPart(index);
    });
  }

  /// Full visible item list. Gating uses the frontier: parts before it
  /// ("the past") always render in full; the frontier part and everything
  /// after follows normal sequential rules — render until the first
  /// unanswered choice, then stop generating content entirely from there
  /// on (across remaining parts too), showing exactly one more transition
  /// marker as a teaser.
  List<ReaderItem> _buildVisibleItems() {
    final all = _rawItems ?? [];
    final visible = <ReaderItem>[];
    final partIndexMap = <int, int>{};
    final choiceIndexMap = <String, int>{};

    int? lockedItemIndex;
    bool cascadeStopped = false;

    for (final item in all) {
      if (cascadeStopped) {
        if (item is TransitionItem) {
          partIndexMap[item.partIndexInList] = visible.length;
          visible.add(item);
        }
        break;
      }

      if (item is TransitionItem) {
        partIndexMap[item.partIndexInList] = visible.length;
        visible.add(item);
        lockedItemIndex = null;
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
          final matches = el.requiredValue!.split(';').map((s) => s.trim()).contains(chosen);
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
          // Unresolved choice already behind us — no card, just silently
          // omit the gated content. Not actionable there, not clutter.
          continue;
        }

        final gateChoiceId = el.gateChoiceId;
        final lastVisible = visible.isNotEmpty ? visible.last : null;
        final immediatelyAfterOwnChoice = lastVisible is ContentItem &&
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
    return visible;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
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
                onBack: () => Navigator.of(context).pop(_confirmedReadOriginalIndex),
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
      return const Center(child: CircularProgressIndicator(color: AppColors.amber));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Failed to load:\n$_error', style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    }

    final visibleItems = _buildVisibleItems();
    final initialIndex = _partListIndex[widget.startAt] ?? 0;

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
          );
        } else if (item is EndOfChapterMarker) {
          child = EndOfChapterWidget(settings: _settings);
        } else if (item is LockedSectionItem) {
          child = LockedSectionWidget(
            settings: _settings,
            onGoToChoice: () => _goToChoice(item.partIndexInList, item.gateChoiceId),
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