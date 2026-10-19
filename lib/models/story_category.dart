enum StoryCategory { mainTheme, sideStory, vignette }

extension StoryCategoryAssets on StoryCategory {
  /// Folder under assets/images/ with the OLD bundled art. Only used now as a
  /// fallback for the few covers that don't exist online.
  String get imageFolder => switch (this) {
    StoryCategory.mainTheme => 'chapters',
    StoryCategory.sideStory => 'side_stories',
    StoryCategory.vignette => 'vignettes',
  };

  /// Folder under assets/covers/ with the bundled WebP covers.
  String get coverFolder => switch (this) {
    StoryCategory.mainTheme => 'main',
    StoryCategory.sideStory => 'side',
    StoryCategory.vignette => 'vignette',
  };

  /// All three categories share the same card + detail layout.
  bool get usesTallHeader => true;
  double get coverAspect => switch (this) {
    StoryCategory.mainTheme => 1.26,
    StoryCategory.sideStory => 0.83,
    StoryCategory.vignette => 0.78,
  };
}

StoryCategory? storyCategoryFromCoverFolder(String folder) => switch (folder) {
  'main' => StoryCategory.mainTheme,
  'side' => StoryCategory.sideStory,
  'vignette' => StoryCategory.vignette,
  _ => null,
};
