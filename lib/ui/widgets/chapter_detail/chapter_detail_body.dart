import 'package:flutter/material.dart';
import '../../../models/chapter_preview.dart';
import '../../../data/parser/word_count_estimator.dart';
import 'chapter_detail_header.dart';
import 'detail_action_button.dart';
import 'detail_colors.dart';
import 'detail_part_row.dart';

/// The sliding content sheet: title block, action buttons, consolidated
/// progress row, then the part list.
class ChapterDetailBody extends StatelessWidget {
  final ChapterPreview chapter;
  final String? description;
  final bool descriptionLoaded;
  final List<bool> finished;
  final Map<int, DownloadState> downloadStates;
  final Map<int, double> downloadProgress;
  final Map<int, int> partWordCounts;
  final List<int> displayIndices;
  final int finishedCount;

  /// Index of the first unread part, or -1 when everything is read.
  final int nextUpIndex;
  final int? totalWordCount;
  final bool computingWordCount;

  final bool selectionMode;
  final Set<int> selectedIndices;
  final Set<String> bookmarkedFilenames;

  final VoidCallback onMarkAllFinished;
  final VoidCallback onClearAll;
  final ValueChanged<int> onDownloadTap;
  final ValueChanged<int> onOpenPart;
  final ValueChanged<int> onLongPressPart;
  final ValueChanged<int> onSwipeFinished;
  final ValueChanged<int> onSwipeBookmark;

  const ChapterDetailBody({
    super.key,
    required this.chapter,
    required this.description,
    required this.descriptionLoaded,
    required this.finished,
    required this.downloadStates,
    required this.downloadProgress,
    required this.partWordCounts,
    required this.displayIndices,
    required this.finishedCount,
    required this.nextUpIndex,
    required this.totalWordCount,
    required this.computingWordCount,
    required this.selectionMode,
    required this.selectedIndices,
    required this.bookmarkedFilenames,
    required this.onMarkAllFinished,
    required this.onClearAll,
    required this.onDownloadTap,
    required this.onOpenPart,
    required this.onLongPressPart,
    required this.onSwipeFinished,
    required this.onSwipeBookmark,
  });

  /// "~45 MIN" or "~1H 12M". Short enough to never collide with the
  /// "N OF M FINISHED" label on the right.
  static String _fmtMinutes(int minutes) {
    if (minutes < 60) return '~$minutes MIN';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '~${h}H' : '~${h}H ${m}M';
  }

  @override
  Widget build(BuildContext context) {
    final total = chapter.parts.length;
    final progressRatio = total == 0 ? 0.0 : finishedCount / total;

    var left = '$total PARTS';
    if (computingWordCount) {
      left += ' • CALCULATING…';
    } else if ((totalWordCount ?? 0) > 0) {
      left +=
          ' • ${_fmtMinutes(WordCountEstimator.estimateMinutes(totalWordCount!))}';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: DetailColors.sheet,
        border: const Border(top: BorderSide(color: DetailColors.hairline)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChapterDetailHeader(
                  chapter: chapter,
                  description: description,
                  descriptionLoaded: descriptionLoaded,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: DetailActionButton(
                        label: 'MARK ALL READ',
                        icon: Icons.check,
                        expanded: true,
                        onPressed: onMarkAllFinished,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DetailActionButton(
                        label: 'CLEAR ALL',
                        icon: Icons.refresh,
                        expanded: true,
                        onPressed: onClearAll,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        left,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: DetailColors.slate,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$finishedCount OF $total FINISHED',
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: DetailColors.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progressRatio,
                    minHeight: 3,
                    backgroundColor: DetailColors.track,
                    valueColor: const AlwaysStoppedAnimation(
                      DetailColors.amber,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
          ...displayIndices.map((index) {
            final part = chapter.parts[index];
            final state = downloadStates[index] ?? DownloadState.notDownloaded;
            final filename = part.filename;
            final words = partWordCounts[index];
            return DetailPartRow(
              part: part,
              index: index,
              finished: finished[index],
              nextUp: index == nextUpIndex,
              downloadState: state,
              minutes: words == null
                  ? null
                  : WordCountEstimator.estimateMinutes(words),
              downloadProgress: state == DownloadState.downloading
                  ? downloadProgress[index]
                  : null,
              selectionMode: selectionMode,
              selected: selectedIndices.contains(index),
              bookmarked:
                  filename != null && bookmarkedFilenames.contains(filename),
              onDownloadTap: () => onDownloadTap(index),
              onOpen: () => onOpenPart(index),
              onLongPress: () => onLongPressPart(index),
              onSwipeFinished: () => onSwipeFinished(index),
              onSwipeBookmark: () => onSwipeBookmark(index),
            );
          }),
          // Clearance so the floating CONTINUE button never covers the last
          // row's download icon.
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
