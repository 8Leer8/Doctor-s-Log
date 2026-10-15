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
class CoverImage extends StatefulWidget {
  final String chapterId;
  final StoryCategory category;
  final String? entryPicId;
  final BoxFit fit;
  final Alignment alignment;
  final double placeholderIconSize;

  const CoverImage({
    super.key,
    required this.chapterId,
    required this.category,
    this.entryPicId,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
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

  Widget _bundled(Key key) {
    final base = _ref.bundledBase;
    return Image.asset(
      '$base.jpg',
      key: key,
      fit: widget.fit,
      alignment: widget.alignment,
      errorBuilder: (context, jpgError, jpgStack) => Image.asset(
        '$base.png',
        fit: widget.fit,
        alignment: widget.alignment,
        errorBuilder: (context, pngError, pngStack) => _placeholder(),
      ),
    );
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
      child: bytes != null
          ? Image.memory(
              bytes,
              key: ValueKey('online-${_ref.cacheKey}'),
              fit: widget.fit,
              alignment: widget.alignment,
              gaplessPlayback: true,
            )
          : _bundled(ValueKey('bundled-${_ref.cacheKey}')),
    );
  }
}
