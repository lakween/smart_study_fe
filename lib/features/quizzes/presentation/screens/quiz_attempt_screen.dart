import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
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
  late List<AnswerOption?> _answers;
  Timer? _timer;
  int _secondsRemaining = 0;
  int _totalSeconds = 0;
  bool _submitting = false;
  final int _startTime = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(quizProvider.notifier).ensureQuiz(widget.quizId);
      if (!mounted) return;
      final quiz = ref.read(quizByIdProvider(widget.quizId));
      if (quiz != null) {
        _answers = List.filled(quiz.questions.length, null);
        if (quiz.timeLimitMinutes != null) {
          _totalSeconds = quiz.timeLimitMinutes! * 60;
          _secondsRemaining = _totalSeconds;
          _timer = Timer.periodic(const Duration(seconds: 1), (_) {
            if (_secondsRemaining <= 0) { _timer?.cancel(); _submitQuiz(); }
            else setState(() => _secondsRemaining--);
          });
        }
      }
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _submitQuiz() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    _timer?.cancel();
    final timeTaken = ((DateTime.now().millisecondsSinceEpoch - _startTime) / 1000).toInt();
    final attempt = await ref.read(quizProvider.notifier).submitAttempt(
      quizId: widget.quizId, answers: _answers, timeTakenSeconds: timeTaken,
    );
    if (!mounted) return;
    if (attempt == null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not submit quiz. Please try again.'), backgroundColor: AppColors.error));
      return;
    }
    context.go('/quizzes/${widget.quizId}/result/${attempt.id}');
  }

  String get _timerText {
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(quizByIdProvider(widget.quizId));
    if (quiz == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_answers.length != quiz.questions.length) {
      _answers = List.filled(quiz.questions.length, null);
    }

    final question = quiz.questions[_currentIndex];
    final theme = Theme.of(context);
    final isLast = _currentIndex == quiz.questions.length - 1;
    final timerColor = _secondsRemaining < 300 ? AppColors.error : AppColors.textPrimary;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quiz.title, style: theme.textTheme.titleSmall),
            Text('Question ${_currentIndex + 1} of ${quiz.questions.length}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          if (quiz.timeLimitMinutes != null)
            Container(
              margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: timerColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Icon(Icons.timer, size: 16, color: timerColor),
                  const SizedBox(width: 4),
                  Text(_timerText, style: TextStyle(fontWeight: FontWeight.bold, color: timerColor)),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () async {
              final ok = await ConfirmDialog.show(context, title: 'Submit Quiz', message: 'Are you sure you want to submit? You cannot change your answers after submission.', confirmLabel: 'Submit');
              if (ok == true) _submitQuiz();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_currentIndex + 1) / quiz.questions.length, backgroundColor: AppColors.divider, color: AppColors.primary),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(question.text, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.5)),
                  const SizedBox(height: 24),
                  ...AnswerOption.values.map((opt) {
                    final isSelected = _answers[_currentIndex] == opt;
                    final optText = question.getOption(opt);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _answers[_currentIndex] = opt),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Theme.of(context).brightness == Brightness.dark ? AppColors.darkCardBg : AppColors.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider, width: isSelected ? 2 : 1),
                            boxShadow: isSelected ? [] : AppColors.cardShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                                child: Center(child: Text(opt.label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.primary))),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Text(optText, style: TextStyle(fontWeight: FontWeight.w500, color: isSelected ? Colors.white : null))),
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
                      onPressed: () => setState(() => _currentIndex--),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Previous'),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: isLast
                      ? ElevatedButton(
                          onPressed: _submitting ? null : () async {
                            final ok = await ConfirmDialog.show(context, title: 'Submit Quiz', message: 'Submit your answers?', confirmLabel: 'Submit');
                            if (ok == true) _submitQuiz();
                          },
                          child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit Quiz'),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => setState(() => _currentIndex++),
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: const Text('Next'),
                        ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 6,
              children: List.generate(quiz.questions.length, (i) {
                final answered = _answers[i] != null;
                final isCurrent = i == _currentIndex;
                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.primary : answered ? AppColors.accent : AppColors.divider,
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: (isCurrent || answered) ? Colors.white : AppColors.textSecondary))),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
