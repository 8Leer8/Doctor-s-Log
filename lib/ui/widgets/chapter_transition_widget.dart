import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/reader_settings.dart';

class ChapterTransitionWidget extends StatelessWidget {
  final String? previousTitle;
  final String currentTitle;
  final ReaderSettings settings;

  /// When non-null, this part failed to load.
  /// Values: 'no_internet' | 'unknown'.
  final String? missingReason;

  /// Optional retry callback. Only shown when [missingReason] is set.
  final VoidCallback? onRetry;

  const ChapterTransitionWidget({
    super.key,
    required this.previousTitle,
    required this.currentTitle,
    required this.settings,
    this.missingReason,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = settings.colors;
    final isMissing = missingReason != null;

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
              color: isMissing
                  ? Colors.redAccent.withValues(alpha: 0.4)
                  : colors.secondaryText.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (previousTitle != null) ...[
                Text(
                  'PREVIOUS',
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: colors.secondaryText,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      previousTitle!,
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
                  color: isMissing ? Colors.redAccent : colors.accent,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    isMissing ? Icons.cloud_off_rounded : Icons.play_circle,
                    color: isMissing ? Colors.redAccent : colors.accent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentTitle,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (isMissing) ...[
                const SizedBox(height: 10),
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
                    onTap: onRetry,
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
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
