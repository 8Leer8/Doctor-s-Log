import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ReaderTopBar extends StatelessWidget {
  final bool visible;
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final VoidCallback onSettingsTap;
  final VoidCallback onTocTap;

  const ReaderTopBar({
    super.key,
    required this.visible,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onSettingsTap,
    required this.onTocTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: visible ? 0 : -84,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          border: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: onBack,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 96),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        title,
                        key: ValueKey(title),
                        textAlign: TextAlign.center,
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: AppColors.coldGray),
                          onPressed: onTocTap,
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, color: AppColors.coldGray),
                          onPressed: onSettingsTap,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    subtitle!,
                    key: ValueKey(subtitle),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}