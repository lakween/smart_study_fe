import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/features/auth/presentation/screens/shell_screen.dart';
import 'package:my_app/shared/widgets/app_bottom_nav.dart';

void main() {
  testWidgets('exam detail keeps the dock with Exams selected', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/exams/exam-1',
      routes: [
        ShellRoute(
          builder: (_, __, child) => ShellScreen(child: child),
          routes: [
            GoRoute(
              path: '/home/exams',
              builder: (_, __) => const SizedBox(),
            ),
            GoRoute(
              path: '/exams/:examId',
              builder: (_, __) => const Center(child: Text('Exam details')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Exam details'), findsOneWidget);
    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(
        tester.widget<AppBottomNav>(find.byType(AppBottomNav)).currentIndex, 2);
    expect(find.bySemanticsLabel('Exams tab'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('focused exam routes stay outside the dock', (tester) async {
    final router = GoRouter(
      initialLocation: '/exams/exam-1/contribute',
      routes: [
        ShellRoute(
          builder: (_, __, child) => ShellScreen(child: child),
          routes: [
            GoRoute(
              path: '/exams/:examId',
              builder: (_, __) => const Text('Exam details'),
            ),
          ],
        ),
        GoRoute(
          path: '/exams/:examId/contribute',
          builder: (_, __) => const Text('Focused contribution'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Focused contribution'), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
