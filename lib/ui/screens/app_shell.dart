import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../controllers/library_search_controller.dart';
import '../widgets/common/home_top_bar.dart';
import '../widgets/library/library_search_bar.dart';
import 'history_screen.dart';
import 'library_screen.dart';
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
  final _search = LibrarySearchController();

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
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _search.dispose();
    super.dispose();
  }

  /// Search only exists on the Library tab; leaving it closes search.
  void _onTabChanged() {
    if (_tabController.index != 0 && _search.searching) _search.close();
  }

  List<Widget> _actionsFor(int tabIndex) {
    if (tabIndex != 0) return const [];
    return [
      IconButton(
        icon: const Icon(Icons.search, color: AppColors.coldGray, size: 22),
        onPressed: _search.open,
      ),
      IconButton(
        icon: const Icon(Icons.tune, color: AppColors.coldGray, size: 20),
        onPressed: () {},
      ),
    ];
  }

  Widget _buildTopBarContent() {
    final index = _tabController.index;

    if (index == 0 && _search.searching) {
      return LibrarySearchBar(
        key: const ValueKey('library-search'),
        controller: _search.text,
        focusNode: _search.focus,
        ghost: _search.ghost,
        hints: _search.hints,
        onClose: _search.close,
        onAcceptGhost: _search.acceptGhost,
      );
    }

    return HomeTitleRow(
      key: ValueKey(_tabs[index].label),
      title: _tabs[index].label,
      actions: _actionsFor(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _search,
      // Android back closes search first instead of leaving the app.
      builder: (context, child) => PopScope(
        canPop: !_search.searching,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _search.close();
        },
        child: child!,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              ListenableBuilder(
                listenable: Listenable.merge([_tabController, _search]),
                builder: (context, _) =>
                    HomeTopBar(child: _buildTopBarContent()),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  // Swiping left/right animates between tabs automatically,
                  // including Library <-> History since they're adjacent.
                  children: [
                    LibraryScreen(search: _search),
                    const HistoryScreen(),
                    const OperatorsScreen(),
                    const SettingsScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _AngularNavBar(
          tabController: _tabController,
          tabs: _tabs,
        ),
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
                      vertical: 8,
                      horizontal: 4,
                    ),
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
