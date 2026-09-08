class StoryUnlockEntry {
  final String storyId;
  final int storySort;
  final String storyName;
  final String storyTxt; // relative path, no extension, e.g. "obt/main/level_main_00-01_beg"
  final String avgTag;
  final String storyCode;

  const StoryUnlockEntry({
    required this.storyId,
    required this.storySort,
    required this.storyName,
    required this.storyTxt,
    required this.avgTag,
    required this.storyCode,
  });

  factory StoryUnlockEntry.fromJson(Map<String, dynamic> json) {
    return StoryUnlockEntry(
      storyId: json['storyId'] as String? ?? '',
      storySort: json['storySort'] as int? ?? 0,
      storyName: json['storyName'] as String? ?? '',
      storyTxt: json['storyTxt'] as String? ?? '',
      avgTag: json['avgTag'] as String? ?? '',
      storyCode: json['storyCode'] as String? ?? '',
    );
  }
}

class ChapterIndexEntry {
  final String id;
  final String name;
  final String entryType; // "MAINLINE", "ACTIVITY", etc.
  final String actType;
  final List<StoryUnlockEntry> infoUnlockDatas;

  const ChapterIndexEntry({
    required this.id,
    required this.name,
    required this.entryType,
    required this.actType,
    required this.infoUnlockDatas,
  });

  factory ChapterIndexEntry.fromJson(String id, Map<String, dynamic> json) {
    final rawList = (json['infoUnlockDatas'] as List<dynamic>? ?? []);
    final parts = rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => StoryUnlockEntry.fromJson(e))
        .where((p) => p.storyTxt.isNotEmpty)
        .toList()
      ..sort((a, b) => a.storySort.compareTo(b.storySort));

    return ChapterIndexEntry(
      id: id,
      name: json['name'] as String? ?? id,
      entryType: json['entryType'] as String? ?? '',
      actType: json['actType'] as String? ?? '',
      infoUnlockDatas: parts,
    );
  }
}