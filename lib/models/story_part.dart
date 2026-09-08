class StoryPart {
  final String title;
  final bool finished;
  final String? filename; // raw .txt filename in the story data source; null = not mapped yet

  const StoryPart({
    required this.title,
    this.finished = false,
    this.filename,
  });
}