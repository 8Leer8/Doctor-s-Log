import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../chapter_detail/detail_action_button.dart';

/// Shown when a Library tab has nothing to display. Either a plain
/// "nothing here" state, or a "no matches" state while searching, with a
/// shortcut to another tab if that one has results.
class LibraryEmptyState extends StatelessWidget {
  final bool filtering;
  final String query;

  /// Plain (not searching) state.
  final String title;
  final String emptyMessage;
  final IconData icon;

  /// Matches in the *other* tab, its label, and its tab index
  /// (only used while [filtering]).
  final int otherCount;
  final String otherLabel;
  final int otherTabIndex;

  const LibraryEmptyState({
    super.key,
    required this.filtering,
    required this.query,
    required this.emptyMessage,
    this.title = 'NOTHING HERE',
    this.icon = Icons.auto_stories_outlined,
    this.otherCount = 0,
    this.otherLabel = '',
    this.otherTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (!filtering) {
      return _EmptyBody(icon: icon, title: title, message: emptyMessage);
    }

    return _EmptyBody(
      icon: Icons.search_off,
      title: 'NO MATCHES',
      message:
          'Nothing for “$query” here.\nTry a chapter title, character or place.',
      action: otherCount > 0
          ? DetailActionButton(
              label: '$otherCount IN $otherLabel',
              icon: Icons.arrow_forward,
              onPressed: () =>
                  DefaultTabController.of(context).animateTo(otherTabIndex),
            )
          : null,
    );
  }
}

class _EmptyBody extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _EmptyBody({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 44,
              color: AppColors.coldGray.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppColors.amber,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}
