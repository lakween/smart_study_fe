# Backend Modules and API

All routes except registration, login, refresh/logout, forgot/reset password, and health require `Authorization: Bearer <JWT>`. Document files are not public static assets; `GET /documents/:id/file` authenticates and authorizes every download.

Registration/login return `{ token, refreshToken, user }`. `POST /auth/refresh`
rotates a valid refresh token, and `POST /auth/logout` revokes it. Password
reset tokens are SHA-256 hashed, expire after `PASSWORD_RESET_TTL_MINUTES`, and
successful password reset revokes all refresh sessions.

## Health and protected files

- `GET /health` -> `{ status: "ok" }`
- `GET /documents/:id/file` serves a persisted upload only after authentication and visibility authorization. There is no public static uploads route.

## Authentication (`auth.routes.ts`)

- `POST /auth/register`: `fullName`, `email`, `password` (8+), optional `university`, `studyLevel`; returns `{ token, refreshToken, user }`.
- `POST /auth/login`: `email`, `password`; returns `{ token, refreshToken, user }`.
- `POST /auth/refresh`: rotates one valid refresh token and returns the next access/refresh pair.
- `POST /auth/logout`: revokes the supplied refresh token.
- `GET /auth/me`: returns `{ user }`.
- `POST /auth/forgot-password`: always returns success. Development mode logs and may return `devResetToken`; no email provider exists.
- `POST /auth/reset-password`: `email`, `token`, `newPassword`.

## Users/profile (`users.routes.ts`)

- `PATCH /users/me`: partial `fullName`, `bio`, `university`, `studyLevel`.
- `POST /users/me/avatar`: multipart field `file`. It currently stores a legacy `/uploads/...` profile URL; a dedicated delivery route/policy is still required because the application no longer exposes the raw uploads directory.
- `POST /users/me/change-password`: `currentPassword`, `newPassword`.
- `POST /users/me/change-email`: `newEmail`, `password`.
- `DELETE /users/me`: cascades account-owned records.
- `GET /users/:userId/profile`: user, friendship status, and visible subjects/quizzes.

## Subjects (`subjects.routes.ts`)

- `GET /subjects?visibility=&search=&archived=&sort=&page=&limit=` -> paginated owner-only subjects with batched viewer progress.
- `GET /subjects/:id` -> `{ subject }` after visibility authorization.
- `POST /subjects`: normalized `name`, optional `description`, `visibility`, `allowCopy`.
- `PATCH /subjects/:id`: owner-only partial update/archive. Narrowing visibility also narrows children transactionally.
- `DELETE /subjects/:id`: owner-only; cascades topics, documents, quizzes, exams, and dependent records.

## Topics (`topics.routes.ts`)

- `GET /topics?subjectId=...`: required subject ID, with quiz count and revision data.
- `GET /topics/:id`.
- `POST /topics`: `subjectId`, normalized name/description, visibility, allowCopy; subject owner only.
- `PATCH /topics/:id`, `DELETE /topics/:id`: subject owner only.

## Documents (`documents.routes.ts`)

- `GET /documents?subjectId=&topicId=` and `GET /documents/:id` enforce visibility.
- `POST /documents`: multipart upload by the subject owner. Topic membership, visibility hierarchy, extension, and PDF/PNG/JPEG file signature are verified.
- `GET /documents/:id/file`: authenticated file delivery after visibility authorization.
- `PATCH /documents/:id`: owner-only visibility/copy update.
- `DELETE /documents/:id`: owner-only; removes the physical upload after its final shared reference is deleted.
- `POST /documents/:id/copy`: requires visibility access and `allowCopy`; creates/reuses a private subject/topic owned by the copier and shares the stored file safely.

Uploads allow PDF/JPG/JPEG/PNG to 10 MB. Disk files receive UUID names.

## Quizzes (`quizzes.routes.ts`)

- `GET /quizzes?filter=mine|friends|public|ai&subjectId=&topicId=&search=&page=&limit=` returns batched stats and pagination.
- `GET /quizzes/:id`.
- `POST /quizzes`: normalized title/questions, subject/topic, visibility, allowCopy, AI flag, optional 1-180 minute time limit, and at least one question. Topic/subject ownership and relationship are verified.
- `PATCH /quizzes/:id`: owner-only; validates topic/subject integrity and replaces supplied questions in a transaction.
- `DELETE /quizzes/:id`: owner-only.
- `POST /quizzes/:id/sessions`: starts `timed` or `untimed` practice and returns server timestamps/deadline.
- `POST /quizzes/:id/attempts`: requires `sessionId`; score, elapsed time, deadline, one-time submission, and visibility are authoritative on the server.
- `GET /quizzes/:id/attempts/:attemptId`: attempt owner only.

Solutions are hidden from non-owners until a successful submission. Attempt,
session claim, answers, and spaced repetition update transactionally; notification
delivery failure cannot invalidate an already-recorded attempt.

## AI quiz (`aiQuiz.routes.ts`)

- `POST /ai-quiz/generate`: multipart `file`, `questionCount` (1-30), difficulty, language, and optional learning objective.
- `POST /ai-quiz/regenerate`: regenerates one question while avoiding the other supplied question texts.

The provider selected by `AI_PROVIDER` returns structured output with supporting source excerpts. The backend validates required fields, unique options, and duplicate questions, and samples the start, middle, and end of large PDFs. OpenAI and Gemini keys/models are configured independently.

## Exams (`exams.routes.ts`)

- `GET /exams?tab=mine|invited&page=&limit=` and `GET /exams/:id`: sanitized summaries; solutions are never included. Organizer summaries also expose accepted/pending/declined invitation totals, while all accessible summaries include participant submission progress.
- `POST /exams`: creates and optionally publishes an exam with duration, question count, pass mark, shuffle setting, schedule, and accepted-friend invitees.
- `PATCH/DELETE /exams/:id` and `POST /exams/:id/publish`: draft-only management.
- `POST /exams/:id/invitations/respond`: accept or decline a pending invitation.
- `POST /exams/:id/attempts`: atomically creates or resumes the user's single attempt and returns the authoritative server time/deadline plus a stable question order.
- `PUT /exams/:id/attempts/:attemptId/answers`: validated, idempotent answer autosave.
- `POST /exams/:id/attempts/:attemptId/submit`: idempotent server-side scoring and submission.
- `GET /exams/:id/results`: personal result, released solutions, and eligible leaderboard data.
- `POST /exams/:id/cancel`: organizer-only cancellation with participant notifications.

Published questions are snapshot copies sampled from the topic quiz pool. Correct answers and explanations stay server-side during an attempt. Individual results release after submission; friend-exam results release after the common close time. A 30-second lifecycle scan starts scheduled exams, auto-submits overdue saved answers, expires invitations, closes exams, and creates durable notifications. The compatibility `POST /exams/:id/start` route only creates/resumes a secure attempt for older clients.

## Friends (`friends.routes.ts`)

- `GET /friends?q=&page=&limit=`: paginated accepted friends.
- `GET /friends/search?q=&page=&limit=`: paginated user discovery/search with relationship, mutual count, total, and `hasMore`.
- `GET /friends/requests`: `{ received, sent }`.
- `POST /friends/request/:userId`.
- `POST /friends/accept/:userId`.
- `POST /friends/decline/:userId`.
- `DELETE /friends/request/:userId` cancels a sent request.
- `DELETE /friends/:userId` removes an accepted friendship.

Friend metadata and mutual counts are batch loaded. Every request/accept/decline/
cancel/remove emits `friendship:changed` to both users; send and accept also
create durable notifications. Duplicate relationships return 409.

## Notifications (`notifications.routes.ts`)

- `GET /notifications?page=&limit=`: newest-first paginated history.
- `POST /notifications/read-all`.
- `POST /notifications/:id/read`.
- `DELETE /notifications/:id`.

The HTTP server also hosts Socket.IO. A JWT supplied in the socket handshake authenticates the connection, which joins `user:<userId>`. Private-room events are `notification:new`, `friendship:changed`, and `exam:changed`.

## Dashboard (`dashboard.routes.ts`)

- `GET /dashboard/home`: totals, a `revisionSummary` (`dueNow`, next-three-day `upcoming`, and `activePlans`), revision items due within three days, five recent quiz attempts, and last subject/topic. Revision quiz DTOs include the backend-owned `revisionIntervalDays`, last score, and next revision date. Recent attempts include subject/topic context, AI origin, practice mode, correctness, score, and server-recorded duration.
- `GET /dashboard/performance?period=all|week|month`: typed performance summary with prior-period score change, pass rate, study minutes, daily quiz trend, real last-seven-day activity and streaks, navigable subject/topic rankings, memory counts and stage distribution, actionable revision queue, recommendations, insights, and exam-attempt history filtered by submission time. Compatibility fields remain for older clients.

## Error/status conventions

- Zod validation errors return 400 with safe field-level details.
- Known Prisma conflicts/not-found conditions map to safe 409/404 responses; unknown server errors return a request ID without exposing SQL or Prisma internals.
- Explicit `ApiError` responses use the specified status and `{ error }`.
- Creation normally returns 201; successful mutations return JSON rather than 204.
