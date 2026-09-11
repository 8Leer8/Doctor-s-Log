import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/reader_settings.dart';

class ChapterTransitionWidget extends StatelessWidget {
  final String? previousTitle;
  final String currentTitle;
  final ReaderSettings settings;

  const ChapterTransitionWidget({
    super.key,
    required this.previousTitle,
    required this.currentTitle,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final colors = settings.colors;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 28),
      child: ClipPath(
        clipper: CutCornerClipper(cut: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: colors.background,
            border: Border.all(color: colors.secondaryText.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (previousTitle != null) ...[
                Text(
                  'PREVIOUS',
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: colors.secondaryText, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      previousTitle!,
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(height: 1, color: colors.secondaryText.withValues(alpha: 0.3)),
                const SizedBox(height: 20),
              ],
              Text(
                'CURRENT',
                style: TextStyle(
                  color: colors.accent,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.play_circle, color: colors.accent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    currentTitle,
                    style: TextStyle(
                      color: colors.text,
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