import 'dart:typed_data';
import '../../models/story_element.dart';
import '../../utils/asset_url_resolver.dart';
import '../local/asset_ref_store.dart';
import '../local/download_store.dart';
import '../local/image_cache_store.dart';
import '../remote/image_data_source.dart';

class PrefetchResult {
  final int totalAssets;
  final int alreadyCached;
  final List<String> failedIds;

  const PrefetchResult({
    required this.totalAssets,
    required this.alreadyCached,
    required this.failedIds,
  });

  int get newlyFetched => totalAssets - alreadyCached - failedIds.length;
}

class ImagePrefetcher {
  static List<AssetRef> collectRefs(List<StoryElement> elements) {
    final seen = <String>{};
    final refs = <AssetRef>[];

    for (final el in elements) {
      if (el is SceneBreakElement) {
        final ref = AssetRef(
          type: AssetType.background,
          id: el.backgroundImageId,
        );
        if (seen.add(ref.cacheKey)) refs.add(ref);
      } else if (el is StoryImageElement) {
        final ref = AssetRef(type: AssetType.cg, id: el.imageId);
        if (seen.add(ref.cacheKey)) refs.add(ref);
      } else if (el is StoryLineElement) {
        final portrait = el.speakerPortraitId;
        if (portrait != null) {
          final ref = AssetRef(type: AssetType.character, id: portrait);
          if (seen.add(ref.cacheKey)) refs.add(ref);
        }
      }
    }

    return refs;
  }

  static Future<PrefetchResult> prefetch({
    required List<StoryElement> elements,
    required String partFilename,
  }) async {
    final refs = collectRefs(elements);

    if (refs.isEmpty) {
      await DownloadStore.saveImageManifest(partFilename, const []);
      return const PrefetchResult(
        totalAssets: 0,
        alreadyCached: 0,
        failedIds: [],
      );
    }

    final failed = <String>[];
    var cachedCount = 0;

    for (final ref in refs) {
      final already = await ImageCacheStore.isCached(ref.cacheKey);
      if (already) {
        cachedCount++;
        continue;
      }
      try {
        final Uint8List bytes = await ImageDataSource.fetchWithFallback(
          ref.urls,
        );
        await ImageCacheStore.saveImage(ref.cacheKey, bytes);
      } catch (_) {
        failed.add(ref.cacheKey);
      }
    }

    final cacheKeys = refs.map((r) => r.cacheKey).toList();
    await DownloadStore.saveImageManifest(partFilename, cacheKeys);
    await AssetRefStore.incrementMany(cacheKeys);

    return PrefetchResult(
      totalAssets: refs.length,
      alreadyCached: cachedCount,
      failedIds: failed,
    );
  }

  static Future<void> releaseImagesForPart(String partFilename) async {
    final cacheKeys = await DownloadStore.getImageManifest(partFilename);
    if (cacheKeys.isEmpty) {
      await DownloadStore.deleteImageManifest(partFilename);
      return;
    }
    final toDelete = await AssetRefStore.decrementMany(cacheKeys);
    for (final key in toDelete) {
      await ImageCacheStore.deleteImage(key);
    }
    await DownloadStore.deleteImageManifest(partFilename);
  }
}
