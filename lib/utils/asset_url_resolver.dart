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

  static List<String> _buildFilenameVariants(String rawId) {
    final results = <String>[];
    final seen = <String>{};

    void add(String name) {
      if (seen.add(name)) results.add(name);
    }

    void addAllFor(String baseId) {
      if (RegExp(r'#\d+\$\d+$').hasMatch(baseId)) {
        add('$baseId.png');
        return;
      }

      if (RegExp(r'#\d+$').hasMatch(baseId)) {
        add('$baseId\$1.png');
        return;
      }

      final stripped = baseId.replaceFirst(RegExp(r'_\d+$'), '');
      if (stripped != baseId) {
        add('$stripped#1\$1.png');
        add('${stripped}_1#1\$1.png');
      }
      add('$baseId#1\$1.png');
      add('${baseId}_1#1\$1.png');
    }

    void addFor(String baseId) {
      addAllFor(baseId);
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
