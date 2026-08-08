import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../dashboard/presentation/providers/performance_provider.dart';
import '../../../documents/presentation/providers/document_provider.dart';
import '../../../exams/presentation/providers/exam_provider.dart';
import '../../../friends/presentation/providers/friend_provider.dart';
import '../../../messages/presentation/providers/message_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../quizzes/presentation/providers/quiz_provider.dart';
import '../../../subjects/presentation/providers/subject_provider.dart';
import '../../../topics/presentation/providers/topic_provider.dart';

/// Disposes every cache whose contents belong to the authenticated user.
///
/// Appearance preferences deliberately remain outside this list because they
/// belong to the installation rather than to a backend account.
void invalidateUserSessionCache(WidgetRef ref) {
  // Stop the old user's real-time transports before rebuilding data providers.
  ref.invalidate(notificationProvider);

  ref.invalidate(dashboardProvider);
  ref.invalidate(performanceProvider);
  ref.invalidate(subjectProvider);
  ref.invalidate(topicProvider);
  ref.invalidate(documentProvider);
  ref.invalidate(quizProvider);
  ref.invalidate(examProvider);
  ref.invalidate(friendProvider);
  ref.invalidate(messageProvider);

  // These families fetch data directly instead of deriving it from the state
  // notifiers above, so invalidate all of their parameterized instances too.
  ref.invalidate(sharedSubjectDetailProvider);
  ref.invalidate(subjectTopicsProvider);
  ref.invalidate(subjectDocumentsProvider);
  ref.invalidate(subjectQuizzesProvider);
  ref.invalidate(relatedExamsProvider);
}
