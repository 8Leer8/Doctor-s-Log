import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/chapter_preview.dart';
import '../../data/repository/chapter_repository.dart';
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
    } catch (e) {
      setState(() => _error = e.toString());
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
      return const Center(
        child: CircularProgressIndicator(color: AppColors.amber),
      );
    }
    return TabBarView(
      children: [
        _ChapterGrid(chapters: _mainTheme!),
        _ChapterGrid(chapters: _sideStories!),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
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
  const _ChapterGrid({required this.chapters});

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty) {
      return const Center(
        child: Text('No chapters found', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisExtent: 270,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: chapters.length,
      itemBuilder: (context, index) => ChapterCard(
        chapter: chapters[index],
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChapterDetailScreen(chapter: chapters[index]),
            ),
          );
        },
      ),
    );
  }
}