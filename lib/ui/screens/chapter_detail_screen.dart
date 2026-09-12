import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/chapter_preview.dart';
import '../../models/reader_part.dart';
import '../../data/remote/story_data_source.dart';
import '../../data/parser/word_count_estimator.dart';
import '../../data/local/chapter_descriptions_loader.dart';
import 'reader_screen.dart';
import '../widgets/chapter_detail/detail_action_button.dart';
import '../widgets/chapter_detail/detail_part_row.dart';
import '../widgets/chapter_detail/chapter_header_image.dart';
import '../widgets/chapter_detail/part_filter_sort_sheet.dart';

String _formatActType(String raw) {
  switch (raw) {
    case 'MAIN_STORY':
      return 'Main Story';
    case 'ACTIVITY_STORY':
      return 'Event Story';
    default:
      return raw
          .split('_')
          .map((w) => w.isEmpty ? w : '${w[0]}${w.substring(1).toLowerCase()}')
          .join(' ');
  }
}

class ChapterDetailScreen extends StatefulWidget {
  final ChapterPreview chapter;

  const ChapterDetailScreen({super.key, required this.chapter});

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen> {
  late List<bool> _finished;
  final Set<int> _downloaded = {};

  final _dataSource = StoryDataSource();
  int? _totalWordCount;
  bool _computingWordCount = true;

  String? _description;
  bool _descriptionLoaded = false;

  PartFilterMode _filterMode = PartFilterMode.all;
  PartSortOrder _sortOrder = PartSortOrder.ascending;

  @override
  void initState() {
    super.initState();
    _finished = widget.chapter.parts.map((p) => p.finished).toList();
    _computeWordCount();
    _loadDescription();
  }

  Future<void> _loadDescription() async {
    final descriptions = await ChapterDescriptionsLoader.load();
    final desc = descriptions[widget.chapter.number];
    if (mounted) {
      setState(() {
        _description = desc;
        _descriptionLoaded = true;
      });
    }
  }

  Future<void> _computeWordCount() async {
    int total = 0;
    for (final part in widget.chapter.parts) {
      if (part.filename == null) continue;
      try {
        final raw = await _dataSource.fetchRawStory(part.filename!);
        total += WordCountEstimator.countWords(raw);
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _totalWordCount = total;
        _computingWordCount = false;
      });
    }
  }

  int get _finishedCount => _finished.where((f) => f).length;

  List<ReaderPart> get _playableParts {
    final result = <ReaderPart>[];
    for (int i = 0; i < widget.chapter.parts.length; i++) {
      final p = widget.chapter.parts[i];
      if (p.filename != null) {
        result.add(ReaderPart(originalIndex: i, part: p));
      }
    }
    return result;
  }

  List<int> get _displayIndices {
    var indices = List<int>.generate(widget.chapter.parts.length, (i) => i);

    indices = indices.where((i) {
      switch (_filterMode) {
        case PartFilterMode.all:
          return true;
        case PartFilterMode.unread:
          return !_finished[i];
        case PartFilterMode.read:
          return _finished[i];
      }
    }).toList();

    if (_sortOrder == PartSortOrder.descending) {
      indices = indices.reversed.toList();
    }

    return indices;
  }

  Future<bool> _confirmSkipAheadIfNeeded(int originalIndex) async {
    final firstUnfinished = _finished.indexWhere((f) => !f);
    final isSkippingAhead = firstUnfinished != -1 && originalIndex > firstUnfinished;
    if (!isSkippingAhead) return true;

    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 20),
            SizedBox(width: 8),
            Text('Skip ahead?',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'Reading from the top keeps the story\'s flow and immersion intact. '
          'You still have earlier unread parts — jumping ahead may skip context or spoil what happens next.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.coldGray, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('READ ANYWAY', style: TextStyle(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _openPart(int originalIndex) async {
    final proceed = await _confirmSkipAheadIfNeeded(originalIndex);
    if (!proceed || !mounted) return;

    final playable = _playableParts;
    final startAt = playable.indexWhere((rp) => rp.originalIndex == originalIndex);

    if (startAt == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This part isn't mapped to a source file yet.")),
      );
      return;
    }

    final furthestOriginalIndex = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          chapterTitle: widget.chapter.title,
          readerParts: playable,
          startAt: startAt,
        ),
      ),
    );

    if (furthestOriginalIndex == null || !mounted) return;
    setState(() {
      for (int i = 0; i <= furthestOriginalIndex && i < _finished.length; i++) {
        _finished[i] = true;
      }
    });
  }

  void _continueReading() {
    final nextIndex = _finished.indexWhere((f) => !f);
    _openPart(nextIndex == -1 ? 0 : nextIndex);
  }

  void _markAllFinished() {
    setState(() => _finished = List.filled(_finished.length, true));
  }

  void _clearAll() {
    setState(() => _finished = List.filled(_finished.length, false));
  }

  void _openFilterSort() {
    PartFilterSortSheet.show(
      context,
      filterMode: _filterMode,
      sortOrder: _sortOrder,
      onFilterChanged: (mode) => setState(() => _filterMode = mode),
      onSortChanged: (order) => setState(() => _sortOrder = order),
    );
  }

  void _downloadAll() {
    setState(() {
      for (int i = 0; i < widget.chapter.parts.length; i++) {
        if (widget.chapter.parts[i].filename != null) _downloaded.add(i);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chapter = widget.chapter;
    final total = chapter.parts.length;
    final progressRatio = total == 0 ? 0.0 : _finishedCount / total;
    final displayIndices = _displayIndices;
    final formattedType = _formatActType(chapter.subtitle);

    return Scaffold(
      backgroundColor: AppColors.background,
      // The top bar floats over the content instead of pushing it down,
      // so the header image is visible directly behind it (Mihon-style).
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ChapterHeaderImage(
                        chapterId: chapter.number,
                        title: chapter.title,
                        subtitleLabel: formattedType,
                      ),
                      // The fade to the page background sits only at the
                      // very bottom edge of the image, overlapping into
                      // where the action buttons begin — the title and
                      // description above stay clear of any fade.
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 60,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppColors.background,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          _descriptionLoaded && _description != null
                              ? _description!
                              : (_descriptionLoaded ? 'No description available.' : ''),
                          style: TextStyle(
                            fontSize: 13,
                            color: (_descriptionLoaded && _description == null)
                                ? AppColors.coldGray
                                : AppColors.textSecondary,
                            fontStyle: (_descriptionLoaded && _description == null)
                                ? FontStyle.italic
                                : FontStyle.normal,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            DetailActionButton(
                              label: 'CONTINUE',
                              icon: Icons.play_arrow,
                              filled: true,
                              onPressed: _continueReading,
                            ),
                            DetailActionButton(
                              label: 'MARK ALL READ',
                              icon: Icons.check,
                              onPressed: _markAllFinished,
                            ),
                            DetailActionButton(
                              label: 'CLEAR ALL',
                              icon: Icons.refresh,
                              onPressed: _clearAll,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progressRatio,
                            minHeight: 4,
                            backgroundColor: AppColors.border,
                            valueColor: const AlwaysStoppedAnimation(AppColors.amber),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _computingWordCount
                                  ? 'Calculating...'
                                  : '${_totalWordCount ?? 0} words · about ${WordCountEstimator.estimateMinutes(_totalWordCount ?? 0)}m',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            Text(
                              '$_finishedCount OF $total FINISHED',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.amber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '$total PARTS',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: AppColors.amber,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...displayIndices.map((index) {
                          final part = chapter.parts[index];
                          return DetailPartRow(
                            part: part,
                            finished: _finished[index],
                            downloaded: _downloaded.contains(index),
                            onToggleFinished: () =>
                                setState(() => _finished[index] = !_finished[index]),
                            onToggleDownload: () => setState(() {
                              if (_downloaded.contains(index)) {
                                _downloaded.remove(index);
                              } else {
                                _downloaded.add(index);
                              }
                            }),
                            onOpen: () => _openPart(index),
                          );
                        }),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: _TopBar(
              onBack: () => Navigator.of(context).pop(),
              onDownloadAll: _downloadAll,
              onFilterTap: _openFilterSort,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onDownloadAll;
  final VoidCallback onFilterTap;

  const _TopBar({
    required this.onBack,
    required this.onDownloadAll,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.transparent,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBack,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            tooltip: 'Download all',
            onPressed: onDownloadAll,
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            tooltip: 'Filter & sort',
            onPressed: onFilterTap,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white),
            color: AppColors.surface,
            onSelected: (value) {},
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'refresh', child: Text('Refresh', style: TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(value: 'wiki', child: Text('Open Wiki', style: TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(value: 'share', child: Text('Share', style: TextStyle(color: AppColors.textPrimary))),
            ],
          ),
        ],
      ),
    );
  }
}