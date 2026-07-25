import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/question_model.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../providers/exam_provider.dart';

class ExamAttemptScreen extends ConsumerStatefulWidget {
  final String examId;
  const ExamAttemptScreen({super.key, required this.examId});

  @override
  ConsumerState<ExamAttemptScreen> createState() => _ExamAttemptScreenState();
}

class _ExamAttemptScreenState extends ConsumerState<ExamAttemptScreen> {
  int _currentIndex = 0;
  late List<AnswerOption?> _answers;
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _initialized = false;

  final int _startTime = DateTime.now().millisecondsSinceEpoch;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(examProvider.notifier).ensureExam(widget.examId);
      if (!mounted) return;
      await ref.read(examProvider.notifier).startExam(widget.examId);
      if (!mounted) return;
      final exam = ref.read(examByIdProvider(widget.examId));
      if (exam != null && !_initialized) {
        _initialized = true;
        _answers = List.filled(exam.questions.length, null);
        _secondsRemaining = exam.durationMinutes * 60;
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (_secondsRemaining <= 0) {
            _timer?.cancel();
            _submitExam();
          } else {
            setState(() => _secondsRemaining--);
          }
        });
        setState(() {});
      }
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _submitExam() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    _timer?.cancel();
    final exam = ref.read(examByIdProvider(widget.examId));
    if (exam == null) return;
    final timeTaken = ((DateTime.now().millisecondsSinceEpoch - _startTime) / 1000).toInt();
    await ref.read(examProvider.notifier).submitExam(
      examId: widget.examId,
      answers: _answers,
      questionIds: exam.questions.map((q) => q.id).toList(),
      timeTakenSeconds: timeTaken,
    );
    if (mounted) context.go('/exams/${widget.examId}/result');
  }

  String get _timerText {
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(examByIdProvider(widget.examId));
    if (exam == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_initialized || _answers.length != exam.questions.length) {
      _answers = List.filled(exam.questions.length, null);
    }
    final question = exam.questions[_currentIndex];
    final isLast = _currentIndex == exam.questions.length - 1;
    final timerRed = _secondsRemaining < 300;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(exam.title),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: (timerRed ? AppColors.error : AppColors.primary).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Icon(Icons.timer, size: 16, color: timerRed ? AppColors.error : AppColors.primary),
              const SizedBox(width: 4),
              Text(_timerText, style: TextStyle(fontWeight: FontWeight.bold, color: timerRed ? AppColors.error : AppColors.primary, fontSize: 15)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () async {
              final ok = await ConfirmDialog.show(context, title: 'Submit Exam', message: 'Submit your exam now? You cannot change answers.', confirmLabel: 'Submit');
              if (ok == true) _submitExam();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_currentIndex + 1) / exam.questions.length, backgroundColor: AppColors.divider, color: AppColors.primary),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Question ${_currentIndex + 1} of ${exam.questions.length}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 12),
                  Text(question.text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.5)),
                  const SizedBox(height: 24),
                  ...AnswerOption.values.map((opt) {
                    final isSelected = _answers[_currentIndex] == opt;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _answers[_currentIndex] = opt),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Theme.of(context).brightness == Brightness.dark ? AppColors.darkCardBg : AppColors.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider, width: isSelected ? 2 : 1),
                            boxShadow: isSelected ? [] : AppColors.cardShadow,
                          ),
                          child: Row(children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                              child: Center(child: Text(opt.label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.primary))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Text(question.getOption(opt), style: TextStyle(color: isSelected ? Colors.white : null))),
                          ]),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(child: OutlinedButton.icon(onPressed: () => setState(() => _currentIndex--), icon: const Icon(Icons.arrow_back, size: 18), label: const Text('Previous'))),
                if (_currentIndex > 0) const SizedBox(width: 12),
                Expanded(child: isLast
                    ? ElevatedButton(onPressed: () async {
                        final ok = await ConfirmDialog.show(context, title: 'Submit Exam', message: 'Submit your exam?', confirmLabel: 'Submit');
                        if (ok == true) _submitExam();
                      }, child: const Text('Submit Exam'))
                    : ElevatedButton.icon(onPressed: () => setState(() => _currentIndex++), icon: const Icon(Icons.arrow_forward, size: 18), label: const Text('Next'))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 6,
              children: List.generate(exam.questions.length, (i) {
                final answered = _answers[i] != null;
                final isCur = i == _currentIndex;
                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: isCur ? AppColors.primary : answered ? AppColors.accent : AppColors.divider,
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: (isCur || answered) ? Colors.white : AppColors.textSecondary))),
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
