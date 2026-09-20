import 'dart:typed_data';
import 'package:dio/dio.dart';

class ImageDataSource {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.bytes,
    ),
  );

  static Future<Uint8List> fetch(String url) async {
    final response = await _dio.get<List<int>>(url);
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw Exception('Empty image response');
    }
    return Uint8List.fromList(data);
  }

  static Future<Uint8List> fetchWithFallback(List<String> urls) async {
    if (urls.isEmpty) {
      throw Exception('No URLs to fetch');
    }
    Object? lastError;
    for (final url in urls) {
      try {
        return await fetch(url);
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('All sources failed: $lastError');
  }
}
