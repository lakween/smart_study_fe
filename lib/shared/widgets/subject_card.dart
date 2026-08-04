import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../models/subject_model.dart';
import '../models/user_model.dart';
import 'avatar_widget.dart';
import 'visibility_badge.dart';

class SubjectCard extends StatelessWidget {
  final SubjectModel subject;
  final bool isOwn;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onChangeVisibility;
  final VoidCallback? onArchive;
  final VoidCallback? onCopy;

  const SubjectCard({
    super.key,
    required this.subject,
    this.isOwn = true,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onChangeVisibility,
    this.onArchive,
    this.onCopy,
  });

  Color _accentColor() {
    switch (subject.visibility) {
      case ContentVisibility.private:
        return AppColors.primary;
      case ContentVisibility.friendsOnly:
        return AppColors.warning;
      case ContentVisibility.public:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _accentColor();
    final description = subject.description?.trim();
    final score = subject.avgScore.clamp(0, 100).toDouble();

    return Semantics(
      button: onTap != null,
      label:
          '${subject.name}, ${subject.topicCount} topics, ${subject.quizCount} quizzes',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBg : AppColors.cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? AppColors.darkDivider
                    : accent.withValues(alpha: 0.16),
              ),
              boxShadow: isDark ? const [] : AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: isDark ? 0.24 : 0.15),
                        AppColors.violet
                            .withValues(alpha: isDark ? 0.12 : 0.05),
                      ],
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(21)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          subject.name.isEmpty
                              ? '?'
                              : subject.name[0].toUpperCase(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Updated ${AppHelpers.timeAgo(subject.updatedAt.toLocal())}',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      if (isOwn)
                        _SubjectMenu(
                            subject: subject,
                            onEdit: onEdit,
                            onDelete: onDelete,
                            onChangeVisibility: onChangeVisibility,
                            onArchive: onArchive),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description == null || description.isEmpty
                            ? 'Keep your topics, quizzes, and study material together.'
                            : description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: description == null || description.isEmpty
                              ? AppColors.textMuted
                              : theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Expanded(
                              child: _Metric(
                                  icon: Icons.topic_outlined,
                                  value: '${subject.topicCount}',
                                  label: 'Topics',
                                  color: AppColors.primary)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _Metric(
                                  icon: Icons.quiz_outlined,
                                  value: '${subject.quizCount}',
                                  label: 'Quizzes',
                                  color: AppColors.violet)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _Metric(
                                  icon: Icons.insights_outlined,
                                  value: '${score.round()}%',
                                  label: 'Average',
                                  color: AppColors.accent)),
                        ],
                      ),
                      const SizedBox(height: 9),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          minHeight: 5,
                          color: score >= 60
                              ? AppColors.accent
                              : AppColors.warning,
                          backgroundColor:
                              (isDark ? Colors.white : AppColors.primary)
                                  .withValues(alpha: 0.09),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          VisibilityBadge(visibility: subject.visibility),
                          if (subject.allowCopy) ...[
                            const SizedBox(width: 7),
                            const _CopyBadge(),
                          ],
                          if (subject.isArchived) ...[
                            const SizedBox(width: 7),
                            const _StatusBadge(
                                icon: Icons.archive_outlined,
                                label: 'Archived'),
                          ],
                          if (isOwn && subject.copiedByCount > 0) ...[
                            const SizedBox(width: 7),
                            _StatusBadge(
                              icon: Icons.people_alt_outlined,
                              label: '${subject.copiedByCount} copied',
                            ),
                          ],
                          const Spacer(),
                          if (!isOwn && subject.allowCopy && onCopy != null)
                            IconButton.filledTonal(
                              tooltip: 'Copy to My Subjects',
                              visualDensity: VisualDensity.compact,
                              onPressed: onCopy,
                              icon:
                                  const Icon(Icons.copy_all_outlined, size: 17),
                            ),
                          if (!isOwn && subject.allowCopy && onCopy != null)
                            const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded,
                              size: 18, color: accent),
                        ],
                      ),
                      if (subject.originalCreatorName != null ||
                          (!isOwn && subject.ownerName != null)) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            AvatarWidget(
                                name: subject.originalCreatorName ??
                                    subject.ownerName!,
                                radius: 10),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                subject.originalCreatorName != null
                                    ? 'Originally by ${subject.originalCreatorName}'
                                    : 'Shared by ${subject.ownerName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textMuted),
                              ),
                            ),
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
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _Metric(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(value,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}

class _CopyBadge extends StatelessWidget {
  const _CopyBadge();

  @override
  Widget build(BuildContext context) =>
      const _StatusBadge(icon: Icons.copy_all_outlined, label: 'Copy allowed');
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatusBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
        ]),
      );
}

class _SubjectMenu extends StatelessWidget {
  final SubjectModel subject;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onChangeVisibility;
  final VoidCallback? onArchive;

  const _SubjectMenu(
      {required this.subject,
      this.onEdit,
      this.onDelete,
      this.onChangeVisibility,
      this.onArchive});

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        tooltip: 'Subject options',
        icon: const Icon(Icons.more_horiz_rounded),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onSelected: (value) {
          if (value == 'edit') onEdit?.call();
          if (value == 'visibility') onChangeVisibility?.call();
          if (value == 'archive') onArchive?.call();
          if (value == 'delete') onDelete?.call();
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
              value: 'edit',
              child: _MenuItem(icon: Icons.edit_outlined, label: 'Edit')),
          const PopupMenuItem(
              value: 'visibility',
              child: _MenuItem(
                  icon: Icons.lock_outline, label: 'Change visibility')),
          PopupMenuItem(
              value: 'archive',
              child: _MenuItem(
                  icon: subject.isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                  label: subject.isArchived ? 'Restore' : 'Archive')),
          const PopupMenuItem(
              value: 'delete',
              child: _MenuItem(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: AppColors.error)),
        ],
      );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MenuItem({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ]);
}
