import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../data/local/cover_store.dart';
import '../../../models/story_category.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/cover_ref.dart';

/// A chapter cover: online art (cached on disk) with the bundled image as the
/// offline backup. While nothing is cached the bundled image shows; when the
/// online cover arrives it fades in (only the first time, afterwards it is
/// served from the cache instantly).
///
/// The ONLINE art is shown whole ([fit] defaults to contain) and, for main
/// chapters, rotated slightly so its polaroid frame is level. The bundled
/// backup is your own image, so it fills the area ([bundledFit]) un-rotated.
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
  late CoverRef _ref;
  Uint8List? _bytes;

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

  void _start() {
    final ref = CoverRef(
      category: widget.category,
      chapterId: widget.chapterId,
      entryPicId: widget.entryPicId,
    );
    _ref = ref;
    _bytes = CoverStore.peek(ref);
    if (_bytes != null) return;

    CoverStore.load(ref).then((bytes) {
      if (!mounted || bytes == null || ref.cacheKey != _ref.cacheKey) return;
      setState(() => _bytes = bytes);
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
    final degrees = widget.straighten ? _ref.straightenDegrees : 0.0;
    if (degrees != 0) {
      // Positive angle = clockwise, which levels the counter-clockwise tilt.
      image = Transform.rotate(angle: degrees * math.pi / 180, child: image);
    }
    return KeyedSubtree(key: ValueKey('online-${_ref.cacheKey}'), child: image);
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [...previous, if (current != null) current],
      ),
      child: bytes != null ? _online(bytes) : _bundled(),
    );
  }
}
