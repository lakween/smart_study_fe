import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/features/auth/presentation/screens/shell_screen.dart';
import 'package:my_app/shared/widgets/app_bottom_nav.dart';

void main() {
  const cases = <({String location, String route, int tab})>[
    (location: '/quizzes', route: '/quizzes', tab: 1),
    (location: '/notifications', route: '/notifications', tab: 0),
    (location: '/subjects/subject-1', route: '/subjects/:subjectId', tab: 1),
    (
      location: '/subjects/subject-1/topics/topic-1',
      route: '/subjects/:subjectId/topics/:topicId',
      tab: 1,
    ),
    (
      location: '/documents/document-1/view',
      route: '/documents/:documentId/view',
      tab: 1,
    ),
    (
      location: '/quizzes/quiz-1/result/attempt-1',
      route: '/quizzes/:quizId/result/:attemptId',
      tab: 1,
    ),
    (location: '/exams/exam-1', route: '/exams/:examId', tab: 2),
    (location: '/friends/find', route: '/friends/find', tab: 3),
    (location: '/messages', route: '/messages', tab: 3),
    (
      location: '/messages/user-1',
      route: '/messages/:friendId',
      tab: 3,
    ),
    (
      location: '/users/user-1/profile',
      route: '/users/:userId/profile',
      tab: 3
    ),
    (location: '/settings', route: '/settings', tab: 4),
  ];

  for (final testCase in cases) {
    testWidgets('${testCase.location} keeps the expected dock tab',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: testCase.location,
        routes: [
          ShellRoute(
            builder: (_, __, child) => ShellScreen(child: child),
            routes: [
              GoRoute(
                path: testCase.route,
                builder: (_, __) => const SizedBox(),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.byType(AppBottomNav), findsOneWidget);
      expect(
        tester.widget<AppBottomNav>(find.byType(AppBottomNav)).currentIndex,
        testCase.tab,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('back from a main tab redirects to Home', (tester) async {
    final router = GoRouter(
      initialLocation: '/home/subjects',
      routes: [
        ShellRoute(
          builder: (_, __, child) => ShellScreen(child: child),
          routes: [
            GoRoute(
              path: '/home/dashboard',
              builder: (_, __) => const Text('Home screen'),
            ),
            GoRoute(
              path: '/home/subjects',
              builder: (_, __) => const Text('Subjects screen'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Home screen'), findsOneWidget);
    expect(find.byType(AppBottomNav), findsOneWidget);
  });

  testWidgets('back from a directly opened drill-down redirects to Home',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/quizzes',
      routes: [
        ShellRoute(
          builder: (_, __, child) => ShellScreen(child: child),
          routes: [
            GoRoute(
              path: '/home/dashboard',
              builder: (_, __) => const Text('Home screen'),
            ),
            GoRoute(
              path: '/quizzes',
              builder: (_, __) => const Text('Quiz list'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Home screen'), findsOneWidget);
  });

  testWidgets('back from a pushed drill-down returns to its previous screen',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/home/subjects',
      routes: [
        ShellRoute(
          builder: (_, __, child) => ShellScreen(child: child),
          routes: [
            GoRoute(
              path: '/home/subjects',
              builder: (_, __) => const Text('Subjects screen'),
            ),
            GoRoute(
              path: '/subjects/:subjectId',
              builder: (_, __) => const Text('Subject details'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    router.push('/subjects/subject-1');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Subjects screen'), findsOneWidget);
  });
}
