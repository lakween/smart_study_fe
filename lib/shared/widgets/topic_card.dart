import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../shared/models/topic_model.dart';
import 'visibility_badge.dart';

class TopicCard extends StatelessWidget {
  final TopicModel topic;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCopy;

  const TopicCard({
    super.key,
    required this.topic,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final score = topic.lastScore;
    final scoreColor = score == null
        ? AppColors.textMuted
        : score >= 60
            ? AppColors.success
            : AppColors.error;

    return Material(
      color: isDark ? AppColors.darkCardBg : AppColors.cardBg,
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: AppColors.primary),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryLight
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.22),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: Colors.white,
                                size: 23,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    topic.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                                  ),
                                  if (topic.description?.trim().isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 5),
                                    Text(
                                      topic.description!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textMuted,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (onEdit != null ||
                                onDelete != null ||
                                onCopy != null)
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.more_horiz,
                                  color: AppColors.textMuted,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (value) {
                                  if (value == 'edit') onEdit?.call();
                                  if (value == 'delete') onDelete?.call();
                                  if (value == 'copy') onCopy?.call();
                                },
                                itemBuilder: (_) => [
                                  if (onCopy != null)
                                    const PopupMenuItem(
                                      value: 'copy',
                                      child: Row(
                                        children: [
                                          Icon(Icons.copy_all_outlined,
                                              size: 18),
                                          SizedBox(width: 10),
                                          Text('Copy to my subject'),
                                        ],
                                      ),
                                    ),
                                  if (onEdit != null)
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 18),
                                          SizedBox(width: 10),
                                          Text('Edit topic'),
                                        ],
                                      ),
                                    ),
                                  if (onDelete != null)
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline,
                                              size: 18, color: AppColors.error),
                                          SizedBox(width: 10),
                                          Text('Delete',
                                              style: TextStyle(
                                                  color: AppColors.error)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            VisibilityBadge(visibility: topic.visibility),
                            _InfoChip(
                              icon: Icons.quiz_outlined,
                              label:
                                  '${topic.quizCount} ${topic.quizCount == 1 ? 'quiz' : 'quizzes'}',
                              color: AppColors.primary,
                            ),
                            if (topic.allowCopy)
                              const _InfoChip(
                                icon: Icons.copy_all_outlined,
                                label: 'Copyable',
                                color: AppColors.accent,
                              ),
                            if ((onEdit != null || onDelete != null) &&
                                topic.copiedByCount > 0)
                              _InfoChip(
                                icon: Icons.people_alt_outlined,
                                label:
                                    '${topic.copiedByCount} ${topic.copiedByCount == 1 ? 'student' : 'students'} copied',
                                color: AppColors.violet,
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: scoreColor.withValues(
                                alpha: isDark ? 0.12 : 0.07),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: score == null
                              ? const Row(
                                  children: [
                                    Icon(Icons.insights_outlined,
                                        size: 18, color: AppColors.textMuted),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'No quiz attempts yet',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.insights_rounded,
                                            size: 18, color: scoreColor),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Latest performance',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${score.toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            color: scoreColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: (score / 100)
                                            .clamp(0.0, 1.0)
                                            .toDouble(),
                                        minHeight: 6,
                                        color: scoreColor,
                                        backgroundColor:
                                            scoreColor.withValues(alpha: 0.16),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        if (topic.nextRevisionDate != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.event_repeat_rounded,
                                size: 17,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  'Next revision ${AppHelpers.nextRevisionLabel(topic.nextRevisionDate!)}',
                                  style: const TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
