import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/models/document_model.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/quiz_card.dart';
import '../../../../shared/widgets/shared_content_context_banner.dart';
import '../../../../shared/widgets/visibility_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../documents/presentation/providers/document_provider.dart';
import '../../../exams/presentation/widgets/related_exams_section.dart';
import '../../../quizzes/presentation/providers/quiz_provider.dart';
import '../../../subjects/presentation/providers/subject_provider.dart';
import '../providers/topic_provider.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String topicId;
  const TopicDetailScreen(
      {super.key, required this.subjectId, required this.topicId});

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(topicProvider.notifier).loadOne(widget.topicId);
    });
  }

  Future<void> _createQuiz() async {
    final created = await context.push<bool>(
      '/quizzes/create',
      extra: {
        'subjectId': widget.subjectId,
        'topicId': widget.topicId,
      },
    );
    if (created == true && mounted) {
      await ref.read(quizProvider.notifier).load();
    }
  }

  Future<void> _editQuiz(String quizId) async {
    final changed = await context.push<bool>('/quizzes/$quizId/edit');
    if (changed == true && mounted) {
      await ref.read(quizProvider.notifier).load();
    }
  }

  Future<void> _deleteQuiz(String quizId, String title) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Quiz',
      message:
          'Delete "$title" and all of its questions and attempts? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true && mounted) {
      await ref.read(quizProvider.notifier).deleteQuiz(quizId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topicId = widget.topicId;
    final topic = ref.watch(topicByIdProvider(topicId));
    if (topic == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final cachedSubject = ref.watch(subjectByIdProvider(widget.subjectId));
    final sharedSubject =
        ref.watch(sharedSubjectDetailProvider(widget.subjectId));
    final subject = cachedSubject ?? sharedSubject.asData?.value;
    if (subject == null) {
      return Scaffold(
        appBar: AppBar(title: Text(topic.name)),
        body: sharedSubject.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(
            child: Text('This subject is no longer available to you.'),
          ),
          data: (_) => const SizedBox.shrink(),
        ),
      );
    }

    final currentUserId = ref.watch(authProvider).user?.id;
    final isOwner = subject.ownerId == currentUserId;

    final quizzes = ref
        .watch(quizProvider)
        .quizzes
        .where((q) => q.topicId == topicId)
        .toList();
    final docs = ref.watch(documentsByTopicProvider(topicId));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(topic.name),
          actions: isOwner
              ? [
                  IconButton(
                    tooltip: 'Create quiz',
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _createQuiz,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => context.push('/topics/$topicId/edit'),
                  ),
                ]
              : null,
          bottom: const TabBar(tabs: [
            Tab(text: 'Quizzes'),
            Tab(text: 'Exams'),
            Tab(text: 'Documents'),
          ]),
        ),
        body: Column(
          children: [
            if (!isOwner)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: SharedContentContextBanner(
                  title:
                      'Viewing ${subject.ownerName ?? 'another student'}’s topic',
                  message:
                      'This topic is shared with you. Create, edit, and upload actions stay inside your own subjects.',
                  badgeLabel: 'Shared topic',
                ),
              ),
            Padding(
              padding: AppSpacing.page,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (topic.description != null)
                    Text(topic.description!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  VisibilityBadge(visibility: topic.visibility),
                  if (topic.nextRevisionDate != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3))),
                      child: Row(
                        children: [
                          const Icon(Icons.access_alarm,
                              color: AppColors.warning, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Next revision: ${AppHelpers.nextRevisionLabel(topic.nextRevisionDate!)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.warning)),
                                if (topic.lastScore != null)
                                  Text(
                                      'Last score: ${topic.lastScore!.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: quizzes.isEmpty
                                ? null
                                : () => context.push(
                                    '/quizzes/${quizzes.first.id}/attempt'),
                            style: ElevatedButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12)),
                            child: const Text('Practice'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  quizzes.isEmpty
                      ? EmptyState(
                          icon: Icons.quiz_outlined,
                          title: 'No visible quizzes',
                          message: isOwner
                              ? 'Create a quiz for this topic'
                              : 'This student has not shared any quizzes here',
                          actionLabel: isOwner ? 'Create Quiz' : null,
                          onAction: isOwner ? _createQuiz : null,
                        )
                      : ListView.separated(
                          padding: AppSpacing.list,
                          itemCount: quizzes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => QuizCard(
                            quiz: quizzes[i],
                            onPractice: () => context
                                .push('/quizzes/${quizzes[i].id}/attempt'),
                            onEdit:
                                isOwner ? () => _editQuiz(quizzes[i].id) : null,
                            onDelete: isOwner
                                ? () => _deleteQuiz(
                                      quizzes[i].id,
                                      quizzes[i].title,
                                    )
                                : null,
                          ),
                        ),
                  RelatedExamsSection(
                    subjectId: widget.subjectId,
                    topicId: topicId,
                  ),
                  docs.isEmpty
                      ? EmptyState(
                          icon: Icons.folder_outlined,
                          title: 'No visible documents',
                          message: isOwner
                              ? 'Upload documents for this topic'
                              : 'This student has not shared any documents here',
                          actionLabel: isOwner ? 'Upload' : null,
                          onAction: isOwner
                              ? () => context.push('/documents/upload')
                              : null,
                        )
                      : ListView.builder(
                          padding: AppSpacing.list,
                          itemCount: docs.length,
                          itemBuilder: (_, i) => ListTile(
                            leading: const Icon(Icons.attach_file,
                                color: AppColors.primary),
                            title: Text(docs[i].title),
                            subtitle: Text(docs[i].fileType.label),
                            onTap: () =>
                                context.push('/documents/${docs[i].id}/view'),
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
