import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/story_category.dart';
import '../common/cover_image.dart';

/// Header art on the chapter detail screen (all three categories). The whole
/// cover is shown (not cropped) at the top, fading into the page background
/// where the title and description sit.
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
        const ColoredBox(color: AppColors.background),
        CoverImage(
          chapterId: chapterId,
          category: category,
          entryPicId: entryPicId,
          alignment: Alignment.topCenter,
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
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
