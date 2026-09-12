class StoryPart {
  final String title;
  final bool finished;
  final String? filename;
  final String? avgTag;
  final String? infoFilename;
  final DateTime? releaseDate; // not populated yet — no per-part date in current data source

  const StoryPart({
    required this.title,
    this.finished = false,
    this.filename,
    this.avgTag,
    this.infoFilename,
    this.releaseDate,
  });
}