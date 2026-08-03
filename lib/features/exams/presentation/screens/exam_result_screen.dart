import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/exam_model.dart';
import '../../../../shared/models/question_model.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../../shared/widgets/score_circle.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/exam_provider.dart';

class ExamResultScreen extends ConsumerStatefulWidget {
  final String examId;

  const ExamResultScreen({super.key, required this.examId});

  @override
  ConsumerState<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends ConsumerState<ExamResultScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (ref.read(examResultProvider(widget.examId)) == null) {
      final result =
          await ref.read(examProvider.notifier).loadResult(widget.examId);
      if (!mounted) return;
      _error = result == null ? ref.read(examProvider).error : null;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(examResultProvider(widget.examId));
    if (_loading && result == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exam result')),
        body: Center(
          child: Padding(
            padding: AppSpacing.page,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_empty_rounded,
                    size: 54, color: AppColors.textMuted),
                const SizedBox(height: 14),
                SelectableText(
                  _error ?? 'Your result is not available yet.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _load();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Check again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final exam = result.exam;
    final attempt = result.attempt;
    final score = attempt.scorePercent;
    final passed = score != null && score >= exam.passPercent;
    final userId = ref.watch(authProvider).user?.id;
    final ranked = exam.participants
        .where((item) => item.score != null)
        .toList()
      ..sort((a, b) => b.score!.compareTo(a.score!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam result'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (score == null)
                _WaitingForRelease(exam: exam)
              else
                _ScoreSummary(
                  exam: exam,
                  attempt: attempt,
                  score: score,
                  passed: passed,
                ),
              if (ranked.length > 1) ...[
                const SizedBox(height: 24),
                Text('Leaderboard',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                _Leaderboard(participants: ranked, userId: userId),
              ],
              if (result.solutionsReleased) ...[
                const SizedBox(height: 24),
                Text('Answer review',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                ...attempt.questions.asMap().entries.map(
                      (entry) => _AnswerReview(
                        number: entry.key + 1,
                        question: entry.value,
                        selected: attempt.answers[entry.value.id],
                      ),
                    ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/dashboard'),
                icon: const Icon(Icons.bar_chart_rounded),
                label: const Text('View dashboard'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/home/exams'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: const Text('Back to exams'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreSummary extends StatelessWidget {
  final ExamModel exam;
  final ExamAttemptModel attempt;
  final double score;
  final bool passed;

  const _ScoreSummary({
    required this.exam,
    required this.attempt,
    required this.score,
    required this.passed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          ScoreCircle(score: score, size: 148),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (passed ? AppColors.success : AppColors.error)
                  .withValues(alpha: .1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              passed ? 'PASSED' : 'NOT PASSED',
              style: TextStyle(
                color: passed ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            exam.title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ResultMetric(
                  value:
                      '${attempt.correctCount ?? 0}/${attempt.totalQuestions}',
                  label: 'Correct',
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(
                child: _ResultMetric(
                  value: '${exam.passPercent}%',
                  label: 'Pass mark',
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(
                child: _ResultMetric(
                  value: attempt.status.label,
                  label: 'Status',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  final String value;
  final String label;

  const _ResultMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textMuted)),
      ],
    );
  }
}

class _WaitingForRelease extends StatelessWidget {
  final ExamModel exam;

  const _WaitingForRelease({required this.exam});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: .25)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_clock_outlined,
              size: 54, color: AppColors.primary),
          const SizedBox(height: 14),
          Text('Submission received',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            exam.closesAt == null
                ? 'Your result will appear when this exam closes.'
                : 'Results and solutions will be released after every participant’s time window closes.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Leaderboard extends StatelessWidget {
  final List<ExamParticipant> participants;
  final String? userId;

  const _Leaderboard({required this.participants, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: participants.asMap().entries.map((entry) {
          final participant = entry.value;
          final isMe = participant.userId == userId;
          return Container(
            color: isMe ? AppColors.primary.withValues(alpha: .06) : null,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: entry.key < 3
                    ? AppColors.warning.withValues(alpha: .15)
                    : AppColors.divider,
                child: Text('${entry.key + 1}'),
              ),
              title: Row(
                children: [
                  AvatarWidget(name: participant.name, radius: 14),
                  const SizedBox(width: 9),
                  Expanded(
                      child: Text(isMe
                          ? '${participant.name} (You)'
                          : participant.name)),
                ],
              ),
              trailing: Text(
                '${participant.score!.toStringAsFixed(0)}%',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w800),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AnswerReview extends StatelessWidget {
  final int number;
  final QuestionModel question;
  final AnswerOption? selected;

  const _AnswerReview({
    required this.number,
    required this.question,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final correct = selected == question.correctAnswer;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: (correct ? AppColors.success : AppColors.error)
              .withValues(alpha: .4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: correct ? AppColors.success : AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('$number. ${question.text}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
              'Your answer: ${selected == null ? 'Not answered' : '${selected!.label}. ${question.getOption(selected!)}'}'),
          if (!correct) ...[
            const SizedBox(height: 4),
            Text(
              'Correct: ${question.correctAnswer.label}. ${question.getOption(question.correctAnswer)}',
              style: const TextStyle(
                  color: AppColors.success, fontWeight: FontWeight.w600),
            ),
          ],
          if (question.explanation?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(question.explanation!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}
