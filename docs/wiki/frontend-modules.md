# Frontend Modules

## Authentication

Provider: `authProvider`. Model: `UserModel`.

- `SplashScreen`: checks the stored JWT through `/auth/me`, then routes to login or dashboard.
- `LoginScreen`: email/password form and login navigation.
- `RegisterScreen`: full name, email, password, university, and study level.
- `ForgotPasswordScreen`: submits email to the development reset endpoint.
- `ShellScreen`: hosts the five-tab bottom navigation.

The provider owns login, registration, session validation, password-reset request, profile update, avatar upload, and sign-out. Access and rotating refresh tokens are stored securely. Authenticated REST `401` responses share one refresh operation and retry once; only failed refresh/retry causes centralized sign-out. Socket authentication follows the same refresh-first behavior.

## Dashboard and performance

Providers: `dashboardProvider`, `performanceProvider`.

- `HomeDashboardScreen`: summary stats, notification badge, due revisions, last subject/topic, quick actions, and a rich recent-learning section. The newest quiz result is featured with score progress, subject/topic, correctness, duration, AI origin, and timed/untimed mode; older attempts use compact contextual cards.
- `PerformanceDashboardScreen`: premium 7-day/30-day/all-time dashboard backed by typed `PerformanceReport` models. It shows overall score and comparison, pass/activity metrics, an actionable recommendation, deep-linkable Memory & Revision details, touch-enabled score and consistency charts, navigable subject/topic rankings, completion-dated exam history, and personalized insights. `/dashboard?section=memory` scrolls directly to the memory section.

Home summary values remain a small API map, while performance analytics use typed `PerformanceReport`, summary, consistency, memory, revision, breakdown, insight, recommendation, and exam-history models.

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

Home places a compact Memory Plan between Quick Start and the Revision Queue. It shows real due/upcoming/active-plan counts and the fixed 1, 3, 7, 14, 30-day path. Revision cards show the last recall score, current interval stage, and human-readable next-review timing; Flutter displays this backend-owned schedule and does not recalculate it.

## AI quiz

- `AiQuizScreen`: selects a PDF/image and question count, uploads it to `/ai-quiz/generate`, lets the user review/edit generated questions, then saves through `quizProvider.createQuiz` with `isAiGenerated=true`.

PDF input is text-extracted; image bytes go directly to the server-selected OpenAI or Gemini provider. AI generation and quiz persistence are intentionally separate operations. The user can choose difficulty, language, and a learning objective, inspect source evidence, and regenerate individual questions.

## Exams

Provider: `examProvider`. Models: `ExamModel`, `ExamParticipant`, `ExamAttemptModel`, and `ExamResultModel`.

- `ExamListScreen`: collapsible exam dashboard with live/upcoming/action/completed totals, next-exam countdown, organizer performance, search, status filters, sorting, paginated My Exams/Invited tabs, and per-exam invitation/submission progress.
- `CreateExamScreen`: optional subject/topic classification for collaborative exams, individual/friend mode, free numeric questions-per-participant, duration, pass mark, shuffle behavior, start time, instructions, and an uncapped friend selection list. Individual exams still require a topic question bank.
- `ExamDetailScreen`: secure preflight, private collaborative-lobby readiness, invitation response, per-participant contribution counts, blind organizer publishing, cancellation, and start/resume/results actions.
- `ExamContributionScreen`: private dynamic question forms with four options, correct answer, optional explanation, Unicode-safe duplicate protection, and no access to another participant's content.
- Subject and topic detail screens include an Exams tab for authenticated-user-accessible exams that selected that classification.
- `ExamAttemptScreen`: server-clock countdown, stable question order, answer resume/autosave, guarded exit, and idempotent submission.
- `ExamResultScreen`: pass/fail summary, conditionally released leaderboard, and solution review.

Questions are snapshot-copied from existing quiz questions for the selected topic. An exam cannot be published without questions. Attempt payloads omit solutions, and friend results stay hidden until the shared close time. `exam:changed` events silently refresh list/detail state while durable notifications provide history.

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
- `PerformanceReport` and its summary, consistency, memory, ranking, revision, insight, recommendation, and exam-history value models.
- `FriendModel`, `NotificationModel`.

Numeric parsing should continue through `num` before conversion. Dates are ISO-8601 strings. Answer labels sent to the server are uppercase A-D.
