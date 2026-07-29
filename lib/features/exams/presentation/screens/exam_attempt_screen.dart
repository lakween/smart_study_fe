import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/exam_model.dart';
import '../../../../shared/models/question_model.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../providers/exam_provider.dart';

class ExamAttemptScreen extends ConsumerStatefulWidget {
  final String examId;

  const ExamAttemptScreen({super.key, required this.examId});

  @override
  ConsumerState<ExamAttemptScreen> createState() => _ExamAttemptScreenState();
}

class _ExamAttemptScreenState extends ConsumerState<ExamAttemptScreen>
    with WidgetsBindingObserver {
  ExamAttemptModel? _attempt;
  final Map<String, AnswerOption?> _answers = {};
  Timer? _countdown;
  Timer? _saveDebounce;
  Duration _serverOffset = Duration.zero;
  int _secondsRemaining = 0;
  int _currentIndex = 0;
  bool _loading = true;
  bool _submitting = false;
  bool _saving = false;
  bool _answersDirty = false;
  bool _allowExit = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startOrResume());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshRemaining();
    if (state == AppLifecycleState.paused) _saveNow();
  }

  Future<void> _startOrResume() async {
    final session =
        await ref.read(examProvider.notifier).startAttempt(widget.examId);
    if (!mounted) return;
    if (session == null) {
      setState(() {
        _loading = false;
        _loadError =
            ref.read(examProvider).error ?? 'Could not open this exam.';
      });
      return;
    }
    if (session.attempt.isSubmitted) {
      context.go('/exams/${widget.examId}/result');
      return;
    }
    _attempt = session.attempt;
    _answers
      ..clear()
      ..addEntries(session.attempt.questions.map(
        (question) => MapEntry(
          question.id,
          session.attempt.answers[question.id],
        ),
      ));
    _serverOffset = session.serverNow.difference(DateTime.now());
    _loading = false;
    _refreshRemaining();
    _countdown = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshRemaining(),
    );
    setState(() {});
  }

  void _refreshRemaining() {
    final attempt = _attempt;
    if (!mounted || attempt == null || _submitting) return;
    final serverNow = DateTime.now().add(_serverOffset);
    final remaining = attempt.deadlineAt.difference(serverNow).inSeconds;
    setState(() => _secondsRemaining = remaining.clamp(0, 86400));
    if (remaining <= 0) {
      _countdown?.cancel();
      _submit(automatic: true);
    }
  }

  void _selectAnswer(String questionId, AnswerOption option) {
    setState(() {
      _answers[questionId] = option;
      _answersDirty = true;
    });
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 300), _saveNow);
  }

  Future<void> _saveNow() async {
    final attempt = _attempt;
    if (attempt == null || _submitting || _saving || !_answersDirty) return;
    _saveDebounce?.cancel();
    _answersDirty = false;
    final snapshot = Map<String, AnswerOption?>.from(_answers);
    if (mounted) setState(() => _saving = true);
    final saved = await ref.read(examProvider.notifier).saveAnswers(
          examId: widget.examId,
          attemptId: attempt.id,
          answers: snapshot,
        );
    if (!saved) _answersDirty = true;
    if (mounted) {
      setState(() => _saving = false);
      if (_answersDirty) {
        _saveDebounce = Timer(const Duration(milliseconds: 100), _saveNow);
      }
    }
  }

  Future<void> _submit({bool automatic = false}) async {
    final attempt = _attempt;
    if (attempt == null || _submitting) return;
    _saveDebounce?.cancel();
    _countdown?.cancel();
    setState(() => _submitting = true);
    final result = await ref.read(examProvider.notifier).submitAttempt(
          examId: widget.examId,
          attemptId: attempt.id,
          answers: Map.unmodifiable(_answers),
        );
    if (!mounted) return;
    if (result != null) {
      if (automatic) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Time is up. Your exam was submitted.')),
        );
      }
      context.go('/exams/${widget.examId}/result');
      return;
    }
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ref.read(examProvider).error ?? 'Submission failed.'),
        backgroundColor: AppColors.error,
      ),
    );
    _refreshRemaining();
  }

  Future<void> _requestExit() async {
    final shouldLeave = await ConfirmDialog.show(
      context,
      title: 'Leave exam?',
      message:
          'Your saved answers and timer will be kept. You can resume before the deadline.',
      confirmLabel: 'Save & leave',
    );
    if (shouldLeave != true || !mounted) return;
    await _saveNow();
    if (!mounted) return;
    setState(() => _allowExit = true);
    context.pop();
  }

  String get _timerText {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdown?.cancel();
    _saveDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final attempt = _attempt;
    if (_loadError != null || attempt == null || attempt.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exam')),
        body: _AttemptError(
          message: _loadError ?? 'This exam has no available questions.',
          onRetry: () {
            setState(() {
              _loading = true;
              _loadError = null;
            });
            _startOrResume();
          },
        ),
      );
    }

    final exam = ref.watch(examByIdProvider(widget.examId));
    final question = attempt.questions[_currentIndex];
    final selected = _answers[question.id];
    final isLast = _currentIndex == attempt.questions.length - 1;
    final timerCritical = _secondsRemaining <= 300;
    final answered = _answers.values.whereType<AnswerOption>().length;

    return PopScope(
      canPop: _allowExit,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestExit();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: _requestExit,
            icon: const Icon(Icons.close_rounded),
          ),
          title: Text(exam?.title ?? 'Exam'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.pageGutter),
              child: _TimerBadge(
                text: _timerText,
                isCritical: timerCritical,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / attempt.questions.length,
              minHeight: 4,
              backgroundColor: AppColors.divider,
              color: timerCritical ? AppColors.warning : AppColors.primary,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.page,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'QUESTION ${_currentIndex + 1} OF ${attempt.questions.length}',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                        ),
                        const Spacer(),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Text(
                            _saving ? 'Saving…' : '$answered answered',
                            key: ValueKey('$_saving-$answered'),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      question.text,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 28),
                    ...AnswerOption.values.map(
                      (option) => _AnswerTile(
                        option: option,
                        text: question.getOption(option),
                        selected: selected == option,
                        onTap: _submitting
                            ? null
                            : () => _selectAnswer(question.id, option),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageGutter,
                  12,
                  AppSpacing.pageGutter,
                  12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border:
                      const Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            List.generate(attempt.questions.length, (index) {
                          final id = attempt.questions[index].id;
                          return _QuestionDot(
                            number: index + 1,
                            current: index == _currentIndex,
                            answered: _answers[id] != null,
                            onTap: () => setState(() => _currentIndex = index),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (_currentIndex > 0) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _submitting
                                  ? null
                                  : () => setState(() => _currentIndex--),
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Previous'),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _submitting
                                ? null
                                : isLast
                                    ? _confirmSubmit
                                    : () => setState(() => _currentIndex++),
                            icon: _submitting
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(isLast
                                    ? Icons.check_rounded
                                    : Icons.arrow_forward_rounded),
                            label: Text(isLast ? 'Submit exam' : 'Next'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSubmit() async {
    final unanswered = _answers.values.where((answer) => answer == null).length;
    final shouldSubmit = await ConfirmDialog.show(
      context,
      title: 'Submit exam?',
      message: unanswered == 0
          ? 'Your answers cannot be changed after submission.'
          : '$unanswered question${unanswered == 1 ? '' : 's'} unanswered. Submit anyway?',
      confirmLabel: 'Submit',
    );
    if (shouldSubmit == true) _submit();
  }
}

class _TimerBadge extends StatelessWidget {
  final String text;
  final bool isCritical;

  const _TimerBadge({required this.text, required this.isCritical});

  @override
  Widget build(BuildContext context) {
    final color = isCritical ? AppColors.error : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 17, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  final AnswerOption option;
  final String text;
  final bool selected;
  final VoidCallback? onTap;

  const _AnswerTile({
    required this.option,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: isDark ? .22 : .08)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider,
                width: selected ? 1.8 : 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: .1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    option.label,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionDot extends StatelessWidget {
  final int number;
  final bool current;
  final bool answered;
  final VoidCallback onTap;

  const _QuestionDot({
    required this.number,
    required this.current,
    required this.answered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: current
                ? AppColors.primary
                : answered
                    ? AppColors.accent.withValues(alpha: .16)
                    : Colors.transparent,
            border: Border.all(
              color: current
                  ? AppColors.primary
                  : answered
                      ? AppColors.accent
                      : AppColors.divider,
            ),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: current
                  ? Colors.white
                  : answered
                      ? AppColors.accent
                      : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _AttemptError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AttemptError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_outlined,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
