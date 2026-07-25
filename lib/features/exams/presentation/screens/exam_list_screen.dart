import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/models/exam_model.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/exam_provider.dart';

class ExamListScreen extends ConsumerWidget {
  const ExamListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(examProvider);
    final userId = ref.watch(authProvider).user?.id;
    final myExams = state.exams.where((e) => e.organizerId == userId).toList();
    final invited = state.exams.where((e) => e.organizerId != userId).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Exams'),
          bottom: const TabBar(tabs: [Tab(text: 'My Exams'), Tab(text: 'Invited')]),
        ),
        body: state.isLoading
            ? const ListShimmer()
            : TabBarView(
                children: [
                  _ExamList(exams: myExams, onTap: (e) => _onExamTap(context, e)),
                  _ExamList(exams: invited, onTap: (e) => _onExamTap(context, e)),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/exams/create'),
          icon: const Icon(Icons.add),
          label: const Text('Create Exam'),
        ),
      ),
    );
  }

  void _onExamTap(BuildContext context, ExamModel exam) {
    if (exam.status == ExamStatus.completed) {
      context.push('/exams/${exam.id}/result');
    } else if (exam.status == ExamStatus.scheduled || exam.status == ExamStatus.started) {
      context.push('/exams/${exam.id}/attempt');
    }
  }
}

class _ExamList extends StatelessWidget {
  final List<ExamModel> exams;
  final ValueChanged<ExamModel> onTap;
  const _ExamList({required this.exams, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (exams.isEmpty) return const EmptyState(icon: Icons.assignment_outlined, title: 'No exams', message: 'Create or join an exam to get started');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: exams.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ExamCard(exam: exams[i], onTap: () => onTap(exams[i])),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final ExamModel exam;
  final VoidCallback onTap;
  const _ExamCard({required this.exam, required this.onTap});

  Color get _statusColor {
    switch (exam.status) {
      case ExamStatus.draft: return AppColors.textMuted;
      case ExamStatus.scheduled: return AppColors.primary;
      case ExamStatus.started: return AppColors.warning;
      case ExamStatus.completed: return AppColors.success;
      case ExamStatus.cancelled: return AppColors.error;
    }
  }

  String get _actionLabel {
    switch (exam.status) {
      case ExamStatus.scheduled: return 'Start';
      case ExamStatus.started: return 'Join';
      case ExamStatus.completed: return 'Results';
      default: return 'View';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exam.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${exam.subjectName} › ${exam.topicName}', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(exam.status.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(AppHelpers.formatDuration(exam.durationMinutes), style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
              const SizedBox(width: 16),
              if (exam.startTime != null) ...[
                Icon(Icons.calendar_today, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(AppHelpers.formatDateTime(exam.startTime!), style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                height: 24,
                child: Stack(
                  children: exam.participants.take(3).toList().asMap().entries.map((e) => Positioned(
                    left: e.key * 18.0,
                    child: AvatarWidget(name: e.value.name, radius: 12),
                  )).toList(),
                ),
              ),
              const SizedBox(width: 8),
              Text('${exam.participants.length} participant${exam.participants.length != 1 ? "s" : ""}', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
              const Spacer(),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), textStyle: const TextStyle(fontSize: 12)),
                child: Text(_actionLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
