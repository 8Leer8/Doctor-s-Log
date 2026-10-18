import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../data/local/cover_store.dart';
import '../../../models/story_category.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/cover_ref.dart';

/// A chapter cover, served from the copy saved on the device.
///
///  * saved copy found  -> shown at once (memory / disk, a few milliseconds);
///  * not saved yet     -> a neutral loading tile while it downloads (it does
///                         NOT show the bundled art first, so nothing swaps);
///  * unavailable       -> the bundled image (offline, or no online cover).
///
/// If a download takes longer than [_patience] the bundled image is shown
/// meanwhile, and the online cover fades in if it eventually arrives.
///
/// The online art is shown whole ([fit]) and, for main chapters, rotated by
/// the angle measured from the picture so its polaroid frame is level. The
/// bundled backup is your own image: it fills the area ([bundledFit]).
class CoverImage extends StatefulWidget {
  final String chapterId;
  final StoryCategory category;
  final String? entryPicId;
  final BoxFit fit;
  final BoxFit bundledFit;
  final Alignment alignment;
  final bool straighten;
  final double placeholderIconSize;

  const CoverImage({
    super.key,
    required this.chapterId,
    required this.category,
    this.entryPicId,
    this.fit = BoxFit.contain,
    this.bundledFit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.straighten = true,
    this.placeholderIconSize = 32,
  });

  @override
  State<CoverImage> createState() => _CoverImageState();
}

class _CoverImageState extends State<CoverImage> {
  static const Duration _patience = Duration(seconds: 4);

  late CoverRef _ref;
  Uint8List? _bytes;
  double _tilt = 0;
  bool _loading = false;
  bool _gaveUpWaiting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(CoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapterId != widget.chapterId ||
        oldWidget.category != widget.category ||
        oldWidget.entryPicId != widget.entryPicId) {
      _start();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    final ref = CoverRef(
      category: widget.category,
      chapterId: widget.chapterId,
      entryPicId: widget.entryPicId,
    );
    _ref = ref;
    _bytes = CoverStore.peek(ref);
    _tilt = CoverStore.tiltOf(ref);
    _loading = false;
    _gaveUpWaiting = false;
    if (_bytes != null) return;

    _loading = true;
    _timer = Timer(_patience, () {
      if (mounted && _loading && _bytes == null) {
        setState(() => _gaveUpWaiting = true);
      }
    });

    CoverStore.load(ref).then((bytes) {
      if (!mounted || ref.cacheKey != _ref.cacheKey) return;
      _timer?.cancel();
      setState(() {
        _loading = false;
        _bytes = bytes;
        _tilt = CoverStore.tiltOf(ref);
      });
    });
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceRaised,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: widget.placeholderIconSize,
          color: AppColors.coldGray.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _loadingTile() {
    return Container(
      key: ValueKey('loading-${_ref.cacheKey}'),
      color: AppColors.surfaceRaised,
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppColors.coldGray.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _bundled() {
    final base = _ref.bundledBase;
    return Image.asset(
      '$base.jpg',
      key: ValueKey('bundled-${_ref.cacheKey}'),
      fit: widget.bundledFit,
      alignment: widget.alignment,
      errorBuilder: (context, jpgError, jpgStack) => Image.asset(
        '$base.png',
        fit: widget.bundledFit,
        alignment: widget.alignment,
        errorBuilder: (context, pngError, pngStack) => _placeholder(),
      ),
    );
  }

  Widget _online(Uint8List bytes) {
    Widget image = Image.memory(
      bytes,
      fit: widget.fit,
      alignment: widget.alignment,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
    // Measured from the picture itself (see CoverTilt), so new chapters need
    // no hand-entered angle. Positive = clockwise = levels a CCW tilt.
    final degrees = widget.straighten ? _tilt : 0.0;
    if (degrees != 0) {
      image = Transform.rotate(angle: degrees * math.pi / 180, child: image);
    }
    return KeyedSubtree(key: ValueKey('online-${_ref.cacheKey}'), child: image);
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    final Widget child;
    if (bytes != null) {
      child = _online(bytes);
    } else if (_loading && !_gaveUpWaiting) {
      child = _loadingTile();
    } else {
      child = _bundled();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      child: child,
    );
  }
}
