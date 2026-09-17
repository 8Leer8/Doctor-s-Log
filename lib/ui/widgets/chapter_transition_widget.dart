import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/reader_settings.dart';

class ChapterTransitionWidget extends StatefulWidget {
  final String? previousTitle;
  final String currentTitle;
  final ReaderSettings settings;

  /// When non-null, the part *before* this transition failed to load.
  /// Values: 'no_internet' | 'unknown'. Rendered in the PREVIOUS/top
  /// section.
  final String? backwardMissingReason;

  /// When non-null, the part this transition represents going forward
  /// failed to load. Rendered in the CURRENT/bottom section.
  final String? forwardMissingReason;

  /// True while the backward-adjacent part is being fetched.
  final bool isLoadingBackward;

  /// True while the forward-adjacent part is being fetched.
  final bool isLoadingForward;

  /// Retry callback for the backward slot. Only shown when
  /// [backwardMissingReason] is set.
  final VoidCallback? onRetryBackward;

  /// Retry callback for the forward slot. Only shown when
  /// [forwardMissingReason] is set.
  final VoidCallback? onRetryForward;

  const ChapterTransitionWidget({
    super.key,
    required this.previousTitle,
    required this.currentTitle,
    required this.settings,
    this.backwardMissingReason,
    this.forwardMissingReason,
    this.isLoadingBackward = false,
    this.isLoadingForward = false,
    this.onRetryBackward,
    this.onRetryForward,
  });

  @override
  State<ChapterTransitionWidget> createState() =>
      _ChapterTransitionWidgetState();
}

class _ChapterTransitionWidgetState extends State<ChapterTransitionWidget> {
  bool _backwardPressed = false;
  bool _forwardPressed = false;

  bool get _hasBackwardIssue =>
      widget.backwardMissingReason != null || widget.isLoadingBackward;

  bool get _hasForwardIssue =>
      widget.forwardMissingReason != null || widget.isLoadingForward;

  @override
  Widget build(BuildContext context) {
    final colors = widget.settings.colors;
    final hasAnyIssue = _hasBackwardIssue || _hasForwardIssue;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 28),
      child: ClipPath(
        clipper: CutCornerClipper(cut: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: colors.background,
            border: Border.all(
              color: hasAnyIssue
                  ? Colors.redAccent.withValues(alpha: 0.4)
                  : colors.secondaryText.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.previousTitle != null) ...[
                _buildSectionLabelRow(
                  label: 'PREVIOUS',
                  hasIssue: _hasBackwardIssue,
                  defaultIcon: Icons.check_circle,
                  defaultLabelColor: colors.secondaryText,
                  defaultIconColor: colors.secondaryText,
                  title: widget.previousTitle!,
                  titleColor: colors.secondaryText,
                  titleWeight: FontWeight.w600,
                  titleSize: 15,
                ),
                if (_hasBackwardIssue) ...[
                  const SizedBox(height: 10),
                  _buildErrorBlock(
                    isLoading: widget.isLoadingBackward,
                    missingReason: widget.backwardMissingReason,
                    onRetry: widget.onRetryBackward,
                    pressed: _backwardPressed,
                    onPressedChanged: (v) =>
                        setState(() => _backwardPressed = v),
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  height: 1,
                  color: colors.secondaryText.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 20),
              ],
              _buildSectionLabelRow(
                label: 'CURRENT',
                hasIssue: _hasForwardIssue,
                defaultIcon: Icons.play_circle,
                defaultLabelColor: colors.accent,
                defaultIconColor: colors.accent,
                title: widget.currentTitle,
                titleColor: colors.text,
                titleWeight: FontWeight.w700,
                titleSize: 17,
                expandTitle: true,
              ),
              if (_hasForwardIssue) ...[
                const SizedBox(height: 10),
                _buildErrorBlock(
                  isLoading: widget.isLoadingForward,
                  missingReason: widget.forwardMissingReason,
                  onRetry: widget.onRetryForward,
                  pressed: _forwardPressed,
                  onPressedChanged: (v) => setState(() => _forwardPressed = v),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabelRow({
    required String label,
    required bool hasIssue,
    required IconData defaultIcon,
    required Color defaultLabelColor,
    required Color defaultIconColor,
    required String title,
    required Color titleColor,
    required FontWeight titleWeight,
    required double titleSize,
    bool expandTitle = false,
  }) {
    final labelColor = hasIssue ? Colors.redAccent : defaultLabelColor;
    final iconColor = hasIssue ? Colors.redAccent : defaultIconColor;
    final icon = hasIssue ? Icons.cloud_off_rounded : defaultIcon;

    final titleWidget = Text(
      title,
      style: TextStyle(
        color: titleColor,
        fontSize: titleSize,
        fontWeight: titleWeight,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            expandTitle ? Expanded(child: titleWidget) : titleWidget,
          ],
        ),
      ],
    );
  }

  /// Same visual layout as before: red title, italic subtitle, RETRY
  /// button with a press-scale animation. Used independently for the
  /// backward and forward slots.
  Widget _buildErrorBlock({
    required bool isLoading,
    required String? missingReason,
    required VoidCallback? onRetry,
    required bool pressed,
    required ValueChanged<bool> onPressedChanged,
  }) {
    final colors = widget.settings.colors;

    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Loading…',
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          missingReason == 'no_internet'
              ? 'Not downloaded · No internet'
              : 'Not downloaded',
          style: const TextStyle(
            color: Colors.redAccent,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Download this part while online, or connect to the internet to read it.',
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 12,
            height: 1.4,
            fontStyle: FontStyle.italic,
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTapDown: (_) => onPressedChanged(true),
            onTapCancel: () => onPressedChanged(false),
            onTapUp: (_) => onPressedChanged(false),
            onTap: onRetry,
            child: AnimatedScale(
              scale: pressed ? 0.94 : 1.0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.15),
                  border: Border.all(color: colors.accent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, color: colors.accent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'RETRY',
                      style: TextStyle(
                        color: colors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
