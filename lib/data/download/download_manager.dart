import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/story_element.dart';
import '../local/download_prefs_store.dart';
import '../local/download_store.dart';
import '../parser/image_prefetcher.dart';
import '../parser/story_parser.dart';
import '../remote/story_data_source.dart';

enum DownloadJobState { queued, downloading }

class DownloadJob {
  final String chapterId;
  final String chapterTitle;
  final String partTitle;
  final String filename;

  DownloadJobState state = DownloadJobState.queued;

  /// 0.0-1.0 while the part's images are being fetched; null = unknown.
  double? progress;

  /// Set when the user cancels a job that is already downloading. The job
  /// finishes its current step, then rolls back whatever it saved.
  bool cancelled = false;

  DownloadJob({
    required this.chapterId,
    required this.chapterTitle,
    required this.partTitle,
    required this.filename,
  });
}

enum DownloadEventKind { partCompleted, partFailed, noInternet, queueFinished }

class DownloadEvent {
  final DownloadEventKind kind;
  final String? chapterId;
  final String? filename;
  final String? partTitle;

  /// Only for [DownloadEventKind.queueFinished].
  final int completedCount;
  final int failedImages;

  final String? message;

  const DownloadEvent({
    required this.kind,
    this.chapterId,
    this.filename,
    this.partTitle,
    this.completedCount = 0,
    this.failedImages = 0,
    this.message,
  });
}

/// One download queue for the whole app. Parts are downloaded strictly one
/// at a time, in the order they were queued, no matter which screen queued
/// them.
///
/// * No internet: the queue pauses and keeps its items. Resume from the
///   Download queue screen (or tap a download icon again).
/// * "Wi-Fi only" on and the phone is on mobile data: the queue waits
///   ([waitingForWifi]) and starts by itself when Wi-Fi connects or the
///   option is turned off.
/// * Any other error: that part is dropped and the queue moves on.
class DownloadManager extends ChangeNotifier {
  DownloadManager._();
  static final DownloadManager instance = DownloadManager._();

  final StoryDataSource _dataSource = StoryDataSource();
  final List<DownloadJob> _jobs = [];
  final StreamController<DownloadEvent> _events =
      StreamController<DownloadEvent>.broadcast();

  /// Fires once each time the queue starts waiting for Wi-Fi (the app shell
  /// turns it into a toast).
  final StreamController<void> _wifiNotices =
      StreamController<void>.broadcast();

  bool _initialized = false;

  bool _running = false;
  bool _paused = false;
  bool _waitingForWifi = false;
  int _sessionCompleted = 0;
  int _sessionFailedImages = 0;
  String? _lastTitle;

  Stream<DownloadEvent> get events => _events.stream;
  Stream<void> get waitingForWifiNotices => _wifiNotices.stream;

  /// Jobs the user can see (cancelled ones that are still winding down are
  /// hidden).
  List<DownloadJob> get jobs =>
      List.unmodifiable(_jobs.where((j) => !j.cancelled));

  int get length => _jobs.where((j) => !j.cancelled).length;
  bool get isPaused => _paused;
  bool get waitingForWifi => _waitingForWifi;

  DownloadJob? jobFor(String filename) {
    for (final j in _jobs) {
      if (j.filename == filename && !j.cancelled) return j;
    }
    return null;
  }

  /// Call once at startup. Restarts a waiting queue when the connection
  /// changes or "Wi-Fi only" is switched off.
  void init() {
    if (_initialized) return;
    _initialized = true;
    try {
      DownloadPrefsStore.mobileOnlyChanges.listen(
        (_) => _retryIfWaiting(),
        onError: (_) {},
      );
    } catch (_) {}
    DownloadPrefsStore.wifiOnly.addListener(_retryIfWaiting);
  }

  void _retryIfWaiting() {
    if (_waitingForWifi) unawaited(_pump());
  }

  void _setWaiting(bool value) {
    if (_waitingForWifi == value) return;
    _waitingForWifi = value;
    if (value) _wifiNotices.add(null);
    notifyListeners();
  }

  // ------------------------------------------------------------------ queue

  void enqueue({
    required String chapterId,
    required String chapterTitle,
    required String partTitle,
    required String filename,
  }) {
    if (jobFor(filename) != null) return;
    _jobs.add(
      DownloadJob(
        chapterId: chapterId,
        chapterTitle: chapterTitle,
        partTitle: partTitle,
        filename: filename,
      ),
    );
    _paused = false;
    notifyListeners();
    unawaited(_pump());
  }

  /// Removes a queued job, or stops one that is already downloading (its
  /// partial files are rolled back).
  void cancel(String filename) {
    final job = jobFor(filename);
    if (job == null) return;
    job.cancelled = true;
    if (job.state == DownloadJobState.queued) _jobs.remove(job);
    notifyListeners();
    _maybeFinishSession();
  }

  void cancelAll() {
    for (final job in List<DownloadJob>.of(_jobs)) {
      job.cancelled = true;
      if (job.state == DownloadJobState.queued) _jobs.remove(job);
    }
    _setWaiting(false);
    notifyListeners();
    _maybeFinishSession();
  }

  void pause() {
    if (_paused) return;
    _paused = true;
    _setWaiting(false);
    notifyListeners();
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    notifyListeners();
    unawaited(_pump());
  }

  // ----------------------------------------------------------------- worker

  Future<void> _pump() async {
    if (_running) return;
    _running = true;
    try {
      while (!_paused) {
        final next = _nextQueued();
        if (next == null) {
          _setWaiting(false);
          break;
        }
        if (!await DownloadPrefsStore.canDownloadNow()) {
          _setWaiting(true);
          break;
        }
        _setWaiting(false);
        await _process(next);
      }
    } finally {
      _running = false;
    }

    // The connection may have changed while we were deciding to wait.
    if (_waitingForWifi &&
        !_paused &&
        _nextQueued() != null &&
        await DownloadPrefsStore.canDownloadNow()) {
      unawaited(_pump());
      return;
    }

    _maybeFinishSession();
    notifyListeners();
  }

  DownloadJob? _nextQueued() {
    for (final j in _jobs) {
      if (j.state == DownloadJobState.queued && !j.cancelled) return j;
    }
    return null;
  }

  Future<void> _process(DownloadJob job) async {
    job.state = DownloadJobState.downloading;
    job.progress = null;
    notifyListeners();

    var keepInQueue = false;

    try {
      final content = await _dataSource.fetchRawStory(job.filename);

      if (content.trim().isEmpty || content.length < 50) {
        throw Exception('Downloaded content is empty or too short');
      }

      await DownloadStore.saveContent(job.filename, content);

      final verify = await DownloadStore.getContent(job.filename);
      if (verify == null || verify.isEmpty) {
        throw Exception('Failed to persist content to disk');
      }

      // Needed so speaker portraits resolve and get downloaded too.
      await StoryParser.ensureSpriteMapLoaded();

      List<StoryElement> elements;
      try {
        elements = StoryParser.parse(content);
      } catch (_) {
        elements = const [];
      }

      PrefetchResult? result;
      try {
        result = await ImagePrefetcher.prefetch(
          elements: elements,
          partFilename: job.filename,
          onProgress: (done, total) {
            if (total <= 0 || job.cancelled) return;
            job.progress = done / total;
            notifyListeners();
          },
        );
      } catch (_) {
        result = null;
      }

      if (job.cancelled) {
        await _rollback(job.filename);
      } else {
        _sessionCompleted++;
        _sessionFailedImages += result?.failedIds.length ?? 0;
        _lastTitle = job.partTitle;
        _events.add(
          DownloadEvent(
            kind: DownloadEventKind.partCompleted,
            chapterId: job.chapterId,
            filename: job.filename,
            partTitle: job.partTitle,
          ),
        );
      }
    } catch (e) {
      if (job.cancelled) {
        await _rollback(job.filename);
      } else if (_isNetworkError(e)) {
        // Keep the job and everything behind it; wait for the user.
        job.state = DownloadJobState.queued;
        job.progress = null;
        keepInQueue = true;
        _paused = true;
        _events.add(const DownloadEvent(kind: DownloadEventKind.noInternet));
      } else {
        _events.add(
          DownloadEvent(
            kind: DownloadEventKind.partFailed,
            chapterId: job.chapterId,
            filename: job.filename,
            partTitle: job.partTitle,
            message: e.toString(),
          ),
        );
      }
    }

    if (!keepInQueue) _jobs.remove(job);
    notifyListeners();
  }

  Future<void> _rollback(String filename) async {
    try {
      await ImagePrefetcher.releaseImagesForPart(filename);
    } catch (_) {}
    try {
      await DownloadStore.deleteContent(filename);
    } catch (_) {}
  }

  void _maybeFinishSession() {
    if (_running || _jobs.isNotEmpty) return;
    if (_sessionCompleted > 0) {
      _events.add(
        DownloadEvent(
          kind: DownloadEventKind.queueFinished,
          partTitle: _lastTitle,
          completedCount: _sessionCompleted,
          failedImages: _sessionFailedImages,
        ),
      );
    }
    _sessionCompleted = 0;
    _sessionFailedImages = 0;
    _lastTitle = null;
  }

  static bool _isNetworkError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('connection error') ||
        s.contains('connectionerror') ||
        s.contains('connection timeout') ||
        s.contains('receive timeout') ||
        s.contains('timed out') ||
        s.contains('no address associated');
  }
}
