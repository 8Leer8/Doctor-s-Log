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
  static final RegExp _imageRegex = RegExp(r'^\[Image\(image="([^"]*)"');
  static final RegExp _stickerRegex = RegExp(
    r'^\[Sticker\([^\]]*text\s*=\s*"((?:[^"\\]|\\.)*)"',
  );
  static final RegExp _subtitleRegex = RegExp(
    r'^\[Subtitle\([^\]]*text\s*=\s*"((?:[^"\\]|\\.)*)"',
  );
  static final RegExp _charslotRegex = RegExp(
    r'^\[charslot\([^\]]*name\s*=\s*"([^"]*)"',
  );
  static final RegExp _charslotBareRegex = RegExp(
    r'^\[charslot\(\s*\)\]|^\[charslot\]',
  );
  static final RegExp _animTextRegex = RegExp(
    r'^\[animtext\([^\]]*\)\]\s*(.*)$',
  );
  static final RegExp _animTextParagraphRegex = RegExp(
    r'<p=\d+>(.*?)</p?>',
    dotAll: true,
  );

  static String _unescapeText(String s) {
    return s
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\"', '"')
        .replaceAll(r'\\', '\\');
  }

  static List<StoryElement> parse(String raw) {
    final result = <StoryElement>[];

    int choiceCounter = 0;
    int? currentGateChoiceId;
    String? currentRequiredValue;

    String? lastBackgroundImage;
    String? lastImageId;
    String? currentPortraitId;

    for (final rawLine in raw.split('\n')) {
      final line = rawLine.trimRight();
      final trimmedLeft = line.trimLeft();
      if (trimmedLeft.isEmpty) continue;

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

      final backgroundMatch = _backgroundRegex.firstMatch(trimmedLeft);
      if (backgroundMatch != null) {
        final image = backgroundMatch.group(1) ?? '';
        if (image.isNotEmpty && image != lastBackgroundImage) {
          result.add(
            SceneBreakElement(
              backgroundImageId: image,
              requiredValue: currentRequiredValue,
              gateChoiceId: currentGateChoiceId,
            ),
          );
          lastBackgroundImage = image;
        }
        lastImageId = null;
        continue;
      }

      final imageMatch = _imageRegex.firstMatch(trimmedLeft);
      if (imageMatch != null) {
        final image = imageMatch.group(1) ?? '';
        if (image.isNotEmpty && image != lastImageId) {
          result.add(
            StoryImageElement(
              imageId: image,
              requiredValue: currentRequiredValue,
              gateChoiceId: currentGateChoiceId,
            ),
          );
          lastImageId = image;
        }
        continue;
      }

      final stickerMatch = _stickerRegex.firstMatch(trimmedLeft);
      if (stickerMatch != null) {
        final text = _unescapeText(stickerMatch.group(1) ?? '');
        if (text.isNotEmpty) {
          result.add(
            StoryLineElement(
              text: text,
              requiredValue: currentRequiredValue,
              gateChoiceId: currentGateChoiceId,
            ),
          );
        }
        continue;
      }

      final subtitleMatch = _subtitleRegex.firstMatch(trimmedLeft);
      if (subtitleMatch != null) {
        final text = _unescapeText(subtitleMatch.group(1) ?? '');
        if (text.isNotEmpty) {
          result.add(
            StoryLineElement(
              text: text,
              requiredValue: currentRequiredValue,
              gateChoiceId: currentGateChoiceId,
            ),
          );
        }
        continue;
      }

      if (_charslotBareRegex.hasMatch(trimmedLeft)) {
        currentPortraitId = null;
        continue;
      }

      final charslotMatch = _charslotRegex.firstMatch(trimmedLeft);
      if (charslotMatch != null) {
        final name = charslotMatch.group(1) ?? '';
        currentPortraitId = name.isEmpty ? null : name;
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
              speakerPortraitId: currentPortraitId,
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
