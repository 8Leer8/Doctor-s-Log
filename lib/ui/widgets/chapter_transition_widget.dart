import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ChapterTransitionWidget extends StatelessWidget {
  final String? previousTitle;
  final String currentTitle;

  const ChapterTransitionWidget({
    super.key,
    required this.previousTitle,
    required this.currentTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 28),
      child: ClipPath(
        clipper: CutCornerClipper(cut: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (previousTitle != null) ...[
                const Text(
                  'PREVIOUS',
                  style: TextStyle(
                    color: AppColors.coldGray,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.coldGray, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      previousTitle!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(height: 1, color: AppColors.border),
                const SizedBox(height: 20),
              ],
              const Text(
                'CURRENT',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.play_circle, color: AppColors.amber, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    currentTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}