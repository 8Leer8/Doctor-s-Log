import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/reader_settings.dart';

class LockedSectionWidget extends StatelessWidget {
  final ReaderSettings settings;
  final VoidCallback? onGoToChoice;

  const LockedSectionWidget({
    super.key,
    required this.settings,
    required this.onGoToChoice,
  });

  @override
  Widget build(BuildContext context) {
    final colors = settings.colors;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ClipPath(
        clipper: CutCornerClipper(cut: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: colors.background,
            border: Border.all(color: colors.secondaryText.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Icon(Icons.lock_outline, color: colors.secondaryText, size: 26),
              const SizedBox(height: 10),
              Text(
                'Choiced Pending',
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'This part continues once you answer the choice above.\nOther parts of the chapter aren\'t affected.',                style: TextStyle(color: colors.secondaryText, fontSize: 12, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              if (onGoToChoice != null)
                ClipPath(
                  clipper: CutCornerClipper(cut: 8),
                  child: Material(
                    color: colors.accent,
                    child: InkWell(
                      onTap: onGoToChoice,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_upward, size: 14, color: Colors.black),
                            const SizedBox(width: 6),
                            Text(
                              'GO TO CHOICE',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}