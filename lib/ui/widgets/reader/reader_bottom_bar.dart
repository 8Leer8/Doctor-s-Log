import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ReaderBottomBar extends StatelessWidget {
  final bool visible;
  final double progress;

  const ReaderBottomBar({super.key, required this.visible, required this.progress});

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      bottom: visible ? 0 : -70,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.amber,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.amber,
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: progress,
                onChanged: (_) {},
              ),
            ),
            Text(
              '${(progress * 100).round()}% read',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}