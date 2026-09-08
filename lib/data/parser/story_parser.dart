import '../../models/story_line.dart';

class StoryParser {
  static final RegExp _speakerLineRegex = RegExp(r'^\[name="([^"]*)"\]\s*(.*)$');
  static final RegExp _onlyTagRegex = RegExp(r'^\[.*\]\s*$');

  /// Converts raw Arknights story script text into clean reading lines.
  /// - Lines like [name="X"] text become StoryLine(speaker: X, text: text)
  /// - Lines that are pure stage direction (e.g. [Background(...)]) are skipped
  /// - Any other non-empty line is treated as plain narration
  static List<StoryLine> parse(String raw) {
    final result = <StoryLine>[];

    for (final rawLine in raw.split('\n')) {
      final line = rawLine.trimRight();
      if (line.trim().isEmpty) continue;

      final speakerMatch = _speakerLineRegex.firstMatch(line);
      if (speakerMatch != null) {
        final speaker = speakerMatch.group(1) ?? '';
        final text = (speakerMatch.group(2) ?? '').trim();
        if (text.isNotEmpty) {
          result.add(StoryLine(speaker: speaker, text: text));
        }
        continue;
      }

      if (_onlyTagRegex.hasMatch(line)) {
        continue; // pure stage direction, skip
      }

      result.add(StoryLine(text: line.trim()));
    }

    return result;
  }
}