import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/chapter_preview.dart';
import '../download/download_manager.dart';

/// Which story parts are saved on the device, held in memory so the Library
/// can filter ~90 chapters without checking thousands of files one by one.
///
/// It lists the downloads folder once ([refresh]) and then stays current by
/// listening to the download queue. Call [refresh] after anything that
/// deletes downloads outside the queue (the chapter screen, Data and
/// storage).
class DownloadedIndex extends ChangeNotifier {
  DownloadedIndex._();
  static final DownloadedIndex instance = DownloadedIndex._();

  Set<String> _names = <String>{};
  StreamSubscription<DownloadEvent>? _sub;

  /// Same naming rule as DownloadStore, so names match the files on disk.
  static String _safe(String filename) =>
      filename.replaceAll('/', '__').replaceAll('\\', '__');

  Future<void> init() async {
    _sub ??= DownloadManager.instance.events.listen((e) {
      final f = e.filename;
      if (e.kind == DownloadEventKind.partCompleted && f != null) {
        _names.add(_safe(f));
        notifyListeners();
      }
    });
    await refresh();
  }

  Future<void> refresh() async {
    final names = <String>{};
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/downloads');
      if (await dir.exists()) {
        await for (final e in dir.list()) {
          if (e is! File) continue;
          final segments = e.uri.pathSegments.where((s) => s.isNotEmpty);
          if (segments.isEmpty) continue;
          final name = segments.last;
          if (name.endsWith('.tmp')) continue;
          names.add(name);
        }
      }
    } catch (_) {}
    _names = names;
    notifyListeners();
  }

  bool isDownloaded(String filename) => _names.contains(_safe(filename));

  /// True when at least one part of [chapter] is downloaded.
  bool hasAny(ChapterPreview chapter) {
    for (final p in chapter.parts) {
      final f = p.filename;
      if (f != null && isDownloaded(f)) return true;
    }
    return false;
  }
}
