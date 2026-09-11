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

  // Keyed "partIndexInList-choiceId" so choices in different parts never collide.
  final Map<String, String> _selections = {};

  int _furthestPartIndex = 0; // originalIndex, reported back to the detail screen

  // Parts BEFORE this index are "the past": always rendered in full, each
  // independently gated (their own unanswered choices still lock their own
  // hidden text) but never allowed to stop later past-zone parts from
  // showing. Parts AT or AFTER this index follow normal cascading rules.
  // Only grows via an explicit jump (TOC / direct-open) — never via scroll.
  int _frontierPartIndexInList = 0;

  int _currentPartIndexInList = 0;
  String? _error;
  bool _loading = true;
  bool _showControls = false;
  ReaderSettings _settings = const ReaderSettings();

  Map<int, int> _partListIndex = {};
  Map<String, int> _choiceListIndex = {};

  @override
  void initState() {
    super.initState();
    _currentPartIndexInList = widget.startAt;
    _frontierPartIndexInList = widget.startAt;
    _furthestPartIndex = widget.startAt;
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

  /// Only updates which part's title/subtitle is shown, and the furthest
  /// point reached (for progress reporting). Never grows the frontier —
  /// scrolling must never be able to bypass a lock.
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

    if (bestPart != null && bestPart != _currentPartIndexInList) {
      final originalIndex = widget.readerParts[bestPart!].originalIndex;
      if (originalIndex > _furthestPartIndex) {
        _furthestPartIndex = originalIndex;
      }
      setState(() => _currentPartIndexInList = bestPart!);
    }
  }

  void _scrollToIndex(int index) {
    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Scrolls to a part ONLY if it's already rendered (in the past zone,
  /// or reached normally without a lock in between). Never unlocks
  /// anything. This is what Prev/Next use — ordinary sequential reading
  /// must never grant bypass privileges.
  void _scrollToRenderedPart(int partIndexInList) {
    final listIndex = _partListIndex[partIndexInList];
    if (listIndex == null) return; // not reachable yet — button should be disabled anyway
    _scrollToIndex(listIndex);
  }

  /// Explicit jump (TOC, or opening a specific part from the detail
  /// screen). Grows the frontier to the target if needed, converting
  /// everything before it into the non-cascading "past" zone, THEN
  /// scrolls once the rebuild has made the target's position known.
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
      _currentPartIndexInList < widget.readerParts.length - 1 &&
      _partListIndex.containsKey(_currentPartIndexInList + 1);

  void _goPrev() {
    if (!_canGoPrev) return;
    _scrollToRenderedPart(_currentPartIndexInList - 1);
  }

  void _goNext() {
    if (!_canGoNext) return;
    _scrollToRenderedPart(_currentPartIndexInList + 1);
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

  /// Single linear pass over the raw (part-ordered) item stream.
  ///
  /// - Parts with index < frontier ("the past"): always fully processed —
  ///   an unanswered choice there still shows a lock placeholder (hidden
  ///   text stays hidden), but does NOT stop later past-zone parts from
  ///   being added.
  /// - Parts with index >= frontier (cascading zone): normal sequential
  ///   rule. The first unanswered choice locks, we add exactly ONE more
  ///   teaser divider for the immediately following part (so the reader
  ///   knows more exists), then generation stops completely — nothing
  ///   further is added, regardless of how many parts remain.
  List<ReaderItem> _buildVisibleItems() {
    final all = _rawItems ?? [];
    final visible = <ReaderItem>[];
    final partIndexMap = <int, int>{};
    final choiceIndexMap = <String, int>{};

    int? lockedItemIndex;
    bool cascadeStopped = false;

    for (final item in all) {
      if (cascadeStopped) {
        // Only looking for the next transition marker to use as a single
        // teaser divider, then we're done entirely.
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
          // else: resolved branch not taken — skip just this one item.
          continue;
        }

        // Unanswered choice's gated content — lock it here.
        final lockedItem = LockedSectionItem(
          partIndexInList: partIndex,
          gateChoiceId: el.gateChoiceId!,
        );
        if (lockedItemIndex != null) {
          visible[lockedItemIndex] = lockedItem;
        } else {
          visible.add(lockedItem);
          lockedItemIndex = visible.length - 1;
        }

        if (!isPast) {
          // In the cascading zone — this stops everything going forward.
          cascadeStopped = true;
        }
        continue;
      }
    }

    if (!cascadeStopped) {
      visible.add(EndOfChapterMarker());
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
        Navigator.of(context).pop(_furthestPartIndex);
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
                onBack: () => Navigator.of(context).pop(_furthestPartIndex),
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