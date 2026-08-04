import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/exam_model.dart';
import '../../../../shared/models/question_model.dart';
import '../../../../shared/widgets/app_message.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/error_state.dart';
import '../providers/exam_provider.dart';
import '../widgets/exam_question_library_picker.dart';

class ExamContributionScreen extends ConsumerStatefulWidget {
  final String examId;

  const ExamContributionScreen({super.key, required this.examId});

  @override
  ConsumerState<ExamContributionScreen> createState() =>
      _ExamContributionScreenState();
}

enum _ContributionMode { library, manual }

class _QuestionDraft {
  final text = TextEditingController();
  final options = List.generate(4, (_) => TextEditingController());
  final explanation = TextEditingController();
  AnswerOption correct = AnswerOption.a;
  String? sourceQuestionId;

  bool get isEmpty =>
      text.text.trim().isEmpty &&
      options.every((controller) => controller.text.trim().isEmpty) &&
      explanation.text.trim().isEmpty;

  bool get isComplete =>
      text.text.trim().length >= 3 &&
      options.every((controller) => controller.text.trim().isNotEmpty) &&
      _normalizedOptions.length == 4;

  Set<String> get _normalizedOptions => options
      .map((controller) => controller.text.trim().toLowerCase())
      .where((value) => value.isNotEmpty)
      .toSet();

  void fillFromQuestion(QuestionModel question) {
    sourceQuestionId = null;
    text.text = question.text;
    options[0].text = question.optionA;
    options[1].text = question.optionB;
    options[2].text = question.optionC;
    options[3].text = question.optionD;
    correct = question.correctAnswer;
    explanation.text = question.explanation ?? '';
  }

  void fillFromLibrary(Map<String, dynamic> question) {
    sourceQuestionId = question['id'] as String?;
    text.text = question['text'] as String? ?? '';
    options[0].text = question['optionA'] as String? ?? '';
    options[1].text = question['optionB'] as String? ?? '';
    options[2].text = question['optionC'] as String? ?? '';
    options[3].text = question['optionD'] as String? ?? '';
    correct = AnswerOptionExt.fromString(
      question['correctAnswer'] as String? ?? 'A',
    );
    explanation.text = question['explanation'] as String? ?? '';
  }

  void clear() {
    sourceQuestionId = null;
    text.clear();
    for (final controller in options) {
      controller.clear();
    }
    explanation.clear();
    correct = AnswerOption.a;
  }

  QuestionModel toModel() => QuestionModel(
        id: '',
        text: text.text.trim(),
        optionA: options[0].text.trim(),
        optionB: options[1].text.trim(),
        optionC: options[2].text.trim(),
        optionD: options[3].text.trim(),
        correctAnswer: correct,
        explanation:
            explanation.text.trim().isEmpty ? null : explanation.text.trim(),
      );

  String get fingerprint => [
        text.text,
        ...options.map((controller) => controller.text),
        correct.label,
        explanation.text,
      ].join('\u0000');

  void dispose() {
    text.dispose();
    for (final controller in options) {
      controller.dispose();
    }
    explanation.dispose();
  }
}

class _DraftIssue {
  final int index;
  final String message;

  const _DraftIssue(this.index, this.message);
}

class _ExamContributionScreenState
    extends ConsumerState<ExamContributionScreen> {
  final List<_QuestionDraft> _drafts = [];
  List<Map<String, dynamic>> _library = [];
  final Set<String> _librarySelection = {};
  _ContributionMode _mode = _ContributionMode.library;
  bool _loading = true;
  bool _libraryLoading = false;
  bool _attemptedSubmit = false;
  int _expandedQuestion = 0;
  String? _loadError;
  String? _libraryError;
  String _baseline = '';
  Set<String> _baselineSelection = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _libraryError = null;
    });
    final notifier = ref.read(examProvider.notifier);
    final exam = await notifier.ensureExam(widget.examId, refresh: true);
    if (!mounted) return;
    if (exam == null) {
      setState(() {
        _loading = false;
        _loadError =
            ref.read(examProvider).error ?? 'Could not load this friend exam';
      });
      return;
    }

    final existing = await notifier.loadContributions(widget.examId);
    if (!mounted) return;
    if (existing == null) {
      setState(() {
        _loading = false;
        _loadError = ref.read(examProvider).error ??
            'Could not load your private questions';
      });
      return;
    }

    final library = await notifier.loadContributionLibrary(widget.examId);
    if (!mounted) return;
    final quota = exam.questionsPerParticipant ?? 0;
    if (quota < 1) {
      setState(() {
        _loading = false;
        _loadError = 'This exam does not have a question quota';
      });
      return;
    }

    for (final draft in _drafts) {
      draft.dispose();
    }
    _drafts
      ..clear()
      ..addAll(List.generate(quota, (_) => _QuestionDraft()));
    for (var index = 0;
        index < existing.length && index < _drafts.length;
        index++) {
      _drafts[index].fillFromQuestion(existing[index]);
    }

    final savedRows = existing.asMap().entries.map((entry) {
      final question = entry.value;
      return <String, dynamic>{
        'id': '__saved_${entry.key}',
        'text': question.text,
        'optionA': question.optionA,
        'optionB': question.optionB,
        'optionC': question.optionC,
        'optionD': question.optionD,
        'correctAnswer': question.correctAnswer.label,
        'explanation': question.explanation,
        'subjectName': 'Private contribution',
        'topicName': 'Saved questions',
        'quizTitle': 'Current private questions',
      };
    }).toList();

    setState(() {
      _library = [...savedRows, ...?library];
      _librarySelection
        ..clear()
        ..addAll(savedRows.map((row) => row['id'] as String));
      _libraryError = library == null && savedRows.isEmpty
          ? ref.read(examProvider).error ?? 'Could not load your quiz library'
          : null;
      _mode = _ContributionMode.library;
      _expandedQuestion = 0;
      _baseline = _draftFingerprint;
      _baselineSelection = Set.of(_librarySelection);
      _loading = false;
    });
  }

  Future<void> _retryLibrary() async {
    setState(() {
      _libraryLoading = true;
      _libraryError = null;
    });
    final rows = await ref
        .read(examProvider.notifier)
        .loadContributionLibrary(widget.examId);
    if (!mounted) return;
    final savedRows = _library.where(
      (row) => (row['id'] as String? ?? '').startsWith('__saved_'),
    );
    setState(() {
      _libraryLoading = false;
      _library = [...savedRows, ...?rows];
      _libraryError = rows == null && savedRows.isEmpty
          ? ref.read(examProvider).error ?? 'Could not load your quiz library'
          : null;
    });
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  int get _quota => _drafts.length;
  int get _readyCount => _drafts.where((draft) => draft.isComplete).length;
  String get _draftFingerprint =>
      _drafts.map((draft) => draft.fingerprint).join('\u0001');
  bool get _hasUnsavedChanges =>
      !_sameSelection(_librarySelection, _baselineSelection) ||
      _draftFingerprint != _baseline;

  bool _sameSelection(Set<String> first, Set<String> second) =>
      first.length == second.length && first.containsAll(second);

  String _normalizedQuestion(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  _DraftIssue? _firstIssue() {
    final questions = <String, int>{};
    for (var index = 0; index < _drafts.length; index++) {
      final draft = _drafts[index];
      final number = index + 1;
      if (draft.text.text.trim().length < 3) {
        return _DraftIssue(
            index, 'Complete question $number before submitting');
      }
      if (draft.options.any((option) => option.text.trim().isEmpty)) {
        return _DraftIssue(index, 'Add all four answers for question $number');
      }
      if (draft._normalizedOptions.length != 4) {
        return _DraftIssue(
          index,
          'Use four different answers for question $number',
        );
      }
      final normalized = _normalizedQuestion(draft.text.text);
      final duplicate = questions[normalized];
      if (duplicate != null) {
        return _DraftIssue(
          index,
          'Questions ${duplicate + 1} and $number are duplicates',
        );
      }
      questions[normalized] = index;
    }
    return null;
  }

  List<Map<String, dynamic>> get _selectedRows => _library
      .where((row) => _librarySelection.contains(row['id'] as String?))
      .toList();

  QuestionModel _questionFromRow(Map<String, dynamic> row) => QuestionModel(
        id: '',
        text: row['text'] as String? ?? '',
        optionA: row['optionA'] as String? ?? '',
        optionB: row['optionB'] as String? ?? '',
        optionC: row['optionC'] as String? ?? '',
        optionD: row['optionD'] as String? ?? '',
        correctAnswer: AnswerOptionExt.fromString(
          row['correctAnswer'] as String? ?? 'A',
        ),
        explanation: row['explanation'] as String?,
      );

  String? _selectedQuestionIssue(List<QuestionModel> questions) {
    final seen = <String>{};
    for (var index = 0; index < questions.length; index++) {
      final question = questions[index];
      final number = index + 1;
      final rawOptions = [
        question.optionA,
        question.optionB,
        question.optionC,
        question.optionD,
      ];
      final options =
          rawOptions.map((value) => value.trim().toLowerCase()).toSet();
      if (question.text.trim().length < 3 ||
          rawOptions.any((value) => value.trim().isEmpty) ||
          options.length != 4) {
        return 'Question $number needs one clear question and four different answers';
      }
      if (!seen.add(_normalizedQuestion(question.text))) {
        return 'Your selection contains duplicate questions';
      }
    }
    return null;
  }

  void _openManualEditor() {
    final selectedRows = _selectedRows;

    setState(() {
      for (final draft in _drafts) {
        draft.clear();
      }
      for (var index = 0;
          index < selectedRows.length && index < _drafts.length;
          index++) {
        _drafts[index].fillFromLibrary(selectedRows[index]);
      }
      _mode = _ContributionMode.manual;
      _expandedQuestion = _drafts.indexWhere((draft) => !draft.isComplete);
      if (_expandedQuestion < 0) _expandedQuestion = -1;
      _attemptedSubmit = false;
    });
  }

  Future<void> _submitSelected() async {
    if (_librarySelection.length != _quota) {
      AppMessage.error(
        context,
        'Select exactly $_quota questions before submitting',
      );
      return;
    }
    final questions = _selectedRows.map(_questionFromRow).toList();
    final issue = _selectedQuestionIssue(questions);
    if (issue != null) {
      AppMessage.error(context, issue);
      return;
    }
    await _saveQuestions(questions);
  }

  Future<void> _submitManual() async {
    setState(() => _attemptedSubmit = true);
    final issue = _firstIssue();
    if (issue != null) {
      setState(() => _expandedQuestion = issue.index);
      AppMessage.error(context, issue.message);
      return;
    }
    await _saveQuestions(_drafts.map((draft) => draft.toModel()).toList());
  }

  Future<void> _saveQuestions(List<QuestionModel> questions) async {
    final saved = await ref.read(examProvider.notifier).submitContributions(
          widget.examId,
          questions,
        );
    if (!mounted) return;
    if (!saved) {
      AppMessage.error(
        context,
        ref.read(examProvider).error ?? 'Could not save questions',
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your private questions are ready'),
        backgroundColor: AppColors.success,
      ),
    );
    context.go('/exams/${widget.examId}');
  }

  Future<void> _requestExit() async {
    if (!_hasUnsavedChanges) {
      context.go('/exams/${widget.examId}');
      return;
    }
    final leave = await ConfirmDialog.show(
      context,
      title: 'Leave question builder?',
      message:
          'Changes on this screen have not been submitted. Your last private submission will stay unchanged.',
      confirmLabel: 'Discard changes',
      isDestructive: true,
    );
    if (leave == true && mounted) {
      context.go('/exams/${widget.examId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(examByIdProvider(widget.examId));
    final saving = ref.watch(examProvider).isActionLoading;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestExit();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: 'Close',
            onPressed: _requestExit,
            icon: const Icon(Icons.close_rounded),
          ),
          title: Text(
            _mode == _ContributionMode.library
                ? 'Choose questions'
                : 'Write new questions',
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null || exam == null
                ? ErrorState(
                    message: _loadError ?? 'Could not load this friend exam',
                    onRetry: _load,
                  )
                : _mode == _ContributionMode.library
                    ? _buildLibrary(exam)
                    : _buildManualEditor(exam),
        bottomNavigationBar: _loading || _loadError != null || exam == null
            ? null
            : _buildBottomBar(saving),
      ),
    );
  }

  Widget _buildLibrary(ExamModel exam) {
    final selected = _librarySelection.length;
    final remaining = (_quota - selected).clamp(0, _quota);
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageGutter,
              12,
              AppSpacing.pageGutter,
              10,
            ),
            child: Column(
              children: [
                _ContributionHero(
                  icon: Icons.lock_rounded,
                  title: '$selected of $_quota selected',
                  message: selected == 0
                      ? 'Choose whole quizzes or only the questions you want.'
                      : remaining == 0
                          ? 'Ready to submit privately. Only your questions are visible to you before publishing.'
                          : 'Choose $remaining more ${remaining == 1 ? 'question' : 'questions'} to fill your quota.',
                ),
                if ((exam.contributionInstructions ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _InstructionsCard(text: exam.contributionInstructions!),
                ],
              ],
            ),
          ),
          Expanded(
            child: _libraryLoading
                ? const Center(child: CircularProgressIndicator())
                : _libraryError != null
                    ? ErrorState(
                        message: _libraryError!,
                        onRetry: _retryLibrary,
                      )
                    : ExamQuestionLibraryPicker(
                        questions: _library,
                        selectedIds: _librarySelection,
                        maxSelection: _quota,
                        onSelectionChanged: (selection) => setState(() {
                          _librarySelection
                            ..clear()
                            ..addAll(selection);
                        }),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pageGutter,
                          0,
                          AppSpacing.pageGutter,
                          24,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEditor(ExamModel exam) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: AppSpacing.form,
        children: [
          _ContributionHero(
            icon: Icons.edit_note_rounded,
            title: 'Write or edit $_quota questions',
            message: _readyCount == _quota
                ? 'Everything is ready. You can still edit any question before submitting.'
                : 'Quiz selections are filled in automatically. Complete the remaining blank questions.',
          ),
          if ((exam.contributionInstructions ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            _InstructionsCard(text: exam.contributionInstructions!),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your private question set',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '$_quota required',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._drafts.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _QuestionCard(
                    number: entry.key + 1,
                    draft: entry.value,
                    expanded: _expandedQuestion == entry.key,
                    showErrors: _attemptedSubmit,
                    onToggle: () => setState(() {
                      _expandedQuestion =
                          _expandedQuestion == entry.key ? -1 : entry.key;
                    }),
                    onChanged: () => setState(() {}),
                    onClear: () => setState(() {
                      entry.value.clear();
                      _expandedQuestion = entry.key;
                    }),
                    onCorrectChanged: (value) => setState(() {
                      entry.value.correct = value;
                    }),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool saving) {
    final selected = _librarySelection.length;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: _mode == _ContributionMode.library
            ? Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          saving || _libraryLoading ? null : _openManualEditor,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 54),
                      ),
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('Write new'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: saving || _libraryLoading || selected != _quota
                          ? null
                          : _submitSelected,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 54),
                      ),
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.lock_rounded),
                      label: Text(
                        saving
                            ? 'Submitting...'
                            : selected == _quota
                                ? 'Submit privately'
                                : 'Select ${_quota - selected} more',
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: saving
                          ? null
                          : () => setState(
                                () => _mode = _ContributionMode.library,
                              ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 54),
                      ),
                      icon: const Icon(Icons.auto_stories_rounded),
                      label: const Text('Choose quizzes'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: saving ? null : _submitManual,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 54),
                      ),
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.lock_rounded),
                      label: Text(saving ? 'Checking...' : 'Submit privately'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ContributionHero extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _ContributionHero({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .86),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  final String text;

  const _InstructionsCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: .22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int number;
  final _QuestionDraft draft;
  final bool expanded;
  final bool showErrors;
  final VoidCallback onToggle;
  final VoidCallback onChanged;
  final VoidCallback onClear;
  final ValueChanged<AnswerOption> onCorrectChanged;

  const _QuestionCard({
    required this.number,
    required this.draft,
    required this.expanded,
    required this.showErrors,
    required this.onToggle,
    required this.onChanged,
    required this.onClear,
    required this.onCorrectChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ready = draft.isComplete;
    final statusColor = ready ? AppColors.success : AppColors.warning;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: expanded
              ? AppColors.primary.withValues(alpha: .45)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: statusColor.withValues(alpha: .12),
                    child: ready
                        ? const Icon(
                            Icons.check_rounded,
                            size: 19,
                            color: AppColors.success,
                          )
                        : Text(
                            '$number',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          draft.text.text.trim().isEmpty
                              ? 'Question $number'
                              : draft.text.text.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          draft.sourceQuestionId == null
                              ? ready
                                  ? 'Custom question • Ready'
                                  : 'Custom question • Needs details'
                              : ready
                                  ? 'Imported from quiz • Ready'
                                  : 'Imported from quiz • Needs details',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (!draft.isEmpty)
                    IconButton(
                      tooltip: 'Clear question',
                      onPressed: onClear,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: draft.text,
                    onChanged: (_) => onChanged(),
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: 'Question',
                      hintText: 'Write one clear, unique question',
                      alignLabelWithHint: true,
                      errorText: showErrors && draft.text.text.trim().length < 3
                          ? 'Enter a complete question'
                          : null,
                    ),
                  ),
                  RadioGroup<AnswerOption>(
                    groupValue: draft.correct,
                    onChanged: (value) {
                      if (value != null) onCorrectChanged(value);
                    },
                    child: Column(
                      children: List.generate(4, (index) {
                        final answer = AnswerOption.values[index];
                        final value = draft.options[index].text.trim();
                        final duplicate = value.isNotEmpty &&
                            draft.options
                                    .where((option) =>
                                        option.text.trim().toLowerCase() ==
                                        value.toLowerCase())
                                    .length >
                                1;
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: TextField(
                            controller: draft.options[index],
                            onChanged: (_) => onChanged(),
                            decoration: InputDecoration(
                              labelText: 'Option ${answer.label}',
                              prefixIcon: Radio<AnswerOption>(value: answer),
                              suffixIcon: draft.correct == answer
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.success,
                                    )
                                  : null,
                              errorText: showErrors && value.isEmpty
                                  ? 'Option ${answer.label} is required'
                                  : showErrors && duplicate
                                      ? 'Use a different answer'
                                      : null,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: draft.explanation,
                    onChanged: (_) => onChanged(),
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Explanation (optional)',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
