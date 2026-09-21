import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/chapter_preview.dart';
import '../../utils/act_type_formatter.dart';

class ChapterLandscapeCard extends StatelessWidget {
  final ChapterPreview chapter;
  final int finishedCount;
  final VoidCallback? onTap;

  const ChapterLandscapeCard({
    super.key,
    required this.chapter,
    required this.finishedCount,
    this.onTap,
  });

  Widget _buildImage() {
    return Image.asset(
      'assets/images/side_stories/${chapter.number}.jpg',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/images/side_stories/${chapter.number}.png',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.surfaceRaised,
          child: Center(
            child: Icon(
              Icons.image_outlined,
              size: 40,
              color: AppColors.coldGray.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(aspectRatio: 3.12, child: _buildImage()),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      chapter.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progressRatio,
                        minHeight: 3,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.amber,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$finishedCount / $total',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
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
