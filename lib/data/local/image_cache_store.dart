import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class ImageCacheStore {
  static Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/images');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _safeName(String cacheKey) {
    return cacheKey
        .replaceAll('#', '_')
        .replaceAll('\$', '_')
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .replaceAll(':', '_');
  }

  static Future<File> _fileFor(String cacheKey) async {
    final dir = await _dir();
    return File('${dir.path}/${_safeName(cacheKey)}.png');
  }

  static Future<bool> isCached(String cacheKey) async {
    final file = await _fileFor(cacheKey);
    return file.exists();
  }

  static Future<Uint8List?> getImage(String cacheKey) async {
    final file = await _fileFor(cacheKey);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  static Future<void> saveImage(String cacheKey, Uint8List bytes) async {
    final file = await _fileFor(cacheKey);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(file.path);
  }

  static Future<void> deleteImage(String cacheKey) async {
    final file = await _fileFor(cacheKey);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
