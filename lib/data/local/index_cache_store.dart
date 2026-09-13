import 'package:shared_preferences/shared_preferences.dart';

/// Caches the raw story_review_table.json content locally, so the
/// Library/chapter list can be browsed offline after the first
/// successful fetch — same pattern Mihon uses for its browse catalog.
class IndexCacheStore {
  static const _key = 'story_index_cache_raw_json';

  static Future<void> save(String rawJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, rawJson);
  }

  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<bool> hasCache() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }
}