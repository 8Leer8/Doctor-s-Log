import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/story_category.dart';

class ChapterHeaderImage extends StatelessWidget {
  final String chapterId;
  final StoryCategory category;

  const ChapterHeaderImage({
    super.key,
    required this.chapterId,
    required this.category,
  });

  String get _folder => category.imageFolder;

  Widget _placeholder(Object error) {
    if (kDebugMode) {
      // Shows up in the `flutter run` console so a missing / unregistered
      // cover is obvious instead of silently showing the gray box.
      debugPrint(
        'Cover not found for "$chapterId" in assets/images/$_folder/ -> $error',
      );
    }
    return Container(
      color: AppColors.surfaceRaised,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: AppColors.coldGray.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Image.asset(
      'assets/images/$_folder/$chapterId.jpg',
      fit: BoxFit.cover,
      errorBuilder: (context, jpgError, _) => Image.asset(
        'assets/images/$_folder/$chapterId.png',
        fit: BoxFit.cover,
        errorBuilder: (context, _, _) => _placeholder(jpgError),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Side stories: plain banner image, no overlays.
    if (!category.usesTallHeader) {
      return _buildImage();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildImage(),
        // Top scrim so the status bar / back button stay readable.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.black26, Colors.transparent],
              stops: [0.0, 0.08, 0.18],
            ),
          ),
        ),
        // Side vignette (drawn BEFORE the bottom fade so it can't tint it).
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
        // Bottom fade into the body color.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withValues(alpha: 0.0),
                AppColors.background.withValues(alpha: 0.0),
                AppColors.background,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
