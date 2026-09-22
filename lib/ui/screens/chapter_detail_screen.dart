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
import '../../data/local/bookmark_store.dart';
import '../../data/local/chapter_descriptions_loader.dart';
import '../../data/local/reading_progress_store.dart';
import '../../data/local/download_store.dart';
import '../../utils/chapter_detail_dialogs.dart';
import '../widgets/common/app_toast.dart';
import 'reader_screen.dart';
import '../widgets/chapter_detail/continue_button.dart';
import '../widgets/chapter_detail/chapter_detail_header.dart';
import '../widgets/chapter_detail/chapter_detail_body.dart';
import '../widgets/chapter_detail/chapter_detail_top_bar.dart';
import '../widgets/chapter_detail/chapter_header_image.dart';
import '../widgets/chapter_detail/part_filter_sort_sheet.dart';
import '../widgets/chapter_detail/detail_part_row.dart';
import '../widgets/chapter_detail/selection_actions.dart';
import '../widgets/chapter_detail/selection_bottom_bar.dart';
import '../widgets/chapter_detail/selection_top_bar.dart';

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
  final Map<int, double> _downloadProgress = {};
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

  bool _selectionMode = false;
  final Set<int> _selectedIndices = {};
  Set<String> _bookmarkedFilenames = {};

  bool _continueButtonCollapsed = false;
  double _lastScrollOffset = 0.0;

  static const double _kScrollDirectionThreshold = 20.0;

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
    _loadBookmarks();
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

  Future<void> _loadBookmarks() async {
    final bookmarks = await BookmarkStore.getBookmarks(widget.chapter.number);
    if (!mounted) return;
    setState(() => _bookmarkedFilenames = bookmarks);
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

    setState(() {
      _downloadStates[index] = DownloadState.downloading;
      _downloadProgress.remove(index);
    });

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
          onProgress: (done, total) {
            if (!mounted) return;
            if (total <= 0) return;
            setState(() {
              _downloadProgress[index] = done / total;
            });
          },
        );
      } catch (_) {
        prefetchResult = null;
      }

      if (mounted) {
        setState(() {
          _downloadStates[index] = DownloadState.downloaded;
          _downloadProgress.remove(index);
        });

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
      setState(() {
        _downloadStates[index] = DownloadState.notDownloaded;
        _downloadProgress.remove(index);
      });

      if (_isNetworkError(e)) {
        AppToast.noInternet(context);
      } else {
        AppToast.failed(context, 'Download failed: $e');
      }
    }
  }

  Future<void> _downloadAll() async {
    final queue = <int>[];
    setState(() {
      for (int i = 0; i < widget.chapter.parts.length; i++) {
        if (widget.chapter.parts[i].filename == null) continue;
        final state = _downloadStates[i] ?? DownloadState.notDownloaded;
        if (state == DownloadState.notDownloaded) {
          _downloadStates[i] = DownloadState.queued;
          queue.add(i);
        }
      }
    });

    for (final i in queue) {
      await _toggleDownload(i);
    }
  }

  double _mainThemeHeaderHeight(BuildContext context) =>
      MediaQuery.of(context).size.width;

  double _sideStoryHeaderHeight(BuildContext context) =>
      MediaQuery.of(context).size.width / 3.12;

  void _onScroll() {
    final offset = _scrollController.offset;
    final position = _scrollController.position;

    final atBottom = position.pixels >= position.maxScrollExtent - 40;

    final delta = offset - _lastScrollOffset;
    bool shouldCollapse = _continueButtonCollapsed;

    if (atBottom) {
      shouldCollapse = false;
    } else if (delta > _kScrollDirectionThreshold) {
      shouldCollapse = true;
    } else if (delta < -_kScrollDirectionThreshold) {
      shouldCollapse = false;
    }

    if (delta.abs() > _kScrollDirectionThreshold) {
      _lastScrollOffset = offset;
    }

    if (shouldCollapse != _continueButtonCollapsed) {
      setState(() => _continueButtonCollapsed = shouldCollapse);
    }

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

  void _enterSelection(int index) {
    setState(() {
      _selectionMode = true;
      _selectedIndices.add(index);
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIndices.clear();
    });
  }

  void _toggleSelected(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
        if (_selectedIndices.isEmpty) _selectionMode = false;
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _selectAll() {
    final all = List<int>.generate(widget.chapter.parts.length, (i) => i);
    setState(() {
      if (_selectedIndices.length == all.length) {
        _selectedIndices.clear();
        _selectionMode = false;
      } else {
        _selectedIndices
          ..clear()
          ..addAll(all);
      }
    });
  }

  void _invertSelection() {
    final all = List<int>.generate(widget.chapter.parts.length, (i) => i);
    setState(() {
      final newSet = <int>{};
      for (final i in all) {
        if (!_selectedIndices.contains(i)) newSet.add(i);
      }
      _selectedIndices
        ..clear()
        ..addAll(newSet);
      if (_selectedIndices.isEmpty) _selectionMode = false;
    });
  }

  Future<void> _bulkDownload() async {
    final targets = _selectedIndices.where((i) {
      final p = widget.chapter.parts[i];
      if (p.filename == null) return false;
      final state = _downloadStates[i] ?? DownloadState.notDownloaded;
      return state == DownloadState.notDownloaded;
    }).toList();
    _exitSelection();

    setState(() {
      for (final i in targets) {
        _downloadStates[i] = DownloadState.queued;
      }
    });

    for (final i in targets) {
      await _toggleDownload(i);
    }
  }

  Future<void> _bulkDelete() async {
    final targets = _selectedIndices.toList();

    final confirmed = await _confirmBulkDelete(targets.length);
    if (confirmed != true || !mounted) return;

    for (final i in targets) {
      final filename = widget.chapter.parts[i].filename;
      if (filename == null) continue;
      try {
        await ImagePrefetcher.releaseImagesForPart(filename);
        await DownloadStore.deleteContent(filename);
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        for (final i in targets) {
          _downloadStates[i] = DownloadState.notDownloaded;
          _downloadProgress.remove(i);
        }
      });
      _exitSelection();
    }
  }

  Future<void> _bulkBookmark() async {
    final filenames = <String>[];
    for (final i in _selectedIndices) {
      final f = widget.chapter.parts[i].filename;
      if (f != null) filenames.add(f);
    }

    if (filenames.isEmpty) {
      _exitSelection();
      return;
    }

    final allBookmarked = filenames.every(
      (f) => _bookmarkedFilenames.contains(f),
    );
    final newState = !allBookmarked;

    await BookmarkStore.toggleMany(widget.chapter.number, filenames, newState);

    if (mounted) {
      setState(() {
        if (newState) {
          _bookmarkedFilenames.addAll(filenames);
        } else {
          _bookmarkedFilenames.removeAll(filenames);
        }
      });
      _exitSelection();
    }
  }

  bool _allSelectedBookmarked() {
    if (_selectedIndices.isEmpty) return false;
    for (final i in _selectedIndices) {
      final f = widget.chapter.parts[i].filename;
      if (f == null) continue;
      if (!_bookmarkedFilenames.contains(f)) return false;
    }
    return true;
  }

  Future<bool?> _confirmBulkDelete(int count) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text(
          'Delete downloads?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will remove the offline copies of $count part(s). You can re-download them anytime.',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: AppColors.coldGray,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'DELETE',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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

  List<SelectionAction> _currentActions() {
    final isDownloaded = List<bool>.generate(
      widget.chapter.parts.length,
      (i) =>
          (_downloadStates[i] ?? DownloadState.notDownloaded) ==
          DownloadState.downloaded,
    );
    final hasFile = List<bool>.generate(
      widget.chapter.parts.length,
      (i) => widget.chapter.parts[i].filename != null,
    );
    return SelectionActions.forIndices(
      selectedIndices: _selectedIndices,
      isDownloaded: isDownloaded,
      hasFile: hasFile,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _exitSelection();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _isSideStory ? _buildSideStoryBody() : _buildMainThemeBody(),
      ),
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
        if (_selectionMode)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SelectionTopBar(
              selectedCount: _selectedIndices.length,
              allSelected:
                  _selectedIndices.length == widget.chapter.parts.length,
              onClose: _exitSelection,
              onSelectAll: _selectAll,
              onInvert: _invertSelection,
            ),
          )
        else
          ChapterDetailTopBar(
            title: chapter.title,
            collapseFraction: _collapseFraction,
            titleFraction: _titleFraction,
            onBack: () => Navigator.of(context).pop(),
            onDownloadAll: _downloadAll,
            onFilterTap: _openFilterSort,
          ),
        if (!_selectionMode) _buildContinueButton(),
        if (_selectionMode)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SelectionBottomBar(
              actions: _currentActions(),
              allBookmarked: _allSelectedBookmarked(),
              onDownload: _bulkDownload,
              onDelete: _bulkDelete,
              onBookmark: _bulkBookmark,
            ),
          ),
      ],
    );
  }

  Widget _buildSideStoryBody() {
    final chapter = widget.chapter;

    return Stack(
      children: [
        Column(
          children: [
            if (_selectionMode)
              SelectionTopBar(
                selectedCount: _selectedIndices.length,
                allSelected:
                    _selectedIndices.length == widget.chapter.parts.length,
                onClose: _exitSelection,
                onSelectAll: _selectAll,
                onInvert: _invertSelection,
              )
            else
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
        if (!_selectionMode) _buildContinueButton(),
        if (_selectionMode)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SelectionBottomBar(
              actions: _currentActions(),
              allBookmarked: _allSelectedBookmarked(),
              onDownload: _bulkDownload,
              onDelete: _bulkDelete,
              onBookmark: _bulkBookmark,
            ),
          ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: ContinueButton(
        onPressed: _continueReading,
        collapsed: _continueButtonCollapsed,
      ),
    );
  }

  Widget _buildBody() {
    return ChapterDetailBody(
      chapter: widget.chapter,
      finished: _finished,
      downloadStates: _downloadStates,
      downloadProgress: _downloadProgress,
      displayIndices: _displayIndices,
      finishedCount: _finishedCount,
      totalWordCount: _totalWordCount,
      computingWordCount: _computingWordCount,
      selectionMode: _selectionMode,
      selectedIndices: _selectedIndices,
      bookmarkedFilenames: _bookmarkedFilenames,
      onMarkAllFinished: _markAllFinished,
      onClearAll: _clearAll,
      onDownloadTap: _toggleDownload,
      onOpenPart: (index) => _openPart(index),
      onLongPressPart: (index) {
        if (_selectionMode) {
          _toggleSelected(index);
        } else {
          _enterSelection(index);
        }
      },
    );
  }
}
