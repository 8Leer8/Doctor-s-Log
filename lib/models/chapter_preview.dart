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

/// Mock data — replace with real parsed data once the story index
/// fetch + parser are built.
final mockMainTheme = [
  ChapterPreview(
    number: '00',
    title: 'Chapter 0: Evil Time Part 1',
    subtitle: 'MAIN STORY / PROLOGUE',
    description:
        'The prologue, or Episode 00, of the main theme and the start of the Act Initium: Hour of an Awakening story arc.',
    progressCurrent: 14,
    progressTotal: 14,
    finished: true,
    wordCount: 6902,
    readTimeMinutes: 31,
    parts: const [
      StoryPart(title: 'Prologue, Part 1', finished: true),
      StoryPart(title: 'Prologue, Part 2', finished: true),
      StoryPart(title: '0-1 Before', finished: true),
      StoryPart(title: '0-1 After', finished: true),
      StoryPart(title: '0-2 Before', finished: true),
      StoryPart(title: '0-2 After', finished: true),
    ],
  ),
  ChapterPreview(
    number: '01',
    title: 'Chapter 1: Lone Trail',
    subtitle: 'MAIN STORY / ACT 1',
    description: 'The first episode of the main story.',
    progressCurrent: 8,
    progressTotal: 20,
    wordCount: 5210,
    readTimeMinutes: 24,
    parts: const [
      StoryPart(title: '1-1 Before', finished: true),
      StoryPart(title: '1-1 After', finished: true),
      StoryPart(title: '1-2 Before', finished: false),
      StoryPart(title: '1-2 After', finished: false),
    ],
  ),
  ChapterPreview(
    number: '02',
    title: 'Chapter 2: Silence',
    subtitle: 'MAIN STORY / ACT 2',
    description: 'The second episode of the main story.',
    progressCurrent: 0,
    progressTotal: 18,
    wordCount: 4890,
    readTimeMinutes: 22,
    parts: const [
      StoryPart(title: '2-1 Before', finished: false),
      StoryPart(title: '2-1 After', finished: false),
    ],
  ),
];

final mockSideStories = [
  ChapterPreview(
    number: 'SS1',
    title: 'Under Tomorrow\'s Wings',
    subtitle: 'SIDE STORY',
    description: 'A side story event chapter.',
    progressCurrent: 0,
    progressTotal: 10,
    wordCount: 3100,
    readTimeMinutes: 15,
    parts: const [
      StoryPart(title: 'Part 1', finished: false),
      StoryPart(title: 'Part 2', finished: false),
    ],
  ),
];