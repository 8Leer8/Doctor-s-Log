import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/story_index_entry.dart';

class StoryIndexSource {
  final Dio _dio = Dio();

  static const String _base =
      'https://cdn.jsdelivr.net/gh/ArknightsAssets/ArknightsGamedata@master/en/gamedata/excel';
  Map<String, ChapterIndexEntry>? _cache;

  Future<Map<String, ChapterIndexEntry>> fetchIndex({bool forceRefresh = false}) async {
    if (_cache != null && !forceRefresh) return _cache!;

    final response = await _dio.get<String>(
      '$_base/story_review_table.json',
      options: Options(responseType: ResponseType.plain),
    );

    final Map<String, dynamic> raw = jsonDecode(response.data ?? '{}');
    final result = <String, ChapterIndexEntry>{};

    raw.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result[key] = ChapterIndexEntry.fromJson(key, value);
      }
    });

    _cache = result;
    return result;
  }
}