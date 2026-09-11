import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/story_element.dart';
import '../../../models/reader_settings.dart';

class ChoiceWidget extends StatelessWidget {
  final StoryChoiceElement element;
  final String? selectedValue;
  final ValueChanged<String> onSelect;
  final ReaderSettings settings;

  const ChoiceWidget({
    super.key,
    required this.element,
    required this.selectedValue,
    required this.onSelect,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final colors = settings.colors;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ClipPath(
        clipper: CutCornerClipper(cut: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.background,
            border: Border.all(color: colors.accent.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.fork_right, size: 16, color: colors.accent),
                  const SizedBox(width: 6),
                  Text(
                    'CHOICE',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                      color: colors.accent,
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
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.secondaryText,
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
                            ? colors.accent.withValues(alpha: 0.15)
                            : colors.secondaryText.withValues(alpha: 0.08),
                        border: Border.all(
                          color: isSelected ? colors.accent : colors.secondaryText.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(Icons.check, size: 14, color: colors.accent),
                            ),
                          Expanded(
                            child: Text(
                              opt.label,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected ? colors.accent : colors.text,
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
                Text(
                  'Pick an option to continue reading.',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.secondaryText,
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