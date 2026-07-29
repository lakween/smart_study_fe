import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/question_model.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../providers/quiz_provider.dart';

class QuizAttemptScreen extends ConsumerStatefulWidget {
  final String quizId;
  const QuizAttemptScreen({super.key, required this.quizId});

  @override
  ConsumerState<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends ConsumerState<QuizAttemptScreen> {
  int _currentIndex = 0;
  List<AnswerOption?> _answers = [];
  List<int> _questionOrder = [];
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _submitting = false;
  bool _ready = false;
  bool _started = false;
  bool _timed = false;
  bool _starting = false;
  bool _shuffleQuestions = false;
  QuizPracticeSession? _session;

  String get _draftKey => 'quiz_attempt_draft_${widget.quizId}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(quizProvider.notifier).ensureQuiz(widget.quizId);
      if (!mounted) return;
      final quiz = ref.read(quizByIdProvider(widget.quizId));
      if (quiz != null) {
        setState(() {
          _answers = List.filled(quiz.questions.length, null);
          _questionOrder =
              List.generate(quiz.questions.length, (index) => index);
          _ready = true;
        });
        await _restoreDraft(quiz.questions.length);
      }
    });
  }

  Future<void> _startAttempt({required bool timed}) async {
    if (_starting) return;
    setState(() => _starting = true);
    final session = await ref.read(quizProvider.notifier).startAttempt(
          quizId: widget.quizId,
          timed: timed,
        );
    if (!mounted) return;
    if (session == null) {
      setState(() => _starting = false);
      final message = ref.read(quizProvider).error ??
          'Could not start practice. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() {
      _session = session;
      _started = true;
      _timed = session.isTimed;
      _starting = false;
      _questionOrder = List.generate(_answers.length, (index) => index);
      if (_shuffleQuestions) _questionOrder.shuffle(Random.secure());
    });
    await _saveDraft();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    final deadline = _session?.deadlineAt;
    if (!_timed || deadline == null) return;

    final initialRemaining = deadline.difference(DateTime.now()).inSeconds;
    if (initialRemaining <= 0) {
      if (mounted) setState(() => _secondsRemaining = 0);
      _submitQuiz();
      return;
    }
    if (mounted) setState(() => _secondsRemaining = initialRemaining);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = deadline.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        timer.cancel();
        if (mounted) setState(() => _secondsRemaining = 0);
        _submitQuiz();
      } else if (mounted) {
        setState(() => _secondsRemaining = remaining);
      }
    });
  }

  Future<void> _saveDraft() async {
    final session = _session;
    if (session == null) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
        _draftKey,
        jsonEncode({
          'sessionId': session.id,
          'timed': session.isTimed,
          'startedAt': session.startedAt.toIso8601String(),
          'deadlineAt': session.deadlineAt?.toIso8601String(),
          'currentIndex': _currentIndex,
          'answers': _answers.map((answer) => answer?.label).toList(),
          'questionOrder': _questionOrder,
          'shuffleQuestions': _shuffleQuestions,
        }));
  }

  Future<void> _clearDraft() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_draftKey);
  }

  Future<void> _restoreDraft(int questionCount) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_draftKey);
    if (raw == null || !mounted) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final answerValues = (data['answers'] as List<dynamic>? ?? const [])
          .take(questionCount)
          .map((value) => value == null
              ? null
              : AnswerOptionExt.fromString(value as String))
          .toList();
      while (answerValues.length < questionCount) {
        answerValues.add(null);
      }
      final deadlineText = data['deadlineAt'] as String?;
      final storedOrder = (data['questionOrder'] as List<dynamic>? ?? const [])
          .map((value) => (value as num).toInt())
          .toList();
      final validOrder = storedOrder.length == questionCount &&
          storedOrder.toSet().length == questionCount &&
          storedOrder.every((index) => index >= 0 && index < questionCount);
      final session = QuizPracticeSession(
        id: data['sessionId'] as String,
        isTimed: data['timed'] as bool? ?? false,
        startedAt: DateTime.parse(data['startedAt'] as String),
        deadlineAt: deadlineText == null ? null : DateTime.parse(deadlineText),
      );
      if (session.deadlineAt != null &&
          DateTime.now()
              .isAfter(session.deadlineAt!.add(const Duration(seconds: 30)))) {
        await _clearDraft();
        return;
      }
      if (!mounted) return;
      setState(() {
        _session = session;
        _timed = session.isTimed;
        _started = true;
        _answers = answerValues;
        _questionOrder = validOrder
            ? storedOrder
            : List.generate(questionCount, (index) => index);
        _shuffleQuestions = data['shuffleQuestions'] as bool? ?? false;
        _currentIndex =
            (data['currentIndex'] as int? ?? 0).clamp(0, questionCount - 1);
      });
      _startTimer();
    } catch (_) {
      await _clearDraft();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _submitQuiz() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    _timer?.cancel();
    final session = _session;
    if (session == null) {
      setState(() => _submitting = false);
      return;
    }
    final attempt = await ref.read(quizProvider.notifier).submitAttempt(
          quizId: widget.quizId,
          sessionId: session.id,
          answers: _answers,
        );
    if (!mounted) return;
    if (attempt == null) {
      setState(() => _submitting = false);
      final message = ref.read(quizProvider).error ??
          'Could not submit quiz. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error));
      return;
    }
    await _clearDraft();
    if (!mounted) return;
    context.go('/quizzes/${widget.quizId}/result/${attempt.id}');
  }

  String get _timerText {
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _leavePractice() async {
    final leave = await ConfirmDialog.show(
      context,
      title: 'Leave practice?',
      message:
          'Your current answers are saved on this device so you can continue later.',
      confirmLabel: 'Leave',
    );
    if (leave != true || !mounted) return;
    await _saveDraft();
    if (!mounted) return;
    context.go('/quizzes');
  }

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(quizByIdProvider(widget.quizId));
    if (quiz == null || !_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_answers.length != quiz.questions.length) {
      _answers = List.filled(quiz.questions.length, null);
    }
    if (_questionOrder.length != quiz.questions.length) {
      _questionOrder = List.generate(quiz.questions.length, (index) => index);
    }

    if (!_started) {
      return Scaffold(
        appBar: AppBar(title: const Text('Choose Practice Mode')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  quiz.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${quiz.questionCount} questions • Choose how you want to practice',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: 28),
                SwitchListTile(
                  value: _shuffleQuestions,
                  onChanged: _starting
                      ? null
                      : (value) => setState(() => _shuffleQuestions = value),
                  title: const Text('Shuffle questions'),
                  subtitle: const Text(
                      'Use a different question order for this attempt.'),
                  secondary: const Icon(Icons.shuffle),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.primary,
                ),
                const SizedBox(height: 12),
                if (quiz.timeLimitMinutes != null) ...[
                  _PracticeModeCard(
                    icon: Icons.timer_outlined,
                    color: AppColors.warning,
                    title: 'Timed Practice',
                    description:
                        '${quiz.timeLimitMinutes} minute countdown. Your answers submit automatically when time expires.',
                    buttonLabel: 'Start Timed',
                    onPressed:
                        _starting ? null : () => _startAttempt(timed: true),
                  ),
                  const SizedBox(height: 16),
                ],
                _PracticeModeCard(
                  icon: Icons.all_inclusive_rounded,
                  color: AppColors.primary,
                  title: 'Untimed Practice',
                  description:
                      'Practice at your own pace without a countdown. Elapsed time is still recorded.',
                  buttonLabel: 'Start Untimed',
                  onPressed:
                      _starting ? null : () => _startAttempt(timed: false),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final answerIndex = _questionOrder[_currentIndex];
    final question = quiz.questions[answerIndex];
    final theme = Theme.of(context);
    final isLast = _currentIndex == quiz.questions.length - 1;
    final timerColor =
        _secondsRemaining < 300 ? AppColors.error : AppColors.textPrimary;

    final answeredCount = _answers.where((answer) => answer != null).length;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leavePractice();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Leave practice',
            onPressed: _leavePractice,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(quiz.title, style: theme.textTheme.titleSmall),
              Text('Question ${_currentIndex + 1} of ${quiz.questions.length}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          actions: [
            if (_timed)
              Container(
                margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: timerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: timerColor),
                    const SizedBox(width: 4),
                    Text(_timerText,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: timerColor)),
                  ],
                ),
              ),
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () async {
                final ok = await ConfirmDialog.show(context,
                    title: 'Submit Quiz',
                    message:
                        'Are you sure you want to submit? You cannot change your answers after submission.',
                    confirmLabel: 'Submit');
                if (ok == true) _submitQuiz();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
                value: (_currentIndex + 1) / quiz.questions.length,
                backgroundColor: AppColors.divider,
                color: AppColors.primary),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageGutter,
                10,
                AppSpacing.pageGutter,
                0,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$answeredCount of ${quiz.questions.length} answered',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.page,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(question.text,
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600, height: 1.5)),
                    const SizedBox(height: 24),
                    ...AnswerOption.values.map((opt) {
                      final isSelected = _answers[answerIndex] == opt;
                      final optText = question.getOption(opt);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _answers[answerIndex] = opt);
                            _saveDraft();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkCardBg
                                      : AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.divider,
                                  width: isSelected ? 2 : 1),
                              boxShadow: isSelected ||
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                  ? const []
                                  : AppColors.cardShadow,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : AppColors.primary
                                              .withValues(alpha: 0.1),
                                      shape: BoxShape.circle),
                                  child: Center(
                                      child: Text(opt.label,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppColors.primary))),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                    child: Text(optText,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: isSelected
                                                ? Colors.white
                                                : null))),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentIndex > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _currentIndex--);
                          _saveDraft();
                        },
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Previous'),
                      ),
                    ),
                  if (_currentIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    child: isLast
                        ? ElevatedButton(
                            onPressed: _submitting
                                ? null
                                : () async {
                                    final ok = await ConfirmDialog.show(context,
                                        title: 'Submit Quiz',
                                        message: 'Submit your answers?',
                                        confirmLabel: 'Submit');
                                    if (ok == true) _submitQuiz();
                                  },
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Submit Quiz'),
                          )
                        : ElevatedButton.icon(
                            onPressed: () {
                              setState(() => _currentIndex++);
                              _saveDraft();
                            },
                            icon: const Icon(Icons.arrow_forward, size: 18),
                            label: const Text('Next'),
                          ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageGutter,
                0,
                AppSpacing.pageGutter,
                16,
              ),
              child: Wrap(
                spacing: 6,
                children: List.generate(quiz.questions.length, (i) {
                  final answered = _answers[_questionOrder[i]] != null;
                  final isCurrent = i == _currentIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _currentIndex = i);
                      _saveDraft();
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.primary
                            : answered
                                ? AppColors.accent
                                : AppColors.divider,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: (isCurrent || answered)
                                      ? Colors.white
                                      : AppColors.textSecondary))),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticeModeCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;

  const _PracticeModeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        boxShadow: isDark ? null : AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
