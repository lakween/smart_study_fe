import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../shared/models/quiz_model.dart';
import 'visibility_badge.dart';

class QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final VoidCallback? onPractice;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const QuizCard({
    super.key,
    required this.quiz,
    this.onPractice,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? [] : AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(quiz.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        '${quiz.subjectName} › ${quiz.topicName}',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (quiz.bestScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (quiz.bestScore! >= 60 ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${quiz.bestScore!.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold,
                        color: quiz.bestScore! >= 60 ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                      if (value == 'edit') onEdit?.call();
                      if (value == 'delete') onDelete?.call();
                    },
                    itemBuilder: (_) => [
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit quiz')]),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))]),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.help_outline, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('${quiz.questionCount} questions', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                if (quiz.timeLimitMinutes != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('${quiz.timeLimitMinutes}m', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                ],
                if (quiz.lastAttemptDate != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(AppHelpers.timeAgo(quiz.lastAttemptDate!), style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                VisibilityBadge(visibility: quiz.visibility),
                if (quiz.isAiGenerated) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 11, color: Colors.white),
                        SizedBox(width: 4),
                        Text('AI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
                if ((onEdit != null || onDelete != null) && quiz.copiedByCount > 0) ...[
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_alt_outlined, size: 14, color: AppColors.violet),
                      const SizedBox(width: 4),
                      Text(
                        '${quiz.copiedByCount} copied',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.violet, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
                const Spacer(),
                if (onPractice != null)
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: onPractice,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: Size.zero,
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Practice'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
