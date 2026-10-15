import '../models/story_category.dart';

/// Describes where one chapter's cover lives: online (community asset repo,
/// found by the ids in story_review_table.json) and bundled (offline backup).
class CoverRef {
  // Raw GitHub first (tested), jsDelivr mirror second.
  static const String _rawBase =
      'https://raw.githubusercontent.com/ArknightsAssets/ArknightsAssets2/en/assets/dyn/arts/ui/';
  static const String _cdnBase =
      'https://cdn.jsdelivr.net/gh/ArknightsAssets/ArknightsAssets2@en/assets/dyn/arts/ui/';

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
