import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/chapter_preview.dart';
import '../../models/story_category.dart';
import '../../utils/act_type_formatter.dart';
import 'common/cover_image.dart';

/// Portrait card used by ALL three Library tabs (main story, side stories,
/// vignettes).
class ChapterCard extends StatelessWidget {
  final ChapterPreview chapter;
  final StoryCategory category;
  final int finishedCount;
  final VoidCallback? onTap;

  const ChapterCard({
    super.key,
    required this.chapter,
    required this.category,
    required this.finishedCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = chapter.parts.length;
    final progressRatio = total == 0
        ? 0.0
        : (finishedCount / total).clamp(0.0, 1.0);
    final cardLabel = formatChapterCardLabel(chapter.number, chapter.subtitle);

    return ClipPath(
      clipper: CutCornerClipper(cut: 12),
      child: Material(
        color: AppColors.surface,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CoverImage(
                chapterId: chapter.number,
                category: category,
                entryPicId: chapter.entryPicId,
              ),
              // Bottom fade so overlaid text stays legible on any artwork.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black87,
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cardLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: AppColors.amber,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      chapter.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progressRatio,
                        minHeight: 3,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.amber,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$finishedCount / $total',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
