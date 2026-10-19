import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/chapter_preview.dart';
import '../../models/story_category.dart';
import '../../utils/act_type_formatter.dart';
import 'common/cover_image.dart';

/// Mihon-style poster card used by ALL three Library tabs:
///   * the cover on its own (nothing drawn over the artwork except the
///     optional unread badge in the top-left),
///   * label + title sitting directly on the screen background below it.
class ChapterCard extends StatelessWidget {
  /// marginTop between the cover and the text.
  static const double coverGap = 6;

  /// marginBottom of the grid item (row separation).
  static const double bottomGap = 16;

  /// Height of the text wrapper. Fits: 1 label line (10px) + 2px gap +
  /// 2 title lines (13px), all at line-height 1.2, with a little spare room.
  static const double _textMinHeight = 56;

  static const Color _labelColor = Color(0xFFD99B26);

  /// Height of everything under the cover (gap + text area + bottom margin).
  /// The grid adds this to the cover height to size each cell. The text area
  /// grows with the system font scale so large text doesn't overflow.
  static double belowCoverHeight(BuildContext context) {
    final scaled = MediaQuery.textScalerOf(context).scale(_textMinHeight);
    return coverGap + math.max(_textMinHeight, scaled) + bottomGap;
  }

  final ChapterPreview chapter;
  final StoryCategory category;
  final int finishedCount;
  final VoidCallback? onTap;

  const ChapterCard({
    super.key,
    required this.chapter,
    required this.category,
    required this.finishedCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalParts = chapter.parts.length;
    final unreadCount = math.max(0, totalParts - finishedCount);
    final cardLabel = formatChapterCardLabel(
      chapter.number,
      chapter.subtitle,
    ).toUpperCase();
    final textAreaHeight = belowCoverHeight(context) - coverGap - bottomGap;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- thumbnail (clipped; no text over the artwork) ----
          AspectRatio(
            aspectRatio: category.coverAspect,
            child: ClipPath(
              clipper: CutCornerClipper(cut: 12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: AppColors.surface),
                  CoverImage(
                    chapterId: chapter.number,
                    category: category,
                    entryPicId: chapter.entryPicId,
                  ),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(onTap: onTap),
                    ),
                  ),
                  // Only while there is something left to read; finished
                  // chapters keep a completely clean cover.
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: IgnorePointer(
                        child: _UnreadBadge(count: unreadCount),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ---- text, directly on the screen background ----
          const SizedBox(height: coverGap),
          SizedBox(
            height: textAreaHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cardLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _labelColor,
                    fontSize: 10,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  chapter.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: bottomGap),
        ],
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(15, 19, 25, 0.88),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.15),
          width: 1,
        ),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: AppColors.amber,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
