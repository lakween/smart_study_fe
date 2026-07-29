import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/subject_model.dart';
import 'visibility_badge.dart';
import 'avatar_widget.dart';

class SubjectCard extends StatelessWidget {
  final SubjectModel subject;
  final bool isOwn;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onChangeVisibility;
  final VoidCallback? onArchive;

  const SubjectCard({
    super.key,
    required this.subject,
    this.isOwn = true,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onChangeVisibility,
    this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBg : AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark ? [] : AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            subject.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOwn)
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            iconSize: 18,
                            icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (val) {
                              if (val == 'edit') onEdit?.call();
                              if (val == 'delete') onDelete?.call();
                              if (val == 'visibility') onChangeVisibility?.call();
                              if (val == 'archive') onArchive?.call();
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit')])),
                              const PopupMenuItem(value: 'visibility', child: Row(children: [Icon(Icons.lock_outline, size: 16), SizedBox(width: 8), Text('Change Visibility')])),
                              PopupMenuItem(
                                value: 'archive',
                                child: Row(children: [
                                  Icon(subject.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined, size: 16),
                                  const SizedBox(width: 8),
                                  Text(subject.isArchived ? 'Restore' : 'Archive'),
                                ]),
                              ),
                              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
                            ],
                          ),
                      ],
                    ),
                    if (subject.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subject.description!,
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.book_outlined, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text('${subject.topicCount}', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                        const SizedBox(width: 8),
                        const Icon(Icons.quiz_outlined, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text('${subject.quizCount}', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    VisibilityBadge(visibility: subject.visibility),
                    if (!isOwn && subject.ownerName != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          AvatarWidget(name: subject.ownerName!, radius: 10),
                          const SizedBox(width: 6),
                          Text(subject.ownerName!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
