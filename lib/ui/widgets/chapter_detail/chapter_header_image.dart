import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ChapterHeaderImage extends StatelessWidget {
  final String chapterId;

  const ChapterHeaderImage({super.key, required this.chapterId});

  Widget _buildImage() {
    return Image.asset(
      'assets/images/chapters/$chapterId.jpg',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/images/chapters/$chapterId.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.surfaceRaised,
          child: Center(
            child: Icon(
              Icons.image_outlined,
              size: 48,
              color: AppColors.coldGray.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildImage(),
        // Bottom vignette so text overlaid on top of it stays legible.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.transparent, Colors.black87],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        // Very light side vignette — subtle depth, kept faint since no
        // text sits near the edges.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black26,
                Colors.transparent,
                Colors.transparent,
                Colors.black26,
              ],
              stops: [0.0, 0.15, 0.85, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}