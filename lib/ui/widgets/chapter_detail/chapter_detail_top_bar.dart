import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

const double _kToolbarHeight = 64;

class ChapterDetailTopBar extends StatelessWidget {
  final String title;
  final double collapseFraction;
  final double titleFraction;
  final VoidCallback onBack;
  final VoidCallback onDownloadAll;
  final VoidCallback onFilterTap;

  /// When true, the bar's background is always fully opaque and the
  /// icons are always their scrolled-in colors. Used for side stories,
  /// where the header image sits below the bar rather than behind it.
  /// The title still fades in via [titleFraction].
  final bool solid;

  const ChapterDetailTopBar({
    super.key,
    required this.title,
    required this.collapseFraction,
    required this.titleFraction,
    required this.onBack,
    required this.onDownloadAll,
    required this.onFilterTap,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    final effectiveCollapse = solid ? 1.0 : collapseFraction;
    final bgColor = AppColors.background.withValues(alpha: effectiveCollapse);
    final iconColor = Color.lerp(
      Colors.white,
      AppColors.coldGray,
      effectiveCollapse,
    )!;
    final backColor = Color.lerp(
      Colors.white,
      AppColors.textPrimary,
      effectiveCollapse,
    )!;
    final titleVisible = titleFraction >= 0.999;

    return Container(
      height: statusBarHeight + _kToolbarHeight,
      padding: EdgeInsets.only(top: statusBarHeight),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: effectiveCollapse),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        height: _kToolbarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                iconSize: 28,
                icon: Icon(Icons.arrow_back, color: backColor),
                onPressed: onBack,
              ),
              Expanded(
                child: AnimatedOpacity(
                  opacity: titleVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              IconButton(
                iconSize: 28,
                icon: Icon(Icons.download_outlined, color: iconColor),
                tooltip: 'Download all',
                onPressed: onDownloadAll,
              ),
              IconButton(
                iconSize: 28,
                icon: Icon(Icons.tune, color: iconColor),
                tooltip: 'Filter & sort',
                onPressed: onFilterTap,
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.menu, size: 28, color: iconColor),
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
    );
  }
}
