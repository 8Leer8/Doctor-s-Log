import 'dart:async';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// One shared style for the real field AND the ghost layer behind it, so the
/// faded completion lines up exactly with what the user has typed.
const TextStyle _kFieldStyle = TextStyle(
  inherit: false,
  color: AppColors.textPrimary,
  fontSize: 14,
  textBaseline: TextBaseline.alphabetic, // required when inherit is false
  fontFamily: 'Roboto',
  fontWeight: FontWeight.w400,
  letterSpacing: 0.2,
  height: 1.2,
);

class LibrarySearchBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  /// Faded completion shown after the typed text ('' = none).
  final String ghost;

  /// Terms shown in the rotating placeholder while the field is empty.
  final List<String> hints;

  final VoidCallback onClose;
  final VoidCallback onAcceptGhost;

  const LibrarySearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.ghost,
    required this.hints,
    required this.onClose,
    required this.onAcceptGhost,
  });

  @override
  State<LibrarySearchBar> createState() => _LibrarySearchBarState();
}

class _LibrarySearchBarState extends State<LibrarySearchBar> {
  Timer? _timer;
  int _hintIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted ||
          widget.controller.text.isNotEmpty ||
          widget.hints.isEmpty) {
        return;
      }
      setState(() => _hintIndex = (_hintIndex + 1) % (widget.hints.length + 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _hintText {
    if (_hintIndex == 0 || widget.hints.isEmpty) {
      return 'Search chapters, parts, keywords…';
    }
    return 'Try “${widget.hints[(_hintIndex - 1) % widget.hints.length]}”';
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    final ghost = hasText ? widget.ghost : '';

    return Row(
      children: [
        IconButton(
          tooltip: 'Close search',
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: 22,
          ),
          onPressed: widget.onClose,
        ),
        Expanded(
          child: ClipPath(
            clipper: CutCornerClipper(cut: 8),
            child: Container(
              height: 38,
              padding: const EdgeInsets.only(left: 12, right: 2),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.amber.withValues(alpha: 0.7),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 16, color: AppColors.amber),
                  const SizedBox(width: 10),
                  Expanded(child: _buildField(hasText, ghost)),
                  if (ghost.isNotEmpty)
                    _smallIconButton(
                      tooltip: 'Autocomplete',
                      icon: Icons.keyboard_tab,
                      color: AppColors.amber,
                      onPressed: widget.onAcceptGhost,
                    ),
                  if (hasText)
                    _smallIconButton(
                      tooltip: 'Clear',
                      icon: Icons.close,
                      color: AppColors.coldGray,
                      onPressed: widget.controller.clear,
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _smallIconButton({
    required String tooltip,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      iconSize: 18,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      icon: Icon(icon, color: color),
      onPressed: onPressed,
    );
  }

  Widget _buildField(bool hasText, String ghost) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        if (!hasText)
          IgnorePointer(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.centerLeft,
                children: [...previous, if (current != null) current],
              ),
              child: Text(
                _hintText,
                key: ValueKey(_hintIndex),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _kFieldStyle.copyWith(
                  color: AppColors.coldGray.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        if (ghost.isNotEmpty)
          IgnorePointer(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: widget.controller.text,
                    style: _kFieldStyle.copyWith(color: Colors.transparent),
                  ),
                  TextSpan(
                    text: ghost,
                    style: _kFieldStyle.copyWith(
                      color: AppColors.coldGray.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: _kFieldStyle,
            ),
          ),
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          autofocus: true,
          maxLines: 1,
          style: _kFieldStyle,
          cursorColor: AppColors.amber,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration.collapsed(hintText: null),
        ),
      ],
    );
  }
}
