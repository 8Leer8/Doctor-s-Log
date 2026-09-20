import 'package:flutter/material.dart';
import '../../../models/reader_settings.dart';

class SceneBreakWidget extends StatelessWidget {
  final ReaderSettings settings;
  final VoidCallback? onTap;

  const SceneBreakWidget({super.key, required this.settings, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = settings.colors;
    final ruleColor = colors.secondaryText.withValues(alpha: 0.25);
    final labelColor = colors.secondaryText.withValues(alpha: 0.7);
    final tappable = onTap != null;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 120, height: 1, color: ruleColor),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tappable) ...[
              Icon(Icons.image_outlined, size: 12, color: labelColor),
              const SizedBox(width: 6),
            ],
            Text(
              '~ Scene shifts ~',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.6,
                color: labelColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(width: 120, height: 1, color: ruleColor),
      ],
    );

    return Semantics(
      label: 'Scene shift',
      button: tappable,
      container: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 20),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
