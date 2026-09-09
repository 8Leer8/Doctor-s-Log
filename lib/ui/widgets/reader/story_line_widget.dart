import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/story_element.dart';
import '../../../utils/inline_markup_parser.dart';

class StoryLineWidget extends StatelessWidget {
  final StoryLineElement line;
  const StoryLineWidget({super.key, required this.line});

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontSize: 16,
      height: 1.6,
      color: AppColors.textPrimary,
    );
    const narrationStyle = TextStyle(
      fontSize: 16,
      height: 1.6,
      fontStyle: FontStyle.italic,
      color: AppColors.textSecondary,
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
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.amber,
                ),
              ),
            ...buildRichSpans(line.text, line.speaker == null ? narrationStyle : baseStyle),
          ],
        ),
      ),
    );
  }
}