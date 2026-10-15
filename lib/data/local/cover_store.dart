import 'dart:collection';
import 'dart:typed_data';
import '../../utils/cover_ref.dart';
import '../remote/image_data_source.dart';
import 'image_cache_store.dart';

/// Loads cover images: memory -> disk cache -> network (then cached).
/// Returns null when the cover isn't available; callers fall back to the
/// bundled image. Failures are NOT cached permanently: a missing cover is
/// retried after [_retryAfter], and the network is skipped for a couple of
/// minutes after an offline failure so a grid of covers doesn't hammer it.
class CoverStore {
  static const int _memoryLimit = 60;
  static const Duration _retryAfter = Duration(hours: 6);
  static const Duration _offlinePause = Duration(minutes: 2);

  static final LinkedHashMap<String, Uint8List> _memory = LinkedHashMap();
  static final Map<String, Future<Uint8List?>> _inFlight = {};
  static final Map<String, DateTime> _failedAt = {};
  static DateTime? _offlineUntil;

  /// Synchronous lookup (no flicker when a card is rebuilt while scrolling).
  static Uint8List? peek(CoverRef ref) {
    final bytes = _memory.remove(ref.cacheKey);
    if (bytes != null) _memory[ref.cacheKey] = bytes; // mark as recently used
    return bytes;
  }

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
    final key = ref.cacheKey;

    try {
      final cached = await ImageCacheStore.getImage(key);
      if (cached != null && cached.isNotEmpty) {
        _remember(key, cached);
        return cached;
      }
    } catch (_) {}

    final urls = ref.urls;
    if (urls.isEmpty) return null;

    final now = DateTime.now();
    final failed = _failedAt[key];
    if (failed != null && now.difference(failed) < _retryAfter) return null;
    final pause = _offlineUntil;
    if (pause != null && now.isBefore(pause)) return null;

    try {
      final bytes = await ImageDataSource.fetchWithFallback(urls);
      await ImageCacheStore.saveImage(key, bytes);
      _failedAt.remove(key);
      _remember(key, bytes);
      return bytes;
    } catch (e) {
      _failedAt[key] = DateTime.now();
      if (_looksOffline(e)) {
        _offlineUntil = DateTime.now().add(_offlinePause);
      }
      return null;
    }
  }

  static void _remember(String key, Uint8List bytes) {
    _memory.remove(key);
    _memory[key] = bytes;
    while (_memory.length > _memoryLimit) {
      _memory.remove(_memory.keys.first);
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
}
