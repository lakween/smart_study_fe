import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/document_model.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/quiz_card.dart';
import '../../../../shared/widgets/topic_card.dart';
import '../../../../shared/widgets/visibility_badge.dart';
import '../../../documents/presentation/providers/document_provider.dart';
import '../../../quizzes/presentation/providers/quiz_provider.dart';
import '../../../topics/presentation/providers/topic_provider.dart';
import '../providers/subject_provider.dart';

class SubjectDetailScreen extends ConsumerStatefulWidget {
  final String subjectId;
  const SubjectDetailScreen({super.key, required this.subjectId});

  @override
  ConsumerState<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends ConsumerState<SubjectDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(topicProvider.notifier).loadForSubject(widget.subjectId);
    });
  }

  Future<void> _createTopic() async {
    final created = await context.push<bool>('/subjects/${widget.subjectId}/topics/create');
    if (created == true && mounted) {
      await ref.read(topicProvider.notifier).loadForSubject(widget.subjectId);
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
      message: 'Delete "$title" and all of its questions and attempts? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true && mounted) {
      await ref.read(quizProvider.notifier).deleteQuiz(quizId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectId = widget.subjectId;
    final subject = ref.watch(subjectByIdProvider(subjectId));
    if (subject == null) return const Scaffold(body: Center(child: Text('Subject not found')));

    final topics = ref.watch(topicsBySubjectProvider(subjectId));
    final quizzes = ref.watch(quizProvider).quizzes.where((q) => q.subjectId == subjectId).toList();
    final docs = ref.watch(documentsBySubjectProvider(subjectId));
    final scored = quizzes.where((q) => q.bestScore != null).toList();
    final avgScore = scored.isEmpty ? 0.0 : scored.fold<double>(0, (s, q) => s + q.bestScore!) / scored.length;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(subject.name),
          actions: [
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => context.push('/subjects/$subjectId/edit')),
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (v) async {
                if (v == 'delete') {
                  final ok = await ConfirmDialog.show(context, title: 'Delete Subject', message: 'This will permanently delete the subject and all its content.', confirmLabel: 'Delete', isDestructive: true);
                  if (ok == true) {
                    await ref.read(subjectProvider.notifier).deleteSubject(subjectId);
                    if (context.mounted) context.pop();
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'visibility', child: Text('Change Visibility')),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
              ],
            ),
          ],
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
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subject.description != null)
                    Text(subject.description!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      VisibilityBadge(visibility: subject.visibility),
                      if (subject.allowCopy) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.accent.withValues(alpha: 0.3))),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.copy, size: 11, color: AppColors.accent), SizedBox(width: 4), Text('Copyable', style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600))]),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatPill(label: '${topics.length} Topics', icon: Icons.book_outlined),
                      const SizedBox(width: 8),
                      _StatPill(label: '${quizzes.length} Quizzes', icon: Icons.quiz_outlined),
                      const SizedBox(width: 8),
                      _StatPill(label: '${avgScore.toStringAsFixed(0)}% Avg', icon: Icons.bar_chart),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  topics.isEmpty
                      ? EmptyState(icon: Icons.topic_outlined, title: 'No topics yet', message: 'Add topics to organize your subject content', actionLabel: 'Add Topic', onAction: _createTopic)
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: topics.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => TopicCard(
                            topic: topics[i],
                            onTap: () => context.push('/subjects/$subjectId/topics/${topics[i].id}'),
                            onEdit: () => context.push('/topics/${topics[i].id}/edit'),
                          ),
                        ),
                  quizzes.isEmpty
                      ? EmptyState(icon: Icons.quiz_outlined, title: 'No quizzes yet', message: 'Create quizzes to test your knowledge', actionLabel: 'Create Quiz', onAction: () => context.push('/quizzes/create'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: quizzes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => QuizCard(
                            quiz: quizzes[i],
                            onPractice: () => context.push('/quizzes/${quizzes[i].id}/attempt'),
                            onEdit: () => _editQuiz(quizzes[i].id),
                            onDelete: () => _deleteQuiz(quizzes[i].id, quizzes[i].title),
                          ),
                        ),
                  docs.isEmpty
                      ? EmptyState(icon: Icons.folder_outlined, title: 'No documents yet', message: 'Upload documents for this subject', actionLabel: 'Upload', onAction: () => context.push('/documents/upload'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: docs.length,
                          itemBuilder: (_, i) => _DocTile(doc: docs[i], onTap: () => context.push('/documents/${docs[i].id}/view')),
                        ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (ctx) {
            final tab = DefaultTabController.of(ctx).index;
            return FloatingActionButton(
              heroTag: 'subject_fab',
              onPressed: () {
                if (tab == 0) {
                  _createTopic();
                } else if (tab == 1) context.push('/quizzes/create');
                else context.push('/documents/upload');
              },
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label; final IconData icon;
  const _StatPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _DocTile extends StatelessWidget {
  final DocumentModel doc; final VoidCallback onTap;
  const _DocTile({required this.doc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPdf = !doc.fileType.isImage;
    return ListTile(
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: (isPdf ? AppColors.error : AppColors.primary).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(isPdf ? Icons.picture_as_pdf : Icons.image_outlined, color: isPdf ? AppColors.error : AppColors.primary),
      ),
      title: Text(doc.title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text('${doc.fileType.label} • ${(doc.fileSizeBytes / 1024 / 1024).toStringAsFixed(1)}MB'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }
}
