import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/story_category.dart';
import '../../utils/cover_ref.dart';
import '../../utils/cover_tilt.dart';
import '../remote/image_data_source.dart';
import 'image_cache_store.dart';

/// Where a cover comes from, in order:
///   1. bundled in the app (assets/covers/*.webp, held in memory by [warmUp])
///   2. saved on the device (chapters released after this build)
///   3. one-time download, then saved
class CoverStore {
  static const int _memoryLimit = 60;
  static const Duration _retryAfter = Duration(hours: 6);
  static const Duration _offlinePause = Duration(minutes: 2);
  static const Duration _missingRetry = Duration(hours: 24);
  static const String _kMissing = 'cover_missing_v1';

  /// Bundled covers. Always in memory (~6 MB), never evicted.
  static final Map<String, Uint8List> _bundled = {};
  static final LinkedHashMap<String, Uint8List> _memory = LinkedHashMap();
  static final Map<String, Future<Uint8List?>> _inFlight = {};
  static final Map<String, Future<Uint8List?>> _downloads = {};
  static final Map<String, DateTime> _failedAt = {};
  static final Map<String, double> _tilt = {};
  static Map<String, int>? _missing;
  static DateTime? _offlineUntil;
  static bool _syncing = false;

  // ---------------------------------------------------------------- warm-up

  /// Await this before runApp. Loads every bundled cover and the precomputed
  /// tilts so the very first Library frame is complete. Never throws.
  static Future<void> warmUp() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final paths = manifest.listAssets().where(
        (p) => p.startsWith('assets/covers/') && p.endsWith('.webp'),
      );
      await Future.wait(
        paths.map((p) async {
          final key = _keyFromAsset(p);
          if (key == null) return;
          try {
            final data = await rootBundle.load(p);
            _bundled[key] = data.buffer.asUint8List(
              data.offsetInBytes,
              data.lengthInBytes,
            );
          } catch (_) {}
        }),
      );
    } catch (_) {}

    try {
      final raw = await rootBundle.loadString('assets/covers/tilt.json');
      (jsonDecode(raw) as Map<String, dynamic>).forEach((id, v) {
        _tilt['cover:${StoryCategory.mainTheme.name}:$id'] = (v as num)
            .toDouble();
      });
    } catch (_) {}
  }

  static String? _keyFromAsset(String path) {
    final parts = path.split('/');
    if (parts.length != 4) return null;
    final category = storyCategoryFromCoverFolder(parts[2]);
    if (category == null) return null;
    final file = parts[3];
    final id = file.substring(0, file.length - '.webp'.length);
    return 'cover:${category.name}:$id';
  }

  static bool isBundled(CoverRef ref) => _bundled.containsKey(ref.cacheKey);

  // ------------------------------------------------------------- UI access

  /// Synchronous: bundled first, then the in-memory LRU.
  static Uint8List? peek(CoverRef ref) {
    final b = _bundled[ref.cacheKey];
    if (b != null) return b;
    final bytes = _memory.remove(ref.cacheKey);
    if (bytes != null) _memory[ref.cacheKey] = bytes;
    return bytes;
  }

  /// Clockwise degrees that level the polaroid frame (0 = leave as is).
  static double tiltOf(CoverRef ref) => _tilt[ref.cacheKey] ?? 0.0;

  static Future<Uint8List?> load(CoverRef ref) {
    final hit = peek(ref);
    if (hit != null) return Future.value(hit);
    final key = ref.cacheKey;
    return _inFlight.putIfAbsent(
      key,
      () => _resolve(ref).whenComplete(() => _inFlight.remove(key)),
    );
  }

  static Future<Uint8List?> _resolve(CoverRef ref) async {
    Uint8List? bytes;
    try {
      bytes = await ImageCacheStore.getImage(ref.cacheKey);
    } catch (_) {}
    if (bytes == null || bytes.isEmpty) bytes = await _download(ref);
    if (bytes == null) return null;

    await _measureTilt(ref, bytes);
    _remember(ref.cacheKey, bytes);
    return bytes;
  }

  // ------------------------------------------- background download (new ones)

  /// Pre-downloads covers of chapters released after the build. Bundled
  /// covers are skipped, so on a normal install this does nothing.
  static Future<void> syncAll(
    List<CoverRef> refs, {
    int concurrency = 3,
  }) async {
    if (_syncing) return;
    _syncing = true;
    try {
      final todo = <CoverRef>[];
      for (final ref in refs) {
        if (ref.urls.isEmpty) continue;
        if (isBundled(ref)) continue;
        if (await ImageCacheStore.isCached(ref.cacheKey)) continue;
        if (await _recentlyMissing(ref.cacheKey)) continue;
        todo.add(ref);
      }
      if (todo.isEmpty) return;

      var next = 0;
      Future<void> worker() async {
        while (next < todo.length) {
          final ref = todo[next++];
          await _download(ref);
          final pause = _offlineUntil;
          if (pause != null && DateTime.now().isBefore(pause)) {
            next = todo.length; // offline: stop, try again next launch
          }
        }
      }

      await Future.wait(List.generate(concurrency, (_) => worker()));
    } finally {
      _syncing = false;
    }
  }

  // ----------------------------------------------------------------- network

  static Future<Uint8List?> _download(CoverRef ref) {
    final key = ref.cacheKey;
    return _downloads.putIfAbsent(
      key,
      () => _downloadNow(ref).whenComplete(() => _downloads.remove(key)),
    );
  }

  static Future<Uint8List?> _downloadNow(CoverRef ref) async {
    final key = ref.cacheKey;
    final urls = ref.urls;
    if (urls.isEmpty) return null;

    final now = DateTime.now();
    final failed = _failedAt[key];
    if (failed != null && now.difference(failed) < _retryAfter) return null;
    final pause = _offlineUntil;
    if (pause != null && now.isBefore(pause)) return null;
    if (await _recentlyMissing(key)) return null;

    try {
      final bytes = await ImageDataSource.fetchWithFallback(urls);
      await ImageCacheStore.saveImage(key, bytes);
      _failedAt.remove(key);
      await _clearMissing(key);
      return bytes;
    } catch (e) {
      _failedAt[key] = DateTime.now();
      if (_looksOffline(e)) {
        _offlineUntil = DateTime.now().add(_offlinePause);
      } else if (e.toString().contains('HTTP 404')) {
        await _markMissing(key);
      }
      return null;
    }
  }

  static bool _looksOffline(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('connection') ||
        s.contains('timed out') ||
        s.contains('timeout') ||
        s.contains('no address associated');
  }

  // ------------------------------------------- "not on the server" memory

  static Future<Map<String, int>> _missingMap() async {
    final existing = _missing;
    if (existing != null) return existing;
    final map = <String, int>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kMissing);
      if (raw != null) {
        (jsonDecode(raw) as Map<String, dynamic>).forEach((k, v) {
          map[k] = (v as num).toInt();
        });
      }
    } catch (_) {}
    return _missing = map;
  }

  static Future<void> _saveMissing(Map<String, int> map) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kMissing, jsonEncode(map));
    } catch (_) {}
  }

  static Future<bool> _recentlyMissing(String key) async {
    final ts = (await _missingMap())[key];
    if (ts == null) return false;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    return age < _missingRetry.inMilliseconds;
  }

  static Future<void> _markMissing(String key) async {
    final map = await _missingMap();
    map[key] = DateTime.now().millisecondsSinceEpoch;
    await _saveMissing(map);
  }

  static Future<void> _clearMissing(String key) async {
    final map = await _missingMap();
    if (map.remove(key) != null) await _saveMissing(map);
  }

  // ------------------------------------------------------------------ helpers

  /// Only for downloaded (non-bundled) main covers; bundled ones already have
  /// their tilt from tilt.json.
  static Future<void> _measureTilt(CoverRef ref, Uint8List bytes) async {
    if (!ref.straightenable || _tilt.containsKey(ref.cacheKey)) return;
    _tilt[ref.cacheKey] = await CoverTilt.detect(bytes) ?? 0.0;
  }

  static void _remember(String key, Uint8List bytes) {
    _memory.remove(key);
    _memory[key] = bytes;
    while (_memory.length > _memoryLimit) {
      _memory.remove(_memory.keys.first);
    }
  }
}
