import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../data/local/image_cache_store.dart';
import '../../../data/remote/image_data_source.dart';
import '../../../models/reader_settings.dart';
import '../../../theme/app_theme.dart';

class SceneImageWidget extends StatefulWidget {
  final String imageId;
  final List<String> urls;
  final String cacheKey;
  final ReaderSettings settings;
  final VoidCallback onTap;

  const SceneImageWidget({
    super.key,
    required this.imageId,
    required this.urls,
    required this.cacheKey,
    required this.settings,
    required this.onTap,
  });

  @override
  State<SceneImageWidget> createState() => _SceneImageWidgetState();
}

class _SceneImageWidgetState extends State<SceneImageWidget> {
  Uint8List? _bytes;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.settings.colors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Material(
          color: colors.background,
          child: InkWell(
            onTap: _failed ? null : widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: colors.secondaryText.withValues(alpha: 0.2),
                ),
              ),
              child: _buildContent(colors),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(dynamic colors) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.amber),
          ),
        ),
      );
    }
    if (_failed || _bytes == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: colors.secondaryText,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              'Image unavailable',
              style: TextStyle(color: colors.secondaryText, fontSize: 11),
            ),
          ],
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(_bytes!, fit: BoxFit.cover, gaplessPlayback: true),
        Positioned(
          right: 6,
          bottom: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.zoom_out_map, color: Colors.white, size: 10),
                SizedBox(width: 4),
                Text(
                  'TAP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
