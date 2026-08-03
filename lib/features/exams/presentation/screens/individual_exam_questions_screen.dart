import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_message.dart';
import '../providers/exam_provider.dart';
import '../widgets/exam_question_library_picker.dart';

class IndividualExamQuestionsScreen extends ConsumerStatefulWidget {
  final String examId;

  const IndividualExamQuestionsScreen({super.key, required this.examId});

  @override
  ConsumerState<IndividualExamQuestionsScreen> createState() => _State();
}

class _State extends ConsumerState<IndividualExamQuestionsScreen> {
  List<Map<String, dynamic>> _questions = [];
  final Set<String> _selected = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows =
        await ref.read(examProvider.notifier).loadQuestionBank(widget.examId);
    if (!mounted) return;
    setState(() {
      _questions = rows ?? [];
      _selected
        ..clear()
        ..addAll(
          _questions
              .where((question) => question['selected'] == true)
              .map((question) => question['id'] as String),
        );
      _loading = false;
    });
  }

  Future<void> _save({bool publish = false}) async {
    if (_selected.isEmpty) {
      AppMessage.error(context, 'Select at least one question');
      return;
    }
    setState(() => _saving = true);
    final saved = await ref
        .read(examProvider.notifier)
        .saveQuestionSelection(widget.examId, _selected.toList());
    if (saved && publish) {
      final published = await ref
          .read(examProvider.notifier)
          .publishCollaborativeExam(widget.examId);
      if (published && mounted) {
        context.go('/exams/${widget.examId}');
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (!saved) {
      AppMessage.error(
        context,
        ref.read(examProvider).error ?? 'Could not save questions',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Build your exam')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(AppSpacing.pageGutter),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.premiumGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_selected.length} questions selected\n'
                          'Add whole quizzes or choose individual questions',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ExamQuestionLibraryPicker(
                    questions: _questions,
                    selectedIds: _selected,
                    onSelectionChanged: (selection) => setState(() {
                      _selected
                        ..clear()
                        ..addAll(selection);
                    }),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageGutter,
                      0,
                      AppSpacing.pageGutter,
                      110,
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => _save(),
                  child: const Text('Save draft'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : () => _save(publish: true),
                  icon: const Icon(Icons.rocket_launch_rounded),
                  label: const Text('Publish'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
