import 'package:flutter/material.dart';
import '../../data/download/download_manager.dart';
import '../../theme/app_theme.dart';
import '../widgets/common/home_top_bar.dart';

/// Live view of the download queue. Parts download one at a time, top to
/// bottom. The row at the top is the one being downloaded right now.
class DownloadQueueScreen extends StatelessWidget {
  const DownloadQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = DownloadManager.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: manager,
        builder: (context, _) {
          final jobs = manager.jobs;
          final paused = manager.isPaused;
          final waiting = manager.waitingForWifi;

          return Column(
            children: [
              HomeTopBar(
                child: Row(
                  key: const ValueKey('download-queue-bar'),
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'DOWNLOAD QUEUE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (jobs.isNotEmpty)
                      IconButton(
                        tooltip: paused ? 'Resume' : 'Pause',
                        icon: Icon(
                          paused ? Icons.play_arrow : Icons.pause,
                          color: AppColors.coldGray,
                          size: 22,
                        ),
                        onPressed: paused ? manager.resume : manager.pause,
                      ),
                    if (jobs.isNotEmpty)
                      IconButton(
                        tooltip: 'Cancel all',
                        icon: const Icon(
                          Icons.delete_sweep_outlined,
                          color: AppColors.coldGray,
                          size: 22,
                        ),
                        onPressed: manager.cancelAll,
                      ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
              if (waiting && jobs.isNotEmpty)
                const _InfoBanner(
                  icon: Icons.wifi_off_rounded,
                  text:
                      'Waiting for Wi-Fi. Downloads start automatically when '
                      'you connect.',
                )
              else if (paused && jobs.isNotEmpty)
                _InfoBanner(
                  icon: Icons.pause_circle_outline,
                  text: 'Paused. Resume when you are back online.',
                  actionLabel: 'RESUME',
                  onAction: manager.resume,
                ),
              Expanded(
                child: jobs.isEmpty
                    ? const _EmptyQueue()
                    : _QueueList(jobs: jobs),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InfoBanner({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 8, actionLabel == null ? 20 : 8, 8),
      color: AppColors.amber.withValues(alpha: 0.10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: AppColors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.download_done_outlined,
              size: 44,
              color: AppColors.coldGray.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 14),
            const Text(
              'QUEUE EMPTY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppColors.amber,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Parts you download show up here and are fetched one at a time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueList extends StatelessWidget {
  final List<DownloadJob> jobs;

  const _QueueList({required this.jobs});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    String? lastChapter;
    for (final job in jobs) {
      if (job.chapterId != lastChapter) {
        children.add(_ChapterHeader(title: job.chapterTitle));
        lastChapter = job.chapterId;
      }
      children.add(_JobRow(key: ValueKey(job.filename), job: job));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: children,
    );
  }
}

class _ChapterHeader extends StatelessWidget {
  final String title;

  const _ChapterHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Text(
        title.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.amber,
        ),
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  final DownloadJob job;

  const _JobRow({super.key, required this.job});

  String get _status {
    if (job.state == DownloadJobState.queued) return 'QUEUED';
    final p = job.progress;
    if (p == null) return 'DOWNLOADING…';
    return 'DOWNLOADING · ${(p * 100).round()}%';
  }

  @override
  Widget build(BuildContext context) {
    final downloading = job.state == DownloadJobState.downloading;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.partTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _status,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.4,
                        color: downloading
                            ? AppColors.amber
                            : AppColors.coldGray,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Cancel',
                icon: const Icon(
                  Icons.close,
                  size: 20,
                  color: AppColors.coldGray,
                ),
                onPressed: () => DownloadManager.instance.cancel(job.filename),
              ),
            ],
          ),
          if (downloading)
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: job.progress,
                  minHeight: 3,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.amber),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
