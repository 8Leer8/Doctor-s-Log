import 'package:dio/dio.dart';

class StoryDataSource {
  final Dio _dio = Dio();

  static const String _base =
      'https://cdn.jsdelivr.net/gh/Kengxxiao/ArknightsGameData_YoStar@master/en_US/gamedata/story';

  /// [relativePath] is the full path under /story/, e.g.
  /// 'obt/main/level_main_00-01_beg.txt' or 'obt/guide/beg/0_welcome_to_guide.txt'
  Future<String> fetchRawStory(String relativePath) async {
    final response = await _dio.get<String>(
      '$_base/$relativePath',
      options: Options(responseType: ResponseType.plain),
    );
    return response.data ?? '';
  }
}