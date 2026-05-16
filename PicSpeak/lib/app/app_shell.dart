import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<_NavDestination> _destinations = const [
    _NavDestination(
      label: 'Cámara',
      icon: Icons.camera_alt,
      path: '/',
    ),
    _NavDestination(
      label: 'Favoritos',
      icon: Icons.favorite,
      path: '/favorites',
    ),
    _NavDestination(
      label: 'Historial',
      icon: Icons.history,
      path: '/history',
    ),
    _NavDestination(
      label: 'Configuración',
      icon: Icons.settings,
      path: '/settings',
    ),
  ];

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final location = GoRouterState.of(context).matchedLocation;
    _currentIndex = _destinations.indexWhere((d) => d.path == location);
    if (_currentIndex < 0) _currentIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    _currentIndex = _destinations.indexWhere((d) => d.path == location);
    if (_currentIndex < 0) _currentIndex = 0;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          final destination = _destinations[index];
          context.go(destination.path);
        },
        destinations: _destinations.map((d) {
          return NavigationDestination(
            icon: Icon(d.icon),
            label: d.label,
          );
        }).toList(),
      ),
    );
  }
}

class _NavDestination {
  final String label;
  final IconData icon;
  final String path;

  const _NavDestination({
    required this.label,
    required this.icon,
    required this.path,
  });
}
