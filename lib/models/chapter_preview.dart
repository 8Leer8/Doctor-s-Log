import 'story_part.dart';

class ChapterPreview {
  final String number;
  final String title;
  final String subtitle;
  final String description;
  final int progressCurrent;
  final int progressTotal;
  final bool finished;
  final int wordCount;
  final int readTimeMinutes;
  final List<StoryPart> parts;

  const ChapterPreview({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.progressCurrent,
    required this.progressTotal,
    this.finished = false,
    this.wordCount = 0,
    this.readTimeMinutes = 0,
    this.parts = const [],
  });
}