import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Asks the user to confirm deleting a downloaded part.
/// Returns true if they confirmed, false/null otherwise.
Future<bool?> showDeleteDownloadDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      title: const Text(
        'Delete download?',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: const Text(
        'This will remove the offline copy of this part. You can re-download it anytime.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'CANCEL',
            style: TextStyle(color: AppColors.coldGray, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'DELETE',
            style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

/// If the user is jumping ahead past their first unfinished part,
/// shows a "Skip ahead?" dialog. Returns true if they're allowed to
/// proceed (including the no-dialog-needed case).
Future<bool> showSkipAheadDialogIfNeeded({
  required BuildContext context,
  required List<bool> finished,
  required int targetOriginalIndex,
}) async {
  final firstUnfinished = finished.indexWhere((f) => !f);
  final isSkippingAhead = firstUnfinished != -1 && targetOriginalIndex > firstUnfinished;
  if (!isSkippingAhead) return true;

  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 20),
          SizedBox(width: 8),
          Text(
            'Skip ahead?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: const Text(
        'Reading from the top keeps the story\'s flow and immersion intact. '
        'You still have earlier unread parts — jumping ahead may skip context or spoil what happens next.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'CANCEL',
            style: TextStyle(color: AppColors.coldGray, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'READ ANYWAY',
            style: TextStyle(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}