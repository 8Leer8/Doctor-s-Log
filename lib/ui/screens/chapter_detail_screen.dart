import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/chapter_preview.dart';
import '../../models/story_part.dart';
import 'reader_screen.dart';

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

  void _openPart(int index) {
    final part = widget.chapter.parts[index];
    if (part.filename == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This part isn't mapped to a source file yet.")),
      );
      return;
    }
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          filename: part.filename!,
          chapterTitle: part.title,
        ),
      ),
    )
        .then((_) {
      setState(() => _finished[index] = true);
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
                        _ActionButton(
                          label: 'CONTINUE',
                          icon: Icons.play_arrow,
                          filled: true,
                          onPressed: _continueReading,
                        ),
                        _ActionButton(
                          label: 'MARK ALL FINISHED',
                          icon: Icons.check,
                          onPressed: _markAllFinished,
                        ),
                        _ActionButton(
                          label: 'CLEAR ALL',
                          icon: Icons.refresh,
                          onPressed: _clearAll,
                        ),
                        _ActionButton(
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
                      return _PartRow(
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: CutCornerClipper(cut: 8),
      child: Material(
        color: filled ? AppColors.amber : AppColors.surface,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: filled
                ? null
                : BoxDecoration(
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 16,
                    color: filled ? Colors.black : AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: filled ? Colors.black : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PartRow extends StatelessWidget {
  final StoryPart part;
  final bool finished;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  const _PartRow({
    required this.part,
    required this.finished,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: Icon(
                finished ? Icons.check_circle : Icons.circle_outlined,
                size: 20,
                color: finished ? Colors.green.shade400 : AppColors.coldGray,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                part.title,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              ),
            ),
            if (part.filename == null)
              const Icon(Icons.cloud_off, size: 14, color: AppColors.coldGray),
          ],
        ),
      ),
    );
  }
}