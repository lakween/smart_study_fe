import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/shared/widgets/app_bottom_nav.dart';

void main() {
  testWidgets('bottom dock stays compact and keeps all destinations accessible',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(
            currentIndex: 1,
            onTap: (_) {},
          ),
        ),
      ),
    );

    final height = tester.getSize(find.byType(AppBottomNav)).height;
    expect(height, greaterThanOrEqualTo(48));
    expect(height, lessThan(70));
    expect(find.bySemanticsLabel('Home tab'), findsOneWidget);
    expect(find.bySemanticsLabel('Subjects tab'), findsOneWidget);
    expect(find.bySemanticsLabel('Exams tab'), findsOneWidget);
    expect(find.bySemanticsLabel('Friends tab'), findsOneWidget);
    expect(find.bySemanticsLabel('Profile tab'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
