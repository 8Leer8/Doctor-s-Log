import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/chapter_preview.dart';
import '../../models/reader_part.dart';
import 'reader_screen.dart';
import '../widgets/chapter_detail/detail_action_button.dart';
import '../widgets/chapter_detail/detail_part_row.dart';

class ChapterDetailScreen extends StatefulWidget {
  final ChapterPreview chapter;

  const ChapterDetailScreen({super.key, required this.chapter});

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen> {
  late List<bool> _finished;

  @override
  void initState() {
    super.initState();
    _finished = widget.chapter.parts.map((p) => p.finished).toList();
  }

  int get _finishedCount => _finished.where((f) => f).length;

  List<ReaderPart> get _playableParts {
    final result = <ReaderPart>[];
    for (int i = 0; i < widget.chapter.parts.length; i++) {
      final p = widget.chapter.parts[i];
      if (p.filename != null) {
        result.add(ReaderPart(originalIndex: i, part: p));
      }
    }
    return result;
  }

  void _openPart(int originalIndex) {
    final playable = _playableParts;
    final startAt = playable.indexWhere((rp) => rp.originalIndex == originalIndex);

    if (startAt == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This part isn't mapped to a source file yet.")),
      );
      return;
    }

    Navigator.of(context)
        .push<int>(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          chapterTitle: widget.chapter.title,
          readerParts: playable,
          startAt: startAt,
        ),
      ),
    )
        .then((furthestOriginalIndex) {
      if (furthestOriginalIndex == null) return;
      setState(() {
        for (int i = 0; i <= furthestOriginalIndex && i < _finished.length; i++) {
          _finished[i] = true;
        }
      });
    });
  }

  void _continueReading() {
    final nextIndex = _finished.indexWhere((f) => !f);
    _openPart(nextIndex == -1 ? 0 : nextIndex);
  }

  void _markAllFinished() {
    setState(() => _finished = List.filled(_finished.length, true));
  }

  void _clearAll() {
    setState(() => _finished = List.filled(_finished.length, false));
  }

  @override
  Widget build(BuildContext context) {
    final chapter = widget.chapter;
    final total = chapter.parts.length;
    final progressRatio = total == 0 ? 0.0 : _finishedCount / total;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  color: AppColors.surfaceRaised,
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: AppColors.coldGray.withValues(alpha: 0.4),
                      size: 36,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chapter.subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      chapter.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        DetailActionButton(
                          label: 'CONTINUE',
                          icon: Icons.play_arrow,
                          filled: true,
                          onPressed: _continueReading,
                        ),
                        DetailActionButton(
                          label: 'MARK ALL FINISHED',
                          icon: Icons.check,
                          onPressed: _markAllFinished,
                        ),
                        DetailActionButton(
                          label: 'CLEAR ALL',
                          icon: Icons.refresh,
                          onPressed: _clearAll,
                        ),
                        DetailActionButton(
                          label: 'WIKI',
                          icon: Icons.open_in_new,
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progressRatio,
                        minHeight: 4,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation(AppColors.amber),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${chapter.wordCount} words · about ${chapter.readTimeMinutes}m',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '$_finishedCount OF $total FINISHED',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.amber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(chapter.parts.length, (index) {
                      final part = chapter.parts[index];
                      return DetailPartRow(
                        part: part,
                        finished: _finished[index],
                        onToggle: () =>
                            setState(() => _finished[index] = !_finished[index]),
                        onOpen: () => _openPart(index),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}