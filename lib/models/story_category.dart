enum StoryCategory { mainTheme, sideStory, vignette }

extension StoryCategoryAssets on StoryCategory {
  /// Folder under assets/images/ with the BUNDLED cover art. These are the
  /// offline backup now; the online covers are the primary source.
  String get imageFolder => switch (this) {
    StoryCategory.mainTheme => 'chapters',
    StoryCategory.sideStory => 'side_stories',
    StoryCategory.vignette => 'vignettes',
  };

  /// All three categories share the same card + detail layout.
  bool get usesTallHeader => true;
  double get coverAspect => switch (this) {
    StoryCategory.mainTheme => 1.26,
    StoryCategory.sideStory => 0.83,
    StoryCategory.vignette => 0.78,
  };
}
