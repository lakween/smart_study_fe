import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/quiz_card.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/quiz_provider.dart';

class QuizListScreen extends ConsumerStatefulWidget {
  const QuizListScreen({super.key});

  @override
  ConsumerState<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends ConsumerState<QuizListScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizProvider);
    final currentUserId = ref.watch(authProvider).user?.id;
    var quizzes = state.quizzes;
    if (_filter == 'mine') {
      quizzes = quizzes.where((q) => q.ownerId == currentUserId).toList();
    } else if (_filter == 'friends') {
      quizzes = quizzes.where((q) => q.ownerId != currentUserId).toList();
    } else if (_filter == 'ai') {
      quizzes = quizzes.where((q) => q.isAiGenerated).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _Chip(label: 'All', value: 'all', selected: _filter, onTap: (v) => setState(() => _filter = v)),
                const SizedBox(width: 8),
                _Chip(label: 'My Quizzes', value: 'mine', selected: _filter, onTap: (v) => setState(() => _filter = v)),
                const SizedBox(width: 8),
                _Chip(label: "Friends'", value: 'friends', selected: _filter, onTap: (v) => setState(() => _filter = v)),
                const SizedBox(width: 8),
                _Chip(label: 'AI Generated', value: 'ai', selected: _filter, onTap: (v) => setState(() => _filter = v)),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const ListShimmer()
                : quizzes.isEmpty
                    ? EmptyState(icon: Icons.quiz_outlined, title: 'No quizzes found', message: 'Create your first quiz or discover public quizzes', actionLabel: 'Create Quiz', onAction: () => context.push('/quizzes/create'))
                    : RefreshIndicator(
                        onRefresh: () => ref.read(quizProvider.notifier).load(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: quizzes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => QuizCard(
                            quiz: quizzes[i],
                            onTap: () {},
                            onPractice: () => context.push('/quizzes/${quizzes[i].id}/attempt'),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/quizzes/create'),
        icon: const Icon(Icons.add),
        label: const Text('Create Quiz'),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label, value, selected;
  final ValueChanged<String> onTap;
  const _Chip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSel = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSel ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSel ? Colors.white : AppColors.primary)),
      ),
    );
  }
}
