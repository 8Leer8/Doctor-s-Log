import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/chapter_preview.dart';

class ChapterCard extends StatelessWidget {
  final ChapterPreview chapter;
  final VoidCallback? onTap;

  const ChapterCard({super.key, required this.chapter, this.onTap});

  @override
  Widget build(BuildContext context) {
    final progressRatio = chapter.progressTotal == 0
        ? 0.0
        : chapter.progressCurrent / chapter.progressTotal;

    return ClipPath(
      clipper: CutCornerClipper(cut: 10),
      child: Material(
        color: AppColors.surface,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed-height thumbnail — swap for real cover art later
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: Container(
                    color: AppColors.surfaceRaised,
                    child: Stack(
                      children: [
                        if (chapter.finished)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade700,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Icon(Icons.check,
                                  size: 12, color: Colors.white),
                            ),
                          ),
                        Center(
                          child: Icon(Icons.image_outlined,
                              color: AppColors.coldGray.withValues(alpha: 0.4),
                              size: 28),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHAPTER ${chapter.number}',
                        style: const TextStyle(
                          fontSize: 10,
                          letterSpacing: 1,
                          color: AppColors.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        chapter.title,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chapter.description,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progressRatio,
                          minHeight: 3,
                          backgroundColor: AppColors.border,
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.amber),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${chapter.progressCurrent}/${chapter.progressTotal}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}