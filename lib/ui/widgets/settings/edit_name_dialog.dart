import 'package:flutter/material.dart';
import '../../../data/local/profile_store.dart';
import '../../../theme/app_theme.dart';

/// Asks for the Doctor's name. Returns the new name, or null if cancelled.
class EditNameDialog extends StatefulWidget {
  final String initial;

  const EditNameDialog({super.key, required this.initial});

  static Future<String?> show(BuildContext context, String initial) {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => EditNameDialog(initial: initial),
    );
  }

  @override
  State<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      title: const Text(
        'Your name',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shown on your profile. Leave it empty to go back to "Doctor".',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: ProfileStore.maxNameLength,
            maxLines: 1,
            cursorColor: AppColors.amber,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: const InputDecoration(
              hintText: ProfileStore.defaultName,
              hintStyle: TextStyle(color: AppColors.coldGray),
              counterStyle: TextStyle(color: AppColors.coldGray),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.amber),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'CANCEL',
            style: TextStyle(
              color: AppColors.coldGray,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: _save,
          child: const Text(
            'SAVE',
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
