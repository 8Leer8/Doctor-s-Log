import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class EndOfChapterWidget extends StatelessWidget {
  const EndOfChapterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20, bottom: 60),
      child: ClipPath(
        clipper: CutCornerClipper(cut: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
          ),
          child: const Column(
            children: [
              Icon(Icons.check_circle, color: AppColors.amber, size: 32),
              SizedBox(height: 10),
              Text(
                'CHAPTER FINISHED',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'You\'ve reached the end.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}