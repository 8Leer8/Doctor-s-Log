import 'package:flutter/material.dart';
import '../../../models/reader_settings.dart';

/// Lightweight inline divider rendered in place of a
/// [SceneBreakElement]. Visually distinct from [ChapterTransitionWidget]
/// (which is a heavy card) — this is a thin centered rule, not a
/// chapter boundary.
///
/// Spacing is intentionally tight so the divider reads as a quiet beat
/// between two dialogue blocks rather than a large structural break:
///   - 20px vertical margin (vs the 44px used previously),
///   - 120px rule width,
///   - 10px gap between rule and label.
class SceneBreakWidget extends StatelessWidget {
  final ReaderSettings settings;

  const SceneBreakWidget({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final colors = settings.colors;
    final ruleColor = colors.secondaryText.withValues(alpha: 0.25);
    final labelColor = colors.secondaryText.withValues(alpha: 0.7);

    return Semantics(
      label: 'Scene shift',
      container: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 120, height: 1, color: ruleColor),
            const SizedBox(height: 10),
            Text(
              '~ Scene shifts ~',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.6,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 10),
            Container(width: 120, height: 1, color: ruleColor),
          ],
        ),
      ),
    );
  }
}
