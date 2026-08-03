import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/friend_model.dart';
import '../../../../shared/models/document_model.dart';
import '../../../../shared/models/quiz_model.dart';
import '../../../../shared/models/subject_model.dart';
import '../../../../shared/models/topic_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../../shared/widgets/app_message.dart';
import '../../../../shared/widgets/profile_cover.dart';
import '../../../../shared/widgets/content_copy_destination_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/quiz_card.dart';
import '../../../../shared/widgets/shared_content_context_banner.dart';
import '../../../../shared/widgets/subject_card.dart';
import '../providers/friend_provider.dart';
import '../../../subjects/presentation/providers/subject_provider.dart';
import '../../../topics/presentation/providers/topic_provider.dart';
import '../../../quizzes/presentation/providers/quiz_provider.dart';

class _ProfileData {
  final UserModel user;
  final FriendStatus friendStatus;
  final List<SubjectModel> subjects;
  final List<TopicModel> topics;
  final List<DocumentModel> documents;
  final List<QuizModel> quizzes;
  final bool hasLockedSubjects;
  final bool hasLockedTopics;
  final bool hasLockedDocuments;
  final bool hasLockedQuizzes;

  _ProfileData({
    required this.user,
    required this.friendStatus,
    required this.subjects,
    required this.topics,
    required this.documents,
    required this.quizzes,
    required this.hasLockedSubjects,
    required this.hasLockedTopics,
    required this.hasLockedDocuments,
    required this.hasLockedQuizzes,
  });
}

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  _ProfileData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient().dio.get('/users/${widget.userId}/profile');
      final data = res.data as Map<String, dynamic>;
      final lockedContent =
          data['lockedContent'] as Map<String, dynamic>? ?? const {};
      setState(() {
        _data = _ProfileData(
          user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
          friendStatus: FriendStatusExt.fromString(
              data['friendStatus'] as String? ?? 'none'),
          subjects: (data['subjects'] as List<dynamic>)
              .map((s) => SubjectModel.fromJson(s as Map<String, dynamic>))
              .toList(),
          topics: (data['topics'] as List<dynamic>? ?? const [])
              .map((t) => TopicModel.fromJson(t as Map<String, dynamic>))
              .toList(),
          documents: (data['documents'] as List<dynamic>? ?? const [])
              .map((d) => DocumentModel.fromJson(d as Map<String, dynamic>))
              .toList(),
          quizzes: (data['quizzes'] as List<dynamic>)
              .map((q) => QuizModel.fromJson(q as Map<String, dynamic>))
              .toList(),
          hasLockedSubjects: lockedContent['subjects'] as bool? ?? false,
          hasLockedTopics: lockedContent['topics'] as bool? ?? false,
          hasLockedDocuments: lockedContent['documents'] as bool? ?? false,
          hasLockedQuizzes: lockedContent['quizzes'] as bool? ?? false,
        );
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = apiErrorMessage(e);
      });
    }
  }

  Future<String?> _chooseSubject(String title) async {
    await ref.read(subjectProvider.notifier).load();
    if (!mounted) return null;
    final subjects =
        ref.read(subjectProvider).subjects.where((s) => !s.isArchived).toList();
    if (subjects.isEmpty) {
      AppMessage.error(
        context,
        'Create a subject first, then try copying again.',
      );
      return null;
    }
    String selected = subjects.first.id;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text(title),
          content: DropdownButtonFormField<String>(
            initialValue: selected,
            decoration: const InputDecoration(labelText: 'Save under subject'),
            items: subjects
                .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                .toList(),
            onChanged: (value) =>
                setDialogState(() => selected = value ?? selected),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, selected),
                child: const Text('Copy')),
          ],
        ),
      ),
    );
  }

  Future<void> _copyTopic(TopicModel topic) async {
    await ref.read(subjectProvider.notifier).load();
    if (!mounted) return;
    final subjects =
        ref.read(subjectProvider).subjects.where((s) => !s.isArchived).toList();
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const SelectableText(
            'Create a subject before copying this topic.',
          ),
          duration: const Duration(days: 1),
          action: SnackBarAction(
            label: 'Create',
            onPressed: () => context.push('/subjects/create'),
          ),
        ),
      );
      return;
    }
    final subjectId = await showTopicCopyDestinationDialog(
      context: context,
      topicName: topic.name,
      subjects: subjects,
    );
    if (subjectId == null || !mounted) return;
    try {
      await ApiClient().dio.post('/topics/${topic.id}/copy',
          data: {'targetSubjectId': subjectId});
      await ref.read(topicProvider.notifier).loadForSubject(subjectId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Topic copied privately to your subject.'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => context.push('/subjects/$subjectId'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppMessage.error(context, apiErrorMessage(e));
      }
    }
  }

  Future<void> _copySubject(SubjectModel subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Copy “${subject.name}”?'),
        content: const Text(
          'A private, editable copy will be added to My Subjects. Only topics, quizzes, and documents that the owner allows copying will be included.',
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
                'Subject copied privately with $topics topics, $quizzes quizzes, and $documents documents.')),
      );
    } catch (e) {
      if (mounted) {
        AppMessage.error(context, apiErrorMessage(e));
      }
    }
  }

  Future<void> _copyDocument(DocumentModel document) async {
    final subjectId = await _chooseSubject('Copy “${document.title}”');
    if (subjectId == null || !mounted) return;
    try {
      await ApiClient().dio.post('/documents/${document.id}/copy',
          data: {'targetSubjectId': subjectId});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Document copied privately to your subject.')));
      }
    } catch (e) {
      if (mounted) {
        AppMessage.error(context, apiErrorMessage(e));
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
          content: const SelectableText(
            'Create a subject before copying this quiz.',
          ),
          duration: const Duration(days: 1),
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
      await ApiClient().dio.post('/quizzes/${quiz.id}/copy',
          data: {'targetTopicId': targetTopicId});
      ref.invalidate(subjectQuizzesProvider(destination.subjectId));
      if (mounted) {
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
      }
    } catch (e) {
      if (mounted) {
        AppMessage.error(context, apiErrorMessage(e));
      }
    }
  }

  Future<void> _onFriendTap(FriendStatus status) async {
    final notifier = ref.read(friendProvider.notifier);
    switch (status) {
      case FriendStatus.none:
        await notifier.sendRequest(widget.userId);
      case FriendStatus.sent:
        await notifier.cancelRequest(widget.userId);
      case FriendStatus.pending:
        await notifier.acceptRequest(widget.userId);
      case FriendStatus.friends:
        await notifier.removeFriend(widget.userId);
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _data == null) {
      return Scaffold(
        body: Center(
          child: SelectableText(
            _error ?? 'User not found',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final user = _data!.user;
    final publicSubjects = _data!.subjects;
    final publicQuizzes = _data!.quizzes;
    final friendStatus = _data!.friendStatus;

    VoidCallback? lockedCardAction() {
      switch (friendStatus) {
        case FriendStatus.none:
        case FriendStatus.pending:
          return () => _onFriendTap(friendStatus);
        case FriendStatus.sent:
        case FriendStatus.friends:
          return null;
      }
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 66,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.fullName),
              Text(
                'Student profile',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'report', child: Text('Report User'))
              ],
            ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  ProfileCover(imageUrl: user.coverImageUrl, height: 140),
                  Transform.translate(
                    offset: const Offset(0, -46),
                    child: Column(
                      children: [
                        AvatarWidget(
                            name: user.fullName,
                            imageUrl: user.profileImageUrl,
                            radius: 40),
                        const SizedBox(height: 12),
                        Text(user.fullName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        if (user.university != null)
                          Text(user.university!,
                              style:
                                  const TextStyle(color: AppColors.textMuted)),
                        Text(user.studyLevel.label,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                        const SizedBox(height: 12),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _Stat(
                                  label: 'Subjects',
                                  value: '${user.subjectCount}'),
                              _Stat(
                                  label: 'Quizzes', value: '${user.quizCount}'),
                              _Stat(
                                  label: 'Friends',
                                  value: '${user.friendCount}'),
                            ]),
                        const SizedBox(height: 12),
                        _FriendButton(
                            status: _data!.friendStatus,
                            onTap: () => _onFriendTap(_data!.friendStatus)),
                        const SizedBox(height: 16),
                        Padding(
                          padding: AppSpacing.pageHorizontal,
                          child: SharedContentContextBanner(
                            title: 'Viewing ${user.fullName}’s profile',
                            message:
                                'This is shared content, not My Subjects. You can view, practise, or copy permitted items into your own study space.',
                            badgeLabel: 'Other profile',
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  const TabBar(isScrollable: true, tabs: [
                    Tab(text: 'Subjects'),
                    Tab(text: 'Topics'),
                    Tab(text: 'Quizzes'),
                    Tab(text: 'Documents')
                  ]),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              publicSubjects.isEmpty && !_data!.hasLockedSubjects
                  ? const EmptyState(
                      icon: Icons.book_outlined,
                      title: 'No visible subjects',
                      message: 'This user has no subjects visible to you')
                  : ListView.separated(
                      padding: AppSpacing.list,
                      itemCount: publicSubjects.length +
                          (_data!.hasLockedSubjects ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        if (i == publicSubjects.length) {
                          return _LockedContentCard(
                            contentLabel: 'subjects',
                            friendStatus: friendStatus,
                            onAction: lockedCardAction(),
                          );
                        }
                        return SubjectCard(
                          subject: publicSubjects[i],
                          isOwn: false,
                          onTap: () =>
                              context.push('/subjects/${publicSubjects[i].id}'),
                          onCopy: publicSubjects[i].allowCopy
                              ? () => _copySubject(publicSubjects[i])
                              : null,
                        );
                      },
                    ),
              _data!.topics.isEmpty && !_data!.hasLockedTopics
                  ? const EmptyState(
                      icon: Icons.topic_outlined,
                      title: 'No visible topics',
                      message:
                          'Public topics and friends-only topics shared with you appear here')
                  : ListView.separated(
                      padding: AppSpacing.list,
                      itemCount: _data!.topics.length +
                          (_data!.hasLockedTopics ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        if (i == _data!.topics.length) {
                          return _LockedContentCard(
                            contentLabel: 'topics',
                            friendStatus: friendStatus,
                            onAction: lockedCardAction(),
                          );
                        }
                        final topic = _data!.topics[i];
                        return Card(
                            child: ListTile(
                          leading: const Icon(Icons.topic_outlined),
                          title: Text(topic.name),
                          subtitle: Text(topic.allowCopy
                              ? 'Shared with copying enabled'
                              : 'View only'),
                          trailing: topic.allowCopy
                              ? IconButton(
                                  tooltip: 'Copy to my subject',
                                  icon: const Icon(Icons.copy_outlined),
                                  onPressed: () => _copyTopic(topic))
                              : null,
                        ));
                      },
                    ),
              publicQuizzes.isEmpty && !_data!.hasLockedQuizzes
                  ? const EmptyState(
                      icon: Icons.quiz_outlined,
                      title: 'No visible quizzes',
                      message: 'This user has no quizzes visible to you')
                  : ListView.separated(
                      padding: AppSpacing.list,
                      itemCount: publicQuizzes.length +
                          (_data!.hasLockedQuizzes ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        if (i == publicQuizzes.length) {
                          return _LockedContentCard(
                            contentLabel: 'quizzes',
                            friendStatus: friendStatus,
                            onAction: lockedCardAction(),
                          );
                        }
                        return Column(children: [
                          QuizCard(
                              quiz: publicQuizzes[i],
                              onPractice: () => context.push(
                                  '/quizzes/${publicQuizzes[i].id}/attempt')),
                          if (publicQuizzes[i].allowCopy)
                            Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                    onPressed: () =>
                                        _copyQuiz(publicQuizzes[i]),
                                    icon: const Icon(Icons.copy_outlined),
                                    label: const Text('Copy to my topic'))),
                        ]);
                      },
                    ),
              _data!.documents.isEmpty && !_data!.hasLockedDocuments
                  ? const EmptyState(
                      icon: Icons.folder_outlined,
                      title: 'No visible documents',
                      message:
                          'Public documents and friends-only documents shared with you appear here')
                  : ListView.separated(
                      padding: AppSpacing.list,
                      itemCount: _data!.documents.length +
                          (_data!.hasLockedDocuments ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        if (i == _data!.documents.length) {
                          return _LockedContentCard(
                            contentLabel: 'documents',
                            friendStatus: friendStatus,
                            onAction: lockedCardAction(),
                          );
                        }
                        final document = _data!.documents[i];
                        return Card(
                            child: ListTile(
                          leading: Icon(document.fileType == DocumentType.pdf
                              ? Icons.picture_as_pdf_outlined
                              : Icons.image_outlined),
                          title: Text(document.title),
                          subtitle: Text(document.allowCopy
                              ? 'Shared with copying enabled'
                              : 'View only'),
                          trailing: document.allowCopy
                              ? IconButton(
                                  tooltip: 'Copy to my subject',
                                  icon: const Icon(Icons.copy_outlined),
                                  onPressed: () => _copyDocument(document))
                              : null,
                        ));
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedContentCard extends StatelessWidget {
  final String contentLabel;
  final FriendStatus friendStatus;
  final VoidCallback? onAction;

  const _LockedContentCard({
    required this.contentLabel,
    required this.friendStatus,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (actionLabel, actionIcon) = switch (friendStatus) {
      FriendStatus.none => ('Add Friend', Icons.person_add_alt_1_outlined),
      FriendStatus.sent => ('Request Sent', Icons.schedule_outlined),
      FriendStatus.pending => (
          'Accept Request',
          Icons.person_add_alt_1_outlined
        ),
      FriendStatus.friends => ('Friends', Icons.people_outline),
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.78),
              colorScheme.surfaceContainerLow,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_outline_rounded,
                  color: colorScheme.primary, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              'Friends-only $contentLabel',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Become friends to view this content.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onAction,
              icon: Icon(actionIcon),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.pageHorizontal,
      child: Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _FriendButton extends StatelessWidget {
  final FriendStatus status;
  final VoidCallback onTap;
  const _FriendButton({required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    switch (status) {
      case FriendStatus.friends:
        label = 'Friends ✓';
        color = AppColors.success;
      case FriendStatus.pending:
        label = 'Accept Request';
        color = AppColors.warning;
      case FriendStatus.sent:
        label = 'Cancel Request';
        color = AppColors.textMuted;
      case FriendStatus.none:
        label = 'Add Friend';
        color = AppColors.primary;
    }
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
          backgroundColor: color, minimumSize: const Size(160, 40)),
      child: Text(label),
    );
  }
}
