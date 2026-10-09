import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// The ONE top bar of the home page, hosted by AppShell and shared by the
/// Library / History / Operators / Settings tabs. Cross-fades between
/// whatever [child] it is given (a title row, or the Library search field).
class HomeTopBar extends StatelessWidget {
  final Widget child;

  const HomeTopBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      height: statusBarHeight + 52,
      padding: EdgeInsets.only(top: statusBarHeight),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: child,
      ),
    );
  }
}

/// Default contents of [HomeTopBar]: a tab title plus optional action buttons.
/// Give it a unique `key` per tab so the title cross-fades when tabs change.
class HomeTitleRow extends StatelessWidget {
  final String title;
  final List<Widget> actions;

  const HomeTitleRow({
    super.key,
    required this.title,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          ...actions,
        ],
      ),
    );
  }
}
