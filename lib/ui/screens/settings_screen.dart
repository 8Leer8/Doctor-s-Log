import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Text('SETTINGS', style: TextStyle(color: AppColors.textPrimary, letterSpacing: 2)),
      ),
    );
  }
}