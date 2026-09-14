import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/chapter_preview.dart';
import '../../data/repository/chapter_repository.dart';
import '../../data/local/reading_progress_store.dart';
import '../widgets/chapter_card.dart';
import 'chapter_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _repository = ChapterRepository();

  List<ChapterPreview>? _mainTheme;
  List<ChapterPreview>? _sideStories;
  final Map<String, int> _finishedCounts = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final main = await _repository.fetchMainTheme();
      final side = await _repository.fetchSideStories();
      setState(() {
        _mainTheme = main;
        _sideStories = side;
      });
      await _loadProgressFor([...main, ...side]);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _loadProgressFor(List<ChapterPreview> chapters) async {
    for (final chapter in chapters) {
      final finished = await ReadingProgressStore.getFinishedParts(chapter.number);
      if (!mounted) return;
      setState(() => _finishedCounts[chapter.number] = finished.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        color: AppColors.background,
        child: Column(
          children: [
            const _TopBar(),
            const _SectionTabBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
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
    if (_mainTheme == null || _sideStories == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.amber));
    }
    return TabBarView(
      children: [
        _ChapterGrid(chapters: _mainTheme!, finishedCounts: _finishedCounts),
        _ChapterGrid(chapters: _sideStories!, finishedCounts: _finishedCounts),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      // Paints status bar + toolbar as ONE continuous block using the
      // same color as the screen body, matching Facebook's unified top.
      height: statusBarHeight + 52,
      padding: EdgeInsets.only(top: statusBarHeight),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Text(
              'LIBRARY',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.search, color: AppColors.coldGray, size: 22),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.tune, color: AppColors.coldGray, size: 20),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTabBar extends StatelessWidget {
  const _SectionTabBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: const TabBar(
        isScrollable: true,
        indicatorColor: AppColors.amber,
        labelColor: AppColors.amber,
        unselectedLabelColor: AppColors.coldGray,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
        tabs: [
          Tab(text: 'MAIN THEME'),
          Tab(text: 'SIDE STORIES'),
        ],
      ),
    );
  }
}

class _ChapterGrid extends StatelessWidget {
  final List<ChapterPreview> chapters;
  final Map<String, int> finishedCounts;

  const _ChapterGrid({required this.chapters, required this.finishedCounts});

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty) {
      return const Center(
        child: Text('No chapters found', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return ChapterCard(
          chapter: chapter,
          finishedCount: finishedCounts[chapter.number] ?? 0,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChapterDetailScreen(chapter: chapter),
              ),
            );
          },
        );
      },
    );
  }
}