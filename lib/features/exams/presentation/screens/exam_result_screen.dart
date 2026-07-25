import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(examProvider.notifier).ensureExam(widget.examId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final examId = widget.examId;
    final exam = ref.watch(examByIdProvider(examId));
    final userId = ref.watch(authProvider).user?.id;
    if (exam == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final myResult = exam.participants.firstWhere((p) => p.userId == userId, orElse: () => exam.participants.first);
    final sorted = List.from(exam.participants)..sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Exam Result'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(child: ScoreCircle(score: myResult.score ?? 0, size: 160)),
            const SizedBox(height: 12),
            Text('${exam.title}', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (exam.participants.length > 1) ...[
              const Align(alignment: Alignment.centerLeft, child: Text('Leaderboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              const SizedBox(height: 12),
              ...sorted.asMap().entries.map((e) {
                final rank = e.key + 1;
                final p = e.value;
                final isMe = p.userId == userId;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary.withOpacity(0.08) : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkCardBg : AppColors.cardBg),
                    borderRadius: BorderRadius.circular(12),
                    border: isMe ? Border.all(color: AppColors.primary.withOpacity(0.4)) : null,
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: rank <= 3 ? [AppColors.warning, AppColors.textMuted, const Color(0xFFB45309)][rank - 1].withOpacity(0.15) : AppColors.divider,
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: Text('$rank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: rank <= 3 ? [AppColors.warning, AppColors.textMuted, const Color(0xFFB45309)][rank - 1] : AppColors.textSecondary))),
                      ),
                      const SizedBox(width: 12),
                      AvatarWidget(name: p.name, radius: 16),
                      const SizedBox(width: 10),
                      Expanded(child: Text(p.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: isMe ? FontWeight.w700 : FontWeight.normal))),
                      if (p.score != null)
                        Text('${p.score!.toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold, color: p.score! >= 60 ? AppColors.success : AppColors.error, fontSize: 15)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
            ElevatedButton.icon(
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.bar_chart),
              label: const Text('View Dashboard'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/home/exams'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
              child: const Text('Back to Exams'),
            ),
          ],
        ),
      ),
    );
  }
}
