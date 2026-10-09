import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class LibrarySectionTabBar extends StatelessWidget {
  /// When non-null, shown next to the tab name (used while searching).
  final int? mainCount;
  final int? sideCount;
  final int? vignetteCount;

  const LibrarySectionTabBar({
    super.key,
    this.mainCount,
    this.sideCount,
    this.vignetteCount,
  });

  String _label(String base, int? count) =>
      count == null ? base : '$base · $count';

  @override
  Widget build(BuildContext context) {
    return TabBar(
      isScrollable: true,
      // Material 3 indents scrollable tabs by 52px by default. Pin them to
      // the left edge; extra tabs later will just scroll horizontally.
      tabAlignment: TabAlignment.start,
      // No divider line under the tabs — only the amber indicator remains.
      dividerColor: Colors.transparent,
      dividerHeight: 0,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
      indicatorColor: AppColors.amber,
      labelColor: AppColors.amber,
      unselectedLabelColor: AppColors.coldGray,
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
      tabs: [
        Tab(text: _label('MAIN THEME', mainCount)),
        Tab(text: _label('SIDE STORIES', sideCount)),
        Tab(text: _label('VIGNETTES', vignetteCount)),
      ],
    );
  }
}
