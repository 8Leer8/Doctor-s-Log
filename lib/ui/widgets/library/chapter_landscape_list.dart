import 'package:flutter/material.dart';
import '../../../models/chapter_preview.dart';
import '../chapter_landscape_card.dart';
import 'library_empty_state.dart';

/// Vertical list of landscape cards. Used for both the Side Stories and
/// Vignettes tabs, so they always look and behave the same.
class ChapterLandscapeList extends StatelessWidget {
  final List<ChapterPreview> chapters;
  final Map<String, int> finishedCounts;
  final Future<void> Function(ChapterPreview chapter) onOpenChapter;

  final bool filtering;
  final String query;

  /// Shown when [chapters] is empty and we're not searching.
  final String emptyTitle;
  final String emptyMessage;

  /// Empty-state shortcut to another tab that has search matches.
  final int otherCount;
  final String otherLabel;
  final int otherTabIndex;

  const ChapterLandscapeList({
    super.key,
    required this.chapters,
    required this.finishedCounts,
    required this.onOpenChapter,
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
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(12),
      itemCount: chapters.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return ChapterLandscapeCard(
          key: ValueKey(chapter.number),
          chapter: chapter,
          finishedCount: finishedCounts[chapter.number] ?? 0,
          onTap: () => onOpenChapter(chapter),
        );
      },
    );
  }
}
