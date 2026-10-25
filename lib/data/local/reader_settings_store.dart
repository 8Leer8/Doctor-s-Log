import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/reader_settings.dart';

/// Saves the reader preferences on the device.
///
/// * One global, versioned JSON blob under "reader_settings_v1".
/// * [load] runs once at startup (see main.dart), so the reader already has
///   the saved theme and font size on its very first frame (no flash).
/// * [save] updates [settings] immediately (live preview, Settings screen
///   subtitle) and writes to disk after a short pause, so dragging the font
///   slider doesn't hit the disk on every tick.
class ReaderSettingsStore {
  static const String _key = 'reader_settings_v1';
  static const Duration _saveDelay = Duration(milliseconds: 400);

  static final ValueNotifier<ReaderSettings> settings =
      ValueNotifier<ReaderSettings>(const ReaderSettings());

  static Timer? _saveTimer;

  static ReaderSettings get current => settings.value;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        settings.value = ReaderSettings.fromJson(decoded);
      }
    } catch (_) {
      // Corrupt data: keep the defaults.
    }
  }

  static void save(ReaderSettings next) {
    settings.value = next;
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDelay, _persist);
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(settings.value.toJson()));
    } catch (_) {}
  }
}