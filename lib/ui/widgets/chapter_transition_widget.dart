import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/reader_settings.dart';

enum TransitionDirection { forward, backward }

class ChapterTransitionWidget extends StatefulWidget {
  final String? previousTitle;
  final String currentTitle;
  final ReaderSettings settings;
  final String? backwardMissingReason;
  final String? forwardMissingReason;
  final bool isPendingBackward;
  final bool isPendingForward;
  final VoidCallback? onRetryBackward;
  final VoidCallback? onRetryForward;

  const ChapterTransitionWidget({
    super.key,
    required this.previousTitle,
    required this.currentTitle,
    required this.settings,
    this.backwardMissingReason,
    this.forwardMissingReason,
    this.isPendingBackward = false,
    this.isPendingForward = false,
    this.onRetryBackward,
    this.onRetryForward,
  });

  @override
  State<ChapterTransitionWidget> createState() =>
      _ChapterTransitionWidgetState();
}

class _ChapterTransitionWidgetState extends State<ChapterTransitionWidget> {
  bool _pressingBackward = false;
  bool _pressingForward = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.settings.colors;
    final backwardMissing = widget.backwardMissingReason != null;
    final forwardMissing = widget.forwardMissingReason != null;
    final backwardPending = widget.isPendingBackward;
    final forwardPending = widget.isPendingForward;

    // A side is "orange" if pending and NOT missing. If it's missing,
    // it's red (error state wins over pending — shouldn't co-occur, but
    // this makes the priority explicit).
    final backwardAccent = backwardMissing
        ? Colors.redAccent
        : (backwardPending ? AppColors.amber : colors.secondaryText);
    final forwardAccent = forwardMissing
        ? Colors.redAccent
        : (forwardPending ? AppColors.amber : colors.accent);

    final anyError = backwardMissing || forwardMissing;
    final anyPending = (backwardPending || forwardPending) && !anyError;

    final borderColor = anyError
        ? Colors.redAccent.withValues(alpha: 0.4)
        : (anyPending
              ? AppColors.amber.withValues(alpha: 0.5)
              : colors.secondaryText.withValues(alpha: 0.3));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 28),
      child: ClipPath(
        clipper: CutCornerClipper(cut: 14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: colors.background,
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.previousTitle != null) ...[
                Text(
                  'PREVIOUS',
                  style: TextStyle(
                    color: backwardAccent,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (backwardPending && !backwardMissing)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.amber),
                        ),
                      )
                    else
                      Icon(
                        backwardMissing
                            ? Icons.cloud_off_rounded
                            : Icons.check_circle,
                        color: backwardAccent,
                        size: 18,
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.previousTitle!,
                        style: TextStyle(
                          color: backwardMissing
                              ? Colors.redAccent
                              : colors.secondaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (backwardMissing) ...[
                  const SizedBox(height: 10),
                  _buildErrorBlock(
                    colors,
                    reason: widget.backwardMissingReason!,
                    onRetry: widget.onRetryBackward,
                    pressing: _pressingBackward,
                    onPressChange: (v) => setState(() => _pressingBackward = v),
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  height: 1,
                  color: colors.secondaryText.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                'CURRENT',
                style: TextStyle(
                  color: forwardAccent,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (forwardPending && !forwardMissing)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.amber),
                      ),
                    )
                  else
                    Icon(
                      forwardMissing
                          ? Icons.cloud_off_rounded
                          : Icons.play_circle,
                      color: forwardAccent,
                      size: 18,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.currentTitle,
                      style: TextStyle(
                        color: forwardMissing ? Colors.redAccent : colors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (forwardMissing) ...[
                const SizedBox(height: 10),
                _buildErrorBlock(
                  colors,
                  reason: widget.forwardMissingReason!,
                  onRetry: widget.onRetryForward,
                  pressing: _pressingForward,
                  onPressChange: (v) => setState(() => _pressingForward = v),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBlock(
    dynamic colors, {
    required String reason,
    required VoidCallback? onRetry,
    required bool pressing,
    required ValueChanged<bool> onPressChange,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          reason == 'no_internet'
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
            onTapDown: (_) => onPressChange(true),
            onTapUp: (_) => onPressChange(false),
            onTapCancel: () => onPressChange(false),
            onTap: onRetry,
            child: AnimatedScale(
              scale: pressing ? 0.94 : 1.0,
              duration: const Duration(milliseconds: 90),
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
