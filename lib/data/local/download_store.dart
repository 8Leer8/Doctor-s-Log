import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DownloadStore {
  static Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/downloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<Directory> _manifestDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/manifests');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _safeName(String filename) {
    return filename.replaceAll('/', '__').replaceAll('\\', '__');
  }

  static Future<File> _fileFor(String filename) async {
    final dir = await _dir();
    return File('${dir.path}/${_safeName(filename)}');
  }

  static Future<File> _manifestFor(String filename) async {
    final dir = await _manifestDir();
    return File('${dir.path}/${_safeName(filename)}.json');
  }

  static Future<bool> isDownloaded(String filename) async {
    final file = await _fileFor(filename);
    return file.exists();
  }

  static Future<String?> getContent(String filename) async {
    final file = await _fileFor(filename);
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  static Future<void> saveContent(String filename, String content) async {
    final file = await _fileFor(filename);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(content, flush: true);
    await tmp.rename(file.path);
  }

  static Future<void> deleteContent(String filename) async {
    final file = await _fileFor(filename);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<void> saveImageManifest(
    String partFilename,
    List<String> cacheKeys,
  ) async {
    final file = await _manifestFor(partFilename);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(cacheKeys), flush: true);
    await tmp.rename(file.path);
  }

  static Future<List<String>> getImageManifest(String partFilename) async {
    final file = await _manifestFor(partFilename);
    if (!await file.exists()) return const <String>[];
    try {
      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return const <String>[];
    }
  }

  static Future<void> deleteImageManifest(String partFilename) async {
    final file = await _manifestFor(partFilename);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
