import 'dart:io';
import 'package:flutter/foundation.dart';
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

  static String _safeName(String filename) {
    return filename.replaceAll('/', '__').replaceAll('\\', '__');
  }

  static Future<File> _fileFor(String filename) async {
    final dir = await _dir();
    return File('${dir.path}/${_safeName(filename)}');
  }

  static Future<bool> isDownloaded(String filename) async {
    final file = await _fileFor(filename);
    final exists = await file.exists();
    debugPrint('[DownloadStore] isDownloaded("$filename") → $exists (${file.path})');
    return exists;
  }

  static Future<String?> getContent(String filename) async {
    final file = await _fileFor(filename);
    final exists = await file.exists();
    debugPrint('[DownloadStore] getContent("$filename") exists=$exists');
    if (!exists) return null;
    final content = await file.readAsString();
    debugPrint('[DownloadStore] getContent("$filename") read ${content.length} chars');
    return content;
  }

  static Future<void> saveContent(String filename, String content) async {
    final file = await _fileFor(filename);
    debugPrint('[DownloadStore] saveContent("$filename") → ${file.path} (${content.length} chars)');
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(content, flush: true);
    await tmp.rename(file.path);
    final check = await file.exists();
    debugPrint('[DownloadStore] saveContent verified exists=$check');
  }

  static Future<void> deleteContent(String filename) async {
    final file = await _fileFor(filename);
    if (await file.exists()) await file.delete();
    debugPrint('[DownloadStore] deleteContent("$filename")');
  }
}