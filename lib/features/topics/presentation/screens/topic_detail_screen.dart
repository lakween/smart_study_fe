import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/models/document_model.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/quiz_card.dart';
import '../../../../shared/widgets/visibility_badge.dart';
import '../../../documents/presentation/providers/document_provider.dart';
import '../../../quizzes/presentation/providers/quiz_provider.dart';
import '../providers/topic_provider.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String topicId;
  const TopicDetailScreen({super.key, required this.subjectId, required this.topicId});

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

  @override
  Widget build(BuildContext context) {
    final topicId = widget.topicId;
    final topic = ref.watch(topicByIdProvider(topicId));
    if (topic == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final quizzes = ref.watch(quizProvider).quizzes.where((q) => q.topicId == topicId).toList();
    final docs = ref.watch(documentsByTopicProvider(topicId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(topic.name),
          actions: [
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => context.push('/topics/${topicId}/edit')),
          ],
          bottom: const TabBar(tabs: [Tab(text: 'Quizzes'), Tab(text: 'Documents')]),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (topic.description != null)
                    Text(topic.description!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  VisibilityBadge(visibility: topic.visibility),
                  if (topic.nextRevisionDate != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.warning.withOpacity(0.3))),
                      child: Row(
                        children: [
                          const Icon(Icons.access_alarm, color: AppColors.warning, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Next revision: ${AppHelpers.nextRevisionLabel(topic.nextRevisionDate!)}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.warning)),
                                if (topic.lastScore != null)
                                  Text('Last score: ${topic.lastScore!.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: quizzes.isEmpty ? null : () => context.push('/quizzes/${quizzes.first.id}/attempt'),
                            style: ElevatedButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), textStyle: const TextStyle(fontSize: 12)),
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
                      ? EmptyState(icon: Icons.quiz_outlined, title: 'No quizzes', message: 'Create a quiz for this topic', actionLabel: 'Create Quiz', onAction: () => context.push('/quizzes/create'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: quizzes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => QuizCard(quiz: quizzes[i], onPractice: () => context.push('/quizzes/${quizzes[i].id}/attempt')),
                        ),
                  docs.isEmpty
                      ? EmptyState(icon: Icons.folder_outlined, title: 'No documents', message: 'Upload documents for this topic', actionLabel: 'Upload', onAction: () => context.push('/documents/upload'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: docs.length,
                          itemBuilder: (_, i) => ListTile(
                            leading: const Icon(Icons.attach_file, color: AppColors.primary),
                            title: Text(docs[i].title),
                            subtitle: Text(docs[i].fileType.label),
                            onTap: () => context.push('/documents/${docs[i].id}/view'),
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
