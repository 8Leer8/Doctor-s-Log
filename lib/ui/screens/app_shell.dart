import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'library_screen.dart';
import 'history_screen.dart';
import 'operators_screen.dart';
import 'settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _tabs = const [
    _TabItem('LIBRARY', Icons.menu_book_outlined),
    _TabItem('HISTORY', Icons.history),
    _TabItem('OPERATORS', Icons.groups_outlined),
    _TabItem('SETTINGS', Icons.settings_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          // Swiping left/right animates between tabs automatically,
          // including Library <-> History since they're adjacent.
          children: const [
            LibraryScreen(),
            HistoryScreen(),
            OperatorsScreen(),
            SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _AngularNavBar(
        tabController: _tabController,
        tabs: _tabs,
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  const _TabItem(this.label, this.icon);
}

class _AngularNavBar extends StatelessWidget {
  final TabController tabController;
  final List<_TabItem> tabs;

  const _AngularNavBar({required this.tabController, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: AnimatedBuilder(
        animation: tabController,
        builder: (context, _) {
          return Row(
            children: List.generate(tabs.length, (index) {
              final selected = tabController.index == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => tabController.animateTo(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 4),
                    child: ClipPath(
                      clipper: CutCornerClipper(cut: 8),
                      child: Container(
                        color: selected
                            ? AppColors.amber.withValues(alpha: 0.12)
                            : Colors.transparent,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              tabs[index].icon,
                              size: 20,
                              color: selected
                                  ? AppColors.amber
                                  : AppColors.coldGray,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tabs[index].label,
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? AppColors.amber
                                    : AppColors.coldGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}