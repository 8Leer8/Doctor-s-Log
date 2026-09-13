String formatActType(String raw) {
  switch (raw) {
    case 'MAIN_STORY':
      return 'Main Story';
    case 'ACTIVITY_STORY':
      return 'Event Story';
    default:
      return raw
          .split('_')
          .map((w) => w.isEmpty ? w : '${w[0]}${w.substring(1).toLowerCase()}')
          .join(' ');
  }
}

/// Short label shown on the chapter card itself — "CHAPTER 3" for main
/// story entries (parsed from the "main_3" id), or the formatted act
/// type ("EVENT STORY") for everything else.
String formatChapterCardLabel(String chapterId, String actTypeRaw) {
  final mainMatch = RegExp(r'^main_(\d+)$').firstMatch(chapterId);
  if (mainMatch != null) {
    return 'CHAPTER ${mainMatch.group(1)}';
  }
  return formatActType(actTypeRaw).toUpperCase();
}