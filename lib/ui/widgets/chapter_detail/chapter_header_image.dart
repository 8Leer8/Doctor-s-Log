import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/story_category.dart';
import '../common/cover_image.dart';

/// Full-bleed header art on the chapter detail screen (all three categories).
class ChapterHeaderImage extends StatelessWidget {
  final String chapterId;
  final StoryCategory category;
  final String? entryPicId;

  const ChapterHeaderImage({
    super.key,
    required this.chapterId,
    required this.category,
    this.entryPicId,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CoverImage(
          chapterId: chapterId,
          category: category,
          entryPicId: entryPicId,
          placeholderIconSize: 48,
        ),
        // Top scrim so the status bar / back button stay readable.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.black26, Colors.transparent],
              stops: [0.0, 0.08, 0.18],
            ),
          ),
        ),
        // Side vignette (drawn BEFORE the bottom fade so it can't tint it).
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black45,
                Colors.transparent,
                Colors.transparent,
                Colors.black45,
              ],
              stops: [0.0, 0.12, 0.88, 1.0],
            ),
          ),
        ),
        // Bottom fade into the body color.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withValues(alpha: 0.0),
                AppColors.background.withValues(alpha: 0.0),
                AppColors.background,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
