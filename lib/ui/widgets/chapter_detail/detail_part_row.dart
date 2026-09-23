import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../theme/app_theme.dart';
import '../../../models/story_part.dart';

enum DownloadState { notDownloaded, queued, downloading, downloaded }

class DetailPartRow extends StatelessWidget {
  final StoryPart part;
  final bool finished;
  final DownloadState downloadState;

  /// 0.0–1.0 while downloading with known progress; null for
  /// indeterminate. Ignored when downloadState isn't [downloading].
  final double? downloadProgress;

  /// True while the parent screen is in multi-select mode.
  final bool selectionMode;

  /// True when this row is part of the current multi-selection.
  final bool selected;

  /// True when the user has bookmarked this part.
  final bool bookmarked;

  final VoidCallback onDownloadTap;
  final VoidCallback onOpen;
  final VoidCallback onLongPress;
  final VoidCallback onSwipeFinished;
  final VoidCallback onSwipeBookmark;

  const DetailPartRow({
    super.key,
    required this.part,
    required this.finished,
    required this.downloadState,
    required this.onDownloadTap,
    required this.onOpen,
    required this.onLongPress,
    required this.onSwipeFinished,
    required this.onSwipeBookmark,
    this.downloadProgress,
    this.selectionMode = false,
    this.selected = false,
    this.bookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);

    // Swipe is disabled while the parent screen is in selection mode.
    if (selectionMode) {
      return content;
    }

    return Slidable(
      key: ValueKey('slidable-${part.filename ?? part.title}'),
      startActionPane: _buildStartPane(),
      endActionPane: _buildEndPane(),
      child: content,
    );
  }

  // Swipe left-to-right → Bookmark action.
  ActionPane _buildStartPane() {
    return ActionPane(
      motion: const BehindMotion(),
      extentRatio: 0.28,
      dismissible: DismissiblePane(
        closeOnCancel: true,
        confirmDismiss: () async {
          onSwipeBookmark();
          return false; // don't actually dismiss; just trigger the callback
        },
        onDismissed: () {},
      ),
      children: [
        CustomSlidableAction(
          onPressed: (_) => onSwipeBookmark(),
          backgroundColor: AppColors.amber.withValues(alpha: 0.15),
          foregroundColor: AppColors.amber,
          padding: EdgeInsets.zero,
          child: Center(
            child: Icon(
              bookmarked ? Icons.bookmark_remove : Icons.bookmark_add,
              color: AppColors.amber,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  // Swipe right-to-left → Finished action.
  ActionPane _buildEndPane() {
    return ActionPane(
      motion: const BehindMotion(),
      extentRatio: 0.28,
      dismissible: DismissiblePane(
        closeOnCancel: true,
        confirmDismiss: () async {
          onSwipeFinished();
          return false;
        },
        onDismissed: () {},
      ),
      children: [
        CustomSlidableAction(
          onPressed: (_) => onSwipeFinished(),
          backgroundColor: finished
              ? Colors.redAccent.withValues(alpha: 0.15)
              : Colors.green.withValues(alpha: 0.15),
          foregroundColor: finished ? Colors.redAccent : Colors.green,
          padding: EdgeInsets.zero,
          child: Center(
            child: Icon(
              finished ? Icons.refresh : Icons.check,
              color: finished ? Colors.redAccent : Colors.green,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: selectionMode ? onLongPress : onOpen,
        onLongPress: onLongPress,
        highlightColor: Colors.white.withValues(alpha: 0.06),
        splashColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: selected
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: finished ? 0.55 : 1.0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (bookmarked) ...[
                        const Icon(
                          Icons.bookmark,
                          size: 16,
                          color: AppColors.amber,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              part.title,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                            if (part.releaseDate != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _formatDate(part.releaseDate!),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.coldGray,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (part.filename == null)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.cloud_off,
                            size: 14,
                            color: AppColors.coldGray,
                          ),
                        ),
                      GestureDetector(
                        onTap: part.filename == null ? null : onDownloadTap,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: _buildDownloadIcon(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(height: 1, color: AppColors.border),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadIcon() {
    switch (downloadState) {
      case DownloadState.downloading:
        final pct = downloadProgress;
        if (pct == null || pct <= 0.0) {
          return const SizedBox(
            width: 26,
            height: 26,
            child: Padding(
              padding: EdgeInsets.all(4),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.amber,
              ),
            ),
          );
        }
        final displayPct = pct.clamp(0.0, 0.99);
        return SizedBox(
          width: 26,
          height: 26,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  value: displayPct,
                  strokeWidth: 2,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.amber),
                ),
              ),
              Text(
                '${(displayPct * 100).round()}',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.amber,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );

      case DownloadState.queued:
        return Icon(
          Icons.download_outlined,
          size: 26,
          color: AppColors.coldGray.withValues(alpha: 0.4),
        );

      case DownloadState.downloaded:
        return const Icon(Icons.check_circle, size: 26, color: AppColors.amber);

      case DownloadState.notDownloaded:
        return const Icon(
          Icons.download_outlined,
          size: 26,
          color: AppColors.coldGray,
        );
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
