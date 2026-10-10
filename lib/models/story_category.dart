enum StoryCategory { mainTheme, sideStory, vignette }

extension StoryCategoryAssets on StoryCategory {
  /// Folder under assets/images/ that holds this category's cover art.
  /// Single source of truth: the Library cards, the detail header and the
  /// tap-to-zoom cover all read from here.
  String get imageFolder => switch (this) {
    StoryCategory.mainTheme => 'chapters',
    StoryCategory.sideStory => 'side_stories',
    StoryCategory.vignette => 'vignettes',
  };
  bool get usesTallHeader => this != StoryCategory.sideStory;
}
