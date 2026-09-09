import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ReaderBottomBar extends StatelessWidget {
  final bool visible;
  final int currentPart; // 1-based for display
  final int totalParts;
  final bool canGoPrev;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const ReaderBottomBar({
    super.key,
    required this.visible,
    required this.currentPart,
    required this.totalParts,
    required this.canGoPrev,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      bottom: visible ? 0 : -70,
      left: 0,
      right: 0,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous),
              color: canGoPrev ? AppColors.textPrimary : AppColors.coldGray,
              onPressed: canGoPrev ? onPrev : null,
            ),
            Expanded(
              child: Center(
                child: Text(
                  'PART $currentPart OF $totalParts',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              color: canGoNext ? AppColors.textPrimary : AppColors.coldGray,
              onPressed: canGoNext ? onNext : null,
            ),
          ],
        ),
      ),
    );
  }
}