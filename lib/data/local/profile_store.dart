import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Doctor's profile: a display name, whether stories should use it, and
/// a couple of reading stats.
class ProfileStore {
  static const String defaultName = 'Doctor';
  static const int maxNameLength = 20;
  static const String _kName = 'profile_name_v1';
  static const String _kUseName = 'profile_use_name_in_stories_v1';

  /// Listen to this to react to name changes anywhere in the app.
  static final ValueNotifier<String> name = ValueNotifier<String>(defaultName);

  /// When true, stories show [name] wherever they say "Doctor".
  static final ValueNotifier<bool> useNameInStories = ValueNotifier<bool>(true);

  /// Call once at startup (main.dart) so the reader already knows the name
  /// the first time it parses a story.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kName);
      if (saved != null && saved.trim().isNotEmpty) {
        name.value = saved.trim();
      }
      useNameInStories.value = prefs.getBool(_kUseName) ?? true;
    } catch (_) {}
  }

  /// An empty name goes back to [defaultName].
  static Future<void> setName(String value) async {
    final cleaned = value.trim();
    final next = cleaned.isEmpty ? defaultName : cleaned;
    name.value = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (next == defaultName) {
        await prefs.remove(_kName);
      } else {
        await prefs.setString(_kName, next);
      }
    } catch (_) {}
  }

  static Future<void> setUseNameInStories(bool value) async {
    useNameInStories.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kUseName, value);
    } catch (_) {}
  }

  /// Finished parts across every chapter. ReadingProgressStore keeps them
  /// under "finished_<chapterId>" as a JSON list, so we add up those lists.
  static Future<int> totalFinishedParts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var total = 0;
      for (final key in prefs.getKeys()) {
        if (!key.startsWith('finished_')) continue;
        try {
          final raw = prefs.getString(key);
          if (raw == null) continue;
          total += (jsonDecode(raw) as List).length;
        } catch (_) {}
      }
      return total;
    } catch (_) {
      return 0;
    }
  }
}
