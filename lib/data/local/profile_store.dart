import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Doctor's profile: a display name (also used inside stories, see
/// PlayerName) and a couple of reading stats.
class ProfileStore {
  static const String defaultName = 'Doctor';
  static const int maxNameLength = 20;
  static const String _kName = 'profile_name_v1';

  /// Listen to this to react to name changes anywhere in the app.
  static final ValueNotifier<String> name = ValueNotifier<String>(defaultName);

  /// Call once at startup (main.dart) so the reader already knows the name
  /// the first time it parses a story.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kName);
      if (saved != null && saved.trim().isNotEmpty) {
        name.value = saved.trim();
      }
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
