import 'package:flutter/material.dart';
import '../../../models/chapter_preview.dart';
import '../../../utils/act_type_formatter.dart';
import 'detail_colors.dart';

/// Title block at the top of the sliding sheet: tag, title, collapsible
/// left-aligned synopsis.
class ChapterDetailHeader extends StatefulWidget {
  final ChapterPreview chapter;
  final String? description;
  final bool descriptionLoaded;

  const ChapterDetailHeader({
    super.key,
    required this.chapter,
    required this.description,
    required this.descriptionLoaded,
  });

  @override
  State<ChapterDetailHeader> createState() => _ChapterDetailHeaderState();
}

class _ChapterDetailHeaderState extends State<ChapterDetailHeader> {
  bool _expanded = false;

  String _tag() {
    final m = RegExp(r'^main_(\d+)$').firstMatch(widget.chapter.number);
    if (m != null) return 'CHAPTER ${m.group(1)} • MAIN STORY';
    return formatActType(widget.chapter.subtitle).toUpperCase();
  }

  Widget _synopsis(BuildContext context) {
    if (!widget.descriptionLoaded) return const SizedBox.shrink();

    final hasDesc = widget.description != null;
    final text = hasDesc ? widget.description! : 'No description available.';
    final style = TextStyle(
      color: DetailColors.synopsis,
      fontSize: 13.5,
      height: 20 / 13.5,
      fontStyle: hasDesc ? FontStyle.normal : FontStyle.italic,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            maxLines: 3,
            textDirection: TextDirection.ltr,
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: constraints.maxWidth);
          final truncated = painter.didExceedMaxLines;
          painter.dispose();

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: truncated
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      text,
                      maxLines: _expanded ? null : 3,
                      overflow: _expanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      style: style,
                    ),
                  ),
                ),
                if (truncated)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _expanded ? 'Show less' : 'Read more',
                          style: const TextStyle(
                            color: DetailColors.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          size: 16,
                          color: DetailColors.amber,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tag(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: DetailColors.amber,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.chapter.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: Colors.white,
          ),
        ),
        _synopsis(context),
      ],
    );
  }
}
