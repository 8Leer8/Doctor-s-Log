import 'package:dio/dio.dart';

class StoryDataSource {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  static const String _primaryBase =
      'https://cdn.jsdelivr.net/gh/ArknightsAssets/ArknightsGamedata@master/en/gamedata/story';

  static const String _fallbackBase =
      'https://cdn.jsdelivr.net/gh/Kengxxiao/ArknightsGameData_YoStar@main/en_US/gamedata/story';

  Future<String> fetchRawStory(
    String relativePath, {
    void Function(int received, int total)? onProgress,
  }) async {
    final primary = '$_primaryBase/$relativePath';

    try {
      final response = await _dio.get<String>(
        primary,
        options: Options(responseType: ResponseType.plain),
        onReceiveProgress: onProgress,
      );
      final data = response.data ?? '';
      if (data.trim().isNotEmpty) return data;
    } catch (_) {
      // fall through to fallback
    }

    final fallback = '$_fallbackBase/$relativePath';
    final response = await _dio.get<String>(
      fallback,
      options: Options(responseType: ResponseType.plain),
      onReceiveProgress: onProgress,
    );

    final data = response.data ?? '';
    if (data.trim().isEmpty) {
      throw Exception('Empty response for $relativePath (both sources)');
    }
    return data;
  }
}
