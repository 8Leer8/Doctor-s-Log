import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'detail_colors.dart';

/// Fixed top bar. Over the artwork it sits on a dark top-down gradient; as the
/// content sheet reaches it, it fades to solid and the title fades in.
class ChapterDetailTopBar extends StatelessWidget {
  static const double toolbarHeight = 64;

  final String title;

  /// 0 = transparent over the artwork, 1 = solid (sheet reached the bar).
  final double solidFraction;
  final VoidCallback onBack;
  final VoidCallback onDownloadAll;
  final VoidCallback onFilterTap;

  const ChapterDetailTopBar({
    super.key,
    required this.title,
    required this.solidFraction,
    required this.onBack,
    required this.onDownloadAll,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final barHeight = topPad + toolbarHeight;
    final gradientHeight = math.max(88.0, barHeight);
    final f = solidFraction.clamp(0.0, 1.0);

    return SizedBox(
      height: gradientHeight,
      child: Stack(
        children: [
          // Dark gradient: keeps white icons legible over bright artwork.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: gradientHeight,
            child: Opacity(
              opacity: 1 - f,
              child: const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromRGBO(15, 19, 25, 0.7),
                        Color.fromRGBO(15, 19, 25, 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Solid bar with a bottom hairline.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: barHeight,
            child: Opacity(
              opacity: f,
              child: const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: DetailColors.sheet,
                    border: Border(
                      bottom: BorderSide(color: DetailColors.hairline),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: topPad,
            left: 0,
            right: 0,
            height: toolbarHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    iconSize: 28,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: onBack,
                  ),
                  Expanded(
                    child: Opacity(
                      opacity: f,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    iconSize: 28,
                    icon: const Icon(
                      Icons.download_outlined,
                      color: Colors.white,
                    ),
                    tooltip: 'Download all',
                    onPressed: onDownloadAll,
                  ),
                  IconButton(
                    iconSize: 28,
                    icon: const Icon(Icons.tune, color: Colors.white),
                    tooltip: 'Filter & sort',
                    onPressed: onFilterTap,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.menu, size: 28, color: Colors.white),
                    color: AppColors.surface,
                    onSelected: (value) {},
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'refresh',
                        child: Text(
                          'Refresh',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'wiki',
                        child: Text(
                          'Open Wiki',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        child: Text(
                          'Share',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
