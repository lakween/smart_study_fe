import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/subject_card.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../providers/subject_provider.dart';

class SubjectListScreen extends ConsumerStatefulWidget {
  const SubjectListScreen({super.key});

  @override
  ConsumerState<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends ConsumerState<SubjectListScreen> {
  ContentVisibility? _filter;
  bool _showArchived = false;
  String _sort = 'updated';
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reload();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    ref.read(subjectProvider.notifier).load(
          search: _searchController.text,
          visibility: _filter,
          archived: _showArchived,
          sort: _sort,
        );
  }

  void _setFilter(ContentVisibility? filter) {
    setState(() => _filter = filter);
    _reload();
  }

  void _search(String _) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _reload);
  }

  Future<void> _openSubjectEditor(String location) async {
    final changed = await context.push<bool>(location);
    if (changed == true && mounted) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subjectProvider);
    final subjects = state.subjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subjects'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort subjects',
            onSelected: (value) {
              setState(() => _sort = value);
              _reload();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'updated', child: Text('Recently updated')),
              PopupMenuItem(value: 'name', child: Text('Name')),
              PopupMenuItem(value: 'created', child: Text('Newest')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.search,
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Search subjects',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
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
                _FilterChip(
                    label: 'All',
                    isSelected: _filter == null && !_showArchived,
                    onTap: () {
                      _showArchived = false;
                      _setFilter(null);
                    }),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'Public',
                    isSelected:
                        _filter == ContentVisibility.public && !_showArchived,
                    onTap: () {
                      _showArchived = false;
                      _setFilter(ContentVisibility.public);
                    },
                    color: AppColors.publicColor),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'Friends Only',
                    isSelected: _filter == ContentVisibility.friendsOnly &&
                        !_showArchived,
                    onTap: () {
                      _showArchived = false;
                      _setFilter(ContentVisibility.friendsOnly);
                    },
                    color: AppColors.friendsColor),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'Private',
                    isSelected:
                        _filter == ContentVisibility.private && !_showArchived,
                    onTap: () {
                      _showArchived = false;
                      _setFilter(ContentVisibility.private);
                    },
                    color: AppColors.privateColor),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'Archived',
                    isSelected: _showArchived,
                    onTap: () {
                      setState(() {
                        _showArchived = true;
                        _filter = null;
                      });
                      _reload();
                    },
                    color: AppColors.textMuted),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const SubjectCardShimmer()
                : state.error != null
                    ? ErrorState(message: state.error!, onRetry: _reload)
                    : subjects.isEmpty
                        ? EmptyState(
                            icon: Icons.book_outlined,
                            title: 'No subjects yet',
                            message:
                                'Create your first subject to start organizing your studies!',
                            actionLabel: 'Create Subject',
                            onAction: () =>
                                _openSubjectEditor('/subjects/create'),
                          )
                        : RefreshIndicator(
                            onRefresh: () async => _reload(),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                Widget buildCard(BuildContext _, int i) {
                                  final s = subjects[i];
                                  return SubjectCard(
                                    subject: s,
                                    isOwn: true,
                                    onTap: () =>
                                        context.push('/subjects/${s.id}'),
                                    onEdit: () => _openSubjectEditor(
                                        '/subjects/${s.id}/edit'),
                                    onArchive: () async {
                                      await ref
                                          .read(subjectProvider.notifier)
                                          .setArchived(s, !s.isArchived);
                                      _reload();
                                    },
                                    onDelete: () async {
                                      final ok = await ConfirmDialog.show(
                                        context,
                                        title: 'Delete Subject',
                                        message:
                                            'Are you sure you want to delete "${s.name}"? This cannot be undone.',
                                        confirmLabel: 'Delete',
                                        isDestructive: true,
                                      );
                                      if (ok == true) {
                                        ref
                                            .read(subjectProvider.notifier)
                                            .deleteSubject(s.id);
                                      }
                                    },
                                  );
                                }

                                if (constraints.maxWidth < 720) {
                                  return ListView.separated(
                                    padding: AppSpacing.listWithFab,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount: subjects.length,
                                    itemBuilder: buildCard,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                  );
                                }
                                return GridView.builder(
                                  padding: AppSpacing.listWithFab,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    mainAxisExtent: 278,
                                  ),
                                  itemCount: subjects.length,
                                  itemBuilder: buildCard,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSubjectEditor('/subjects/create'),
        icon: const Icon(Icons.add),
        label: const Text('Subject'),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  const _FilterChip(
      {required this.label,
      required this.isSelected,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? c : c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? c : c.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : c,
          ),
        ),
      ),
    );
  }
}
