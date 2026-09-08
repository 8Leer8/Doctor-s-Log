import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF15181F);
  static const surface = Color(0xFF1C2029);
  static const surfaceRaised = Color(0xFF232833);
  static const amber = Color(0xFFF2A93C);
  static const coldGray = Color(0xFF6B7280);
  static const border = Color(0xFF2E333F);
  static const textPrimary = Color(0xFFEDEDED);
  static const textSecondary = Color(0xFF9CA3AF);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.amber,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.amber,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
        bodyMedium: TextStyle(color: AppColors.textPrimary),
        bodySmall: TextStyle(color: AppColors.textSecondary),
      ),
      dividerColor: AppColors.border,
    );
  }
}

/// Angular "cut corner" clipper used across nav bar and cards
/// to match the Arknights terminal aesthetic.
class CutCornerClipper extends CustomClipper<Path> {
  final double cut;
  CutCornerClipper({this.cut = 12});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(cut, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - cut);
    path.lineTo(size.width - cut, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, cut);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}