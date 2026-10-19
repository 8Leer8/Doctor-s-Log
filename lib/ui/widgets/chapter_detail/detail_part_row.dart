import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../theme/app_theme.dart';
import '../../../models/story_part.dart';
import 'detail_colors.dart';

enum DownloadState { notDownloaded, queued, downloading, downloaded }

class DetailPartRow extends StatelessWidget {
  final StoryPart part;

  /// Position in the chapter; used for the fallback stage code ("01", "02").
  final int index;
  final bool finished;

  /// True for the first unread part (the one CONTINUE launches).
  final bool nextUp;
  final DownloadState downloadState;

  /// Estimated reading time for this part, when known.
  final int? minutes;

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
    required this.index,
    required this.finished,
    required this.downloadState,
    required this.onDownloadTap,
    required this.onOpen,
    required this.onLongPress,
    required this.onSwipeFinished,
    required this.onSwipeBookmark,
    this.nextUp = false,
    this.minutes,
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

  String get _stageCode {
    final code = part.code;
    if (code != null && code.isNotEmpty) return code;
    return (index + 1).toString().padLeft(2, '0');
  }

  String? get _subtitle {
    final pieces = <String>[];
    final phase = part.avgTag;
    if (phase != null && phase.trim().isNotEmpty) {
      pieces.add(phase.trim().toUpperCase());
    }
    if (minutes != null && minutes! > 0) pieces.add('$minutes MIN');
    return pieces.isEmpty ? null : pieces.join(' • ');
  }

  Widget _buildContent(BuildContext context) {
    final subtitle = _subtitle;
    final codeColor = finished ? DetailColors.stageDim : DetailColors.amber;
    final titleColor = finished ? DetailColors.slate : Colors.white;

    Color background = Colors.transparent;
    if (selected) {
      background = Colors.white.withValues(alpha: 0.08);
    } else if (nextUp) {
      background = DetailColors.nextUpTint;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: selectionMode ? onLongPress : onOpen,
        onLongPress: onLongPress,
        highlightColor: Colors.white.withValues(alpha: 0.06),
        splashColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: background,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: DetailColors.rowLine),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Opacity(
                        opacity: finished ? 0.45 : 1.0,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 38,
                              child: Text(
                                _stageCode,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: codeColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      if (bookmarked) ...[
                                        const Icon(
                                          Icons.bookmark,
                                          size: 14,
                                          color: DetailColors.amber,
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Expanded(
                                        child: Text(
                                          part.title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            height: 1.25,
                                            color: titleColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (subtitle != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: Text(
                                        subtitle,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          letterSpacing: 0.4,
                                          color: DetailColors.slate,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                      behavior: HitTestBehavior.opaque,
                      onTap: part.filename == null ? null : onDownloadTap,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _buildDownloadIcon(),
                      ),
                    ),
                  ],
                ),
              ),
              // "Next up" accent bar, flush on the left edge.
              if (nextUp)
                const Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 3,
                  child: ColoredBox(color: DetailColors.amber),
                ),
            ],
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
}
