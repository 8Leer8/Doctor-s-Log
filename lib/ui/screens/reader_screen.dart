import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/story_part.dart';
import '../../models/story_element.dart';
import '../../data/remote/story_data_source.dart';
import '../../data/parser/story_parser.dart';
import '../widgets/chapter_transition_widget.dart';

class ReaderPart {
  final int originalIndex;
  final StoryPart part;
  const ReaderPart({required this.originalIndex, required this.part});
}

abstract class _ReaderItem {}

class _ContentItem extends _ReaderItem {
  final StoryElement element;
  final int partIndexInList;
  _ContentItem(this.element, this.partIndexInList);
}

class _TransitionItem extends _ReaderItem {
  final String? previousTitle;
  final String currentTitle;
  final int partIndexInList;
  _TransitionItem({required this.previousTitle, required this.currentTitle, required this.partIndexInList});
}

class _EndOfChapterItem extends _ReaderItem {}

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

  List<_ReaderItem>? _items;
  final Map<String, String> _selections = {};
  int _furthestPartIndex = 0;
  String? _error;
  bool _loading = true;
  bool _showControls = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
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

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    setState(() {
      _progress = max == 0 ? 1 : (offset / max).clamp(0.0, 1.0);
    });
  }

  Future<void> _fetchAll() async {
    try {
      final items = <_ReaderItem>[];
      for (int i = 0; i < widget.readerParts.length; i++) {
        final readerPart = widget.readerParts[i];

        items.add(_TransitionItem(
          previousTitle: i == 0 ? null : widget.readerParts[i - 1].part.title,
          currentTitle: readerPart.part.title,
          partIndexInList: i,
        ));

        final raw = await _dataSource.fetchRawStory(readerPart.part.filename!);
        final elements = StoryParser.parse(raw);
        for (final el in elements) {
          items.add(_ContentItem(el, i));
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

  /// Walks items in order. Stops immediately after showing an unanswered
  /// choice — nothing beyond it renders until it's answered. If the whole
  /// list is consumed without stopping, appends an end-of-chapter card.
  List<_ReaderItem> _buildVisibleItems() {
    final all = _items ?? [];
    final visible = <_ReaderItem>[];

    for (final item in all) {
      if (item is _TransitionItem) {
        visible.add(item);
        continue;
      }
      if (item is _ContentItem) {
        final el = item.element;

        if (!_isGateSatisfied(el)) {
          // Gated by a choice not yet answered (or answered differently) — skip silently.
          continue;
        }

        visible.add(item);

        if (el is StoryChoiceElement) {
          final key = '${el.id}';
          final answered = _selections.containsKey(key);
          if (!answered) {
            // Stop here — force the reader to answer before seeing more.
            return visible;
          }
        }
      }
    }

    visible.add(_EndOfChapterItem());
    return visible;
  }

  void _onTransitionReached(int partIndexInList) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final originalIndex = widget.readerParts[partIndexInList].originalIndex;
      if (originalIndex > _furthestPartIndex) {
        setState(() => _furthestPartIndex = originalIndex);
      }
    });
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
              _TopBar(
                visible: _showControls,
                title: widget.chapterTitle,
                onBack: () => Navigator.of(context).pop(_furthestPartIndex),
              ),
              _BottomBar(visible: _showControls, progress: _progress),
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

        if (item is _TransitionItem) {
          _onTransitionReached(item.partIndexInList);
          return ChapterTransitionWidget(
            previousTitle: item.previousTitle,
            currentTitle: item.currentTitle,
          );
        }

        if (item is _EndOfChapterItem) {
          return const _EndOfChapterWidget();
        }

        if (item is _ContentItem) {
          final el = item.element;
          if (el is StoryChoiceElement) {
            return _ChoiceWidget(
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
            return _StoryLineWidget(line: el);
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _EndOfChapterWidget extends StatelessWidget {
  const _EndOfChapterWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20, bottom: 60),
      child: ClipPath(
        clipper: CutCornerClipper(cut: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
          ),
          child: const Column(
            children: [
              Icon(Icons.check_circle, color: AppColors.amber, size: 32),
              SizedBox(height: 10),
              Text(
                'CHAPTER FINISHED',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'You\'ve reached the end.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryLineWidget extends StatelessWidget {
  final StoryLineElement line;
  const _StoryLineWidget({required this.line});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: AppColors.textPrimary,
          ),
          children: [
            if (line.speaker != null)
              TextSpan(
                text: '${line.speaker}: ',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.amber,
                ),
              ),
            TextSpan(
              text: line.text,
              style: line.speaker == null
                  ? const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceWidget extends StatelessWidget {
  final StoryChoiceElement element;
  final String? selectedValue;
  final ValueChanged<String> onSelect;

  const _ChoiceWidget({
    required this.element,
    required this.selectedValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ClipPath(
        clipper: CutCornerClipper(cut: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.fork_right, size: 16, color: AppColors.amber),
                  SizedBox(width: 6),
                  Text(
                    'CHOICE',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...element.options.map((opt) {
                final isSelected = selectedValue == opt.value;
                final hasSelection = selectedValue != null;

                if (hasSelection && !isSelected) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: GestureDetector(
                      onTap: () => onSelect(opt.value),
                      child: Text(
                        'You didn\'t choose: ${opt.label}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.coldGray,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    onTap: () => onSelect(opt.value),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.amber.withValues(alpha: 0.15)
                            : AppColors.surfaceRaised,
                        border: Border.all(
                          color: isSelected ? AppColors.amber : AppColors.border,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          if (isSelected)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(Icons.check, size: 14, color: AppColors.amber),
                            ),
                          Expanded(
                            child: Text(
                              opt.label,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected ? AppColors.amber : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (selectedValue == null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Pick an option to continue reading.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.coldGray,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool visible;
  final String title;
  final VoidCallback onBack;

  const _TopBar({
    required this.visible,
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: visible ? 0 : -60,
      left: 0,
      right: 0,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          border: const Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: onBack,
            ),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppColors.coldGray),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool visible;
  final double progress;

  const _BottomBar({required this.visible, required this.progress});

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      bottom: visible ? 0 : -70,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.amber,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.amber,
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: progress,
                onChanged: (_) {},
              ),
            ),
            Text(
              '${(progress * 100).round()}% read',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}