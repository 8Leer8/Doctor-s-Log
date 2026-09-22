import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ContinueButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool collapsed;

  static const Duration _kDuration = Duration(milliseconds: 260);
  static const Curve _kCurve = Curves.easeInOutCubic;
  static const double _kExpandedWidth = 134.0;
  static const double _kCollapsedWidth = 52.0;
  static const double _kHeight = 56.0;
  static const double _kIconSize = 20.0;
  static const double _kIconLeftExpanded = 16.0;
  static const double _kTextLeftExpanded = 44.0;
  static const double _kTextLeftCollapsed = 60.0;

  const ContinueButton({
    super.key,
    required this.onPressed,
    required this.collapsed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: CutCornerClipper(cut: 10),
      child: Material(
        color: AppColors.amber,
        child: InkWell(
          onTap: onPressed,
          child: ClipRect(
            child: AnimatedContainer(
              duration: _kDuration,
              curve: _kCurve,
              width: collapsed ? _kCollapsedWidth : _kExpandedWidth,
              height: _kHeight,
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: _kDuration,
                    curve: _kCurve,
                    left: collapsed
                        ? (_kCollapsedWidth - _kIconSize) / 2
                        : _kIconLeftExpanded,
                    top: (_kHeight - _kIconSize) / 2,
                    child: const Icon(
                      Icons.play_arrow,
                      size: _kIconSize,
                      color: Colors.black,
                    ),
                  ),
                  AnimatedPositioned(
                    duration: _kDuration,
                    curve: _kCurve,
                    left: collapsed ? _kTextLeftCollapsed : _kTextLeftExpanded,
                    top: 0,
                    bottom: 0,
                    child: AnimatedOpacity(
                      duration: _kDuration,
                      curve: _kCurve,
                      opacity: collapsed ? 0.0 : 1.0,
                      child: const Center(
                        child: Text(
                          'CONTINUE',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
