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
    final encoded = Uri.encodeComponent('$id.png');
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
        return [
          'https://cdn.jsdelivr.net/gh/akgcc/arkdata@main/assets/avg/characters/$encoded',
          'https://cdn.jsdelivr.net/gh/fexli/ArknightsResource@main/avgs/characters/$encoded',
          'https://cdn.jsdelivr.net/gh/akgcc/arkdata@main/assets/avg/npcs/$encoded',
        ];
    }
  }

  String get primaryUrl => urls.first;
}
