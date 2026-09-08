import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/remote/story_data_source.dart';
import '../../data/parser/story_parser.dart';
import '../../models/story_line.dart';

class ReaderScreen extends StatefulWidget {
  final String filename;
  final String chapterTitle;

  const ReaderScreen({
    super.key,
    required this.filename,
    required this.chapterTitle,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final _dataSource = StoryDataSource();
  final _scrollController = ScrollController();

  List<StoryLine>? _lines;
  String? _error;
  bool _loading = true;
  bool _showControls = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    setState(() {
      _progress = max == 0 ? 1 : (offset / max).clamp(0.0, 1.0);
    });
  }

  Future<void> _fetch() async {
    try {
      final raw = await _dataSource.fetchRawStory(widget.filename);
      setState(() {
        _lines = StoryParser.parse(raw);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _toggleControls,
              child: _buildBody(),
            ),
            _TopBar(
              visible: _showControls,
              title: widget.chapterTitle,
              onBack: () => Navigator.of(context).pop(),
            ),
            _BottomBar(visible: _showControls, progress: _progress),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.amber),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Failed to load:\n$_error',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }
    final lines = _lines ?? [];
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 70, 20, 90),
      itemCount: lines.length,
      itemBuilder: (context, index) => _StoryLineWidget(line: lines[index]),
    );
  }
}

class _StoryLineWidget extends StatelessWidget {
  final StoryLine line;
  const _StoryLineWidget({required this.line});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: AppColors.textPrimary,
          ),
          children: [
            if (line.speaker != null)
              TextSpan(
                text: '${line.speaker}: ',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.amber,
                ),
              ),
            TextSpan(
              text: line.text,
              style: line.speaker == null
                  ? const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool visible;
  final String title;
  final VoidCallback onBack;

  const _TopBar({
    required this.visible,
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: visible ? 0 : -60,
      left: 0,
      right: 0,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          border: const Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: onBack,
            ),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppColors.coldGray),
              onPressed: () {
                // TODO: reading settings (font size, theme)
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool visible;
  final double progress;

  const _BottomBar({required this.visible, required this.progress});

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      bottom: visible ? 0 : -70,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.amber,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.amber,
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: progress,
                onChanged: (_) {}, // seek-by-drag not wired yet
              ),
            ),
            Text(
              '${(progress * 100).round()}% read',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}