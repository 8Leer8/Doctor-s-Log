import 'package:dio/dio.dart';

class StoryDataSource {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  static const String _base =
      'https://cdn.jsdelivr.net/gh/ArknightsAssets/ArknightsGamedata@master/en/gamedata/story';

  /// [relativePath] is the full path under /story/, e.g.
  /// 'obt/main/level_main_00-01_beg.txt' or 'obt/guide/beg/0_welcome_to_guide.txt'
  Future<String> fetchRawStory(String relativePath) async {
    final response = await _dio.get<String>(
      '$_base/$relativePath',
      options: Options(responseType: ResponseType.plain),
    );

    final data = response.data ?? '';
    if (data.trim().isEmpty) {
      throw Exception('Empty response for $relativePath');
    }
    return data;
  }
}
