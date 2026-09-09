import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/reader_part.dart';
import '../../models/story_element.dart';
import '../../data/remote/story_data_source.dart';
import '../../data/parser/story_parser.dart';
import '../widgets/chapter_transition_widget.dart';
import '../widgets/reader/reader_item.dart';
import '../widgets/reader/story_line_widget.dart';
import '../widgets/reader/choice_widget.dart';
import '../widgets/reader/end_of_chapter_widget.dart';
import '../widgets/reader/reader_top_bar.dart';
import '../widgets/reader/reader_bottom_bar.dart';

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
  final _scrollController = ScrollController();
  final _endKey = GlobalKey();
  final Map<int, GlobalKey> _transitionKeys = {};

  List<ReaderItem>? _items;
  final Map<String, String> _selections = {};
  int _furthestPartIndex = 0;
  int _currentPartIndexInList = 0;
  bool _reachedEnd = false;
  String? _error;
  bool _loading = true;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    _currentPartIndexInList = widget.startAt;
    _furthestPartIndex = widget.startAt;
    _fetchAll();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(int partIndexInList) =>
      _transitionKeys.putIfAbsent(partIndexInList, () => GlobalKey());

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    _updateCurrentPart();
  }

  void _updateCurrentPart() {
    const thresholdPx = 70.0;

    int? bestIndex;
    _transitionKeys.forEach((partIndex, key) {
      final ctx = key.currentContext;
      if (ctx == null) return;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) return;
      final dy = box.localToGlobal(Offset.zero).dy;
      if (dy <= thresholdPx) {
        if (bestIndex == null || partIndex > bestIndex!) bestIndex = partIndex;
      }
    });

    bool endVisible = false;
    final endCtx = _endKey.currentContext;
    if (endCtx != null) {
      final box = endCtx.findRenderObject() as RenderBox?;
      if (box != null && box.attached) {
        final dy = box.localToGlobal(Offset.zero).dy;
        final screenHeight = MediaQuery.of(context).size.height;
        if (dy <= screenHeight) endVisible = true;
      }
    }

    if (bestIndex != null && bestIndex != _currentPartIndexInList) {
      final originalIndex = widget.readerParts[bestIndex!].originalIndex;
      setState(() {
        _currentPartIndexInList = bestIndex!;
        if (originalIndex > _furthestPartIndex) {
          _furthestPartIndex = originalIndex;
        }
      });
    }
    if (endVisible != _reachedEnd) {
      setState(() => _reachedEnd = endVisible);
    }
  }

  double get _progress {
    final totalParts = widget.readerParts.length;
    if (_reachedEnd) return 1.0;
    if (totalParts <= 1) return 0.0;
    return (_currentPartIndexInList / (totalParts - 1)).clamp(0.0, 1.0);
  }

  String get _currentPartTitle {
    if (widget.readerParts.isEmpty) return widget.chapterTitle;
    final index = _currentPartIndexInList.clamp(0, widget.readerParts.length - 1);
    return widget.readerParts[index].part.title;
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
        _items = items;
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

  bool _isGateSatisfied(StoryElement el) {
    if (el.requiredValue == null) return true;
    final key = '${el.gateChoiceId}';
    final chosen = _selections[key];
    if (chosen == null) return false;
    return el.requiredValue!.split(';').map((s) => s.trim()).contains(chosen);
  }

  List<ReaderItem> _buildVisibleItems() {
    final all = _items ?? [];
    final visible = <ReaderItem>[];

    for (final item in all) {
      if (item is TransitionItem) {
        visible.add(item);
        continue;
      }
      if (item is ContentItem) {
        final el = item.element;

        if (!_isGateSatisfied(el)) continue;

        visible.add(item);

        if (el is StoryChoiceElement) {
          final answered = _selections.containsKey('${el.id}');
          if (!answered) return visible;
        }
      }
    }

    visible.add(EndOfChapterMarker());
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
        backgroundColor: AppColors.background,
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
                onBack: () => Navigator.of(context).pop(_furthestPartIndex),
              ),
              ReaderBottomBar(visible: _showControls, progress: _progress),
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
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 70, 20, 90),
      itemCount: visibleItems.length,
      itemBuilder: (context, index) {
        final item = visibleItems[index];

        if (item is TransitionItem) {
          return KeyedSubtree(
            key: _keyFor(item.partIndexInList),
            child: ChapterTransitionWidget(
              previousTitle: item.previousTitle,
              currentTitle: item.currentTitle,
            ),
          );
        }

        if (item is EndOfChapterMarker) {
          return KeyedSubtree(key: _endKey, child: const EndOfChapterWidget());
        }

        if (item is ContentItem) {
          final el = item.element;
          if (el is StoryChoiceElement) {
            return ChoiceWidget(
              element: el,
              selectedValue: _selections['${el.id}'],
              onSelect: (value) {
                setState(() {
                  _selections['${el.id}'] = value;
                });
              },
            );
          }
          if (el is StoryLineElement) {
            return StoryLineWidget(line: el);
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
}