import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// One row of the settings list: icon, title, optional subtitle and an
/// optional widget on the right. Same layout as Mihon's "More" screen.
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Red icon + title, for actions that delete things.
  final bool destructive;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = destructive ? Colors.redAccent : AppColors.coldGray;
    final titleColor = destructive ? Colors.redAccent : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        highlightColor: Colors.white.withValues(alpha: 0.05),
        splashColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 24, color: iconColor),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 15, color: titleColor),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: trailing!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin line between groups of settings rows.
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.border);
  }
}

/// Small uppercase label for the right side of a row ("DELETE ALL").
class SettingsActionLabel extends StatelessWidget {
  final String label;
  final bool destructive;

  const SettingsActionLabel(this.label, {super.key, this.destructive = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: destructive ? Colors.redAccent : AppColors.amber,
      ),
    );
  }
}
