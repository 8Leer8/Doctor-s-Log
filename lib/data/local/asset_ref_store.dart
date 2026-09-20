import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AssetRefStore {
  static const String _key = 'asset_ref_counts';

  static Future<Map<String, int>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <String, int>{};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return <String, int>{};
    }
  }

  static Future<void> _save(Map<String, int> counts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(counts));
  }

  static Future<int> get(String cacheKey) async {
    final counts = await _load();
    return counts[cacheKey] ?? 0;
  }

  static Future<Map<String, int>> getAll() async => _load();

  static Future<void> increment(String cacheKey) async {
    final counts = await _load();
    counts[cacheKey] = (counts[cacheKey] ?? 0) + 1;
    await _save(counts);
  }

  static Future<void> incrementMany(List<String> cacheKeys) async {
    final counts = await _load();
    for (final k in cacheKeys) {
      counts[k] = (counts[k] ?? 0) + 1;
    }
    await _save(counts);
  }

  static Future<List<String>> decrementMany(List<String> cacheKeys) async {
    final counts = await _load();
    final toDelete = <String>[];
    for (final k in cacheKeys) {
      final current = counts[k] ?? 0;
      final next = current - 1;
      if (next <= 0) {
        counts.remove(k);
        if (current > 0) toDelete.add(k);
      } else {
        counts[k] = next;
      }
    }
    await _save(counts);
    return toDelete;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
