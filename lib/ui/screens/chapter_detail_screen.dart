import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/chapter_preview.dart';
import '../../models/story_category.dart';
import '../../models/reader_part.dart';
import '../../models/story_element.dart';
import '../../data/remote/story_data_source.dart';
import '../../data/parser/word_count_estimator.dart';
import '../../data/parser/story_parser.dart';
import '../../data/parser/image_prefetcher.dart';
import '../../data/local/chapter_descriptions_loader.dart';
import '../../data/local/reading_progress_store.dart';
import '../../data/local/download_store.dart';
import '../../utils/chapter_detail_dialogs.dart';
import '../widgets/common/app_toast.dart';
import 'reader_screen.dart';
import '../widgets/chapter_detail/detail_action_button.dart';
import '../widgets/chapter_detail/chapter_detail_header.dart';
import '../widgets/chapter_detail/chapter_detail_body.dart';
import '../widgets/chapter_detail/chapter_detail_top_bar.dart';
import '../widgets/chapter_detail/chapter_header_image.dart';
import '../widgets/chapter_detail/part_filter_sort_sheet.dart';
import '../widgets/chapter_detail/detail_part_row.dart';

const double _kToolbarHeight = 64;

class ChapterDetailScreen extends StatefulWidget {
  final ChapterPreview chapter;
  final StoryCategory category;

  const ChapterDetailScreen({
    super.key,
    required this.chapter,
    required this.category,
  });

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen> {
  List<bool> _finished = [];
  final Map<int, DownloadState> _downloadStates = {};
  final _scrollController = ScrollController();

  final _dataSource = StoryDataSource();
  int? _totalWordCount;
  bool _computingWordCount = true;

  String? _description;
  bool _descriptionLoaded = false;

  double _collapseFraction = 0;
  double _titleFraction = 0;

  PartFilterMode _filterMode = PartFilterMode.all;
  PartSortOrder _sortOrder = PartSortOrder.ascending;

  bool get _isSideStory => widget.category == StoryCategory.sideStory;

  @override
  void initState() {
    super.initState();
    _finished = widget.chapter.parts.map((p) => p.finished).toList();
    for (int i = 0; i < widget.chapter.parts.length; i++) {
      _downloadStates[i] = DownloadState.notDownloaded;
    }
    _loadFinishedProgress();
    _loadDownloadStates();
    _computeWordCount();
    _loadDescription();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFinishedProgress() async {
    final finishedSet = await ReadingProgressStore.getFinishedParts(
      widget.chapter.number,
    );
    if (!mounted || finishedSet.isEmpty) return;
    setState(() {
      for (final i in finishedSet) {
        if (i >= 0 && i < _finished.length) _finished[i] = true;
      }
    });
  }

  Future<void> _saveFinishedProgress() async {
    final finishedIndices = <int>{};
    for (int i = 0; i < _finished.length; i++) {
      if (_finished[i]) finishedIndices.add(i);
    }
    await ReadingProgressStore.setFinishedParts(
      widget.chapter.number,
      finishedIndices,
    );
  }

  Future<void> _loadDownloadStates() async {
    for (int i = 0; i < widget.chapter.parts.length; i++) {
      final filename = widget.chapter.parts[i].filename;
      if (filename == null) continue;
      final isDownloaded = await DownloadStore.isDownloaded(filename);
      if (isDownloaded && mounted) {
        setState(() => _downloadStates[i] = DownloadState.downloaded);
      }
    }
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

  bool _isNetworkError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('connection error') ||
        s.contains('connectionerror') ||
        s.contains('no address associated');
  }

  Future<void> _toggleDownload(int index) async {
    final filename = widget.chapter.parts[index].filename;
    if (filename == null) return;

    final currentState = _downloadStates[index] ?? DownloadState.notDownloaded;

    if (currentState == DownloadState.downloaded) {
      final confirmed = await showDeleteDownloadDialog(context);
      if (confirmed != true) return;

      await ImagePrefetcher.releaseImagesForPart(filename);
      await DownloadStore.deleteContent(filename);

      if (mounted) {
        setState(() => _downloadStates[index] = DownloadState.notDownloaded);
      }
      return;
    }

    if (currentState == DownloadState.downloading) return;

    setState(() => _downloadStates[index] = DownloadState.downloading);
    try {
      final content = await _dataSource.fetchRawStory(filename);

      if (content.trim().isEmpty || content.length < 50) {
        throw Exception('Downloaded content is empty or too short');
      }

      await DownloadStore.saveContent(filename, content);

      final verify = await DownloadStore.getContent(filename);
      if (verify == null || verify.isEmpty) {
        throw Exception('Failed to persist content to disk');
      }

      List<StoryElement> elements;
      try {
        elements = StoryParser.parse(content);
      } catch (_) {
        elements = const [];
      }

      PrefetchResult? prefetchResult;
      try {
        prefetchResult = await ImagePrefetcher.prefetch(
          elements: elements,
          partFilename: filename,
        );
      } catch (_) {
        prefetchResult = null;
      }

      if (mounted) {
        setState(() => _downloadStates[index] = DownloadState.downloaded);

        if (prefetchResult != null && prefetchResult.failedIds.isNotEmpty) {
          AppToast.show(
            context,
            'Downloaded · ${prefetchResult.failedIds.length} image(s) failed',
            icon: Icons.warning_amber_rounded,
            accent: AppColors.amber,
          );
        } else {
          AppToast.show(
            context,
            'Downloaded: ${widget.chapter.parts[index].title}',
            icon: Icons.check_circle_outline,
            accent: AppColors.amber,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _downloadStates[index] = DownloadState.notDownloaded);

      if (_isNetworkError(e)) {
        AppToast.noInternet(context);
      } else {
        AppToast.failed(context, 'Download failed: $e');
      }
    }
  }

  Future<void> _downloadAll() async {
    for (int i = 0; i < widget.chapter.parts.length; i++) {
      if (_downloadStates[i] == DownloadState.notDownloaded) {
        await _toggleDownload(i);
      }
    }
  }

  double _mainThemeHeaderHeight(BuildContext context) =>
      MediaQuery.of(context).size.width;

  double _sideStoryHeaderHeight(BuildContext context) =>
      MediaQuery.of(context).size.width / 3.12;

  void _onScroll() {
    final offset = _scrollController.offset;

    const fillRangePx = 40.0;
    final fillFraction = (offset / fillRangePx).clamp(0.0, 1.0);

    final headerHeight = _isSideStory
        ? _sideStoryHeaderHeight(context)
        : _mainThemeHeaderHeight(context);
    final titleStart = headerHeight - _kToolbarHeight + 20;
    const titleRangePx = 60.0;
    final titleFraction = ((offset - titleStart) / titleRangePx).clamp(
      0.0,
      1.0,
    );

    if (fillFraction != _collapseFraction || titleFraction != _titleFraction) {
      setState(() {
        _collapseFraction = fillFraction;
        _titleFraction = titleFraction;
      });
    }
  }

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

  Future<void> _openPart(
    int originalIndex, {
    bool useResumePosition = false,
  }) async {
    final proceed = await showSkipAheadDialogIfNeeded(
      context: context,
      finished: _finished,
      targetOriginalIndex: originalIndex,
    );
    if (!proceed || !mounted) return;

    final playable = _playableParts;
    final startAt = playable.indexWhere(
      (rp) => rp.originalIndex == originalIndex,
    );

    if (startAt == -1) {
      AppToast.show(
        context,
        "This part isn't mapped to a source file yet.",
        icon: Icons.link_off,
        accent: AppColors.coldGray,
      );
      return;
    }

    final filename = playable[startAt].part.filename!;
    final isDownloaded = await DownloadStore.isDownloaded(filename);

    if (!isDownloaded) {
      try {
        await _dataSource.fetchRawStory(filename);
      } catch (e) {
        if (!mounted) return;
        if (_isNetworkError(e)) {
          AppToast.show(
            context,
            'Not downloaded · No internet',
            icon: Icons.cloud_off_rounded,
            accent: Colors.redAccent,
          );
        } else {
          AppToast.failed(context, 'Failed to load part');
        }
        return;
      }
    }

    final initialChoices = await ReadingProgressStore.getChoices(
      widget.chapter.number,
    );
    int? resumePart;
    int? resumeElement;
    if (useResumePosition) {
      final resume = await ReadingProgressStore.getResumePosition(
        widget.chapter.number,
      );
      if (resume != null) {
        resumePart = resume.$1;
        resumeElement = resume.$2;
      }
    }

    if (!mounted) return;

    final furthestOriginalIndex = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          chapterId: widget.chapter.number,
          chapterTitle: widget.chapter.title,
          readerParts: playable,
          startAt: startAt,
          initialChoices: initialChoices,
          resumePartOriginalIndex: resumePart,
          resumeElementIndex: resumeElement,
        ),
      ),
    );

    if (furthestOriginalIndex == null || !mounted) return;
    setState(() {
      for (int i = 0; i <= furthestOriginalIndex && i < _finished.length; i++) {
        _finished[i] = true;
      }
    });
    await _saveFinishedProgress();
  }

  void _continueReading() {
    final nextIndex = _finished.indexWhere((f) => !f);
    _openPart(nextIndex == -1 ? 0 : nextIndex, useResumePosition: true);
  }

  void _markAllFinished() {
    setState(() => _finished = List.filled(_finished.length, true));
    _saveFinishedProgress();
  }

  void _clearAll() {
    setState(() => _finished = List.filled(_finished.length, false));
    _saveFinishedProgress();
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

  int get _finishedCount => _finished.where((f) => f).length;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isSideStory ? _buildSideStoryBody() : _buildMainThemeBody(),
    );
  }

  Widget _buildMainThemeBody() {
    final chapter = widget.chapter;
    final headerHeight = _mainThemeHeaderHeight(context);

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: headerHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: ChapterHeaderImage(
                  chapterId: chapter.number,
                  category: widget.category,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ChapterDetailHeader(
                  chapter: chapter,
                  category: widget.category,
                  description: _description,
                  descriptionLoaded: _descriptionLoaded,
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: headerHeight),
              _buildBody(),
            ],
          ),
        ),
        ChapterDetailTopBar(
          title: chapter.title,
          collapseFraction: _collapseFraction,
          titleFraction: _titleFraction,
          onBack: () => Navigator.of(context).pop(),
          onDownloadAll: _downloadAll,
          onFilterTap: _openFilterSort,
        ),
        _buildContinueButton(),
      ],
    );
  }

  Widget _buildSideStoryBody() {
    final chapter = widget.chapter;

    return Stack(
      children: [
        Column(
          children: [
            ChapterDetailTopBar(
              title: chapter.title,
              collapseFraction: _collapseFraction,
              titleFraction: _titleFraction,
              onBack: () => Navigator.of(context).pop(),
              onDownloadAll: _downloadAll,
              onFilterTap: _openFilterSort,
              solid: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 3.12,
                      child: ChapterHeaderImage(
                        chapterId: chapter.number,
                        category: widget.category,
                      ),
                    ),
                    ChapterDetailHeader(
                      chapter: chapter,
                      category: widget.category,
                      description: _description,
                      descriptionLoaded: _descriptionLoaded,
                    ),
                    _buildBody(),
                  ],
                ),
              ),
            ),
          ],
        ),
        _buildContinueButton(),
      ],
    );
  }

  Widget _buildContinueButton() {
    return Positioned(
      right: 20,
      bottom: 20,
      child: DetailActionButton(
        label: 'CONTINUE',
        icon: Icons.play_arrow,
        filled: true,
        large: true,
        onPressed: _continueReading,
      ),
    );
  }

  Widget _buildBody() {
    return ChapterDetailBody(
      chapter: widget.chapter,
      finished: _finished,
      downloadStates: _downloadStates,
      displayIndices: _displayIndices,
      finishedCount: _finishedCount,
      totalWordCount: _totalWordCount,
      computingWordCount: _computingWordCount,
      onMarkAllFinished: _markAllFinished,
      onClearAll: _clearAll,
      onToggleFinished: (index) {
        setState(() => _finished[index] = !_finished[index]);
        _saveFinishedProgress();
      },
      onDownloadTap: _toggleDownload,
      onOpenPart: (index) => _openPart(index),
    );
  }
}
