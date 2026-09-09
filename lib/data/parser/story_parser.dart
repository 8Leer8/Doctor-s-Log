import '../../models/story_element.dart';

class StoryParser {
  static final RegExp _speakerLineRegex = RegExp(r'^\[name="([^"]*)"\]\s*(.*)$');
  static final RegExp _decisionRegex =
      RegExp(r'^\[Decision\(options="(.*)",\s*values="(.*)"\)\]\s*$');
  static final RegExp _predicateRegex =
      RegExp(r'^\[Predicate\(references="(.*)"\)\]\s*$');

  /// Converts raw Arknights story script text into a sequence of
  /// StoryLineElement / StoryChoiceElement, with visibility gating
  /// derived from [Decision(...)] / [Predicate(...)] tags.
  static List<StoryElement> parse(String raw) {
    final result = <StoryElement>[];

    int choiceCounter = 0;
    int? currentGateChoiceId;
    String? currentRequiredValue;

    for (final rawLine in raw.split('\n')) {
      final line = rawLine.trimRight();
      final trimmedLeft = line.trimLeft();
      if (trimmedLeft.isEmpty) continue;

      final decisionMatch = _decisionRegex.firstMatch(line);
      if (decisionMatch != null) {
        choiceCounter++;
        final options = (decisionMatch.group(1) ?? '').split(';');
        final values = (decisionMatch.group(2) ?? '').split(';');
        final count = options.length < values.length ? options.length : values.length;
        final opts = <StoryChoiceOption>[
          for (int i = 0; i < count; i++)
            StoryChoiceOption(label: options[i].trim(), value: values[i].trim()),
        ];
        result.add(StoryChoiceElement(
          id: choiceCounter,
          options: opts,
          requiredValue: currentRequiredValue,
          gateChoiceId: currentGateChoiceId,
        ));
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
          result.add(StoryLineElement(
            speaker: speaker,
            text: text,
            requiredValue: currentRequiredValue,
            gateChoiceId: currentGateChoiceId,
          ));
        }
        continue;
      }

      // Any other line that starts with '[' is stage direction / a tag,
      // possibly with a trailing dev comment after it (e.g. untranslated
      // Chinese notes) — always skip it, never show it as narration.
      if (trimmedLeft.startsWith('[')) {
        continue;
      }

      result.add(StoryLineElement(
        text: line.trim(),
        requiredValue: currentRequiredValue,
        gateChoiceId: currentGateChoiceId,
      ));
    }

    return result;
  }
}