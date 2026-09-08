import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Text('LIBRARY', style: TextStyle(color: AppColors.textPrimary, letterSpacing: 2)),
      ),
    );
  }
}