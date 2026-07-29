import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/document_model.dart';
import '../../../../shared/models/quiz_model.dart';
import '../../../../shared/models/subject_model.dart';
import '../../../../shared/models/topic_model.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/content_copy_destination_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/quiz_card.dart';
import '../../../../shared/widgets/shared_content_context_banner.dart';
import '../../../../shared/widgets/topic_card.dart';
import '../../../../shared/widgets/visibility_badge.dart';
import '../../../documents/presentation/providers/document_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../quizzes/presentation/providers/quiz_provider.dart';
import '../../../topics/presentation/providers/topic_provider.dart';
import '../providers/subject_provider.dart';

class SubjectDetailScreen extends ConsumerStatefulWidget {
  final String subjectId;
  const SubjectDetailScreen({super.key, required this.subjectId});

  @override
  ConsumerState<SubjectDetailScreen> createState() =>
      _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends ConsumerState<SubjectDetailScreen> {
  Future<void> _createTopic() async {
    final created =
        await context.push<bool>('/subjects/${widget.subjectId}/topics/create');
    if (created == true && mounted) {
      await ref.read(topicProvider.notifier).loadForSubject(widget.subjectId);
      ref.invalidate(subjectTopicsProvider(widget.subjectId));
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

  Future<void> _copyTopic(TopicModel topic) async {
    await ref.read(subjectProvider.notifier).load();
    if (!mounted) return;
    final subjects =
        ref.read(subjectProvider).subjects.where((s) => !s.isArchived).toList();
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Create a subject before copying this topic.'),
          action: SnackBarAction(
            label: 'Create',
            onPressed: () => context.push('/subjects/create'),
          ),
        ),
      );
      return;
    }
    final targetSubjectId = await showTopicCopyDestinationDialog(
      context: context,
      topicName: topic.name,
      subjects: subjects,
    );
    if (targetSubjectId == null || !mounted) return;
    try {
      await ApiClient().dio.post(
        '/topics/${topic.id}/copy',
        data: {'targetSubjectId': targetSubjectId},
      );
      await ref.read(topicProvider.notifier).loadForSubject(targetSubjectId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Topic copied privately to your subject.'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => context.push('/subjects/$targetSubjectId'),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(error))),
        );
      }
    }
  }

  Future<void> _copyQuiz(QuizModel quiz, {String? initialSubjectId}) async {
    await ref.read(subjectProvider.notifier).load();
    if (!mounted) return;
    final subjects =
        ref.read(subjectProvider).subjects.where((s) => !s.isArchived).toList();
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Create a subject before copying this quiz.'),
          action: SnackBarAction(
            label: 'Create',
            onPressed: () => context.push('/subjects/create'),
          ),
        ),
      );
      return;
    }
    await Future.wait(subjects.map(
      (subject) => ref.read(topicProvider.notifier).loadForSubject(subject.id),
    ));
    if (!mounted) return;
    final topics =
        ref.read(topicProvider).topics.where((t) => !t.isArchived).toList();
    final destination = await showQuizCopyDestinationDialog(
      context: context,
      quizTitle: quiz.title,
      subjects: subjects,
      topics: topics,
      initialSubjectId: initialSubjectId,
    );
    if (destination == null || !mounted) return;
    if (destination.createTopic) {
      final created = await context.push<bool>(
        '/subjects/${destination.subjectId}/topics/create',
      );
      if (created == true && mounted) {
        await ref
            .read(topicProvider.notifier)
            .loadForSubject(destination.subjectId);
        if (mounted) {
          await _copyQuiz(quiz, initialSubjectId: destination.subjectId);
        }
      }
      return;
    }
    final targetTopicId = destination.topicId;
    if (targetTopicId == null) return;
    try {
      await ApiClient().dio.post(
        '/quizzes/${quiz.id}/copy',
        data: {'targetTopicId': targetTopicId},
      );
      ref.invalidate(subjectQuizzesProvider(destination.subjectId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Quiz copied privately to your topic.'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => context.push(
              '/subjects/${destination.subjectId}/topics/$targetTopicId',
            ),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(error))),
        );
      }
    }
  }

  Future<void> _copySubject(SubjectModel subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Copy “${subject.name}”?'),
        content: const Text(
          'A private, editable copy will be added to My Subjects. Only nested content whose owner enabled copying will be included.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text('Copy subject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final response =
          await ApiClient().dio.post('/subjects/${subject.id}/copy');
      await ref.read(subjectProvider.notifier).load();
      if (!mounted) return;
      final copied = response.data['copied'] as Map<String, dynamic>?;
      final topics = (copied?['topics'] as num?)?.toInt() ?? 0;
      final quizzes = (copied?['quizzes'] as num?)?.toInt() ?? 0;
      final documents = (copied?['documents'] as num?)?.toInt() ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Copied privately: $topics topics, $quizzes quizzes, $documents documents.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectId = widget.subjectId;
    final cachedSubject = ref.watch(subjectByIdProvider(subjectId));
    final remoteSubject = ref.watch(sharedSubjectDetailProvider(subjectId));
    final subject = cachedSubject ?? remoteSubject.asData?.value;
    if (subject == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Subject')),
        body: remoteSubject.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: AppSpacing.page,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline,
                      size: 44, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'This subject is unavailable',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'It may be private, removed, or no longer shared with you.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.invalidate(sharedSubjectDetailProvider(subjectId)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
          data: (_) => const SizedBox.shrink(),
        ),
      );
    }

    final currentUserId = ref.watch(authProvider).user?.id;
    final isOwner = subject.ownerId == currentUserId;

    final topicRequest = ref.watch(subjectTopicsProvider(subjectId));
    final cachedTopics = ref.watch(topicsBySubjectProvider(subjectId));
    final topics = topicRequest.asData?.value ?? cachedTopics;
    final quizRequest = ref.watch(subjectQuizzesProvider(subjectId));
    final documentRequest = ref.watch(subjectDocumentsProvider(subjectId));
    final quizzes = quizRequest.asData?.value ??
        ref
            .watch(quizProvider)
            .quizzes
            .where((quiz) => quiz.subjectId == subjectId)
            .toList();
    final List<DocumentModel> docs = documentRequest.asData?.value ??
        ref.watch(documentsBySubjectProvider(subjectId)) ??
        const <DocumentModel>[];
    final scored = quizzes.where((q) => q.bestScore != null).toList();
    final avgScore = scored.isEmpty
        ? 0.0
        : scored.fold<double>(0, (s, q) => s + q.bestScore!) / scored.length;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(subject.name),
          actions: isOwner
              ? [
                  IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () =>
                          context.push('/subjects/$subjectId/edit')),
                  PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onSelected: (v) async {
                      if (v == 'delete') {
                        final ok = await ConfirmDialog.show(context,
                            title: 'Delete Subject',
                            message:
                                'This will permanently delete the subject and all its content.',
                            confirmLabel: 'Delete',
                            isDestructive: true);
                        if (ok == true) {
                          await ref
                              .read(subjectProvider.notifier)
                              .deleteSubject(subjectId);
                          if (context.mounted) context.pop();
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'visibility',
                          child: Text('Change Visibility')),
                      const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete',
                              style: TextStyle(color: AppColors.error))),
                    ],
                  ),
                ]
              : subject.allowCopy
                  ? [
                      IconButton(
                        tooltip: 'Copy to My Subjects',
                        onPressed: () => _copySubject(subject),
                        icon: const Icon(Icons.copy_all_outlined),
                      ),
                    ]
                  : null,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Topics'),
              Tab(text: 'Quizzes'),
              Tab(text: 'Documents'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (!isOwner)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: SharedContentContextBanner(
                  title:
                      'Viewing ${subject.ownerName ?? 'another student'}’s subject',
                  message:
                      'Create and upload actions are available only in your own subjects. You can practise or copy items when the owner allows it.',
                  badgeLabel: 'Shared subject',
                ),
              ),
            Container(
              padding: AppSpacing.page,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subject.description != null)
                    Text(subject.description!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      VisibilityBadge(visibility: subject.visibility),
                      if (subject.allowCopy) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.3))),
                          child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy,
                                    size: 11, color: AppColors.accent),
                                SizedBox(width: 4),
                                Text('Copyable',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w600))
                              ]),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatPill(
                          label: '${topics.length} Topics',
                          icon: Icons.book_outlined),
                      _StatPill(
                          label: '${quizzes.length} Quizzes',
                          icon: Icons.quiz_outlined),
                      _StatPill(
                          label: '${avgScore.toStringAsFixed(0)}% Avg',
                          icon: Icons.bar_chart),
                      if (isOwner && subject.copiedByCount > 0)
                        _StatPill(
                            label: '${subject.copiedByCount} Copied',
                            icon: Icons.people_alt_outlined),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  topicRequest.isLoading && topics.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : topicRequest.hasError && topics.isEmpty
                          ? ErrorState(
                              message: 'Could not load this subject\'s topics.',
                              onRetry: () => ref
                                  .invalidate(subjectTopicsProvider(subjectId)),
                            )
                          : topics.isEmpty
                              ? EmptyState(
                                  icon: Icons.topic_outlined,
                                  title: 'No visible topics',
                                  message: isOwner
                                      ? 'Add topics to organize your subject content'
                                      : 'This subject has no topics shared with you',
                                  actionLabel: isOwner ? 'Add Topic' : null,
                                  onAction: isOwner ? _createTopic : null)
                              : ListView.separated(
                                  padding: AppSpacing.list,
                                  itemCount: topics.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (_, i) => TopicCard(
                                    topic: topics[i],
                                    onTap: () => context.push(
                                        '/subjects/$subjectId/topics/${topics[i].id}'),
                                    onEdit: isOwner
                                        ? () => context.push(
                                            '/topics/${topics[i].id}/edit')
                                        : null,
                                    onCopy: !isOwner && topics[i].allowCopy
                                        ? () => _copyTopic(topics[i])
                                        : null,
                                  ),
                                ),
                  quizRequest.isLoading && quizzes.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : quizRequest.hasError && quizzes.isEmpty
                          ? ErrorState(
                              message:
                                  'Could not load this subject\'s quizzes.',
                              onRetry: () => ref.invalidate(
                                  subjectQuizzesProvider(subjectId)),
                            )
                          : quizzes.isEmpty
                              ? EmptyState(
                                  icon: Icons.quiz_outlined,
                                  title: 'No visible quizzes',
                                  message: isOwner
                                      ? 'Create quizzes to test your knowledge'
                                      : 'This subject has no quizzes shared with you',
                                  actionLabel: isOwner ? 'Create Quiz' : null,
                                  onAction: isOwner
                                      ? () => context.push('/quizzes/create')
                                      : null)
                              : ListView.separated(
                                  padding: AppSpacing.list,
                                  itemCount: quizzes.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (_, i) => QuizCard(
                                    quiz: quizzes[i],
                                    onPractice: () => context.push(
                                        '/quizzes/${quizzes[i].id}/attempt'),
                                    onEdit: isOwner
                                        ? () => _editQuiz(quizzes[i].id)
                                        : null,
                                    onDelete: isOwner
                                        ? () => _deleteQuiz(
                                            quizzes[i].id, quizzes[i].title)
                                        : null,
                                    onCopy: !isOwner && quizzes[i].allowCopy
                                        ? () => _copyQuiz(quizzes[i])
                                        : null,
                                  ),
                                ),
                  documentRequest.isLoading && docs.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : documentRequest.hasError && docs.isEmpty
                          ? ErrorState(
                              message:
                                  'Could not load this subject\'s documents.',
                              onRetry: () => ref.invalidate(
                                  subjectDocumentsProvider(subjectId)),
                            )
                          : docs.isEmpty
                              ? EmptyState(
                                  icon: Icons.folder_outlined,
                                  title: 'No visible documents',
                                  message: isOwner
                                      ? 'Upload documents for this subject'
                                      : 'This subject has no documents shared with you',
                                  actionLabel: isOwner ? 'Upload' : null,
                                  onAction: isOwner
                                      ? () => context.push('/documents/upload')
                                      : null)
                              : ListView.builder(
                                  padding: AppSpacing.list,
                                  itemCount: docs.length,
                                  itemBuilder: (_, i) => _DocTile(
                                      doc: docs[i],
                                      onTap: () => context.push(
                                          '/documents/${docs[i].id}/view')),
                                ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: isOwner
            ? Builder(
                builder: (ctx) {
                  final tab = DefaultTabController.of(ctx).index;
                  return FloatingActionButton(
                    heroTag: 'subject_fab',
                    onPressed: () {
                      if (tab == 0) {
                        _createTopic();
                      } else if (tab == 1) {
                        context.push('/quizzes/create');
                      } else {
                        context.push('/documents/upload');
                      }
                    },
                    child: const Icon(Icons.add),
                  );
                },
              )
            : null,
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _StatPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _DocTile extends StatelessWidget {
  final DocumentModel doc;
  final VoidCallback onTap;
  const _DocTile({required this.doc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPdf = !doc.fileType.isImage;
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: (isPdf ? AppColors.error : AppColors.primary)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(isPdf ? Icons.picture_as_pdf : Icons.image_outlined,
            color: isPdf ? AppColors.error : AppColors.primary),
      ),
      title: Text(doc.title,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(
          '${doc.fileType.label} • ${(doc.fileSizeBytes / 1024 / 1024).toStringAsFixed(1)}MB'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }
}
