import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/chapter_preview.dart';
import '../widgets/chapter_card.dart';
import 'chapter_detail_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

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
            Expanded(
              child: TabBarView(
                children: [
                  _ChapterGrid(chapters: mockMainTheme),
                  _ChapterGrid(chapters: mockSideStories),
                ],
              ),
            ),
          ],
        ),
      ),
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