import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/cover_ref.dart';
import '../../utils/cover_tilt.dart';
import '../remote/image_data_source.dart';
import 'image_cache_store.dart';

/// Progress of the background cover download (shown by the Library banner).
class CoverSyncProgress {
  final int done;
  final int total;
  const CoverSyncProgress(this.done, this.total);
}

/// Covers live on the device: memory -> disk -> (download once, then disk).
///
/// * [syncAll] downloads every cover that isn't saved yet, so after the first
///   run the app never waits for the network to show a cover.
/// * [load] serves one cover for the UI (memory, then disk, then a download if
///   it is still missing). It returns null when the cover isn't available, and
///   the UI then falls back to the bundled image.
/// * A cover the server says doesn't exist (404) is not asked for again for 24
///   hours (remembered across launches), so the few covers that don't exist
///   online don't cost a request on every start. Offline failures are never
///   remembered.
///
/// For main chapters it also measures how much the polaroid frame leans (once
/// per cover per session) so the UI can level it.
class CoverStore {
  static const int _memoryLimit = 60;
  static const Duration _retryAfter = Duration(hours: 6);
  static const Duration _offlinePause = Duration(minutes: 2);
  static const Duration _missingRetry = Duration(hours: 24);
  static const String _kMissing = 'cover_missing_v1';

  static final LinkedHashMap<String, Uint8List> _memory = LinkedHashMap();
  static final Map<String, Future<Uint8List?>> _inFlight = {};
  static final Map<String, Future<Uint8List?>> _downloads = {};
  static final Map<String, DateTime> _failedAt = {};
  static final Map<String, double> _tilt = {};
  static Map<String, int>? _missing;
  static DateTime? _offlineUntil;
  static bool _syncing = false;

  /// Non-null while covers are being downloaded.
  static final ValueNotifier<CoverSyncProgress?> syncProgress = ValueNotifier(
    null,
  );

  // ------------------------------------------------------------- UI access

  /// Synchronous lookup (no flicker when a card is rebuilt while scrolling).
  static Uint8List? peek(CoverRef ref) {
    final bytes = _memory.remove(ref.cacheKey);
    if (bytes != null) _memory[ref.cacheKey] = bytes; // mark as recently used
    return bytes;
  }

  /// Clockwise degrees that level this cover's frame; 0 when it hasn't been
  /// measured, isn't a polaroid, or the measurement wasn't reliable.
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

  // ------------------------------------------------------------ first-run sync

  /// Downloads every cover that isn't on the device yet. Safe to call on every
  /// launch: covers already saved are skipped, so it only does work the first
  /// time and when new chapters appear. Stops early when the device is offline.
  static Future<void> syncAll(
    List<CoverRef> refs, {
    int concurrency = 4,
  }) async {
    if (_syncing) return;
    _syncing = true;
    try {
      final missing = <CoverRef>[];
      for (final ref in refs) {
        if (ref.urls.isEmpty) continue;
        if (await ImageCacheStore.isCached(ref.cacheKey)) continue;
        if (await _recentlyMissing(ref.cacheKey)) continue;
        missing.add(ref);
      }
      if (missing.isEmpty) return;

      var done = 0;
      var next = 0;
      syncProgress.value = CoverSyncProgress(0, missing.length);

      Future<void> worker() async {
        while (next < missing.length) {
          final ref = missing[next++];
          await _download(ref); // failures are swallowed (returns null)
          done++;
          syncProgress.value = CoverSyncProgress(done, missing.length);
          final pause = _offlineUntil;
          if (pause != null && DateTime.now().isBefore(pause)) {
            next = missing.length; // clearly offline: stop, retry next launch
          }
        }
      }

      await Future.wait(List.generate(concurrency, (_) => worker()));
    } finally {
      _syncing = false;
      syncProgress.value = null;
    }
  }

  // ----------------------------------------------------------------- network

  /// Download + save, shared by the UI and the sync (de-duplicated).
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

  static Future<void> _measureTilt(CoverRef ref, Uint8List bytes) async {
    if (!ref.straightenable || _tilt.containsKey(ref.cacheKey)) return;
    final degrees = await CoverTilt.detect(bytes);
    _tilt[ref.cacheKey] = degrees ?? 0.0;
  }

  static void _remember(String key, Uint8List bytes) {
    _memory.remove(key);
    _memory[key] = bytes;
    while (_memory.length > _memoryLimit) {
      _memory.remove(_memory.keys.first);
    }
  }
}
