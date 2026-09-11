import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/reader_settings.dart';

class EndOfChapterWidget extends StatelessWidget {
  final ReaderSettings settings;

  const EndOfChapterWidget({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final colors = settings.colors;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20, bottom: 60),
      child: ClipPath(
        clipper: CutCornerClipper(cut: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            color: colors.background,
            border: Border.all(color: colors.accent.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Icon(Icons.check_circle, color: colors.accent, size: 32),
              const SizedBox(height: 10),
              Text(
                'CHAPTER FINISHED',
                style: TextStyle(
                  color: colors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You\'ve reached the end.',
                style: TextStyle(color: colors.secondaryText, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}