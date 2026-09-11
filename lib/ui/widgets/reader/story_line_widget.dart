import 'package:flutter/material.dart';
import '../../../models/story_element.dart';
import '../../../models/reader_settings.dart';
import '../../../utils/inline_markup_parser.dart';

class StoryLineWidget extends StatelessWidget {
  final StoryLineElement line;
  final ReaderSettings settings;

  const StoryLineWidget({super.key, required this.line, required this.settings});

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: RichText(
        text: TextSpan(
          style: baseStyle,
          children: [
            if (line.speaker != null)
              TextSpan(
                text: '${line.speaker}: ',
                style: TextStyle(fontWeight: FontWeight.w700, color: colors.speaker),
              ),
            ...buildRichSpans(line.text, line.speaker == null ? narrationStyle : baseStyle),
          ],
        ),
      ),
    );
  }
}