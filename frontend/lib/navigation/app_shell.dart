import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/advanced_workspaces/advanced_stem_workspaces_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/placeholder/feature_placeholder_screen.dart';
import '../shared/widgets/cyber_background.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  void _openSection(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showRail = constraints.maxWidth >= 860;
        final pages = [
          DashboardScreen(onOpenSection: _openSection),
          const AdvancedStemWorkspacesScreen(),
          const FeaturePlaceholderScreen(
            title: 'AR Simulation',
            message:
                'AR scene controls and camera logic are intentionally not built yet.',
            icon: Icons.view_in_ar_outlined,
            accent: AppColors.pink,
          ),
          const FeaturePlaceholderScreen(
            title: 'Progress Tracker',
            message:
                'Learner analytics and misconception history will be connected later.',
            icon: Icons.insights_outlined,
            accent: AppColors.lime,
          ),
        ];

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'logout') {
                            await authProvider.logout();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Logged out successfully'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            enabled: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  authProvider.currentUser?.fullName ?? 'User',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  authProvider.currentUser?.email ?? '',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout),
                                SizedBox(width: 8),
                                Text('Logout'),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.glass,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.cyan.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [AppColors.cyan, AppColors.pink],
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.person,
                                    size: 18,
                                    color: AppColors.backgroundTop,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_drop_down,
                                size: 20,
                                color: AppColors.cyan,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: CyberBackground(
            child: Row(
              children: [
                if (showRail)
                  _CyberNavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _openSection,
                  ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: KeyedSubtree(
                      key: ValueKey(_selectedIndex),
                      child: pages[_selectedIndex],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: showRail
              ? null
              : BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: _openSection,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard_outlined),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.science_outlined),
                      label: 'Labs',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.view_in_ar_outlined),
                      label: 'AR',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.insights_outlined),
                      label: 'Progress',
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _CyberNavigationRail extends StatelessWidget {
  const _CyberNavigationRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.12),
            blurRadius: 28,
          ),
        ],
      ),
      child: NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        labelType: NavigationRailLabelType.all,
        leading: const Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Icon(Icons.auto_awesome, color: AppColors.pink),
        ),
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: Text('Home'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.science_outlined),
            selectedIcon: Icon(Icons.science),
            label: Text('Labs'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.view_in_ar_outlined),
            selectedIcon: Icon(Icons.view_in_ar),
            label: Text('AR'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: Text('Progress'),
          ),
        ],
      ),
    );
  }
}
