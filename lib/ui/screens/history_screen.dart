import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Text('HISTORY', style: TextStyle(color: AppColors.textPrimary, letterSpacing: 2)),
      ),
    );
  }
}