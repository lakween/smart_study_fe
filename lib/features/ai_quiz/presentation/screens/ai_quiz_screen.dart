import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/question_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../quizzes/presentation/providers/quiz_provider.dart';
import '../../../subjects/presentation/providers/subject_provider.dart';
import '../../../topics/presentation/providers/topic_provider.dart';

class _EditableQuestion {
  final String id;
  TextEditingController text = TextEditingController();
  TextEditingController optA = TextEditingController();
  TextEditingController optB = TextEditingController();
  TextEditingController optC = TextEditingController();
  TextEditingController optD = TextEditingController();
  TextEditingController explanation = TextEditingController();
  String sourceExcerpt;
  AnswerOption correct = AnswerOption.a;
  _EditableQuestion(
      {required this.id,
      required String qText,
      required String a,
      required String b,
      required String c,
      required String d,
      required this.correct,
      String? exp,
      this.sourceExcerpt = ''}) {
    text.text = qText;
    optA.text = a;
    optB.text = b;
    optC.text = c;
    optD.text = d;
    if (exp != null) explanation.text = exp;
  }
  void dispose() {
    text.dispose();
    optA.dispose();
    optB.dispose();
    optC.dispose();
    optD.dispose();
    explanation.dispose();
  }
}

class AiQuizScreen extends ConsumerStatefulWidget {
  const AiQuizScreen({super.key});
  @override
  ConsumerState<AiQuizScreen> createState() => _AiQuizScreenState();
}

class _AiQuizScreenState extends ConsumerState<AiQuizScreen> {
  int _step = 0;
  PlatformFile? _file;
  String? _subjectId, _topicId;
  int _questionCount = 10;
  String _difficulty = 'mixed';
  final _learningObjectiveController = TextEditingController();
  final _languageController = TextEditingController(text: 'English');
  bool _generating = false;
  int _genStage = 0;
  String? _genError;
  List<_EditableQuestion> _questions = [];
  bool _saving = false;
  final Set<String> _regeneratingQuestionIds = {};

  final List<String> _genMessages = [
    'Extracting text from document...',
    'Sending to AI...',
    'Generating questions...',
    'Formatting results...'
  ];

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
    if (result != null) setState(() => _file = result.files.first);
  }

  Future<void> _generate() async {
    if (_file == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a file'),
          backgroundColor: AppColors.error));
      return;
    }
    if (_languageController.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter a valid quiz language'),
          backgroundColor: AppColors.error));
      return;
    }
    setState(() {
      _step = 1;
      _generating = true;
      _genStage = 0;
      _genError = null;
    });

    final progressTimer =
        Stream.periodic(const Duration(milliseconds: 800), (i) => i)
            .listen((i) {
      if (mounted && i < _genMessages.length) setState(() => _genStage = i);
    });

    try {
      final formData = FormData.fromMap({
        'questionCount': _questionCount,
        'difficulty': _difficulty,
        'learningObjective': _learningObjectiveController.text.trim(),
        'language': _languageController.text.trim(),
        'file':
            await MultipartFile.fromFile(_file!.path!, filename: _file!.name),
      });
      final res = await ApiClient().dio.post('/ai-quiz/generate',
          data: formData,
          options: Options(
              sendTimeout: const Duration(minutes: 2),
              receiveTimeout: const Duration(minutes: 2)));
      final generated = res.data['questions'] as List<dynamic>;
      _questions = generated.map((q) {
        final map = q as Map<String, dynamic>;
        return _EditableQuestion(
          id: const Uuid().v4(),
          qText: map['text'] as String? ?? '',
          a: map['optionA'] as String? ?? '',
          b: map['optionB'] as String? ?? '',
          c: map['optionC'] as String? ?? '',
          d: map['optionD'] as String? ?? '',
          correct: AnswerOptionExt.fromString(
              map['correctAnswer'] as String? ?? 'A'),
          exp: map['explanation'] as String?,
          sourceExcerpt: map['sourceExcerpt'] as String? ?? '',
        );
      }).toList();
      if (mounted) {
        setState(() {
          _generating = false;
          _step = 2;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generating = false;
          _step = 0;
          _genError = apiErrorMessage(e,
              fallback: 'Could not generate quiz from this document');
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_genError!), backgroundColor: AppColors.error));
      }
    } finally {
      await progressTimer.cancel();
    }
  }

  Future<void> _regenerateQuestion(_EditableQuestion question) async {
    if (_file == null || _regeneratingQuestionIds.contains(question.id)) return;
    setState(() => _regeneratingQuestionIds.add(question.id));

    try {
      final avoidQuestions = _questions
          .where((candidate) => candidate.id != question.id)
          .map((candidate) => candidate.text.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      final formData = FormData.fromMap({
        'difficulty': _difficulty,
        'learningObjective': _learningObjectiveController.text.trim(),
        'language': _languageController.text.trim(),
        'avoidQuestions': jsonEncode(avoidQuestions),
        'file':
            await MultipartFile.fromFile(_file!.path!, filename: _file!.name),
      });
      final response = await ApiClient().dio.post(
            '/ai-quiz/regenerate',
            data: formData,
            options: Options(
              sendTimeout: const Duration(minutes: 2),
              receiveTimeout: const Duration(minutes: 2),
            ),
          );
      final generated = response.data['question'] as Map<String, dynamic>;
      final replacement = _EditableQuestion(
        id: question.id,
        qText: generated['text'] as String? ?? '',
        a: generated['optionA'] as String? ?? '',
        b: generated['optionB'] as String? ?? '',
        c: generated['optionC'] as String? ?? '',
        d: generated['optionD'] as String? ?? '',
        correct: AnswerOptionExt.fromString(
          generated['correctAnswer'] as String? ?? 'A',
        ),
        exp: generated['explanation'] as String?,
        sourceExcerpt: generated['sourceExcerpt'] as String? ?? '',
      );
      final index =
          _questions.indexWhere((candidate) => candidate.id == question.id);
      if (!mounted || index < 0) {
        replacement.dispose();
        return;
      }
      question.dispose();
      setState(() => _questions[index] = replacement);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiErrorMessage(
              error,
              fallback: 'Could not regenerate this question',
            )),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _regeneratingQuestionIds.remove(question.id));
      }
    }
  }

  Future<void> _saveQuiz() async {
    if (_subjectId == null || _topicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please go back and select a subject and topic'),
          backgroundColor: AppColors.error));
      return;
    }
    final validationError = _questionValidationError();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(validationError), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _saving = true);
    final ok = await ref.read(quizProvider.notifier).createQuiz(
          title: '${_file?.name.split('.').first ?? 'AI Quiz'} — AI Generated',
          subjectId: _subjectId!,
          topicId: _topicId!,
          visibility: ContentVisibility.private,
          allowCopy: false,
          isAiGenerated: true,
          questions: _questions
              .map((q) => QuestionModel(
                    id: q.id,
                    text: q.text.text.trim(),
                    optionA: q.optA.text.trim(),
                    optionB: q.optB.text.trim(),
                    optionC: q.optC.text.trim(),
                    optionD: q.optD.text.trim(),
                    correctAnswer: q.correct,
                    explanation: q.explanation.text.trim().isEmpty
                        ? null
                        : q.explanation.text.trim(),
                  ))
              .toList(),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('AI Quiz saved!'), backgroundColor: AppColors.success));
      context.go('/home/dashboard');
    } else {
      final error = ref.read(quizProvider).error ?? 'Could not save quiz';
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error));
    }
  }

  String? _questionValidationError() {
    if (_questions.isEmpty) return 'Add at least one question before saving';

    final seenQuestions = <String>{};
    for (var i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final text = question.text.text.trim();
      final options = [
        question.optA,
        question.optB,
        question.optC,
        question.optD
      ].map((controller) => controller.text.trim()).toList();
      if (text.length < 5 || options.any((option) => option.isEmpty)) {
        return 'Question ${i + 1} has an empty or incomplete field';
      }
      final normalizedOptions =
          options.map((option) => option.toLowerCase()).toSet();
      if (normalizedOptions.length != 4) {
        return 'Question ${i + 1} contains duplicate answer options';
      }
      final normalizedQuestion = text.toLowerCase();
      if (!seenQuestions.add(normalizedQuestion)) {
        return 'Questions must not be duplicated';
      }
    }
    return null;
  }

  @override
  void dispose() {
    for (final q in _questions) {
      q.dispose();
    }
    _learningObjectiveController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectProvider).subjects;
    final topics = _subjectId != null
        ? ref.watch(topicsBySubjectProvider(_subjectId!))
        : [];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Text('AI Quiz Generator'),
        ]),
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.page,
            child: Row(
              children: List.generate(
                  3,
                  (i) => Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: i <= _step
                                    ? AppColors.primary
                                    : AppColors.divider,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                  child: i < _step
                                      ? const Icon(Icons.check,
                                          size: 14, color: Colors.white)
                                      : Text('${i + 1}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: i <= _step
                                                  ? Colors.white
                                                  : AppColors.textMuted))),
                            ),
                            const SizedBox(width: 6),
                            Text(['Upload', 'Generate', 'Review'][i],
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: i == _step
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    color: i == _step
                                        ? AppColors.primary
                                        : AppColors.textMuted)),
                            if (i < 2)
                              Expanded(
                                  child: Container(
                                      height: 2,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      color: i < _step
                                          ? AppColors.primary
                                          : AppColors.divider)),
                          ],
                        ),
                      )),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: IndexedStack(
              index: _step,
              children: [
                // Step 1: Upload
                SingleChildScrollView(
                  padding: AppSpacing.form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: _file != null
                                      ? AppColors.primary
                                      : AppColors.divider,
                                  width: 1.5),
                              borderRadius: BorderRadius.circular(16),
                              color: _file != null
                                  ? AppColors.primary.withValues(alpha: 0.04)
                                  : null),
                          child: _file != null
                              ? Column(children: [
                                  const Icon(Icons.check_circle,
                                      size: 48, color: AppColors.success),
                                  const SizedBox(height: 8),
                                  Text(_file!.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                      '${(_file!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12)),
                                  const SizedBox(height: 8),
                                  TextButton(
                                      onPressed: _pickFile,
                                      child: const Text('Change file')),
                                ])
                              : const Column(children: [
                                  Icon(Icons.upload_file,
                                      size: 48, color: AppColors.textMuted),
                                  SizedBox(height: 8),
                                  Text('Tap to select document',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary)),
                                  SizedBox(height: 4),
                                  Text('PDF, JPG, PNG, JPEG',
                                      style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12)),
                                ]),
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        initialValue: _subjectId,
                        hint: const Text('Select Subject'),
                        decoration: InputDecoration(
                            labelText: 'Subject',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            filled: true),
                        items: subjects
                            .map((s) => DropdownMenuItem(
                                value: s.id, child: Text(s.name)))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _subjectId = v;
                            _topicId = null;
                          });
                          if (v != null) {
                            ref.read(topicProvider.notifier).loadForSubject(v);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _topicId,
                        hint: const Text('Select Topic'),
                        decoration: InputDecoration(
                            labelText: 'Topic',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            filled: true),
                        items: topics
                            .map((t) => DropdownMenuItem<String>(
                                value: t.id, child: Text(t.name)))
                            .toList(),
                        onChanged: (v) => setState(() => _topicId = v),
                      ),
                      const SizedBox(height: 20),
                      Text('Number of Questions',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: AppConstants.questionCountOptions.map((n) {
                          final sel = n == _questionCount;
                          return GestureDetector(
                            onTap: () => setState(() => _questionCount = n),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: sel
                                        ? AppColors.primary
                                        : AppColors.primary
                                            .withValues(alpha: 0.3)),
                              ),
                              child: Text('$n',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: sel
                                          ? Colors.white
                                          : AppColors.primary)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Text('Difficulty',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: ['easy', 'medium', 'hard', 'mixed']
                            .map((difficulty) {
                          final selected = difficulty == _difficulty;
                          return ChoiceChip(
                            label: Text(
                                '${difficulty[0].toUpperCase()}${difficulty.substring(1)}'),
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => _difficulty = difficulty),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _learningObjectiveController,
                        maxLength: 200,
                        decoration: const InputDecoration(
                          labelText: 'Learning objective (optional)',
                          hintText: 'Example: Apply binary-search concepts',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _languageController,
                        maxLength: 50,
                        decoration: const InputDecoration(
                          labelText: 'Quiz language',
                        ),
                      ),
                      const SizedBox(height: 28),
                      AppButton(
                          label: 'Generate Quiz',
                          onPressed: _generate,
                          icon: Icons.auto_awesome),
                    ],
                  ),
                ),
                // Step 2: Generating
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome,
                                size: 72, color: AppColors.primary)
                            .animate(onPlay: (c) => c.repeat())
                            .scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1.2, 1.2),
                                duration: 800.ms,
                                curve: Curves.easeInOut),
                        const SizedBox(height: 24),
                        const Text('Generating your quiz...',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                            _generating
                                ? _genMessages[
                                    _genStage.clamp(0, _genMessages.length - 1)]
                                : 'Done!',
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(
                            color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                // Step 3: Review
                _questions.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: AppSpacing.list,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.warning
                                        .withValues(alpha: 0.3))),
                            child: const Row(
                              children: [
                                Icon(Icons.warning_amber,
                                    color: AppColors.warning, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                        'AI Generated — Please review before saving',
                                        style: TextStyle(
                                            color: AppColors.warning,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._questions.asMap().entries.map((e) {
                            final i = e.key;
                            final q = e.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkCardBg
                                    : AppColors.cardBg,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const []
                                    : AppColors.cardShadow,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('Q${i + 1}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary)),
                                      const Spacer(),
                                      TextButton.icon(
                                        onPressed: _regeneratingQuestionIds
                                                .contains(q.id)
                                            ? null
                                            : () => _regenerateQuestion(q),
                                        icon: _regeneratingQuestionIds
                                                .contains(q.id)
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2))
                                            : const Icon(Icons.refresh,
                                                size: 16),
                                        label: const Text('Regenerate'),
                                      ),
                                      IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              size: 18, color: AppColors.error),
                                          onPressed: () {
                                            q.dispose();
                                            setState(
                                                () => _questions.removeAt(i));
                                          },
                                          padding: EdgeInsets.zero),
                                    ],
                                  ),
                                  TextFormField(
                                      controller: q.text,
                                      maxLines: 2,
                                      decoration: const InputDecoration(
                                          labelText: 'Question',
                                          filled: true,
                                          border: InputBorder.none),
                                      style: const TextStyle(fontSize: 13)),
                                  const SizedBox(height: 8),
                                  RadioGroup<AnswerOption>(
                                    groupValue: q.correct,
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => q.correct = value);
                                      }
                                    },
                                    child: Column(
                                      children: AnswerOption.values
                                          .map((opt) => Row(
                                                children: [
                                                  Radio<AnswerOption>(
                                                      value: opt,
                                                      activeColor:
                                                          AppColors.primary,
                                                      materialTapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap),
                                                  Expanded(
                                                      child: TextFormField(
                                                    controller: switch (opt) {
                                                      AnswerOption.a => q.optA,
                                                      AnswerOption.b => q.optB,
                                                      AnswerOption.c => q.optC,
                                                      AnswerOption.d => q.optD
                                                    },
                                                    decoration: InputDecoration(
                                                        labelText: opt.label,
                                                        filled: true,
                                                        border:
                                                            InputBorder.none,
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 6)),
                                                    style: const TextStyle(
                                                        fontSize: 12),
                                                  )),
                                                ],
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                  if (q.sourceExcerpt.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Source: “${q.sourceExcerpt}”',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                          TextButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add More Questions'),
                              onPressed: () => setState(() => _questions.add(
                                  _EditableQuestion(
                                      id: const Uuid().v4(),
                                      qText: '',
                                      a: '',
                                      b: '',
                                      c: '',
                                      d: '',
                                      correct: AnswerOption.a)))),
                          const SizedBox(height: 16),
                          AppButton(
                            label: 'Save Quiz',
                            isLoading: _saving,
                            onPressed: _saving ? null : _saveQuiz,
                          ),
                          const SizedBox(height: 12),
                          AppButton(
                              label: 'Discard',
                              variant: AppButtonVariant.outlined,
                              onPressed: () => setState(() {
                                    _step = 0;
                                    _questions.clear();
                                  })),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
