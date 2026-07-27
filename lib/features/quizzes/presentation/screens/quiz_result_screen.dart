import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/models/question_model.dart';
import '../../../../shared/widgets/score_circle.dart';
import '../providers/quiz_provider.dart';

class QuizResultScreen extends ConsumerStatefulWidget {
  final String quizId;
  final String attemptId;
  const QuizResultScreen({super.key, required this.quizId, required this.attemptId});

  @override
  ConsumerState<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends ConsumerState<QuizResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(quizProvider.notifier).ensureQuiz(widget.quizId);
      if (!mounted) return;
      await ref.read(quizProvider.notifier).ensureAttempt(widget.quizId, widget.attemptId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizId = widget.quizId;
    final attemptId = widget.attemptId;
    final attempt = ref.watch(attemptByIdProvider(attemptId));
    final quiz = ref.watch(quizByIdProvider(quizId));
    if (attempt == null || quiz == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final theme = Theme.of(context);
    final passed = attempt.scorePercent >= 60;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Result'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(child: ScoreCircle(score: attempt.scorePercent, size: 160)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: (passed ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(passed ? '🎉 Passed!' : '😔 Keep Practicing', style: TextStyle(fontWeight: FontWeight.bold, color: passed ? AppColors.success : AppColors.error, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            Text('${attempt.correctCount} out of ${attempt.totalQuestions} correct', style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
            if (attempt.timeTakenSeconds != null)
              Text('Time: ${AppHelpers.formatDuration(attempt.timeTakenSeconds! ~/ 60)}', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
            Text('${quiz.subjectName} › ${quiz.topicName}', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.warning.withValues(alpha: 0.3))),
              child: Row(
                children: [
                  const Icon(Icons.access_alarm, color: AppColors.warning, size: 20),
                  const SizedBox(width: 10),
                  Text('Revise again in 3 days', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text('Question Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            const SizedBox(height: 12),
            ...List.generate(quiz.questions.length, (i) {
              final q = quiz.questions[i];
              final ans = i < attempt.answers.length ? attempt.answers[i] : null;
              final isCorrect = ans?.isCorrect ?? false;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCardBg : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (isCorrect ? AppColors.success : AppColors.error).withValues(alpha: 0.3)),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? AppColors.success : AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${i + 1}. ${q.text}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (ans?.selectedAnswer != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: (isCorrect ? AppColors.success : AppColors.error).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Text('Your answer: ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            Text('${ans!.selectedAnswer!.label}. ${q.getOption(ans.selectedAnswer!)}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isCorrect ? AppColors.success : AppColors.error)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (!isCorrect)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Text('Correct: ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            Text('${q.correctAnswer.label}. ${q.getOption(q.correctAnswer)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
                          ],
                        ),
                      ),
                    if (q.explanation != null) ...[
                      const SizedBox(height: 8),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('View explanation', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                        children: [Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(q.explanation!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)))],
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => context.go('/quizzes/$quizId/attempt'), child: const Text('Retry'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: () => context.go('/home/dashboard'), child: const Text('Dashboard'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
