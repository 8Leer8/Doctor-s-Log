import '../models/story_category.dart';

/// Describes where one chapter's cover lives: online (community asset repo,
/// found by the ids in story_review_table.json) and bundled (offline backup).
class CoverRef {
  // Raw GitHub first (tested), jsDelivr mirror second.
  static const String _rawBase =
      'https://raw.githubusercontent.com/ArknightsAssets/ArknightsAssets2/en/assets/dyn/arts/ui/';
  static const String _cdnBase =
      'https://cdn.jsdelivr.net/gh/ArknightsAssets/ArknightsAssets2@en/assets/dyn/arts/ui/';

  /// The main-chapter art is a polaroid that is drawn tilted by about 1 degree
  /// (counter-clockwise). These are the measured angles, in degrees, to rotate
  /// it CLOCKWISE so the frame is level. Chapters not listed (new ones) use
  /// [_defaultMainTilt], the value of the most recent chapters.
  static const double _defaultMainTilt = 1.05;
  static const Map<String, double> _mainTilt = {
    'main_0': 0.89,
    'main_1': 0.87,
    'main_2': 0.0, // drawn straight
    'main_3': 0.87,
    'main_4': 1.17,
    'main_5': 0.87,
    'main_6': 0.87,
    'main_7': 0.81,
    'main_8': 0.81,
    'main_9': 0.81,
    'main_10': 0.86,
    'main_11': 0.86,
    'main_12': 1.10,
    'main_13': 1.08,
    'main_14': 1.06,
    'main_15': 1.05,
    'main_16': 1.05,
    'main_17': 1.05,
  };

  final StoryCategory category;
  final String chapterId;

  /// `storyEntryPicId` from the index (e.g. "storyEntryPic_act35side").
  /// Needed for side stories and vignettes; main chapters use [chapterId].
  final String? entryPicId;

  const CoverRef({
    required this.category,
    required this.chapterId,
    this.entryPicId,
  });

  /// Key used by the on-disk image cache.
  String get cacheKey => 'cover:${category.name}:$chapterId';

  /// Clockwise rotation (degrees) that levels the online art. Only main
  /// chapters have a regular polaroid frame; side stories and vignettes are
  /// irregular collages, so they are shown as drawn.
  double get straightenDegrees {
    if (category != StoryCategory.mainTheme) return 0;
    return _mainTilt[chapterId.toLowerCase()] ?? _defaultMainTilt;
  }

  String? get _relativePath {
    final pic = entryPicId?.trim().toLowerCase();
    switch (category) {
      case StoryCategory.mainTheme:
        return 'mainmission/${chapterId.toLowerCase()}.png';
      case StoryCategory.sideStory:
        if (pic == null || pic.isEmpty) return null;
        return 'storyreview/hubs/activity/$pic.png';
      case StoryCategory.vignette:
        if (pic == null || pic.isEmpty) return null;
        return 'storyreview/hubs/mini/storyentrypic/$pic.png';
    }
  }

  /// Online URLs to try, in order. Empty when the index has no picture id.
  List<String> get urls {
    final p = _relativePath;
    if (p == null) return const [];
    return ['$_rawBase$p', '$_cdnBase$p'];
  }

  /// Bundled backup, without extension (try .jpg then .png).
  String get bundledBase => 'assets/images/${category.imageFolder}/$chapterId';
}
