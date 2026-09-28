import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ImageDataSource {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.bytes,
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  static Future<Uint8List> fetch(String url) async {
    final response = await _dio.get<List<int>>(url);
    final status = response.statusCode ?? 0;

    if (status < 200 || status >= 300) {
      throw Exception('HTTP $status for $url');
    }

    final data = response.data;
    if (data == null || data.isEmpty) {
      throw Exception('Empty image response for $url');
    }

    if (data.length < 4 ||
        data[0] != 0x89 ||
        data[1] != 0x50 ||
        data[2] != 0x4E ||
        data[3] != 0x47) {
      throw Exception('Response is not a PNG');
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
