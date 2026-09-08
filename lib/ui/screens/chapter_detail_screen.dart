import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/chapter_preview.dart';

class ChapterDetailScreen extends StatelessWidget {
  final ChapterPreview chapter;

  const ChapterDetailScreen({super.key, required this.chapter});

  @override
  Widget build(BuildContext context) {
    final progressRatio = chapter.progressTotal == 0
        ? 0.0
        : chapter.progressCurrent / chapter.progressTotal;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header image placeholder + close button
            Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  color: AppColors.surfaceRaised,
                  child: Center(
                    child: Icon(Icons.image_outlined,
                        color: AppColors.coldGray.withValues(alpha: 0.4),
                        size: 36),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chapter.subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      chapter.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ActionButton(
                          label: 'CONTINUE',
                          icon: Icons.play_arrow,
                          filled: true,
                          onPressed: () {
                            // TODO: navigate to last-read position
                          },
                        ),
                        _ActionButton(
                          label: 'MARK ALL FINISHED',
                          icon: Icons.check,
                          onPressed: () {
                            // TODO: wire mark-all
                          },
                        ),
                        _ActionButton(
                          label: 'CLEAR ALL',
                          icon: Icons.refresh,
                          onPressed: () {
                            // TODO: wire clear-all
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progressRatio,
                        minHeight: 4,
                        backgroundColor: AppColors.border,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.amber),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${chapter.wordCount} words · about ${chapter.readTimeMinutes}m',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${chapter.progressCurrent} OF ${chapter.progressTotal} FINISHED',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.amber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ...chapter.parts.map((part) => _PartRow(part: part)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: CutCornerClipper(cut: 8),
      child: Material(
        color: filled ? AppColors.amber : AppColors.surface,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: filled
                ? null
                : BoxDecoration(
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 16,
                    color: filled ? Colors.black : AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: filled ? Colors.black : AppColors.textPrimary,
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

class _PartRow extends StatelessWidget {
  final dynamic part; // StoryPart

  const _PartRow({required this.part});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO: open reader screen for this part
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: [
            Icon(
              part.finished ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: part.finished ? Colors.green.shade400 : AppColors.coldGray,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                part.title,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}