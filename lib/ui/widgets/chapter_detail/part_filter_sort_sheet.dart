import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

enum PartFilterMode { all, unread, read }
enum PartSortOrder { ascending, descending }

class PartFilterSortSheet extends StatefulWidget {
  final PartFilterMode filterMode;
  final PartSortOrder sortOrder;
  final ValueChanged<PartFilterMode> onFilterChanged;
  final ValueChanged<PartSortOrder> onSortChanged;

  const PartFilterSortSheet({
    super.key,
    required this.filterMode,
    required this.sortOrder,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  static void show(
    BuildContext context, {
    required PartFilterMode filterMode,
    required PartSortOrder sortOrder,
    required ValueChanged<PartFilterMode> onFilterChanged,
    required ValueChanged<PartSortOrder> onSortChanged,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Filter and sort',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: SafeArea(
              bottom: false,
              child: PartFilterSortSheet(
                filterMode: filterMode,
                sortOrder: sortOrder,
                onFilterChanged: onFilterChanged,
                onSortChanged: onSortChanged,
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final offsetAnim = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
        return SlideTransition(position: offsetAnim, child: child);
      },
    );
  }

  @override
  State<PartFilterSortSheet> createState() => _PartFilterSortSheetState();
}

class _PartFilterSortSheetState extends State<PartFilterSortSheet> {
  late PartFilterMode _filterMode;
  late PartSortOrder _sortOrder;

  @override
  void initState() {
    super.initState();
    _filterMode = widget.filterMode;
    _sortOrder = widget.sortOrder;
  }

  void _setFilter(PartFilterMode mode) {
    setState(() => _filterMode = mode);
    widget.onFilterChanged(mode);
  }

  void _setSort(PartSortOrder order) {
    setState(() => _sortOrder = order);
    widget.onSortChanged(order);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'FILTER',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.coldGray, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Chip(label: 'All', selected: _filterMode == PartFilterMode.all, onTap: () => _setFilter(PartFilterMode.all)),
              const SizedBox(width: 8),
              _Chip(label: 'Unread', selected: _filterMode == PartFilterMode.unread, onTap: () => _setFilter(PartFilterMode.unread)),
              const SizedBox(width: 8),
              _Chip(label: 'Read', selected: _filterMode == PartFilterMode.read, onTap: () => _setFilter(PartFilterMode.read)),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'SORT',
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Chip(
                  label: 'Ascending',
                  hint: '1 → last',
                  selected: _sortOrder == PartSortOrder.ascending,
                  onTap: () => _setSort(PartSortOrder.ascending),
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Chip(
                  label: 'Descending',
                  hint: 'last → 1',
                  selected: _sortOrder == PartSortOrder.descending,
                  onTap: () => _setSort(PartSortOrder.descending),
                  fullWidth: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String? hint;
  final bool selected;
  final VoidCallback onTap;
  final bool fullWidth;

  const _Chip({
    required this.label,
    this.hint,
    required this.selected,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.amber.withValues(alpha: 0.15) : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? AppColors.amber : AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.amber : AppColors.textPrimary,
              ),
            ),
            if (hint != null)
              Text(hint!, style: const TextStyle(fontSize: 10, color: AppColors.coldGray)),
          ],
        ),
      ),
    );
  }
}