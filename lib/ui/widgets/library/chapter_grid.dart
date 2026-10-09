import 'package:flutter/material.dart';
import '../../../models/chapter_preview.dart';
import '../chapter_card.dart';
import 'library_empty_state.dart';

/// Two-column grid of portrait chapter cards. Used by the Main Theme and
/// Vignettes tabs, so they always look and behave the same.
class ChapterGrid extends StatelessWidget {
  final List<ChapterPreview> chapters;
  final Map<String, int> finishedCounts;
  final Future<void> Function(ChapterPreview chapter) onOpenChapter;

  /// Folder under assets/images/ with this tab's cover art
  /// ('chapters' for Main Theme, 'vignettes' for Vignettes).
  final String imageFolder;

  final bool filtering;
  final String query;

  /// Shown when [chapters] is empty and we're not searching.
  final String emptyTitle;
  final String emptyMessage;

  /// Empty-state shortcut to another tab that has search matches.
  final int otherCount;
  final String otherLabel;
  final int otherTabIndex;

  const ChapterGrid({
    super.key,
    required this.chapters,
    required this.finishedCounts,
    required this.onOpenChapter,
    required this.imageFolder,
    required this.filtering,
    required this.query,
    required this.emptyTitle,
    required this.emptyMessage,
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
        title: emptyTitle,
        emptyMessage: emptyMessage,
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
          imageFolder: imageFolder,
          onTap: () => onOpenChapter(chapter),
        );
      },
    );
  }
}
