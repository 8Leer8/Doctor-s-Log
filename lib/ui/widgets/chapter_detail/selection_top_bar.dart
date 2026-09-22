import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class SelectionTopBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onClose;
  final VoidCallback onSelectAll;
  final VoidCallback onInvert;
  final bool allSelected;

  const SelectionTopBar({
    super.key,
    required this.selectedCount,
    required this.onClose,
    required this.onSelectAll,
    required this.onInvert,
    required this.allSelected,
  });

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      height: statusBarHeight + 56,
      padding: EdgeInsets.only(top: statusBarHeight),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: onClose,
          ),
          const SizedBox(width: 4),
          Text(
            '$selectedCount',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: allSelected ? 'Deselect all' : 'Select all',
            icon: Icon(
              allSelected ? Icons.deselect : Icons.select_all,
              color: AppColors.coldGray,
            ),
            onPressed: onSelectAll,
          ),
          IconButton(
            tooltip: 'Invert selection',
            icon: const Icon(Icons.flip_to_back, color: AppColors.coldGray),
            onPressed: onInvert,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
