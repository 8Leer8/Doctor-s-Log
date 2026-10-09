import 'package:flutter/material.dart';
import '../../../models/chapter_preview.dart';
import '../chapter_card.dart';
import 'library_empty_state.dart';

class MainThemeGrid extends StatelessWidget {
  final List<ChapterPreview> chapters;
  final Map<String, int> finishedCounts;
  final Future<void> Function(ChapterPreview chapter) onOpenChapter;
  final bool filtering;
  final String query;

  /// Empty-state shortcut to another tab that has search matches.
  final int otherCount;
  final String otherLabel;
  final int otherTabIndex;

  const MainThemeGrid({
    super.key,
    required this.chapters,
    required this.finishedCounts,
    required this.onOpenChapter,
    required this.filtering,
    required this.query,
    required this.otherCount,
    required this.otherLabel,
    required this.otherTabIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty) {
      return LibraryEmptyState(
        filtering: filtering,
        query: query,
        title: 'NO CHAPTERS',
        emptyMessage: 'No chapters found.',
        otherCount: otherCount,
        otherLabel: otherLabel,
        otherTabIndex: otherTabIndex,
      );
    }
    return GridView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
          key: ValueKey(chapter.number),
          chapter: chapter,
          finishedCount: finishedCounts[chapter.number] ?? 0,
          onTap: () => onOpenChapter(chapter),
        );
      },
    );
  }
}
