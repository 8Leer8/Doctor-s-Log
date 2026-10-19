import '../models/story_category.dart';

/// Describes where one chapter's cover lives: bundled in the app, online
/// (community asset repo, found by the ids in story_review_table.json), and
/// the old bundled image (fallback for the few covers that aren't online).
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

  /// Key used by the on-disk image cache and the in-memory stores.
  String get cacheKey => 'cover:${category.name}:$chapterId';

  /// Only main chapters are a regular polaroid frame whose tilt can be
  /// measured and levelled (see CoverTilt). Side stories and vignettes are
  /// irregular collages, so they are shown as drawn.
  bool get straightenable => category == StoryCategory.mainTheme;

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

  /// Cover shipped inside the app (made by tools/bundle_covers.py).
  String get bundledCoverAsset =>
      'assets/covers/${category.coverFolder}/$chapterId.webp';

  /// Old bundled image, without extension (try .jpg then .png). Fallback only.
  String get bundledBase => 'assets/images/${category.imageFolder}/$chapterId';
}
