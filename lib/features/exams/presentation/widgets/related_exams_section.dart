import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/exam_model.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../providers/exam_provider.dart';

class RelatedExamsSection extends ConsumerWidget {
  final String? subjectId;
  final String? topicId;

  const RelatedExamsSection({super.key, this.subjectId, this.topicId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (subjectId: subjectId, topicId: topicId);
    final request = ref.watch(relatedExamsProvider(query));
    return request.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => ErrorState(
        message: 'Could not load related exams.',
        onRetry: () => ref.invalidate(relatedExamsProvider(query)),
      ),
      data: (exams) => exams.isEmpty
          ? const EmptyState(
              icon: Icons.assignment_outlined,
              title: 'No related exams',
              message: 'Exams classified here will appear automatically.',
            )
          : ListView.separated(
              padding: AppSpacing.list,
              itemCount: exams.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) => _RelatedExamCard(exam: exams[index]),
            ),
    );
  }
}

class _RelatedExamCard extends StatelessWidget {
  final ExamModel exam;

  const _RelatedExamCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    final color = switch (exam.status) {
      ExamStatus.started => AppColors.warning,
      ExamStatus.completed => AppColors.success,
      ExamStatus.cancelled => AppColors.error,
      _ => AppColors.primary,
    };
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/exams/${exam.id}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.assignment_outlined, color: color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exam.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      '${exam.questionCount} questions · ${exam.durationMinutes} min · ${exam.status.label}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
