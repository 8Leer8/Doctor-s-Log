class StoryPart {
  final String title;
  final bool finished;
  final String? filename;
  final String? avgTag; // real data from story_review_table.json, e.g. "Interlude", "Before Operation"

  const StoryPart({
    required this.title,
    this.finished = false,
    this.filename,
    this.avgTag,
  });
}