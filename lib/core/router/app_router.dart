import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/shell_screen.dart';
import '../../features/dashboard/presentation/screens/home_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/performance_dashboard_screen.dart';
import '../../features/subjects/presentation/screens/subject_list_screen.dart';
import '../../features/subjects/presentation/screens/subject_detail_screen.dart';
import '../../features/subjects/presentation/screens/create_edit_subject_screen.dart';
import '../../features/topics/presentation/screens/topic_detail_screen.dart';
import '../../features/topics/presentation/screens/create_edit_topic_screen.dart';
import '../../features/documents/presentation/screens/document_upload_screen.dart';
import '../../features/documents/presentation/screens/document_viewer_screen.dart';
import '../../features/quizzes/presentation/screens/quiz_list_screen.dart';
import '../../features/quizzes/presentation/screens/create_quiz_screen.dart';
import '../../features/quizzes/presentation/screens/quiz_attempt_screen.dart';
import '../../features/quizzes/presentation/screens/quiz_result_screen.dart';
import '../../features/ai_quiz/presentation/screens/ai_quiz_screen.dart';
import '../../features/exams/presentation/screens/exam_list_screen.dart';
import '../../features/exams/presentation/screens/create_exam_screen.dart';
import '../../features/exams/presentation/screens/exam_attempt_screen.dart';
import '../../features/exams/presentation/screens/exam_result_screen.dart';
import '../../features/friends/presentation/screens/friends_list_screen.dart';
import '../../features/friends/presentation/screens/friend_requests_screen.dart';
import '../../features/friends/presentation/screens/find_friends_screen.dart';
import '../../features/friends/presentation/screens/user_profile_screen.dart';
import '../../features/profile/presentation/screens/my_profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),

    // Shell (bottom nav)
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (_, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(path: '/home/dashboard', builder: (_, __) => const HomeDashboardScreen()),
        GoRoute(path: '/home/subjects', builder: (_, __) => const SubjectListScreen()),
        GoRoute(path: '/home/exams', builder: (_, __) => const ExamListScreen()),
        GoRoute(path: '/home/friends', builder: (_, __) => const FriendsListScreen()),
        GoRoute(path: '/home/profile', builder: (_, __) => const MyProfileScreen()),
      ],
    ),

    // Subjects
    GoRoute(path: '/subjects/create', builder: (_, __) => const CreateEditSubjectScreen()),
    GoRoute(
      path: '/subjects/:subjectId',
      builder: (_, state) => SubjectDetailScreen(subjectId: state.pathParameters['subjectId']!),
    ),
    GoRoute(
      path: '/subjects/:subjectId/edit',
      builder: (_, state) => CreateEditSubjectScreen(subjectId: state.pathParameters['subjectId']),
    ),
    GoRoute(
      path: '/subjects/:subjectId/topics/create',
      builder: (_, state) => CreateEditTopicScreen(subjectId: state.pathParameters['subjectId']!),
    ),
    GoRoute(
      path: '/subjects/:subjectId/topics/:topicId',
      builder: (_, state) => TopicDetailScreen(subjectId: state.pathParameters['subjectId']!, topicId: state.pathParameters['topicId']!),
    ),

    // Topics
    GoRoute(
      path: '/topics/:topicId/edit',
      builder: (_, state) => CreateEditTopicScreen(topicId: state.pathParameters['topicId']),
    ),

    // Documents
    GoRoute(path: '/documents/upload', builder: (_, __) => const DocumentUploadScreen()),
    GoRoute(
      path: '/documents/:documentId/view',
      builder: (_, state) => DocumentViewerScreen(documentId: state.pathParameters['documentId']!),
    ),

    // Quizzes
    GoRoute(path: '/quizzes', builder: (_, __) => const QuizListScreen()),
    GoRoute(
      path: '/quizzes/create',
      builder: (_, state) {
        final contextIds = state.extra as Map<String, String>?;
        return CreateQuizScreen(
          subjectId: contextIds?['subjectId'],
          topicId: contextIds?['topicId'],
        );
      },
    ),
    GoRoute(
      path: '/quizzes/:quizId/edit',
      builder: (_, state) => CreateQuizScreen(quizId: state.pathParameters['quizId']!),
    ),
    GoRoute(
      path: '/quizzes/:quizId/attempt',
      builder: (_, state) => QuizAttemptScreen(quizId: state.pathParameters['quizId']!),
    ),
    GoRoute(
      path: '/quizzes/:quizId/result/:attemptId',
      builder: (_, state) => QuizResultScreen(quizId: state.pathParameters['quizId']!, attemptId: state.pathParameters['attemptId']!),
    ),

    // AI Quiz
    GoRoute(path: '/ai-quiz', builder: (_, __) => const AiQuizScreen()),

    // Exams
    GoRoute(path: '/exams/create', builder: (_, __) => const CreateExamScreen()),
    GoRoute(
      path: '/exams/:examId/attempt',
      builder: (_, state) => ExamAttemptScreen(examId: state.pathParameters['examId']!),
    ),
    GoRoute(
      path: '/exams/:examId/result',
      builder: (_, state) => ExamResultScreen(examId: state.pathParameters['examId']!),
    ),

    // Friends
    GoRoute(path: '/friends/requests', builder: (_, __) => const FriendRequestsScreen()),
    GoRoute(path: '/friends/find', builder: (_, __) => const FindFriendsScreen()),
    GoRoute(
      path: '/users/:userId/profile',
      builder: (_, state) => UserProfileScreen(userId: state.pathParameters['userId']!),
    ),

    // Notifications, Dashboard, Settings, Profile
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/dashboard', builder: (_, __) => const PerformanceDashboardScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
  ],
);
