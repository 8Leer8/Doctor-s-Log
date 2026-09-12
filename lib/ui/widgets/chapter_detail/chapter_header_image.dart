import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ChapterHeaderImage extends StatelessWidget {
  final String chapterId;
  final String title;
  final String subtitleLabel;

  const ChapterHeaderImage({
    super.key,
    required this.chapterId,
    required this.title,
    required this.subtitleLabel,
  });

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
    return SizedBox(
      height: 420,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildImage(),
          // Darkens the lower edge enough for the title/subtitle text to
          // stay legible against any image content.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black54,
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
          // A light, short fade at the very top so the toolbar icons
          // (back, download, filter, menu) stay visible even when the
          // chapter image is light-colored or white near the top edge.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 110,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitleLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}