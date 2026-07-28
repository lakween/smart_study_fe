# Smart Study domain and API contracts

## Networking and authentication

`ApiClient` is an initialized singleton wrapping Dio. It selects the backend in this order: `API_BASE_URL` dart define, web/desktop `http://localhost:4000`, or Android emulator `http://10.0.2.2:4000`. The request interceptor reads `auth_token` from secure storage and sends `Authorization: Bearer <token>`.

The current app constants default to the deployed HTTPS backend when no override is supplied. Always inspect `AppConstants.baseUrl` rather than assuming localhost behavior.

Use the backend `{ "error": "..." }` message through `apiErrorMessage`; connection failures receive a friendly offline message. There are no refresh tokens. An authenticated REST `401` or a Socket.IO authentication failure clears the stored token, disconnects the socket, resets `authProvider`, and redirects to login once.

Auth endpoints include register, login, current user, forgot password, profile update, avatar upload, password/email change, and account deletion. Successful login/register stores `token`; sign-out clears it.

## Core domains

- `UserModel`: identity, profile, study level, profile image, counts, average score, creation time.
- `ContentVisibility`: `private`, `friendsOnly`, `public`; tolerate backend spellings already handled by its parser.
- `SubjectModel`: owner-controlled container with visibility, copying, topic/quiz counts, average score, timestamps.
- `TopicModel`: belongs to a subject and carries quiz/revision performance.
- `DocumentModel`: PDF/image metadata, subject/topic ownership, visibility/copy rules, file URL and timestamps.
- `QuestionModel`: four options A-D, correct answer, optional explanation.
- `QuizModel`: subject/topic quiz, questions, visibility/copy rules, AI flag, time limit, attempts and spaced-repetition fields.
- `QuizAttemptModel`: submitted answers, counts, score, time taken, attempt time.
- `ExamModel`: individual/friend exam, scheduling/status, participants, questions, timing, and results.
- `FriendModel`: friendship/request state around a user.
- `NotificationModel`: typed notification, related entity, read state, timestamp.

Enums serialize using existing `name` or label behavior. Check each model before changing wire values; for example question answers use uppercase labels while visibility generally uses enum names.

## Provider/API ownership

- `authProvider`: authentication, session check, password reset, profile and avatar.
- `subjectProvider`: owner-only personal subject CRUD and entity lookup. Public/friend subjects do not belong in My Subjects.
- `topicProvider`: subject-filtered loading, topic CRUD/copy, entity/filter lookup.
- `documentProvider`: multipart upload with progress, delete/copy, entity/filter lookup.
- `quizProvider`: quiz loading/create/copy, attempt submission/results, entity lookup.
- `examProvider`: mine/invited loading, detail/start/submit/create, entity lookup.
- `friendProvider`: accepted friends, separate received/sent requests, paginated people discovery/search, and send/accept/decline/cancel/remove actions.
- `notificationProvider`: load, mark one/all read, dismiss.
- `dashboardProvider`: home statistics, revision queue, recent activity, last subject/topic.
- `performanceProvider`: period-filtered summary, trends, subject/topic metrics, weekly activity, revisions, insights, and exam history.

Prefer provider-owned API calls. A few specialized screens currently call Dio directly (AI generation, user profile detail, settings mutations); follow that only when the operation has no reusable feature state, otherwise place it in the responsible notifier.

## Real-time notification contract

- Backend `src/server.ts` creates an HTTP server shared by Express and Socket.IO.
- The client sends `{ token: <JWT> }` in handshake auth.
- REST and Socket middleware verify both the JWT and that its user still exists before allowing protected work; valid sockets join `user:<userId>`.
- Backend notification creation goes through `createNotification`, which persists first and emits `notification:new` to the recipient room.
- Current emitters: friend request/acceptance, exam invitation, quiz completion, and AI quiz generation.
- Flutter `SocketClient` forces WebSocket transport, derives its proxy path from `API_BASE_URL`, reconnects automatically, and is disposed on sign-out.
- REST `GET /notifications` remains the durable source for initial history and manual refresh.
- This is foreground in-app delivery, not closed-app push notification delivery.

## Spaced-repetition contract

- Quiz attempt submission is authoritative for scoring and scheduling.
- `computeNextRevision` uses the interval ladder `[1, 3, 7, 14, 30]` and pass threshold `60`.
- A failing score resets to one day; a passing score advances one step, capped at 30 days.
- Store one `SpacedRepetition` row per user/quiz and expose `nextRevisionDate` through quiz, topic, home-dashboard, and performance responses.
- The Settings spaced-repetition switch is currently UI-only and must not be described as controlling backend scheduling.

## Nested creation and quiz practice

- Subject Details opens topic creation with a fixed `subjectId`; the form does not render a subject selector.
- Topic Details opens `/quizzes/create` with fixed subject/topic navigation context; the form does not render either selector.
- Owned quizzes support update and confirmed deletion. Updating questions replaces the quiz's current question set.
- Quiz `timeLimitMinutes` is nullable and constrained to 1-180 when present.
- Attempt startup offers timed mode only when a limit exists and always offers untimed mode. Timed mode auto-submits at zero; both modes record elapsed time.
- Subject/topic/quiz text schemas remove NUL characters before validation to prevent PostgreSQL UTF-8 `0x00` errors.

## Settings and exam ownership

- Dark mode is persisted locally with `SharedPreferences` and restored before app startup.
- Font size, notification preference switches, default visibility, terms, and privacy controls remain incomplete/placeholders.
- Classify exams as owned when their ID is returned by `tab=mine` or a successful local creation; fall back to `organizerId` only as additional evidence.

## Contract checklist

Before changing an endpoint integration, verify:

1. HTTP method and relative route.
2. Authentication requirement.
3. JSON versus multipart payload.
4. Request enum/date/boolean representation.
5. Response envelope such as `user`, `subject`, `documents`, or `exam`.
6. Nullability and numeric coercion.
7. Whether local state needs insert, upsert, removal, or full reload.
8. Loading, retry, progress, error, and offline UI behavior.
9. Ownership, visibility, copying, and friend-access rules.
10. Navigation after success and mounted checks after awaits.
