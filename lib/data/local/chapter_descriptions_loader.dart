import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ChapterDescriptionsLoader {
  static Map<String, String>? _cache;

  static Future<Map<String, String>> load() async {
    if (_cache != null) return _cache!;
    try {
      final raw = await rootBundle.loadString('assets/data/chapter_descriptions.json');
      final Map<String, dynamic> decoded = jsonDecode(raw);
      _cache = decoded.map((key, value) => MapEntry(key, value as String));
    } catch (_) {
      _cache = {};
    }
    return _cache!;
  }
}