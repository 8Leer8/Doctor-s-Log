import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/story_index_entry.dart';
import '../local/index_cache_store.dart';

class StoryIndexSource {
  final Dio _dio = Dio();

  static const String _base =
      'https://cdn.jsdelivr.net/gh/ArknightsAssets/ArknightsGamedata@master/en/gamedata/excel';

  Map<String, ChapterIndexEntry>? _memoryCache;

  Future<Map<String, ChapterIndexEntry>> fetchIndex({bool forceRefresh = false}) async {
    if (_memoryCache != null && !forceRefresh) return _memoryCache!;

    String? rawJson;

    try {
      final response = await _dio.get<String>(
        '$_base/story_review_table.json',
        options: Options(responseType: ResponseType.plain),
      );
      rawJson = response.data;
      if (rawJson != null) {
        // Fire-and-forget: don't block the current load on the write.
        IndexCacheStore.save(rawJson);
      }
    } catch (e) {
      // Network failed — fall back to whatever was cached from a
      // previous successful fetch, so browsing still works offline.
      rawJson = await IndexCacheStore.load();
      if (rawJson == null) {
        // Never successfully fetched even once — nothing to fall back to.
        rethrow;
      }
    }

    final Map<String, dynamic> raw = jsonDecode(rawJson!);
    final result = <String, ChapterIndexEntry>{};

    raw.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result[key] = ChapterIndexEntry.fromJson(key, value);
      }
    });

    _memoryCache = result;
    return result;
  }
}