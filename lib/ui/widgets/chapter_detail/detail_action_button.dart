import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class DetailActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool large;

  /// Fill the width the parent gives (use inside an Expanded) and center the
  /// content.
  final bool expanded;
  final VoidCallback onPressed;

  const DetailActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
    this.large = false,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: CutCornerClipper(cut: large ? 10 : 8),
      child: Material(
        color: filled ? AppColors.amber : AppColors.surface,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: large ? 22 : 14,
              vertical: large ? 16 : 10,
            ),
            decoration: filled
                ? null
                : BoxDecoration(
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
            child: Row(
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: large ? 22 : 16,
                  color: filled ? Colors.black : AppColors.textSecondary,
                ),
                SizedBox(width: large ? 8 : 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: large ? 14 : 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: filled ? Colors.black : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
