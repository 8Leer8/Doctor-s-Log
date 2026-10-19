class StoryPart {
  final String title;
  final bool finished;
  final String? filename;
  final String? avgTag;
  final String? infoFilename;
  final DateTime?
  releaseDate; // not populated yet — no per-part date in current data source

  /// Stage code from the index (e.g. "07-01"). Null when the index has none.
  final String? code;

  const StoryPart({
    required this.title,
    this.finished = false,
    this.filename,
    this.avgTag,
    this.infoFilename,
    this.releaseDate,
    this.code,
  });
}
