import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:worship_manager/features/settings/presentation/settings_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/services/presentation/services_list_screen.dart';
import '../../features/songs/presentation/songs_screen.dart';
import '../theme/app_theme.dart';
import '../theme/glass_widgets.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    SongsScreen(),
    ServicesListScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Menor a 640px es móvil; mayor o igual es Desktop/Tablet
        final isDesktop = constraints.maxWidth >= 640;

        if (isDesktop) {
          // Disposición Desktop con Glassmorfismo
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: GlassBackground(
              child: Row(
                children: [
                  ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.75),
                          border: const Border(
                            right: BorderSide(
                              color: AppColors.glassBorder,
                              width: 1,
                            ),
                          ),
                        ),
                        child: NavigationRail(
                          backgroundColor: Colors.transparent,
                          selectedIndex: _currentIndex,
                          onDestinationSelected: (index) =>
                              setState(() => _currentIndex = index),
                          labelType: NavigationRailLabelType.all,
                          leading: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: GlassBadge(
                              glowColor: AppColors.primary,
                              size: 48,
                              child: const Icon(
                                Icons.queue_music,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          destinations: const [
                            NavigationRailDestination(
                              icon: Icon(Icons.library_music_outlined),
                              selectedIcon: Icon(Icons.library_music),
                              label: Text('Repertorio'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.church_outlined),
                              selectedIcon: Icon(Icons.church),
                              label: Text('Cultos'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.insights_outlined),
                              selectedIcon: Icon(Icons.insights),
                              label: Text('Métricas'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.settings_outlined),
                              selectedIcon: Icon(Icons.settings),
                              label: Text('Ajustes'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: IndexedStack(index: _currentIndex, children: _pages),
                  ),
                ],
              ),
            ),
          );
        }

        // Disposición Móvil con Glassmorfismo
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: GlassBackground(
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),
          bottomNavigationBar: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.8),
                  border: const Border(
                    top: BorderSide(
                      color: AppColors.glassBorder,
                      width: 1,
                    ),
                  ),
                ),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _currentIndex = index),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.library_music_outlined),
                      selectedIcon: Icon(Icons.library_music),
                      label: 'Repertorio',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.church_outlined),
                      selectedIcon: Icon(Icons.church),
                      label: 'Cultos',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.insights_outlined),
                      selectedIcon: Icon(Icons.insights),
                      label: 'Métricas',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: 'Ajustes',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
