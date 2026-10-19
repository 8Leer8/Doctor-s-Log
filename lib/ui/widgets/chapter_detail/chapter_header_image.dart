import 'package:flutter/material.dart';
import '../../../models/story_category.dart';
import '../common/cover_image.dart';
import 'detail_colors.dart';

class ChapterHeaderImage extends StatelessWidget {
  static const double _mainFrameZoom = 1.15;
  static const double _zoomAnchorY = -0.5;
  static const double _fadeHeight = 64;

  final String chapterId;
  final StoryCategory category;
  final String? entryPicId;

  const ChapterHeaderImage({
    super.key,
    required this.chapterId,
    required this.category,
    this.entryPicId,
  });

  @override
  Widget build(BuildContext context) {
    final isMain = category == StoryCategory.mainTheme;
    final zoom = isMain ? _mainFrameZoom : 1.0;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: DetailColors.sheet),
          Transform.scale(
            scale: zoom,
            alignment: Alignment(0, _zoomAnchorY),
            child: CoverImage(
              chapterId: chapterId,
              category: category,
              entryPicId: entryPicId,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              placeholderIconSize: 48,
            ),
          ),
          // Bottom-up fade into the sheet: no harsh line at the seam.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _fadeHeight,
            child: const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [DetailColors.sheet, Color(0x000F1319)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
