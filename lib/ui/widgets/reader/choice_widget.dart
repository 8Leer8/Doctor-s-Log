import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/story_element.dart';

class ChoiceWidget extends StatelessWidget {
  final StoryChoiceElement element;
  final String? selectedValue;
  final ValueChanged<String> onSelect;

  const ChoiceWidget({
    super.key,
    required this.element,
    required this.selectedValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ClipPath(
        clipper: CutCornerClipper(cut: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.fork_right, size: 16, color: AppColors.amber),
                  SizedBox(width: 6),
                  Text(
                    'CHOICE',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...element.options.map((opt) {
                final isSelected = selectedValue == opt.value;
                final hasSelection = selectedValue != null;

                if (hasSelection && !isSelected) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: GestureDetector(
                      onTap: () => onSelect(opt.value),
                      child: Text(
                        'You didn\'t choose: ${opt.label}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.coldGray,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    onTap: () => onSelect(opt.value),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.amber.withValues(alpha: 0.15)
                            : AppColors.surfaceRaised,
                        border: Border.all(
                          color: isSelected ? AppColors.amber : AppColors.border,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          if (isSelected)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(Icons.check, size: 14, color: AppColors.amber),
                            ),
                          Expanded(
                            child: Text(
                              opt.label,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected ? AppColors.amber : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (selectedValue == null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Pick an option to continue reading.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.coldGray,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}