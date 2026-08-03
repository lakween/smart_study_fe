import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/models/exam_model.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../../shared/widgets/app_message.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../providers/exam_provider.dart';

class ExamDetailScreen extends ConsumerStatefulWidget {
  final String examId;

  const ExamDetailScreen({super.key, required this.examId});

  @override
  ConsumerState<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends ConsumerState<ExamDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref
          .read(examProvider.notifier)
          .ensureExam(widget.examId, refresh: true),
    );
  }

  Future<void> _respond(bool accept) async {
    final success = await ref
        .read(examProvider.notifier)
        .respondToInvitation(widget.examId, accept: accept);
    if (!mounted) return;
    if (!success) {
      _showError();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(accept ? 'Invitation accepted' : 'Invitation declined'),
      ),
    );
    if (!accept) context.pop();
  }

  Future<void> _cancel() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Cancel exam?',
      message:
          'Participants will be notified. A cancelled exam cannot be reopened.',
      confirmLabel: 'Cancel exam',
      isDestructive: true,
    );
    if (confirmed != true) return;
    final success =
        await ref.read(examProvider.notifier).cancelExam(widget.examId);
    if (!mounted) return;
    if (!success) _showError();
  }

  Future<void> _publish() async {
    final success = await ref
        .read(examProvider.notifier)
        .publishCollaborativeExam(widget.examId);
    if (!mounted) return;
    if (!success) {
      _showError();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Exam published. Good luck everyone!'),
      backgroundColor: AppColors.success,
    ));
  }

  void _showError() {
    AppMessage.error(
      context,
      ref.read(examProvider).error ?? 'Something went wrong.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(examProvider);
    final exam = ref.watch(examByIdProvider(widget.examId));
    if (exam == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exam details')),
        body: state.error == null
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Padding(
                  padding: AppSpacing.page,
                  child: Text(state.error!, textAlign: TextAlign.center),
                ),
              ),
      );
    }

    final owned = state.ownedExamIds.contains(exam.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Exam details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ExamHero(exam: exam),
              if (exam.isInvitationPending) ...[
                const SizedBox(height: 18),
                _InvitationPanel(
                  loading: state.isActionLoading,
                  onAccept: () => _respond(true),
                  onDecline: () => _respond(false),
                ),
              ],
              if (exam.isCollaborative && exam.status == ExamStatus.draft) ...[
                const SizedBox(height: 18),
                _CollaborativeLobby(
                  exam: exam,
                  owned: owned,
                  loading: state.isActionLoading,
                  onContribute: () =>
                      context.push('/exams/${exam.id}/contribute'),
                  onPublish: _publish,
                ),
              ],
              if (owned &&
                  exam.type == ExamType.individual &&
                  exam.status == ExamStatus.draft) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.primary.withValues(alpha: .12),
                      AppColors.accent.withValues(alpha: .07),
                    ]),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: .22)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Build your question set',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text('${exam.questionCount} questions selected'),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () =>
                            context.push('/exams/${exam.id}/questions'),
                        icon: const Icon(Icons.library_add_check_rounded),
                        label: const Text('Choose & review questions'),
                        style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Text('Exam setup',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              _InfoGrid(exam: exam),
              if (owned) ...[
                const SizedBox(height: 22),
                Text(
                  'Organizer overview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                _OrganizerSnapshot(exam: exam),
              ],
              const SizedBox(height: 22),
              Text(
                'Participants (${exam.participants.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              _Participants(
                participants: exam.participants,
                contributionQuota: exam.questionsPerParticipant,
                lobbyOpen: exam.status == ExamStatus.draft,
              ),
              const SizedBox(height: 24),
              _PrimaryAction(exam: exam),
              if (owned &&
                  exam.status != ExamStatus.completed &&
                  exam.status != ExamStatus.cancelled) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: state.isActionLoading ? null : _cancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel exam'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamHero extends StatelessWidget {
  final ExamModel exam;

  const _ExamHero({required this.exam});

  Color get color => switch (exam.status) {
        ExamStatus.started => AppColors.warning,
        ExamStatus.completed => AppColors.success,
        ExamStatus.cancelled => AppColors.error,
        ExamStatus.draft => AppColors.textMuted,
        ExamStatus.scheduled => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: .72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              exam.status.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            exam.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            exam.subjectName.isEmpty
                ? 'General collaborative exam'
                : exam.topicName.isEmpty
                    ? exam.subjectName
                    : '${exam.subjectName} · ${exam.topicName}',
            style: TextStyle(color: Colors.white.withValues(alpha: .82)),
          ),
          if (exam.startTime != null) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    exam.status == ExamStatus.scheduled
                        ? 'Opens ${AppHelpers.formatDateTime(exam.startTime!.toLocal())}'
                        : exam.closesAt == null
                            ? AppHelpers.formatDateTime(
                                exam.startTime!.toLocal())
                            : 'Closes ${AppHelpers.formatDateTime(exam.closesAt!.toLocal())}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InvitationPanel extends StatelessWidget {
  final bool loading;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _InvitationPanel({
    required this.loading,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mark_email_unread_outlined, color: AppColors.warning),
              SizedBox(width: 9),
              Text('Your response is needed',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Accept this invitation to reserve your place.'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: loading ? null : onDecline,
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: loading ? null : onAccept,
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final ExamModel exam;

  const _InfoGrid({required this.exam});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.quiz_outlined, '${exam.questionCount}', 'Questions'),
      (Icons.timer_outlined, '${exam.durationMinutes} min', 'Duration'),
      (Icons.verified_outlined, '${exam.passPercent}%', 'Pass mark'),
      (
        Icons.visibility_outlined,
        exam.resultRelease.label,
        'Results',
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.9,
      children: items
          .map((item) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Icon(item.$1, color: AppColors.primary, size: 21),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          Text(item.$3,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _OrganizerSnapshot extends StatelessWidget {
  final ExamModel exam;

  const _OrganizerSnapshot({required this.exam});

  @override
  Widget build(BuildContext context) {
    final scores = exam.participants
        .map((participant) => participant.score)
        .whereType<double>()
        .toList();
    final average =
        scores.isEmpty ? null : scores.reduce((a, b) => a + b) / scores.length;
    final passed = scores.isEmpty
        ? null
        : scores.where((score) => score >= exam.passPercent).length /
            scores.length *
            100;
    final items = [
      (
        Icons.how_to_reg_outlined,
        '${exam.acceptedInvitationCount}',
        'Accepted',
        AppColors.success,
      ),
      (
        Icons.schedule_send_outlined,
        '${exam.pendingInvitationCount}',
        'Pending',
        AppColors.warning,
      ),
      (
        Icons.task_alt_rounded,
        '${exam.submittedCount}/${exam.participants.length}',
        'Submitted',
        AppColors.primary,
      ),
      (
        Icons.insights_rounded,
        average == null ? '—' : '${average.toStringAsFixed(0)}%',
        passed == null ? 'Average' : '${passed.toStringAsFixed(0)}% passed',
        AppColors.accent,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: item.$4.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: item.$4.withValues(alpha: .2)),
          ),
          child: Row(
            children: [
              Icon(item.$1, color: item.$4, size: 21),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: item.$4,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      item.$3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CollaborativeLobby extends StatelessWidget {
  final ExamModel exam;
  final bool owned;
  final bool loading;
  final VoidCallback onContribute;
  final VoidCallback onPublish;

  const _CollaborativeLobby({
    required this.exam,
    required this.owned,
    required this.loading,
    required this.onContribute,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    final quota = exam.questionsPerParticipant ?? 0;
    final mineReady = exam.myContributionCount == quota;
    final publishReady = exam.contributionsReady &&
        exam.pendingInvitationCount == 0 &&
        exam.participants.length >= 2;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.primary.withValues(alpha: .12),
          AppColors.accent.withValues(alpha: .07),
        ]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: .22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(13),
              ),
              child:
                  const Icon(Icons.groups_2_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Private question lobby',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Text('$quota unique questions from every participant',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
          ]),
          if ((exam.contributionInstructions ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(exam.contributionInstructions!),
          ],
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: quota == 0 ? 0 : exam.myContributionCount / quota,
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
            color: mineReady ? AppColors.success : AppColors.primary,
          ),
          const SizedBox(height: 7),
          Text(
            mineReady
                ? 'Your questions are ready and hidden'
                : 'Your progress: ${exam.myContributionCount}/$quota',
            style: TextStyle(
              color: mineReady ? AppColors.success : AppColors.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 15),
          if (!exam.isInvitationPending)
            FilledButton.icon(
              onPressed: loading ? null : onContribute,
              icon: Icon(mineReady ? Icons.edit_rounded : Icons.add_rounded),
              label:
                  Text(mineReady ? 'Review my questions' : 'Add my questions'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),
          if (owned) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: loading || !publishReady ? null : onPublish,
              icon: const Icon(Icons.rocket_launch_rounded),
              label: Text(publishReady
                  ? 'Publish exam'
                  : 'Waiting for everyone to be ready'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),
          ],
          const SizedBox(height: 9),
          const Text(
            'Question text and answers remain private until the exam opens.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Participants extends StatelessWidget {
  final List<ExamParticipant> participants;
  final int? contributionQuota;
  final bool lobbyOpen;

  const _Participants({
    required this.participants,
    this.contributionQuota,
    this.lobbyOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return const Text('No participants yet.');
    }
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: participants.asMap().entries.map((entry) {
          final participant = entry.value;
          return Column(
            children: [
              ListTile(
                leading: AvatarWidget(name: participant.name, radius: 18),
                title: Text(participant.name),
                trailing: Text(
                  contributionQuota != null && lobbyOpen
                      ? '${participant.contributionCount}/$contributionQuota ready'
                      : participant.hasCompleted
                          ? 'Submitted'
                          : 'Not submitted',
                  style: TextStyle(
                    fontSize: 12,
                    color: contributionQuota != null && lobbyOpen
                        ? participant.contributionCount == contributionQuota
                            ? AppColors.success
                            : AppColors.warning
                        : participant.hasCompleted
                            ? AppColors.success
                            : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (entry.key != participants.length - 1)
                const Divider(height: 1, indent: 64),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final ExamModel exam;

  const _PrimaryAction({required this.exam});

  @override
  Widget build(BuildContext context) {
    if (exam.status == ExamStatus.draft) {
      return const SizedBox.shrink();
    }
    if (exam.isInvitationPending ||
        exam.invitationStatus == ExamInvitationStatus.declined ||
        exam.status == ExamStatus.cancelled) {
      return const SizedBox.shrink();
    }
    if (exam.hasSubmitted || exam.status == ExamStatus.completed) {
      return ElevatedButton.icon(
        onPressed: exam.hasSubmitted
            ? () => context.push('/exams/${exam.id}/result')
            : null,
        icon: const Icon(Icons.insights_rounded),
        label: Text(exam.hasSubmitted
            ? 'View results'
            : 'No submitted attempt to show'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
        ),
      );
    }
    if (exam.status == ExamStatus.scheduled) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.lock_clock_outlined),
        label: const Text('Exam has not opened yet'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: () => context.push('/exams/${exam.id}/attempt'),
      icon: Icon(exam.attemptStatus == ExamAttemptStatus.inProgress
          ? Icons.play_arrow_rounded
          : Icons.login_rounded),
      label: Text(exam.attemptStatus == ExamAttemptStatus.inProgress
          ? 'Resume exam'
          : 'Start exam'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
      ),
    );
  }
}
