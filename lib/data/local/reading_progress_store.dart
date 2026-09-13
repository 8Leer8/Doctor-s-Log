import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReadingProgressStore {
  static Future<Set<int>> getFinishedParts(String chapterId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('finished_$chapterId');
    if (raw == null) return {};
    final list = (jsonDecode(raw) as List).cast<int>();
    return list.toSet();
  }

  static Future<void> setFinishedParts(String chapterId, Set<int> finished) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('finished_$chapterId', jsonEncode(finished.toList()));
  }

  /// Keyed "partOriginalIndex-choiceId" -> chosen value.
  static Future<Map<String, String>> getChoices(String chapterId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('choices_$chapterId');
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>).cast<String, String>();
  }

  static Future<void> setChoices(String chapterId, Map<String, String> choices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('choices_$chapterId', jsonEncode(choices));
  }

  /// Exact resume point: which part (by originalIndex) and which line
  /// within that part's raw content the reader was last at.
  static Future<(int partOriginalIndex, int elementIndex)?> getResumePosition(
      String chapterId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('resume_$chapterId');
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return (decoded['part'] as int, decoded['element'] as int);
  }

  static Future<void> setResumePosition(
      String chapterId, int partOriginalIndex, int elementIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'resume_$chapterId',
      jsonEncode({'part': partOriginalIndex, 'element': elementIndex}),
    );
  }
}