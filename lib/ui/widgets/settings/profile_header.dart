import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Top of the Settings screen (the spot Mihon uses for its logo): the
/// Doctor's avatar, name and two reading stats. Tap to edit the name.
class ProfileHeader extends StatelessWidget {
  final String name;
  final int partsRead;
  final int downloaded;
  final VoidCallback onEdit;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.partsRead,
    required this.downloaded,
    required this.onEdit,
  });

  String get _initial {
    final t = name.trim();
    if (t.isEmpty) return 'D';
    return String.fromCharCode(t.runes.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        highlightColor: Colors.white.withValues(alpha: 0.04),
        splashColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              _Avatar(initial: _initial),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: AppColors.coldGray,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'RHODES ISLAND · DOCTOR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.amber,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _Stat(value: '$partsRead', label: 'PARTS READ'),
                  ),
                  Container(width: 1, height: 28, color: AppColors.border),
                  Expanded(
                    child: _Stat(value: '$downloaded', label: 'DOWNLOADED'),
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

class _Avatar extends StatelessWidget {
  final String initial;

  const _Avatar({required this.initial});

  @override
  Widget build(BuildContext context) {
    // Outer shape = amber "border", inner shape = dark fill.
    return ClipPath(
      clipper: CutCornerClipper(cut: 14),
      child: Container(
        width: 84,
        height: 84,
        padding: const EdgeInsets.all(1.5),
        color: AppColors.amber.withValues(alpha: 0.4),
        child: ClipPath(
          clipper: CutCornerClipper(cut: 13),
          child: Container(
            color: AppColors.surface,
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: AppColors.amber,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.coldGray,
          ),
        ),
      ],
    );
  }
}
