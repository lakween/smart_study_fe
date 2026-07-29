import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/quiz_card.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../providers/quiz_provider.dart';

class QuizListScreen extends ConsumerStatefulWidget {
  const QuizListScreen({super.key});

  @override
  ConsumerState<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends ConsumerState<QuizListScreen> {
  String _filter = 'mine';
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 240) {
        ref.read(quizProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _selectFilter(String filter) {
    setState(() => _filter = filter);
    ref.read(quizProvider.notifier).load(
      filter: filter,
      search: _searchController.text,
    );
  }

  void _search(String value) {
    if (mounted) setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(quizProvider.notifier).load(filter: _filter, search: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizProvider);
    final quizzes = state.listedQuizzes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.search,
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search quizzes',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          _search('');
                        },
                      ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: AppSpacing.filters,
            child: Row(
              children: [
                _Chip(label: 'My Quizzes', value: 'mine', selected: _filter, onTap: _selectFilter),
                const SizedBox(width: 8),
                _Chip(label: "Friends'", value: 'friends', selected: _filter, onTap: _selectFilter),
                const SizedBox(width: 8),
                _Chip(label: 'Public', value: 'public', selected: _filter, onTap: _selectFilter),
                const SizedBox(width: 8),
                _Chip(label: 'AI Generated', value: 'ai', selected: _filter, onTap: _selectFilter),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const ListShimmer()
                : quizzes.isEmpty
                    ? EmptyState(
                        icon: Icons.quiz_outlined,
                        title: 'No quizzes found',
                        message: _filter == 'mine'
                            ? 'Create your first quiz to start practicing.'
                            : 'Try another category or search phrase.',
                        actionLabel: _filter == 'mine' ? 'Create Quiz' : null,
                        onAction: _filter == 'mine' ? () => context.push('/quizzes/create') : null,
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(quizProvider.notifier).load(
                          filter: _filter,
                          search: _searchController.text,
                        ),
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: AppSpacing.listWithFab,
                          itemCount: quizzes.length + (state.isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            if (i == quizzes.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            return QuizCard(
                              quiz: quizzes[i],
                              onPractice: () => context.push('/quizzes/${quizzes[i].id}/attempt'),
                            );
                          },
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
