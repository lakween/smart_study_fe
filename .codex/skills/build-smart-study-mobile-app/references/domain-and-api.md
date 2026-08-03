# Smart Study domain and API contracts

## Contents

- [Networking and authentication](#networking-and-authentication)
- [Core domains](#core-domains)
- [Provider/API ownership](#providerapi-ownership)
- [Subject deep-copy contract](#subject-deep-copy-contract)
- [Real-time contract](#real-time-contract)
- [Spaced-repetition contract](#spaced-repetition-contract)
- [Nested creation and quiz practice](#nested-creation-and-quiz-practice)
- [Exam lifecycle and security](#exam-lifecycle-and-security)
- [Settings and exam ownership](#settings-and-exam-ownership)
- [Contract checklist](#contract-checklist)

## Networking and authentication

`ApiClient` is an initialized singleton wrapping Dio. It selects the backend in this order: a non-empty `API_BASE_URL` Dart define; the deployed `productionUrl` for every release build; then, for debug development, web/desktop `http://localhost:4000` or Android emulator `http://10.0.2.2:4000`. The request interceptor reads `auth_token` from secure storage and sends `Authorization: Bearer <token>`.

The current app constants default release builds to the deployed HTTPS backend when no override is supplied. URL changes are compile-time changes, so rebuild and reinstall the APK. Always inspect `AppConstants.baseUrl` rather than assuming localhost behavior.

Use the backend `{ "error": "..." }` message through `apiErrorMessage`; generic 500 responses never expose database internals and include a request ID. Present action failures with `AppMessage.error` and persistent error details with `SelectableText` so the exact message can be selected and copied. Access and rotating refresh tokens live in secure storage. Dio shares one refresh operation, retries a failed authenticated request once, and signs out only when refresh/retry fails. Socket authentication follows the same refresh-first behavior.

Auth endpoints include register, login, current user, forgot password, profile update, avatar upload, password/email change, and account deletion. Successful login/register stores `token`; sign-out clears it.

## Core domains

- `UserModel`: identity, profile, study level, profile image, counts, average score, creation time.
- `ContentVisibility`: `private`, `friendsOnly`, `public`; tolerate backend spellings already handled by its parser.
- `SubjectModel`: owner-controlled, searchable/sortable/archiveable container with visibility, copying, topic/quiz counts, average score, timestamps.
- `TopicModel`: belongs to a subject, may be archived, and carries quiz/revision performance.
- `DocumentModel`: PDF/image metadata, subject/topic ownership, visibility/copy rules, file URL and timestamps.
- `QuestionModel`: four options A-D, correct answer, optional explanation.
- `QuizModel`: subject/topic quiz, questions, visibility/copy rules, AI flag, time limit, attempts and spaced-repetition fields.
- `QuizAttemptModel`: submitted answers, counts, score, time taken, attempt time, subject/topic context, AI origin, and optional timed/untimed practice mode.
- `ExamModel`: sanitized individual/friend exam summary with scheduling, invitation/attempt status, organizer invitation counts, participant submission count, close time, pass mark, and release policy.
- `ExamAttemptModel` / `ExamResultModel`: stable ordered attempt questions, autosaved answers, authoritative deadline, score, and conditionally released solutions.
- `FriendModel`: friendship/request state around a user.
- `NotificationModel`: typed notification, related entity, read state, timestamp.

Enums serialize using existing `name` or label behavior. Check each model before changing wire values; for example question answers use uppercase labels while visibility generally uses enum names.

## Provider/API ownership

- `authProvider`: authentication, session check, password reset, profile and avatar.
- `subjectProvider`: owner-only personal subject CRUD and entity lookup. Public/friend subjects do not belong in My Subjects; successful foreign subject copies refresh the owner's subject collection.
- `topicProvider`: subject-filtered loading, topic CRUD/copy, entity/filter lookup.
- `documentProvider`: multipart upload with progress, delete/copy, entity/filter lookup.
- `quizProvider`: entity cache plus paginated management/discovery list, create/edit/delete, server practice sessions, attempt submission/results, and entity lookup.
- `examProvider`: mine/invited loading, create/detail/cancel, invitation response, attempt start/resume, answer autosave, idempotent submit, results, and entity lookup.
- `friendProvider`: accepted friends, separate received/sent requests, paginated people discovery/search, and send/accept/decline/cancel/remove actions.
- `notificationProvider`: paginated history, live insert, mark one/all read, dismiss.
- `dashboardProvider`: home statistics, revision queue, recent activity, last subject/topic.
- `performanceProvider`: typed period-filtered `PerformanceReport` with summary/comparison, score trend, real daily activity and streaks, memory stages and revision queue, subject/topic rankings, recommendations, insights, and completion-dated exam history.

Prefer provider-owned API calls. A few specialized screens currently call Dio directly (AI generation, user profile detail, settings mutations); follow that only when the operation has no reusable feature state, otherwise place it in the responsible notifier.

## Subject deep-copy contract

- `POST /subjects/:id/copy` accepts an optional JSON `{ "name": "..." }`; an empty body is valid. It returns `{ subject, copied: { topics, quizzes, documents } }` with copied-item counts.
- The source subject must be visible to the authenticated viewer. A non-owner may copy only when the subject's `allowCopy` is true.
- The copied subject belongs to the viewer and is private, active, editable, and non-copyable. Preserve `copiedFromId` plus the earliest immutable original-creator identity.
- Copy only nested topics, quizzes, and documents that are visible to the viewer and independently allow copying. A quiz is copied only with a copied parent topic; all of its questions are cloned. A topic-scoped document is skipped if that topic is not copied.
- Copied documents reuse the protected stored file reference. Delete the physical file only after its final database reference is gone.

## Real-time contract

- The target FastAPI ASGI application must host `python-socketio` on the same origin and preserve the existing Socket.IO protocol. The legacy `src/server.ts` remains parity evidence until this is implemented.
- The client sends `{ token: <JWT> }` in handshake auth.
- REST and Socket middleware verify both the JWT and that its user still exists before allowing protected work; valid sockets join `user:<userId>`.
- Backend notification creation goes through `createNotification`, which persists first and emits `notification:new` to the recipient room.
- Friendship mutations emit `friendship:changed` to both affected rooms; the client refreshes accepted/request/discovery state with a debounce.
- Exam invitation, submission, cancellation, auto-submission, and completion changes emit `exam:changed`; the client silently refreshes exam state.
- Current emitters: friend request/acceptance, exam invitation, quiz completion, and AI quiz generation.
- Flutter `SocketClient` forces WebSocket transport, derives its proxy path from `API_BASE_URL`, reconnects automatically, and is disposed on sign-out.
- REST `GET /notifications` remains the durable source for initial history and manual refresh.
- This is foreground in-app delivery, not closed-app push notification delivery.

## Spaced-repetition contract

- Quiz attempt submission is authoritative for scoring and scheduling.
- `computeNextRevision` uses the interval ladder `[1, 3, 7, 14, 30]` and pass threshold `60`.
- A failing score resets to one day; a passing score advances one step, capped at 30 days.
- Store one `SpacedRepetition` row per user/quiz and expose `nextRevisionDate` through quiz, topic, home-dashboard, and performance responses.
- Home dashboard responses expose `revisionSummary` counts and `revisionIntervalDays`; derive the displayed stage from the `[1, 3, 7, 14, 30]` ladder without recalculating a revision date in Flutter.
- Performance responses expose due/overdue/upcoming counts and the stored interval stage. Treat daily activity as actual dated completions and filter exam performance by `ExamAttempt.submittedAt`, never exam creation time.
- The Settings spaced-repetition switch is currently UI-only and must not be described as controlling backend scheduling.

## Nested creation and quiz practice

- Subject Details opens topic creation with a fixed `subjectId`; the form does not render a subject selector.
- Topic Details opens `/quizzes/create` with fixed subject/topic navigation context; the form does not render either selector.
- Owned quizzes support update and confirmed deletion. Updating questions replaces the quiz's current question set.
- Practice starts with `POST /quizzes/:id/sessions`; submit the returned `sessionId`. Never trust client elapsed time. Non-owner quiz DTOs hide solutions until submission. The attempt screen saves session/answers locally for resume and confirms before leaving.
- Quiz `timeLimitMinutes` is nullable and constrained to 1-180 when present.
- Attempt startup offers timed mode only when a limit exists and always offers untimed mode. Timed mode auto-submits at zero; both modes record elapsed time.
- Subject/topic/quiz text schemas remove NUL characters before validation to prevent PostgreSQL UTF-8 `0x00` errors.
- Individual exam creation may omit subject, topic, and start time. The organizer then builds the draft paper through `GET /exams/:id/question-bank` and `PUT /exams/:id/question-bank` using questions from any owned quiz.
- `ExamQuestionLibraryPicker` groups the catalog by quiz, keeps selected and available groups separate, supports search and subject/topic/quiz filters, and allows whole-quiz or individual-question add/remove. The same picker imports a participant's own quiz questions into friend contributions while enforcing the contribution quota.

## Exam lifecycle and security

- New friend exams use a private collaborative lobby. The organizer and every accepted participant contribute the configured equal question quota; contributors can read/edit only their own draft questions, while lobby summaries expose counts but never another participant's question text or answers.
- Collaborative invitations are created while the exam is `DRAFT`. Publishing is organizer-only and is blocked until all invitations are resolved, at least two participants remain, and every participant has submitted exactly the quota. The organizer is also a normal participant and must contribute.
- Contribution duplicates are rejected from Unicode-normalized question text under a per-exam database lock. The error never reveals the existing question. Instructions should divide subject areas to reduce semantic duplicates without requiring an AI call.
- Publishing snapshots every accepted contribution into the common exam question set. Everyone receives the same questions, with stable per-attempt order shuffling; friend-exam solutions still wait until shared completion.
- Individual and collaborative exams may be unclassified: `subjectId`, `topicId`, and `startTime` are optional. A selected topic requires its owned subject; selected classifications surface accessible related exams inside subject/topic detail tabs. Individual question selection is organizer-owned across the organizer's quiz library rather than restricted to one classified topic.
- Participant IDs and questions-per-participant use positive, user-entered counts without product-level list caps; transport/body and infrastructure protections remain authoritative. Do not reintroduce preset-only question chips.
- `POST /exams/:id/attempts` creates or resumes the unique exam+user attempt and returns `serverNow`; calculate countdowns from `deadlineAt` with that clock offset.
- Autosave with `PUT /exams/:id/attempts/:attemptId/answers`; submit with `POST /exams/:id/attempts/:attemptId/submit`; both validate question ownership and the authenticated attempt owner.
- Attempt payloads never include `correctAnswer` or `explanation`. Individual solutions release after submission; friend-exam score, leaderboard, and solutions release only after the shared close time.
- The backend lifecycle scheduler claims overdue attempts idempotently, scores saved answers, expires invitations, completes closed exams, and creates durable notifications.
- Pending friend invitations must be accepted before start. Only draft exams can be edited/deleted; published active exams can be cancelled by the organizer.

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
