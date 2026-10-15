import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/chapter_preview.dart';
import '../../models/story_category.dart';
import '../../data/repository/chapter_repository.dart';
import '../../data/local/chapter_descriptions_loader.dart';
import '../../data/local/reading_progress_store.dart';
import '../../data/search/library_search_index.dart';
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

  List<ChapterPreview>? _mainTheme;
  List<ChapterPreview>? _sideStories;
  List<ChapterPreview>? _vignettes;
  final Map<String, int> _finishedCounts = {};
  String? _error;

  // Cached results — refreshed only when the effective query changes
  // (or the data reloads), NOT on every rebuild.
  List<ChapterPreview> _shownMain = const [];
  List<ChapterPreview> _shownSide = const [];
  List<ChapterPreview> _shownVignettes = const [];
  String? _resultsKey;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _search.removeListener(_onSearchChanged);
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

    final key = _search.filtering ? _search.query : '';
    if (key == _resultsKey) return;
    _resultsKey = key;
    _shownMain = key.isEmpty ? main : index.searchMain(key);
    _shownSide = key.isEmpty ? side : index.searchSide(key);
    _shownVignettes = key.isEmpty ? vignettes : index.searchVignettes(key);
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(_refreshResults);
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
            LibrarySectionTabBar(
              mainCount: filtering ? _shownMain.length : null,
              sideCount: filtering ? _shownSide.length : null,
              vignetteCount: filtering ? _shownVignettes.length : null,
            ),
            Expanded(child: _buildBody(filtering)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool filtering) {
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

    return TabBarView(
      children: [
        ChapterGrid(
          chapters: _shownMain,
          finishedCounts: _finishedCounts,
          category: StoryCategory.mainTheme,
          filtering: filtering,
          query: _search.query,
          emptyTitle: 'NO CHAPTERS',
          emptyMessage: 'No chapters found.',
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
          emptyTitle: 'NO SIDE STORIES',
          emptyMessage: 'No side stories found.',
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
          emptyTitle: 'NO VIGNETTES',
          emptyMessage: 'No vignettes found.',
          otherCount: altVignette.count,
          otherLabel: altVignette.label,
          otherTabIndex: altVignette.tab,
          onOpenChapter: (c) => _openChapter(c, StoryCategory.vignette),
        ),
      ],
    );
  }
}
