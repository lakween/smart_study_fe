import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/topic_model.dart';
import '../../core/utils/helpers.dart';
import 'visibility_badge.dart';

class TopicCard extends StatelessWidget {
  final TopicModel topic;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TopicCard({super.key, required this.topic, this.onTap, this.onEdit, this.onDelete});

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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.topic_outlined, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(topic.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        icon: Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (val) {
                          if (val == 'edit') onEdit?.call();
                          if (val == 'delete') onDelete?.call();
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                        ],
                      ),
                    ],
                  ),
                  if (topic.description != null)
                    Text(topic.description!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      VisibilityBadge(visibility: topic.visibility),
                      const SizedBox(width: 8),
                      Icon(Icons.quiz_outlined, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('${topic.quizCount}', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                      if (topic.lastScore != null) ...[
                        const Spacer(),
                        Text(
                          '${topic.lastScore!.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold,
                            color: topic.lastScore! >= 60 ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (topic.nextRevisionDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Revision: ${AppHelpers.nextRevisionLabel(topic.nextRevisionDate!)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
