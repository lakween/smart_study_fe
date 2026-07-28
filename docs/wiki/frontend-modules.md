# Frontend Modules

## Authentication

Provider: `authProvider`. Model: `UserModel`.

- `SplashScreen`: checks the stored JWT through `/auth/me`, then routes to login or dashboard.
- `LoginScreen`: email/password form and login navigation.
- `RegisterScreen`: full name, email, password, university, and study level.
- `ForgotPasswordScreen`: submits email to the development reset endpoint.
- `ShellScreen`: hosts the five-tab bottom navigation.

The provider owns login, registration, session validation, password-reset request, profile update, avatar upload, and sign-out. Tokens are stored securely. Authenticated REST `401` responses and Socket.IO authentication failures trigger one centralized automatic sign-out while preserving appearance preferences.

## Dashboard and performance

Providers: `dashboardProvider`, `performanceProvider`.

- `HomeDashboardScreen`: summary stats, notification badge, due revisions, recent activity, last subject/topic, and quick actions.
- `PerformanceDashboardScreen`: all/week/month filters, summary metrics, score trend, subject/topic performance, weekly activity, revisions, insights, and exam history.

Dashboard state still uses some dynamic maps. Introduce typed models before substantially expanding analytics.

## Subjects

Provider: `subjectProvider`. Model: `SubjectModel`.

- `SubjectListScreen`: searchable/filterable subject list, refresh, edit, delete, and create.
- `SubjectDetailScreen`: tabs for topics, quizzes, and documents plus owner actions.
- `CreateEditSubjectScreen`: create/edit form for name, description, visibility, copying permission, and deletion.

Creation prepends locally, updates replace by ID, and deletion removes by ID. **My Subjects** is owner-only; public and accepted-friend subjects are not mixed into this personal workspace.

## Topics

Provider: `topicProvider`. Model: `TopicModel`.

- `TopicDetailScreen`: topic metadata, revision information, quizzes/documents, and edit navigation.
- `CreateEditTopicScreen`: subject-scoped create/edit form with visibility and copy permission. Creation receives the current subject ID and does not render a subject selector.

`GET /topics` requires `subjectId`. The provider merges fetched topics by subject and exposes `topicByIdProvider` and `topicsBySubjectProvider`.

## Documents

Provider: `documentProvider`. Model: `DocumentModel`.

- `DocumentUploadScreen`: selects PDF/JPG/JPEG/PNG, subject/topic, visibility, and copy permission; displays upload progress.
- `DocumentViewerScreen`: file metadata and open/download behavior, owner deletion, and allowed copying.

The provider currently loads all visible documents and filters them locally by subject/topic. Uploaded files are stored by the backend; copied records reuse the original file URL.

## Quizzes

Provider: `quizProvider`. Models: `QuizModel`, `QuestionModel`, `QuizAttemptModel`.

- `QuizListScreen`: filters visible quizzes and launches attempts.
- `CreateQuizScreen`: create/edit manual quizzes, questions, four options, correct answers, explanations, optional 1-180 minute timing, visibility, and copying. Topic-scoped creation fixes subject/topic context and hides both selectors.
- `QuizAttemptScreen`: timed/untimed mode selection, question navigation, selected answers, countdown auto-submit for timed practice, elapsed-time tracking, submission, and result navigation.
- `QuizResultScreen`: score, answer correctness, explanations, and revision information.

Owned quiz cards expose edit and confirmed deletion. Submitting an attempt creates answer rows, calculates the score server-side, updates spaced repetition, creates a notification, and refreshes quiz summary data.

## AI quiz

- `AiQuizScreen`: selects a PDF/image and question count, uploads it to `/ai-quiz/generate`, lets the user review/edit generated questions, then saves through `quizProvider.createQuiz` with `isAiGenerated=true`.

PDF input is text-extracted; image bytes go directly to the server-selected OpenAI or Gemini provider. AI generation and quiz persistence are intentionally separate operations. The user can choose difficulty, language, and a learning objective, inspect source evidence, and regenerate individual questions.

## Exams

Provider: `examProvider`. Models: `ExamModel`, `ExamParticipant`.

- `ExamListScreen`: My Exams and Invited tabs.
- `CreateExamScreen`: subject/topic, individual/friend mode, duration, start time, and invited friends.
- `ExamAttemptScreen`: ensures exam data, starts the exam, times and submits answers.
- `ExamResultScreen`: participant/result summary.

Questions are randomly copied from existing quiz questions for the selected topic. An exam cannot be created for a topic without questions. Newly created and `/exams?tab=mine` IDs are tracked as owned so they appear immediately.

## Friends and public profiles

Provider: `friendProvider`. Model: `FriendModel`.

- `FriendsListScreen`: accepted friends, refresh, profile view, request navigation, and removal.
- `FriendRequestsScreen`: separate Received and Sent tabs with accept/decline/cancel actions.
- `FindFriendsScreen`: paginated user discovery and debounced name/email search with initial and load-more indicators.
- `UserProfileScreen`: other user's profile, friendship action, visible subjects, and visible quizzes.

Sending and accepting requests create database notifications and emit them to the recipient's authenticated Socket.IO room. Friend-list state itself is refreshed separately from notification state.

## Notifications

Provider: `notificationProvider`. Model: `NotificationModel`.

- `NotificationsScreen`: all/unread filtering, pull-to-refresh, mark one/all read, and swipe dismissal.
- Dashboard consumes the same provider for its unread badge.

The provider performs one REST history load, then maintains an authenticated Socket.IO connection and merges `notification:new` events by ID. This is not OS push and does not operate while the app is closed.

## Profile

- `MyProfileScreen`: authenticated profile, stats, owned content, settings, and edit navigation.
- `EditProfileScreen`: avatar picker plus name, bio, university, and study-level editing.

Profile state is owned by `authProvider`; there is no separate profile provider.

## Settings

- `SettingsScreen`: password/email changes, account deletion, dark mode, font-size UI, notification toggles, default visibility UI, legal placeholders, and sign-out.
- `themeProvider`: persists dark mode using `SharedPreferences` and restores it before app rendering.

Only dark mode is persisted and applied. Font size is in-memory and not applied globally. Notification switches and default visibility are local/placeholders. Terms and privacy actions are empty.

## Shared models

- `UserModel`: user identity/profile/stats plus `StudyLevel` and `ContentVisibility`.
- `SubjectModel`, `TopicModel`, `DocumentModel`.
- `QuestionModel`, `QuizModel`, `QuizAttemptModel`.
- `ExamModel`, `ExamParticipant`.
- `FriendModel`, `NotificationModel`.

Numeric parsing should continue through `num` before conversion. Dates are ISO-8601 strings. Answer labels sent to the server are uppercase A-D.
