import '../../models/story_element.dart';

class StoryParser {
  static final RegExp _speakerLineRegex = RegExp(
    r'^\[name="([^"]*)"\]\s*(.*)$',
  );
  static final RegExp _decisionRegex = RegExp(
    r'^\[Decision\(options="(.*)",\s*values="(.*)"\)\]\s*$',
  );
  static final RegExp _predicateRegex = RegExp(
    r'^\[Predicate\(references="(.*)"\)\]\s*$',
  );
  static final RegExp _backgroundRegex = RegExp(
    r'^\[Background\(image="([^"]*)"',
  );
  static final RegExp _animTextRegex = RegExp(
    r'^\[animtext\([^\]]*\)\]\s*(.*)$',
  );

  /// Matches a single `<p=N>...</p>` fragment, capturing the inner text.
  ///
  /// Note: the game's data uses a shorthand closing tag — `</>` — rather
  /// than the well-formed `</p>`. The trailing `p?` makes the `p`
  /// optional so both forms match.
  static final RegExp _animTextParagraphRegex = RegExp(
    r'<p=\d+>(.*?)</p?>',
    dotAll: true,
  );

  static List<StoryElement> parse(String raw) {
    final result = <StoryElement>[];

    int choiceCounter = 0;
    int? currentGateChoiceId;
    String? currentRequiredValue;
    String? lastBackgroundImage;

    for (final rawLine in raw.split('\n')) {
      final line = rawLine.trimRight();
      final trimmedLeft = line.trimLeft();
      if (trimmedLeft.isEmpty) continue;

      // ── animtext overlay (dates, location stamps, ambient text).
      //    Must come before the generic "starts with [" skip.
      final animMatch = _animTextRegex.firstMatch(trimmedLeft);
      if (animMatch != null) {
        final payload = animMatch.group(1) ?? '';
        if (payload.isNotEmpty) {
          final paragraphs = _animTextParagraphRegex
              .allMatches(payload)
              .map((m) => (m.group(1) ?? '').trim())
              .where((t) => t.isNotEmpty)
              .toList();

          for (final text in paragraphs) {
            result.add(
              StoryLineElement(
                speaker: null,
                text: text,
                requiredValue: currentRequiredValue,
                gateChoiceId: currentGateChoiceId,
              ),
            );
          }
        }
        continue;
      }

      // ── Background tag.
      final backgroundMatch = _backgroundRegex.firstMatch(trimmedLeft);
      if (backgroundMatch != null) {
        final image = backgroundMatch.group(1) ?? '';
        if (lastBackgroundImage == null) {
          lastBackgroundImage = image;
        } else if (image != lastBackgroundImage) {
          result.add(const SceneBreakElement());
          lastBackgroundImage = image;
        }
        continue;
      }

      final decisionMatch = _decisionRegex.firstMatch(line);
      if (decisionMatch != null) {
        choiceCounter++;
        final options = (decisionMatch.group(1) ?? '').split(';');
        final values = (decisionMatch.group(2) ?? '').split(';');
        final count = options.length < values.length
            ? options.length
            : values.length;
        final opts = <StoryChoiceOption>[
          for (int i = 0; i < count; i++)
            StoryChoiceOption(
              label: options[i].trim(),
              value: values[i].trim(),
            ),
        ];
        result.add(
          StoryChoiceElement(
            id: choiceCounter,
            options: opts,
            requiredValue: currentRequiredValue,
            gateChoiceId: currentGateChoiceId,
          ),
        );
        continue;
      }

      final predicateMatch = _predicateRegex.firstMatch(line);
      if (predicateMatch != null) {
        currentRequiredValue = predicateMatch.group(1);
        currentGateChoiceId = choiceCounter == 0 ? null : choiceCounter;
        continue;
      }

      final speakerMatch = _speakerLineRegex.firstMatch(line);
      if (speakerMatch != null) {
        final rawSpeaker = speakerMatch.group(1) ?? '';
        final speaker = rawSpeaker.trim().isEmpty ? null : rawSpeaker;
        final text = (speakerMatch.group(2) ?? '').trim();
        if (text.isNotEmpty) {
          result.add(
            StoryLineElement(
              speaker: speaker,
              text: text,
              requiredValue: currentRequiredValue,
              gateChoiceId: currentGateChoiceId,
            ),
          );
        }
        continue;
      }

      if (trimmedLeft.startsWith('[')) {
        continue;
      }

      result.add(
        StoryLineElement(
          text: line.trim(),
          requiredValue: currentRequiredValue,
          gateChoiceId: currentGateChoiceId,
        ),
      );
    }

    return result;
  }
}
