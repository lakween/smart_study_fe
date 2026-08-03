import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/exams/presentation/widgets/exam_question_library_picker.dart';

const _questions = <Map<String, dynamic>>[
  {
    'id': 'question-1',
    'text': 'First database question',
    'subjectName': 'Computing',
    'topicName': 'Databases',
    'quizTitle': 'Database basics',
  },
  {
    'id': 'question-2',
    'text': 'Second database question',
    'subjectName': 'Computing',
    'topicName': 'Databases',
    'quizTitle': 'Database basics',
  },
  {
    'id': 'question-3',
    'text': 'A networking question',
    'subjectName': 'Computing',
    'topicName': 'Networks',
    'quizTitle': 'Network basics',
  },
];

void main() {
  testWidgets('separates selected quizzes from the available library',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: _PickerHarness(
            initialSelection: {'question-1', 'question-2'},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Selected quizzes'), findsOneWidget);
    expect(find.text('Available quiz library'), findsOneWidget);
    expect(find.text('1 quiz • 2 questions'), findsOneWidget);
    expect(find.text('Database basics'), findsOneWidget);
    expect(find.text('Network basics'), findsOneWidget);

    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();

    expect(
      find.text('Choose a whole quiz or add only the questions you want.'),
      findsOneWidget,
    );
    expect(find.text('3 questions ready to add'), findsOneWidget);
  });

  testWidgets(
      'disables additional questions when the friend-exam quota is full',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: _PickerHarness(
            initialSelection: {'question-1'},
            maxSelection: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('All 1 question slot is filled'), findsOneWidget);
    final addQuestion = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.add_circle_rounded).first,
    );
    expect(addQuestion.onPressed, isNull);

    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.remove_circle_rounded).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('0 of 1 selected • 1 slot remaining'), findsOneWidget);
    final enabledAddQuestion = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.add_circle_rounded).first,
    );
    expect(enabledAddQuestion.onPressed, isNotNull);
  });
}

class _PickerHarness extends StatefulWidget {
  final Set<String> initialSelection;
  final int? maxSelection;

  const _PickerHarness({
    required this.initialSelection,
    this.maxSelection,
  });

  @override
  State<_PickerHarness> createState() => _PickerHarnessState();
}

class _PickerHarnessState extends State<_PickerHarness> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.of(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    return ExamQuestionLibraryPicker(
      questions: _questions,
      selectedIds: _selected,
      maxSelection: widget.maxSelection,
      onSelectionChanged: (selection) {
        setState(() => _selected = Set.of(selection));
      },
    );
  }
}
