import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../download/download_manager.dart';
import 'asset_ref_store.dart';

class StorageSnapshot {
  /// Downloaded story parts (text files).
  final int downloadedParts;

  /// Story text + image manifests.
  final int downloadedBytes;

  /// Scene art / portraits cached for offline reading.
  final int storyImageCount;
  final int storyImageBytes;

  /// Covers saved for chapters newer than the bundled set.
  final int coverCount;
  final int coverBytes;

  const StorageSnapshot({
    required this.downloadedParts,
    required this.downloadedBytes,
    required this.storyImageCount,
    required this.storyImageBytes,
    required this.coverCount,
    required this.coverBytes,
  });

  int get downloadsTotalBytes => downloadedBytes + storyImageBytes;
  int get totalBytes => downloadsTotalBytes + coverBytes;
}

/// Reads and cleans the app's folders. Folder names match DownloadStore
/// ("downloads", "manifests") and ImageCacheStore ("images"). Cover files in
/// "images" are the ones whose name starts with "cover_".
class StorageStats {
  static const String _coverPrefix = 'cover_';

  static Future<Directory> _sub(String name) async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/$name');
  }

  static String _name(FileSystemEntity e) {
    final segments = e.uri.pathSegments.where((s) => s.isNotEmpty).toList();
    return segments.isEmpty ? '' : segments.last;
  }

  static Future<({int count, int bytes})> _scan(
    Directory dir, {
    bool Function(String name)? where,
  }) async {
    var count = 0;
    var bytes = 0;
    if (!await dir.exists()) return (count: 0, bytes: 0);
    try {
      await for (final e in dir.list()) {
        if (e is! File) continue;
        final name = _name(e);
        if (name.endsWith('.tmp')) continue;
        if (where != null && !where(name)) continue;
        count++;
        try {
          bytes += await e.length();
        } catch (_) {}
      }
    } catch (_) {}
    return (count: count, bytes: bytes);
  }

  static Future<void> _deleteFiles(
    Directory dir, {
    bool Function(String name)? where,
  }) async {
    if (!await dir.exists()) return;
    List<FileSystemEntity> entries;
    try {
      entries = await dir.list().toList();
    } catch (_) {
      return;
    }
    for (final e in entries) {
      if (e is! File) continue;
      if (where != null && !where(_name(e))) continue;
      try {
        await e.delete();
      } catch (_) {}
    }
  }

  // ------------------------------------------------------------------ read

  static Future<int> downloadedPartCount() async =>
      (await _scan(await _sub('downloads'))).count;

  static Future<StorageSnapshot> load() async {
    final downloads = await _scan(await _sub('downloads'));
    final manifests = await _scan(await _sub('manifests'));
    final imagesDir = await _sub('images');
    final storyImages = await _scan(
      imagesDir,
      where: (n) => !n.startsWith(_coverPrefix),
    );
    final covers = await _scan(
      imagesDir,
      where: (n) => n.startsWith(_coverPrefix),
    );

    return StorageSnapshot(
      downloadedParts: downloads.count,
      downloadedBytes: downloads.bytes + manifests.bytes,
      storyImageCount: storyImages.count,
      storyImageBytes: storyImages.bytes,
      coverCount: covers.count,
      coverBytes: covers.bytes,
    );
  }

  // ----------------------------------------------------------------- clean

  /// Cancels the queue, then removes every downloaded part, its manifest and
  /// all cached story images. Covers are left alone.
  static Future<void> deleteAllDownloads() async {
    DownloadManager.instance.cancelAll();
    await _deleteFiles(await _sub('downloads'));
    await _deleteFiles(await _sub('manifests'));
    await _deleteFiles(
      await _sub('images'),
      where: (n) => !n.startsWith(_coverPrefix),
    );
    await AssetRefStore.clear();
  }

  /// Removes covers saved on the device. Covers bundled inside the app are
  /// not affected; newer ones download again when needed.
  static Future<void> clearCoverCache() async {
    await _deleteFiles(
      await _sub('images'),
      where: (n) => n.startsWith(_coverPrefix),
    );
  }

  /// Wipes finished parts, answered choices and resume points for every
  /// chapter. Bookmarks are kept.
  static Future<void> resetReadingProgress() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith('finished_') ||
          key.startsWith('choices_') ||
          key.startsWith('resume_')) {
        await prefs.remove(key);
      }
    }
  }

  // ---------------------------------------------------------------- format

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    return '${(mb / 1024).toStringAsFixed(2)} GB';
  }
}
