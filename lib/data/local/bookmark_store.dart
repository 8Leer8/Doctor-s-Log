import 'package:shared_preferences/shared_preferences.dart';

class BookmarkStore {
  static String _key(String chapterId) => 'bookmarked_parts_$chapterId';

  static Future<Set<String>> getBookmarks(String chapterId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key(chapterId));
    return (list ?? const []).toSet();
  }

  static Future<void> setBookmarks(
    String chapterId,
    Set<String> filenames,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(chapterId), filenames.toList());
  }

  static Future<void> toggleBookmark(
    String chapterId,
    String filename,
    bool bookmarked,
  ) async {
    final current = await getBookmarks(chapterId);
    if (bookmarked) {
      current.add(filename);
    } else {
      current.remove(filename);
    }
    await setBookmarks(chapterId, current);
  }

  static Future<void> toggleMany(
    String chapterId,
    List<String> filenames,
    bool bookmarked,
  ) async {
    final current = await getBookmarks(chapterId);
    for (final f in filenames) {
      if (bookmarked) {
        current.add(f);
      } else {
        current.remove(f);
      }
    }
    await setBookmarks(chapterId, current);
  }
}
