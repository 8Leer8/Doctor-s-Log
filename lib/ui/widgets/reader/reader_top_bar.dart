import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ReaderTopBar extends StatelessWidget {
  final bool visible;
  final String title;
  final VoidCallback onBack;

  const ReaderTopBar({
    super.key,
    required this.visible,
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: visible ? 0 : -60,
      left: 0,
      right: 0,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          border: const Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: onBack,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  title,
                  key: ValueKey(title),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppColors.coldGray),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}