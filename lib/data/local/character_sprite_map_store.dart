import 'dart:convert';
import 'package:flutter/services.dart';

class CharacterSpriteMapStore {
  static Map<String, String>? _cache;

  static Future<Map<String, String>> load() async {
    if (_cache != null) return _cache!;

    try {
      final raw = await rootBundle.loadString(
        'assets/data/character_sprites.json',
      );
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _cache = decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      _cache = const {};
    }

    return _cache!;
  }

  static String? lookupSync(String name) => _cache?[name];
}
