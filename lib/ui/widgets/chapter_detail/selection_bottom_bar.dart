import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'selection_actions.dart';

class SelectionBottomBar extends StatelessWidget {
  final List<SelectionAction> actions;
  final bool allBookmarked;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final VoidCallback onBookmark;

  const SelectionBottomBar({
    super.key,
    required this.actions,
    required this.allBookmarked,
    required this.onDownload,
    required this.onDelete,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [for (final action in actions) _buildActionButton(action)],
        ),
      ),
    );
  }

  Widget _buildActionButton(SelectionAction action) {
    switch (action) {
      case SelectionAction.bookmark:
        return IconButton(
          tooltip: allBookmarked ? 'Remove bookmark' : 'Bookmark',
          iconSize: 26,
          icon: Icon(
            allBookmarked
                ? Icons.bookmark_remove_outlined
                : Icons.bookmark_add_outlined,
            color: AppColors.amber,
          ),
          onPressed: onBookmark,
        );
      case SelectionAction.download:
        return IconButton(
          tooltip: 'Download',
          iconSize: 26,
          icon: const Icon(
            Icons.download_for_offline_outlined,
            color: AppColors.amber,
          ),
          onPressed: onDownload,
        );
      case SelectionAction.delete:
        return IconButton(
          tooltip: 'Delete',
          iconSize: 26,
          icon: const Icon(
            Icons.delete_forever_outlined,
            color: Colors.redAccent,
          ),
          onPressed: onDelete,
        );
    }
  }
}
