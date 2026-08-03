import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/question_model.dart';
import '../../../../shared/widgets/app_message.dart';
import '../providers/exam_provider.dart';
import '../widgets/exam_question_library_picker.dart';

class ExamContributionScreen extends ConsumerStatefulWidget {
  final String examId;

  const ExamContributionScreen({super.key, required this.examId});

  @override
  ConsumerState<ExamContributionScreen> createState() =>
      _ExamContributionScreenState();
}

class _QuestionDraft {
  final text = TextEditingController();
  final options = List.generate(4, (_) => TextEditingController());
  final explanation = TextEditingController();
  AnswerOption correct = AnswerOption.a;

  void dispose() {
    text.dispose();
    for (final controller in options) {
      controller.dispose();
    }
    explanation.dispose();
  }
}

class _ExamContributionScreenState
    extends ConsumerState<ExamContributionScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_QuestionDraft> _drafts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final exam = await ref
        .read(examProvider.notifier)
        .ensureExam(widget.examId, refresh: true);
    if (exam == null || !mounted) {
      setState(() => _loading = false);
      return;
    }
    final existing =
        await ref.read(examProvider.notifier).loadContributions(widget.examId);
    if (!mounted) return;
    final quota = exam.questionsPerParticipant ?? 0;
    for (var index = 0; index < quota; index++) {
      final draft = _QuestionDraft();
      if (existing != null && index < existing.length) {
        final question = existing[index];
        draft.text.text = question.text;
        draft.options[0].text = question.optionA;
        draft.options[1].text = question.optionB;
        draft.options[2].text = question.optionC;
        draft.options[3].text = question.optionD;
        draft.correct = question.correctAnswer;
        draft.explanation.text = question.explanation ?? '';
      }
      _drafts.add(draft);
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final questions = _drafts.map((draft) {
      return QuestionModel(
        id: '',
        text: draft.text.text.trim(),
        optionA: draft.options[0].text.trim(),
        optionB: draft.options[1].text.trim(),
        optionC: draft.options[2].text.trim(),
        optionD: draft.options[3].text.trim(),
        correctAnswer: draft.correct,
        explanation: draft.explanation.text.trim().isEmpty
            ? null
            : draft.explanation.text.trim(),
      );
    }).toList();
    final saved = await ref
        .read(examProvider.notifier)
        .submitContributions(widget.examId, questions);
    if (!mounted) return;
    if (saved) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Your private questions are ready'),
        backgroundColor: AppColors.success,
      ));
      context.pop();
    } else {
      AppMessage.error(
        context,
        ref.read(examProvider).error ?? 'Could not save questions',
      );
    }
  }

  Future<void> _importFromLibrary() async {
    final rows = await ref
        .read(examProvider.notifier)
        .loadContributionLibrary(widget.examId);
    if (!mounted || rows == null) return;
    if (rows.isEmpty) {
      AppMessage.error(context, 'Create a quiz first to import questions');
      return;
    }
    final chosen = <String>{};
    final imported = await showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SizedBox(
          height: MediaQuery.sizeOf(context).height * .92,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose from your quizzes',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Selected and available quizzes stay separate',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ExamQuestionLibraryPicker(
                  questions: rows,
                  selectedIds: chosen,
                  maxSelection: _drafts.length,
                  onSelectionChanged: (selection) => setSheetState(() {
                    chosen
                      ..clear()
                      ..addAll(selection);
                  }),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: FilledButton.icon(
                  onPressed: chosen.isEmpty
                      ? null
                      : () => Navigator.pop(
                            sheetContext,
                            rows
                                .where((row) =>
                                    chosen.contains(row['id'] as String))
                                .toList(),
                          ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                  ),
                  icon: const Icon(Icons.library_add_check_rounded),
                  label: Text(
                    chosen.isEmpty
                        ? 'Choose questions to import'
                        : 'Import ${chosen.length} of ${_drafts.length} questions',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (imported == null || !mounted) return;
    setState(() {
      for (var i = 0; i < imported.length; i++) {
        final q = imported[i], draft = _drafts[i];
        draft.text.text = q['text'] as String;
        draft.options[0].text = q['optionA'] as String;
        draft.options[1].text = q['optionB'] as String;
        draft.options[2].text = q['optionC'] as String;
        draft.options[3].text = q['optionD'] as String;
        draft.correct =
            AnswerOptionExt.fromString(q['correctAnswer'] as String);
        draft.explanation.text = q['explanation'] as String? ?? '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(examByIdProvider(widget.examId));
    final saving = ref.watch(examProvider).isActionLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Build your question set')),
      body: _loading || exam == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: AppSpacing.form,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF7C4DFF)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lock_rounded,
                              color: Colors.white, size: 28),
                          const SizedBox(height: 12),
                          Text(
                            '${_drafts.length} private questions',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Only you can see these before the exam. Similar questions are rejected without revealing anyone else\'s work.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if ((exam.contributionInstructions ?? '').isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: .09),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: .25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline_rounded,
                                color: AppColors.accent),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(exam.contributionInstructions!)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: saving ? null : _importFromLibrary,
                      icon: const Icon(Icons.library_add_rounded),
                      label: const Text('Import questions from my quizzes'),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52)),
                    ),
                    const SizedBox(height: 16),
                    ..._drafts.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _QuestionCard(
                            number: entry.key + 1,
                            draft: entry.value,
                            onCorrectChanged: (value) =>
                                setState(() => entry.value.correct = value),
                          ),
                        )),
                    FilledButton.icon(
                      onPressed: saving ? null : _submit,
                      icon: const Icon(Icons.verified_rounded),
                      label: Text(
                          saving ? 'Checking questions…' : 'Submit privately'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int number;
  final _QuestionDraft draft;
  final ValueChanged<AnswerOption> onCorrectChanged;

  const _QuestionCard({
    required this.number,
    required this.draft,
    required this.onCorrectChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: .12),
              child: Text('$number',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  )),
            ),
            const SizedBox(width: 10),
            Text('Question $number',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 16),
          TextFormField(
            controller: draft.text,
            minLines: 2,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Question',
              hintText: 'Write one clear, unique question',
              alignLabelWithHint: true,
            ),
            validator: (value) => (value?.trim().length ?? 0) < 3
                ? 'Enter a complete question'
                : null,
          ),
          RadioGroup<AnswerOption>(
            groupValue: draft.correct,
            onChanged: (value) {
              if (value != null) onCorrectChanged(value);
            },
            child: Column(
              children: List.generate(4, (index) {
                final answer = AnswerOption.values[index];
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextFormField(
                    controller: draft.options[index],
                    decoration: InputDecoration(
                      labelText: 'Option ${answer.label}',
                      prefixIcon: Radio<AnswerOption>(value: answer),
                      suffixIcon: draft.correct == answer
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.success)
                          : null,
                    ),
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? 'Option ${answer.label} is required'
                        : null,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: draft.explanation,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Explanation (optional)',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
