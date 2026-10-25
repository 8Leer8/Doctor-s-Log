import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Library filters that survive restarts.
class LibraryFilterStore {
  static const String _kDownloadedOnly = 'library_downloaded_only_v1';

  /// When true the Library only lists chapters with at least one
  /// downloaded part.
  static final ValueNotifier<bool> downloadedOnly = ValueNotifier<bool>(false);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      downloadedOnly.value = prefs.getBool(_kDownloadedOnly) ?? false;
    } catch (_) {}
  }

  static Future<void> setDownloadedOnly(bool value) async {
    downloadedOnly.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDownloadedOnly, value);
    } catch (_) {}
  }
}
