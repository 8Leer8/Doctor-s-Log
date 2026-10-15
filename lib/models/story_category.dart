enum StoryCategory { mainTheme, sideStory, vignette }

extension StoryCategoryAssets on StoryCategory {
  /// Folder under assets/images/ with the BUNDLED cover art. These are the
  /// offline backup now; the online covers are the primary source.
  String get imageFolder => switch (this) {
    StoryCategory.mainTheme => 'chapters',
    StoryCategory.sideStory => 'side_stories',
    StoryCategory.vignette => 'vignettes',
  };

  /// All three categories now share the same portrait card + tall header.
  bool get usesTallHeader => true;
}
