import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/reader_part.dart';

class ReaderTocSheet extends StatelessWidget {
  final List<ReaderPart> readerParts;
  final int currentPartIndex;
  final ValueChanged<int> onSelect;

  const ReaderTocSheet({
    super.key,
    required this.readerParts,
    required this.currentPartIndex,
    required this.onSelect,
  });

  static void show(
    BuildContext context,
    List<ReaderPart> readerParts,
    int currentPartIndex,
    ValueChanged<int> onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => ReaderTocSheet(
        readerParts: readerParts,
        currentPartIndex: currentPartIndex,
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(Icons.list, size: 16, color: AppColors.amber),
                SizedBox(width: 6),
                Text(
                  'CHAPTER PARTS',
                  style: TextStyle(
                    color: AppColors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: readerParts.length,
              itemBuilder: (context, index) {
                final isCurrent = index == currentPartIndex;
                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelect(index);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.amber.withValues(alpha: 0.1) : null,
                      border: const Border(
                        bottom: BorderSide(color: AppColors.border, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCurrent ? Icons.play_circle : Icons.circle_outlined,
                          size: 16,
                          color: isCurrent ? AppColors.amber : AppColors.coldGray,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            readerParts[index].part.title,
                            style: TextStyle(
                              fontSize: 13,
                              color: isCurrent ? AppColors.amber : AppColors.textPrimary,
                              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}