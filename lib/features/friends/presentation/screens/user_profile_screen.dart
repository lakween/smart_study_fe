import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/friend_model.dart';
import '../../../../shared/models/quiz_model.dart';
import '../../../../shared/models/subject_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/quiz_card.dart';
import '../../../../shared/widgets/subject_card.dart';
import '../providers/friend_provider.dart';

class _ProfileData {
  final UserModel user;
  final FriendStatus friendStatus;
  final List<SubjectModel> subjects;
  final List<QuizModel> quizzes;
  _ProfileData({required this.user, required this.friendStatus, required this.subjects, required this.quizzes});
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
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient().dio.get('/users/${widget.userId}/profile');
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _data = _ProfileData(
          user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
          friendStatus: FriendStatusExt.fromString(data['friendStatus'] as String? ?? 'none'),
          subjects: (data['subjects'] as List<dynamic>).map((s) => SubjectModel.fromJson(s as Map<String, dynamic>)).toList(),
          quizzes: (data['quizzes'] as List<dynamic>).map((q) => QuizModel.fromJson(q as Map<String, dynamic>)).toList(),
        );
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = apiErrorMessage(e); });
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
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null || _data == null) return Scaffold(body: Center(child: Text(_error ?? 'User not found')));

    final user = _data!.user;
    final publicSubjects = _data!.subjects;
    final publicQuizzes = _data!.quizzes;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(user.fullName),
          actions: [
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => [const PopupMenuItem(value: 'report', child: Text('Report User'))],
            ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Container(
                    height: 100,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.7), AppColors.primaryLight])),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Column(
                      children: [
                        AvatarWidget(name: user.fullName, imageUrl: user.profileImageUrl, radius: 40),
                        const SizedBox(height: 12),
                        Text(user.fullName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        if (user.university != null)
                          Text(user.university!, style: const TextStyle(color: AppColors.textMuted)),
                        Text(user.studyLevel.label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        const SizedBox(height: 12),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          _Stat(label: 'Subjects', value: '${user.subjectCount}'),
                          _Stat(label: 'Quizzes', value: '${user.quizCount}'),
                          _Stat(label: 'Friends', value: '${user.friendCount}'),
                        ]),
                        const SizedBox(height: 12),
                        _FriendButton(status: _data!.friendStatus, onTap: () => _onFriendTap(_data!.friendStatus)),
                        const SizedBox(height: 12),
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
              publicSubjects.isEmpty
                  ? const EmptyState(icon: Icons.book_outlined, title: 'No visible subjects', message: 'This user has no subjects visible to you')
                  : GridView.builder(
                      padding: AppSpacing.list,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.82),
                      itemCount: publicSubjects.length,
                      itemBuilder: (_, i) => SubjectCard(subject: publicSubjects[i], isOwn: false, onTap: () => context.push('/subjects/${publicSubjects[i].id}')),
                    ),
              publicQuizzes.isEmpty
                  ? const EmptyState(icon: Icons.quiz_outlined, title: 'No visible quizzes', message: 'This user has no quizzes visible to you')
                  : ListView.separated(
                      padding: AppSpacing.list,
                      itemCount: publicQuizzes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => QuizCard(quiz: publicQuizzes[i], onPractice: () => context.push('/quizzes/${publicQuizzes[i].id}/attempt')),
                    ),
              const EmptyState(icon: Icons.folder_outlined, title: 'No public documents', message: 'This user has no public documents'),
            ],
          ),
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
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
      case FriendStatus.friends: label = 'Friends ✓'; color = AppColors.success;
      case FriendStatus.pending: label = 'Accept Request'; color = AppColors.warning;
      case FriendStatus.sent: label = 'Cancel Request'; color = AppColors.textMuted;
      case FriendStatus.none: label = 'Add Friend'; color = AppColors.primary;
    }
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(backgroundColor: color, minimumSize: const Size(160, 40)),
      child: Text(label),
    );
  }
}
