import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  static const _routes = [
    '/home/dashboard',
    '/home/subjects',
    '/home/exams',
    '/home/friends',
    '/home/profile',
  ];

  int _locationToIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/subjects/') ||
        location.startsWith('/documents/') ||
        location.startsWith('/quizzes')) {
      return 1;
    }
    if (location.startsWith('/exams/')) return 2;
    if (location.startsWith('/friends/') || location.startsWith('/users/')) {
      return 3;
    }
    if (location.startsWith('/settings')) return 4;
    for (int i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(context);
    final hasPreviousRoute = Navigator.of(context).canPop();
    final isHome = location == _routes.first;
    return PopScope(
      canPop: hasPreviousRoute || isHome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(_routes.first);
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: AppBottomNav(
          currentIndex: currentIndex,
          onTap: (i) => context.go(_routes[i]),
        ),
      ),
    );
  }
}
