import 'package:flutter/material.dart';
import '../../../models/story_element.dart';
import '../../../models/reader_settings.dart';
import '../../../utils/inline_markup_parser.dart';

/// Renders a run of consecutive same-speaker [StoryLineElement]s as one
/// visual block: a single speaker label inline with the first paragraph,
/// and every subsequent paragraph starting flush-left (aligned with the
/// speaker label, not indented under the text after the colon).
///
/// Styling matches [StoryLineWidget] exactly so grouped and ungrouped
/// lines read consistently.
class DialogueGroupWidget extends StatelessWidget {
  final String? speaker;
  final List<StoryLineElement> lines;
  final ReaderSettings settings;

  const DialogueGroupWidget({
    super.key,
    required this.speaker,
    required this.lines,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final colors = settings.colors;
    final lineHeight = settings.lineSpacing.multiplier;

    final baseStyle = TextStyle(
      fontSize: settings.fontSize,
      height: lineHeight,
      color: colors.text,
    );
    final narrationStyle = TextStyle(
      fontSize: settings.fontSize,
      height: lineHeight,
      fontStyle: FontStyle.italic,
      color: colors.secondaryText,
    );

    final bodyStyle = speaker == null ? narrationStyle : baseStyle;
    final labelText = speaker != null ? '$speaker: ' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // First paragraph — label inline with its first line.
          RichText(
            text: TextSpan(
              style: bodyStyle,
              children: [
                if (labelText.isNotEmpty)
                  TextSpan(
                    text: labelText,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.speaker,
                    ),
                  ),
                ...buildRichSpans(lines.first.text, bodyStyle),
              ],
            ),
          ),
          // Subsequent paragraphs — flush left, same as the label.
          for (int i = 1; i < lines.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: RichText(
                text: TextSpan(
                  style: bodyStyle,
                  children: buildRichSpans(lines[i].text, bodyStyle),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
