import 'package:flutter/material.dart';
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

  final VoidCallback onToggleFinished;
  final VoidCallback onDownloadTap;
  final VoidCallback onOpen;

  const DetailPartRow({
    super.key,
    required this.part,
    required this.finished,
    required this.downloadState,
    required this.onToggleFinished,
    required this.onDownloadTap,
    required this.onOpen,
    this.downloadProgress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Opacity(
          opacity: finished ? 0.55 : 1.0,
          child: Row(
            children: [
              GestureDetector(
                onTap: onToggleFinished,
                child: Icon(
                  finished ? Icons.check_circle : Icons.circle_outlined,
                  size: 22,
                  color: finished ? Colors.green.shade400 : AppColors.coldGray,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (part.releaseDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _formatDate(part.releaseDate!),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.coldGray,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (part.filename == null)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.cloud_off,
                    size: 14,
                    color: AppColors.coldGray,
                  ),
                ),
              GestureDetector(
                onTap: part.filename == null ? null : onDownloadTap,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _buildDownloadIcon(),
                ),
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
        // Clamp the displayed value so the ring never reaches 1.0
        // while still downloading. That avoids the "full ring for one
        // frame then it disappears" flash.
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
