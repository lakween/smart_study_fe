import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/subject_card.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/subject_provider.dart';

class SubjectListScreen extends ConsumerStatefulWidget {
  const SubjectListScreen({super.key});

  @override
  ConsumerState<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends ConsumerState<SubjectListScreen> {
  ContentVisibility? _filter;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subjectProvider);
    final currentUserId = ref.watch(authProvider).user?.id;
    var subjects = state.subjects;
    if (_filter != null) subjects = subjects.where((s) => s.visibility == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subjects'),
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
                _FilterChip(label: 'All', isSelected: _filter == null, onTap: () => setState(() => _filter = null)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Public', isSelected: _filter == ContentVisibility.public, onTap: () => setState(() => _filter = ContentVisibility.public), color: AppColors.publicColor),
                const SizedBox(width: 8),
                _FilterChip(label: 'Friends Only', isSelected: _filter == ContentVisibility.friendsOnly, onTap: () => setState(() => _filter = ContentVisibility.friendsOnly), color: AppColors.friendsColor),
                const SizedBox(width: 8),
                _FilterChip(label: 'Private', isSelected: _filter == ContentVisibility.private, onTap: () => setState(() => _filter = ContentVisibility.private), color: AppColors.privateColor),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const SubjectCardShimmer()
                : subjects.isEmpty
                    ? EmptyState(
                        icon: Icons.book_outlined,
                        title: 'No subjects yet',
                        message: 'Create your first subject to start organizing your studies!',
                        actionLabel: 'Create Subject',
                        onAction: () => context.push('/subjects/create'),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(subjectProvider.notifier).load(),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.82,
                          ),
                          itemCount: subjects.length,
                          itemBuilder: (_, i) {
                            final s = subjects[i];
                            return SubjectCard(
                              subject: s,
                              isOwn: s.ownerId == currentUserId,
                              onTap: () => context.push('/subjects/${s.id}'),
                              onEdit: () => context.push('/subjects/${s.id}/edit'),
                              onDelete: () async {
                                final ok = await ConfirmDialog.show(context,
                                  title: 'Delete Subject',
                                  message: 'Are you sure you want to delete "${s.name}"? This cannot be undone.',
                                  confirmLabel: 'Delete', isDestructive: true,
                                );
                                if (ok == true) ref.read(subjectProvider.notifier).deleteSubject(s.id);
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/subjects/create'),
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
  const _FilterChip({required this.label, required this.isSelected, required this.onTap, this.color});

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
            fontSize: 13, fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : c,
          ),
        ),
      ),
    );
  }
}
