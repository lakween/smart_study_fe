import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/shared/models/subject_model.dart';
import 'package:my_app/shared/models/user_model.dart';
import 'package:my_app/shared/widgets/subject_card.dart';

void main() {
  testWidgets('subject card uses compact intrinsic height without overflow',
      (tester) async {
    final subject = SubjectModel(
      id: 'subject-1',
      name: 'Database Management Systems (Copy)',
      description:
          'Relational databases, SQL, normalization, transactions, and NoSQL databases.',
      visibility: ContentVisibility.private,
      allowCopy: false,
      ownerId: 'owner-1',
      originalCreatorName: 'Alex Johnson',
      topicCount: 1,
      quizCount: 1,
      avgScore: 0,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: SubjectCard(subject: subject),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(SubjectCard)).height, lessThan(278));
    expect(find.text('Originally by Alex Johnson'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
