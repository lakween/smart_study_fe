# Backend Modules and API

All routes except registration, login, forgot/reset password, health, and static uploads require `Authorization: Bearer <JWT>`.

## Health and static files

- `GET /health` -> `{ status: "ok" }`
- `GET /uploads/:filename` serves persisted uploads.

## Authentication (`auth.routes.ts`)

- `POST /auth/register`: `fullName`, `email`, `password` (8+), optional `university`, `studyLevel`; returns `{ token, user }`.
- `POST /auth/login`: `email`, `password`; returns `{ token, user }`.
- `GET /auth/me`: returns `{ user }`.
- `POST /auth/forgot-password`: always returns success. Development mode logs and may return `devResetToken`; no email provider exists.
- `POST /auth/reset-password`: `email`, `token`, `newPassword`.

## Users/profile (`users.routes.ts`)

- `PATCH /users/me`: partial `fullName`, `bio`, `university`, `studyLevel`.
- `POST /users/me/avatar`: multipart field `file`.
- `POST /users/me/change-password`: `currentPassword`, `newPassword`.
- `POST /users/me/change-email`: `newEmail`, `password`.
- `DELETE /users/me`: cascades account-owned records.
- `GET /users/:userId/profile`: user, friendship status, and visible subjects/quizzes.

## Subjects (`subjects.routes.ts`)

- `GET /subjects?visibility=` -> visible subjects and viewer-specific average score.
- `GET /subjects/:id` -> `{ subject }` after visibility authorization.
- `POST /subjects`: `name`, optional `description`, `visibility`, `allowCopy`.
- `PATCH /subjects/:id`: owner-only partial update.
- `DELETE /subjects/:id`: owner-only; cascades topics, documents, quizzes, exams, and dependent records.

## Topics (`topics.routes.ts`)

- `GET /topics?subjectId=...`: required subject ID, with quiz count and revision data.
- `GET /topics/:id`.
- `POST /topics`: `subjectId`, `name`, optional description, visibility, allowCopy; subject owner only.
- `PATCH /topics/:id`, `DELETE /topics/:id`: subject owner only.

## Documents (`documents.routes.ts`)

- `GET /documents?subjectId=&topicId=` and `GET /documents/:id` enforce visibility.
- `POST /documents`: multipart `file`, `title`, `subjectId`, optional `topicId`, visibility, allowCopy.
- `PATCH /documents/:id`: owner-only visibility/copy update.
- `DELETE /documents/:id`: owner-only record deletion. The route does not remove the physical file.
- `POST /documents/:id/copy`: requires `allowCopy`; creates a private record using the same URL.

Uploads allow PDF/JPG/JPEG/PNG to 10 MB. Disk files receive UUID names.

## Quizzes (`quizzes.routes.ts`)

- `GET /quizzes?filter=mine|friends|public|ai&subjectId=&topicId=`.
- `GET /quizzes/:id`.
- `POST /quizzes`: title, subject/topic, visibility, allowCopy, AI flag, optional time limit, and at least one question.
- `PATCH /quizzes/:id`: owner-only; supplied questions replace all existing questions in a transaction.
- `DELETE /quizzes/:id`: owner-only.
- `POST /quizzes/:id/attempts`: answer array and optional elapsed time; score is authoritative on the server.
- `GET /quizzes/:id/attempts/:attemptId`: attempt owner only.

Attempt submission creates `QuestionAnswer` rows, updates `SpacedRepetition`, and creates a quiz-completed notification.

## AI quiz (`aiQuiz.routes.ts`)

- `POST /ai-quiz/generate`: multipart `file` and `questionCount` (1-30).

PDF text is limited to 20,000 characters in the Gemini prompt. Generated JSON is normalized, but semantic quality and empty option text are not validated after generation. `GEMINI_API_KEY` is required.

## Exams (`exams.routes.ts`)

- `GET /exams?tab=mine|invited`.
- `GET /exams/:id`: organizer or participant only.
- `POST /exams`: title, subject/topic, type, duration, optional ISO start time, participant IDs, optional question count (default 20).
- `POST /exams/:id/start`: participant access; scheduled becomes started.
- `POST /exams/:id/submit`: participant answers and elapsed time; completes exam after all participants finish.

Exam questions are copied randomly from the topic's quiz-question pool. Friend-exam invitees must be accepted friends. Invitations create notifications.

## Friends (`friends.routes.ts`)

- `GET /friends`: accepted friends.
- `GET /friends/search?q=`: up to 20 users with relationship and mutual count.
- `GET /friends/requests`: `{ received, sent }`.
- `POST /friends/request/:userId`.
- `POST /friends/accept/:userId`.
- `POST /friends/decline/:userId`.
- `DELETE /friends/request/:userId` cancels a sent request.
- `DELETE /friends/:userId` removes an accepted friendship.

Send and accept create notification records. Duplicate relationships in either direction return 409.

## Notifications (`notifications.routes.ts`)

- `GET /notifications`: newest first.
- `POST /notifications/read-all`.
- `POST /notifications/:id/read`.
- `DELETE /notifications/:id`.

The HTTP server also hosts Socket.IO. A JWT supplied in the socket handshake authenticates the connection, which joins `user:<userId>`. New notification records emit `notification:new` only to that private room.

## Dashboard (`dashboard.routes.ts`)

- `GET /dashboard/home`: totals, revisions due within three days, five recent quiz attempts, and last subject/topic.
- `GET /dashboard/performance?period=all|week|month`: summaries, trends, subject/topic averages, Monday-first weekly activity, upcoming revisions, insights, and recent exams.

## Error/status conventions

- Validation errors currently fall through to the generic 500 handler unless Zod handling is added.
- Explicit `ApiError` responses use the specified status and `{ error }`.
- Creation normally returns 201; successful mutations return JSON rather than 204.
