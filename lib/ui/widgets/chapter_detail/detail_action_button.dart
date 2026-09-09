import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class DetailActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onPressed;

  const DetailActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: CutCornerClipper(cut: 8),
      child: Material(
        color: filled ? AppColors.amber : AppColors.surface,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: filled
                ? null
                : BoxDecoration(
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 16,
                    color: filled ? Colors.black : AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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