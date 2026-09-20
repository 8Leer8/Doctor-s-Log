import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../data/local/image_cache_store.dart';
import '../../../data/remote/image_data_source.dart';
import '../../../theme/app_theme.dart';

class ImageModal extends StatefulWidget {
  final List<String> urls;
  final String cacheKey;
  final String title;
  final String? placeholderInitials;

  const ImageModal({
    super.key,
    required this.urls,
    required this.cacheKey,
    required this.title,
    this.placeholderInitials,
  });

  static Future<void> show(
    BuildContext context, {
    required List<String> urls,
    required String cacheKey,
    required String title,
    String? placeholderInitials,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      barrierDismissible: true,
      useSafeArea: true,
      builder: (_) => ImageModal(
        urls: urls,
        cacheKey: cacheKey,
        title: title,
        placeholderInitials: placeholderInitials,
      ),
    );
  }

  @override
  State<ImageModal> createState() => _ImageModalState();
}

class _ImageModalState extends State<ImageModal> {
  final _transformController = TransformationController();
  TapDownDetails? _doubleTapDetails;

  Uint8List? _bytes;
  bool _loading = true;
  bool _allFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _allFailed = false;
    });

    final cached = await ImageCacheStore.getImage(widget.cacheKey);
    if (cached != null && cached.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _bytes = cached;
        _loading = false;
      });
      return;
    }

    try {
      final fetched = await ImageDataSource.fetchWithFallback(widget.urls);
      await ImageCacheStore.saveImage(widget.cacheKey, fetched);
      if (!mounted) return;
      setState(() {
        _bytes = fetched;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allFailed = true;
        _loading = false;
      });
    }
  }

  void _handleDoubleTap() {
    final current = _transformController.value.getMaxScaleOnAxis();
    if (current > 1.05) {
      _transformController.value = Matrix4.identity();
      return;
    }
    final pos = _doubleTapDetails?.localPosition;
    if (pos == null) return;
    const scale = 2.5;
    final x = -pos.dx * (scale - 1);
    final y = -pos.dy * (scale - 1);
    _transformController.value = Matrix4.identity()
      ..translateByDouble(x, y, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned.fill(
            top: 56,
            bottom: 40,
            child: GestureDetector(
              onDoubleTapDown: (d) => _doubleTapDetails = d,
              onDoubleTap: _handleDoubleTap,
              child: _buildContent(),
            ),
          ),
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),
          Positioned(
            top: 12,
            right: 12,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 26),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.amber),
      );
    }
    if (_allFailed || _bytes == null) {
      return _buildPlaceholder();
    }
    return InteractiveViewer(
      transformationController: _transformController,
      minScale: 1.0,
      maxScale: 5.0,
      panEnabled: true,
      scaleEnabled: true,
      child: Center(
        child: Image.memory(
          _bytes!,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final initials = widget.placeholderInitials ?? '';
    final showInitials = initials.isNotEmpty && initials.length <= 3;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white10,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Center(
              child: showInitials
                  ? Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    )
                  : const Icon(
                      Icons.person_outline,
                      color: Colors.white54,
                      size: 48,
                    ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Portrait unavailable',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'We do not have an image for this character.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 64, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
        ),
      ),
      child: Text(
        widget.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
