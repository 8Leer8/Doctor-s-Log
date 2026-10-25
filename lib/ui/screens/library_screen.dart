import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/chapter_preview.dart';
import '../../models/story_category.dart';
import '../../data/repository/chapter_repository.dart';
import '../../data/local/chapter_descriptions_loader.dart';
import '../../data/local/cover_store.dart';
import '../../data/local/downloaded_index.dart';
import '../../data/local/library_filter_store.dart';
import '../../data/local/reading_progress_store.dart';
import '../../data/search/library_search_index.dart';
import '../../utils/cover_ref.dart';
import '../controllers/library_search_controller.dart';
import '../widgets/library/chapter_grid.dart';
import '../widgets/library/library_section_tab_bar.dart';
import '../widgets/library/search_suggestions.dart';
import 'chapter_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  /// Search state owned by AppShell (the single top bar hosts the field).
  final LibrarySearchController search;

  const LibraryScreen({super.key, required this.search});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _repository = ChapterRepository();

  LibrarySearchController get _search => widget.search;
  bool get _downloadedOnly => LibraryFilterStore.downloadedOnly.value;

  List<ChapterPreview>? _mainTheme;
  List<ChapterPreview>? _sideStories;
  List<ChapterPreview>? _vignettes;
  final Map<String, int> _finishedCounts = {};
  String? _error;

  // Cached results — refreshed only when the effective query or the
  // "downloaded only" filter changes (or the data reloads), NOT on every
  // rebuild.
  List<ChapterPreview> _shownMain = const [];
  List<ChapterPreview> _shownSide = const [];
  List<ChapterPreview> _shownVignettes = const [];
  String? _resultsKey;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
    LibraryFilterStore.downloadedOnly.addListener(_onFilterChanged);
    DownloadedIndex.instance.addListener(_onFilterChanged);
    _load();
  }

  @override
  void dispose() {
    _search.removeListener(_onSearchChanged);
    LibraryFilterStore.downloadedOnly.removeListener(_onFilterChanged);
    DownloadedIndex.instance.removeListener(_onFilterChanged);
    super.dispose();
  }

  // ----------------------------------------------------------------- data

  Future<void> _load() async {
    try {
      final main = await _repository.fetchMainTheme();
      final side = await _repository.fetchSideStories();
      final vignettes = await _repository.fetchVignettes();
      final descriptions = await ChapterDescriptionsLoader.load();
      if (!mounted) return;
      setState(() {
        _mainTheme = main;
        _sideStories = side;
        _vignettes = vignettes;
        _resultsKey = null; // force results to rebuild
      });
      // Notifies listeners -> _onSearchChanged -> results refresh.
      _search.attachIndex(
        LibrarySearchIndex(
          main: main,
          side: side,
          vignettes: vignettes,
          descriptions: descriptions,
        ),
      );

      // Fire-and-forget: only fetches covers newer than the bundled set.
      CoverStore.syncAll([
        for (final c in main)
          CoverRef(
            category: StoryCategory.mainTheme,
            chapterId: c.number,
            entryPicId: c.entryPicId,
          ),
        for (final c in side)
          CoverRef(
            category: StoryCategory.sideStory,
            chapterId: c.number,
            entryPicId: c.entryPicId,
          ),
        for (final c in vignettes)
          CoverRef(
            category: StoryCategory.vignette,
            chapterId: c.number,
            entryPicId: c.entryPicId,
          ),
      ]);

      // Make sure "Downloaded only" sees what is on disk right now.
      DownloadedIndex.instance.refresh();

      await _loadProgressFor([...main, ...side, ...vignettes]);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _loadProgressFor(List<ChapterPreview> chapters) async {
    for (final chapter in chapters) {
      final finished = await ReadingProgressStore.getFinishedParts(
        chapter.number,
      );
      if (!mounted) return;
      setState(() => _finishedCounts[chapter.number] = finished.length);
    }
  }

  Future<void> _refreshChapter(ChapterPreview chapter) async {
    final finished = await ReadingProgressStore.getFinishedParts(
      chapter.number,
    );
    if (!mounted) return;
    setState(() => _finishedCounts[chapter.number] = finished.length);
  }

  /// Opens a chapter, then refreshes its progress bar when it closes.
  /// Side stories and vignettes use the same detail layout as the main story.
  Future<void> _openChapter(
    ChapterPreview chapter,
    StoryCategory category,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ChapterDetailScreen(chapter: chapter, category: category),
      ),
    );
    // Parts may have been downloaded or deleted inside the chapter.
    await DownloadedIndex.instance.refresh();
    await _refreshChapter(chapter);
  }

  // --------------------------------------------------------------- search

  /// Must be called inside setState.
  void _refreshResults() {
    final index = _search.index;
    final main = _mainTheme;
    final side = _sideStories;
    final vignettes = _vignettes;
    if (index == null || main == null || side == null || vignettes == null) {
      return;
    }

    final downloadedOnly = _downloadedOnly;
    final key = _search.filtering ? _search.query : '';
    final cacheKey = '${downloadedOnly ? 1 : 0}|$key';
    if (cacheKey == _resultsKey) return;
    _resultsKey = cacheKey;

    var m = key.isEmpty ? main : index.searchMain(key);
    var s = key.isEmpty ? side : index.searchSide(key);
    var v = key.isEmpty ? vignettes : index.searchVignettes(key);

    if (downloadedOnly) {
      final downloaded = DownloadedIndex.instance;
      m = m.where(downloaded.hasAny).toList();
      s = s.where(downloaded.hasAny).toList();
      v = v.where(downloaded.hasAny).toList();
    }

    _shownMain = m;
    _shownSide = s;
    _shownVignettes = v;
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(_refreshResults);
  }

  /// The filter switch or the set of downloaded parts changed.
  void _onFilterChanged() {
    if (!mounted) return;
    setState(() {
      _resultsKey = null;
      _refreshResults();
    });
  }

  /// While searching: the first OTHER tab that has matches, offered as a
  /// shortcut from an empty tab.
  ({int count, String label, int tab}) _altTabFor(int current) {
    final tabs = <(String, int)>[
      ('MAIN THEME', _shownMain.length),
      ('SIDE STORIES', _shownSide.length),
      ('VIGNETTES', _shownVignettes.length),
    ];
    for (int i = 0; i < tabs.length; i++) {
      if (i != current && tabs[i].$2 > 0) {
        return (count: tabs[i].$2, label: tabs[i].$1, tab: i);
      }
    }
    return (count: 0, label: '', tab: 0);
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final filtering = _search.filtering;
    final downloadedOnly = _downloadedOnly;
    final showCounts = filtering || downloadedOnly;

    return DefaultTabController(
      length: 3,
      child: Container(
        color: AppColors.background,
        child: Column(
          children: [
            if (_search.searching)
              SearchSuggestions(
                suggestions: _search.suggestions,
                query: _search.rawQuery,
                isStart: _search.query.isEmpty,
                onTap: _search.applySuggestion,
              ),
            if (downloadedOnly)
              _DownloadedOnlyBanner(
                onTurnOff: () => LibraryFilterStore.setDownloadedOnly(false),
              ),
            LibrarySectionTabBar(
              mainCount: showCounts ? _shownMain.length : null,
              sideCount: showCounts ? _shownSide.length : null,
              vignetteCount: showCounts ? _shownVignettes.length : null,
            ),
            Expanded(child: _buildBody(filtering, downloadedOnly)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool filtering, bool downloadedOnly) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Failed to load library:\n$_error',
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_mainTheme == null || _sideStories == null || _vignettes == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.amber),
      );
    }

    final altMain = _altTabFor(0);
    final altSide = _altTabFor(1);
    final altVignette = _altTabFor(2);

    String emptyTitle(String normal) =>
        downloadedOnly ? 'NOTHING DOWNLOADED' : normal;
    String emptyMessage(String normal) => downloadedOnly
        ? 'No downloaded chapters here yet.\nDownload parts from a chapter to see it in this list.'
        : normal;

    return TabBarView(
      children: [
        ChapterGrid(
          chapters: _shownMain,
          finishedCounts: _finishedCounts,
          category: StoryCategory.mainTheme,
          filtering: filtering,
          query: _search.query,
          emptyTitle: emptyTitle('NO CHAPTERS'),
          emptyMessage: emptyMessage('No chapters found.'),
          otherCount: altMain.count,
          otherLabel: altMain.label,
          otherTabIndex: altMain.tab,
          onOpenChapter: (c) => _openChapter(c, StoryCategory.mainTheme),
        ),
        ChapterGrid(
          chapters: _shownSide,
          finishedCounts: _finishedCounts,
          category: StoryCategory.sideStory,
          filtering: filtering,
          query: _search.query,
          emptyTitle: emptyTitle('NO SIDE STORIES'),
          emptyMessage: emptyMessage('No side stories found.'),
          otherCount: altSide.count,
          otherLabel: altSide.label,
          otherTabIndex: altSide.tab,
          onOpenChapter: (c) => _openChapter(c, StoryCategory.sideStory),
        ),
        ChapterGrid(
          chapters: _shownVignettes,
          finishedCounts: _finishedCounts,
          category: StoryCategory.vignette,
          filtering: filtering,
          query: _search.query,
          emptyTitle: emptyTitle('NO VIGNETTES'),
          emptyMessage: emptyMessage('No vignettes found.'),
          otherCount: altVignette.count,
          otherLabel: altVignette.label,
          otherTabIndex: altVignette.tab,
          onOpenChapter: (c) => _openChapter(c, StoryCategory.vignette),
        ),
      ],
    );
  }
}

/// Thin strip under the top bar while "Downloaded only" is on, with a quick
/// way to switch it off.
class _DownloadedOnlyBanner extends StatelessWidget {
  final VoidCallback onTurnOff;

  const _DownloadedOnlyBanner({required this.onTurnOff});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
      color: AppColors.amber.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 16,
            color: AppColors.amber,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'DOWNLOADED ONLY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.amber,
              ),
            ),
          ),
          TextButton(
            onPressed: onTurnOff,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'TURN OFF',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
