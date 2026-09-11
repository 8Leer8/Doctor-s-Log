import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/reader_settings.dart';

class ReaderSettingsSheet extends StatefulWidget {
  final ReaderSettings settings;
  final ValueChanged<ReaderSettings> onChanged;

  const ReaderSettingsSheet({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  static void show(
    BuildContext context,
    ReaderSettings settings,
    ValueChanged<ReaderSettings> onChanged,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Reading settings',
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
              child: ReaderSettingsSheet(settings: settings, onChanged: onChanged),
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
  State<ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<ReaderSettingsSheet> {
  late ReaderSettings _current;

  @override
  void initState() {
    super.initState();
    _current = widget.settings;
  }

  void _update(ReaderSettings updated) {
    setState(() => _current = updated);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final accent = _current.colors.accent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'READING SETTINGS',
                style: TextStyle(
                  color: accent,
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
          const SizedBox(height: 16),

          const Text('Font size',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.text_decrease, color: AppColors.textSecondary),
                onPressed: _current.fontSize > 12
                    ? () => _update(_current.copyWith(fontSize: _current.fontSize - 1))
                    : null,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: accent,
                    inactiveTrackColor: AppColors.border,
                    thumbColor: accent,
                    overlayColor: accent.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _current.fontSize,
                    min: 12,
                    max: 24,
                    divisions: 12,
                    label: _current.fontSize.round().toString(),
                    onChanged: (v) => _update(_current.copyWith(fontSize: v)),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.text_increase, color: AppColors.textSecondary),
                onPressed: _current.fontSize < 24
                    ? () => _update(_current.copyWith(fontSize: _current.fontSize + 1))
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Text('Background',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: ReaderThemeOption.values.map((option) {
              final colors = ReaderThemeColors.presets[option]!;
              final isSelected = _current.theme == option;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _update(_current.copyWith(theme: option)),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? colors.accent : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text('Aa', style: TextStyle(color: colors.text, fontWeight: FontWeight.w600)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          const Text('Line spacing',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: LineSpacingOption.values.map((option) {
              final isSelected = _current.lineSpacing == option;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _update(_current.copyWith(lineSpacing: option)),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? accent.withValues(alpha: 0.15) : AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isSelected ? accent : AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? accent : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              const Expanded(
                child: Text('Keep screen awake',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Switch(
                value: _current.keepScreenAwake,
                activeThumbColor: accent,
                onChanged: (v) => _update(_current.copyWith(keepScreenAwake: v)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}