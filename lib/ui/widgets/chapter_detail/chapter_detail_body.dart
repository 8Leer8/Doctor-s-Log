import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/chapter_preview.dart';
import '../../../data/parser/word_count_estimator.dart';
import 'detail_action_button.dart';
import 'detail_part_row.dart';

class ChapterDetailBody extends StatelessWidget {
  final ChapterPreview chapter;
  final List<bool> finished;
  final Map<int, DownloadState> downloadStates;
  final List<int> displayIndices;
  final int finishedCount;
  final int? totalWordCount;
  final bool computingWordCount;

  final VoidCallback onMarkAllFinished;
  final VoidCallback onClearAll;
  final ValueChanged<int> onToggleFinished;
  final ValueChanged<int> onDownloadTap;
  final ValueChanged<int> onOpenPart;

  const ChapterDetailBody({
    super.key,
    required this.chapter,
    required this.finished,
    required this.downloadStates,
    required this.displayIndices,
    required this.finishedCount,
    required this.totalWordCount,
    required this.computingWordCount,
    required this.onMarkAllFinished,
    required this.onClearAll,
    required this.onToggleFinished,
    required this.onDownloadTap,
    required this.onOpenPart,
  });

  @override
  Widget build(BuildContext context) {
    final total = chapter.parts.length;
    final progressRatio = total == 0 ? 0.0 : finishedCount / total;

    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DetailActionButton(
                label: 'MARK ALL READ',
                icon: Icons.check,
                onPressed: onMarkAllFinished,
              ),
              DetailActionButton(
                label: 'CLEAR ALL',
                icon: Icons.refresh,
                onPressed: onClearAll,
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progressRatio,
              minHeight: 4,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.amber),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                computingWordCount
                    ? 'Calculating...'
                    : '${totalWordCount ?? 0} words · about ${WordCountEstimator.estimateMinutes(totalWordCount ?? 0)}m',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                '$finishedCount OF $total FINISHED',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '$total PARTS',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.amber,
            ),
          ),
          const SizedBox(height: 4),
          ...displayIndices.map((index) {
            final part = chapter.parts[index];
            return DetailPartRow(
              part: part,
              finished: finished[index],
              downloadState: downloadStates[index] ?? DownloadState.notDownloaded,
              onToggleFinished: () => onToggleFinished(index),
              onDownloadTap: () => onDownloadTap(index),
              onOpen: () => onOpenPart(index),
            );
          }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}