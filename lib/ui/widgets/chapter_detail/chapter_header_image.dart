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
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black54, // strongest at the very top
                Colors.black26, // softening
                Colors.transparent,
              ],
              stops: [0.0, 0.08, 0.18],
            ),
          ),
        ),
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
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black45,
                Colors.transparent,
                Colors.transparent,
                Colors.black45,
              ],
              stops: [0.0, 0.12, 0.88, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}