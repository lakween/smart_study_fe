import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/document_model.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/quiz_card.dart';
import '../../../../shared/widgets/subject_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../documents/presentation/providers/document_provider.dart';
import '../../../quizzes/presentation/providers/quiz_provider.dart';
import '../../../subjects/presentation/providers/subject_provider.dart';

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final mySubjects = ref.watch(subjectProvider).subjects.where((s) => s.ownerId == user.id).toList();
    final myQuizzes = ref.watch(quizProvider).quizzes.where((q) => q.ownerId == user.id).toList();
    final myDocuments = ref.watch(documentProvider).documents.where((d) => d.ownerId == user.id).toList();
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          actions: [
            IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => context.push('/settings')),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.8), AppColors.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            AvatarWidget(name: user.fullName, imageUrl: user.profileImageUrl, radius: 40),
                            Positioned(
                              bottom: 0, right: 0,
                              child: GestureDetector(
                                onTap: () => context.push('/profile/edit'),
                                child: Container(
                                  width: 28, height: 28,
                                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                  child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(user.fullName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        if (user.bio != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                            child: Text(user.bio!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
                          ),
                        if (user.university != null)
                          Text(user.university!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatItem(label: 'Subjects', value: '${mySubjects.length}'),
                              _StatItem(label: 'Quizzes', value: '${user.quizzesAttempted}'),
                              _StatItem(label: 'Avg Score', value: '${user.avgScore.toStringAsFixed(0)}%'),
                              _StatItem(label: 'Friends', value: '${user.friendCount}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ElevatedButton(
                            onPressed: () => context.push('/profile/edit'),
                            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 40)),
                            child: const Text('Edit Profile'),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  const TabBar(tabs: [Tab(text: 'Subjects'), Tab(text: 'Quizzes'), Tab(text: 'Documents')]),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              mySubjects.isEmpty
                  ? EmptyState(icon: Icons.book_outlined, title: 'No subjects', message: 'Create your first subject', actionLabel: 'Create', onAction: () => context.push('/subjects/create'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.82),
                      itemCount: mySubjects.length,
                      itemBuilder: (_, i) => SubjectCard(subject: mySubjects[i], onTap: () => context.push('/subjects/${mySubjects[i].id}')),
                    ),
              myQuizzes.isEmpty
                  ? const EmptyState(icon: Icons.quiz_outlined, title: 'No quizzes', message: 'Create your first quiz')
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: myQuizzes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => QuizCard(quiz: myQuizzes[i], onPractice: () => context.push('/quizzes/${myQuizzes[i].id}/attempt')),
                    ),
              myDocuments.isEmpty
                  ? EmptyState(icon: Icons.folder_outlined, title: 'No documents', message: 'Upload your first document', actionLabel: 'Upload', onAction: () => context.push('/documents/upload'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: myDocuments.length,
                      itemBuilder: (_, i) => ListTile(
                        leading: const Icon(Icons.attach_file, color: AppColors.primary),
                        title: Text(myDocuments[i].title),
                        subtitle: Text(myDocuments[i].fileType.label),
                        onTap: () => context.push('/documents/${myDocuments[i].id}/view'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
  ]);
}
