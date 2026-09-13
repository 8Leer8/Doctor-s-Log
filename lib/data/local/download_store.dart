import 'package:shared_preferences/shared_preferences.dart';

class DownloadStore {
  static String _key(String filename) => 'download_content_$filename';

  static Future<bool> isDownloaded(String filename) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key(filename));
  }

  static Future<String?> getContent(String filename) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(filename));
  }

  static Future<void> saveContent(String filename, String content) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(filename), content);
  }

  static Future<void> deleteContent(String filename) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(filename));
  }
}