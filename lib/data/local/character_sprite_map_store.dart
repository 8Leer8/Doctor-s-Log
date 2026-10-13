import 'dart:convert';
import 'package:flutter/services.dart';

class CharacterSpriteMapStore {
  static Map<String, String>? _cache;

  static Future<Map<String, String>> load() async {
    if (_cache != null) return _cache!;

    final merged = <String, String>{};
    // NPCs first so operators override on name collisions.
    merged.addAll(await _loadAsset('assets/data/npc_sprites.json'));
    merged.addAll(await _loadAsset('assets/data/character_sprites.json'));

    _cache = merged;
    return _cache!;
  }

  static Future<Map<String, String>> _loadAsset(String path) async {
    try {
      final raw = await rootBundle.loadString(path);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return const {};
    }
  }

  static String? lookupSync(String name) => _cache?[name];
}
