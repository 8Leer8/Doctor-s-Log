enum AssetType { background, cg, character }

class AssetRef {
  final AssetType type;
  final String id;

  const AssetRef({required this.type, required this.id});

  String get cacheKey {
    switch (type) {
      case AssetType.background:
        return 'bg:$id';
      case AssetType.cg:
        return 'cg:$id';
      case AssetType.character:
        return 'char:$id';
    }
  }

  List<String> get urls {
    switch (type) {
      case AssetType.background:
        return [
          'https://cdn.jsdelivr.net/gh/fexli/ArknightsResource@main/avgs/bg/$id.png',
        ];

      case AssetType.cg:
        return [
          'https://cdn.jsdelivr.net/gh/fexli/ArknightsResource@main/avgs/$id.png',
        ];

      case AssetType.character:
        return _buildCharacterUrls(id);
    }
  }

  static List<String> _buildCharacterUrls(String id) {
    final variants = _buildFilenameVariants(id);
    final seen = <String>{};
    final urls = <String>[];

    for (final filename in variants) {
      final encoded = Uri.encodeComponent(filename);
      final jsdelivr =
          'https://cdn.jsdelivr.net/gh/akgcc/arkdata@main/assets/avg/characters/$encoded';
      final raw =
          'https://raw.githubusercontent.com/akgcc/arkdata/main/assets/avg/characters/$encoded';
      if (seen.add(jsdelivr)) urls.add(jsdelivr);
      if (seen.add(raw)) urls.add(raw);
    }

    return urls;
  }

  static bool _isNpcId(String id) =>
      id.startsWith('avg_npc') ||
      id.startsWith('avgnew_npc') ||
      id.startsWith('npc_');

  static List<String> _buildFilenameVariants(String rawId) {
    final results = <String>[];
    final seen = <String>{};

    void add(String name) {
      if (seen.add(name)) results.add(name);
    }

    void addAllFor(String baseId) {
      // Already a full filename id, e.g. "avg_npc_394_1#7$1".
      if (RegExp(r'#\d+\$\d+$').hasMatch(baseId)) {
        add('$baseId.png');
        return;
      }

      // Has an expression but no outfit suffix, e.g. "avg_npc_143#2".
      if (RegExp(r'#\d+$').hasMatch(baseId)) {
        add('$baseId\$1.png');
        return;
      }

      // NPC ids (from npc_sprites.json) are already complete base ids such as
      // "avg_npc_1612_1" or "avg_npc_242": try them as-is first so the very
      // first request hits.
      if (_isNpcId(baseId)) {
        add('$baseId#1\$1.png');
      }

      // Only strip a trailing variant number when TWO numbers trail
      // (avg_npc_1612_1 -> avg_npc_1612). Never strip from ids with a single
      // number such as avg_npc_242 or char_002_amiya.
      final m = RegExp(r'^(.+_\d+)_\d+$').firstMatch(baseId);
      if (m != null) {
        final stripped = m.group(1)!;
        add('$stripped#1\$1.png');
        add('${stripped}_1#1\$1.png');
      }
      add('$baseId#1\$1.png');
      add('${baseId}_1#1\$1.png');
    }

    void addFor(String baseId) {
      addAllFor(baseId);
      // The char_/avg_ prefix swap only makes sense for operator sprites.
      if (_isNpcId(baseId)) return;
      if (baseId.startsWith('char_')) {
        addAllFor('avg_${baseId.substring(5)}');
      } else if (baseId.startsWith('avg_')) {
        addAllFor('char_${baseId.substring(4)}');
      }
    }

    final lowerId = rawId.toLowerCase();
    final withoutEx = lowerId.replaceAll('_ex', '');
    if (withoutEx != lowerId) {
      addFor(withoutEx);
    }
    addFor(lowerId);

    return results;
  }

  String get primaryUrl => urls.first;
}
