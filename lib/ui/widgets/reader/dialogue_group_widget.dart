import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../models/story_element.dart';
import '../../../models/reader_settings.dart';
import '../../../utils/inline_markup_parser.dart';

class DialogueGroupWidget extends StatefulWidget {
  final String? speaker;
  final List<StoryLineElement> lines;
  final ReaderSettings settings;
  final VoidCallback? onSpeakerTap;

  const DialogueGroupWidget({
    super.key,
    required this.speaker,
    required this.lines,
    required this.settings,
    this.onSpeakerTap,
  });

  @override
  State<DialogueGroupWidget> createState() => _DialogueGroupWidgetState();
}

class _DialogueGroupWidgetState extends State<DialogueGroupWidget> {
  TapGestureRecognizer? _speakerRecognizer;

  @override
  void initState() {
    super.initState();
    _refreshRecognizer();
  }

  @override
  void didUpdateWidget(DialogueGroupWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onSpeakerTap != widget.onSpeakerTap ||
        oldWidget.speaker != widget.speaker) {
      _refreshRecognizer();
    }
  }

  @override
  void dispose() {
    _speakerRecognizer?.dispose();
    super.dispose();
  }

  void _refreshRecognizer() {
    _speakerRecognizer?.dispose();
    _speakerRecognizer = null;
    final tap = widget.onSpeakerTap;
    if (tap != null && widget.speaker != null) {
      _speakerRecognizer = TapGestureRecognizer()..onTap = tap;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.settings.colors;
    final lineHeight = widget.settings.lineSpacing.multiplier;

    final baseStyle = TextStyle(
      fontSize: widget.settings.fontSize,
      height: lineHeight,
      color: colors.text,
    );
    final narrationStyle = TextStyle(
      fontSize: widget.settings.fontSize,
      height: lineHeight,
      fontStyle: FontStyle.italic,
      color: colors.secondaryText,
    );

    final bodyStyle = widget.speaker == null ? narrationStyle : baseStyle;

    final speakerSpan = widget.speaker == null
        ? null
        : TextSpan(
            text: '${widget.speaker}: ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.speaker,
            ),
            recognizer: _speakerRecognizer,
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(
              style: bodyStyle,
              children: [
                ?speakerSpan,
                ...buildRichSpans(widget.lines.first.text, bodyStyle),
              ],
            ),
          ),
          for (int i = 1; i < widget.lines.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: RichText(
                text: TextSpan(
                  style: bodyStyle,
                  children: buildRichSpans(widget.lines[i].text, bodyStyle),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
