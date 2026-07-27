# Architecture

## Frontend stack

- Flutter and Material 3, with light and dark themes.
- Riverpod `StateNotifierProvider` for feature state and `Provider.family` for entity/filter selectors.
- GoRouter with a five-tab authenticated shell.
- Dio for REST and multipart requests.
- `flutter_secure_storage` for the JWT.
- `shared_preferences` for the persisted dark-mode choice.
- Equatable immutable domain models with manual JSON parsing.

`main.dart` initializes Flutter, reads the saved theme, initializes the API singleton, overrides the theme provider, and starts `MaterialApp.router`.

## Backend stack

- Node.js, Express, TypeScript, Zod, Prisma, PostgreSQL.
- JWT bearer authentication; passwords use bcrypt.
- Multer handles disk uploads and memory-only AI inputs.
- Gemini 1.5 Flash generates quiz questions.
- Central JSON errors use `{ "error": "message" }`.

Required backend variables are `DATABASE_URL` and `JWT_SECRET`. Optional configuration includes `PORT`, `JWT_EXPIRES_IN`, `GEMINI_API_KEY`, `CORS_ORIGIN`, and `PUBLIC_BASE_URL`.

## Navigation

Unauthenticated routes:

- `/splash`, `/login`, `/register`, `/forgot-password`

Shell tabs:

- `/home/dashboard`, `/home/subjects`, `/home/exams`, `/home/friends`, `/home/profile`

Drill-down routes:

- Subjects: `/subjects/create`, `/subjects/:subjectId`, `/subjects/:subjectId/edit`
- Topics: `/subjects/:subjectId/topics/:topicId`, `/topics/create`, `/topics/:topicId/edit`
- Documents: `/documents/upload`, `/documents/:documentId/view`
- Quizzes: `/quizzes`, `/quizzes/create`, `/quizzes/:quizId/attempt`, `/quizzes/:quizId/result/:attemptId`
- AI: `/ai-quiz`
- Exams: `/exams/create`, `/exams/:examId/attempt`, `/exams/:examId/result`
- Social/profile: `/friends/requests`, `/users/:userId/profile`, `/profile/edit`
- Utility: `/notifications`, `/dashboard`, `/settings`

There is no global GoRouter redirect. Splash performs the token check and navigates to login or the dashboard.

## State flow

Feature notifiers generally load in their constructors. Screens watch state and render loading, error, empty, or content UI. Create/update/delete calls modify local collections after a successful API response.

Topic state is a merged per-subject cache. Quiz and exam state use `ensure*` methods for deep links. Exam state tracks owned IDs explicitly. Notification state loads history once through REST, then receives authenticated `notification:new` events through Socket.IO while the app is open.

## Authentication and networking

The frontend base URL is selected by `AppConstants.baseUrl`:

- `--dart-define=API_BASE_URL=...` wins.
- Android defaults to `http://10.0.2.2:4000`.
- Web/desktop defaults to `http://localhost:4000`.

Dio reads `auth_token` from secure storage before each request. A 401 refresh flow is not implemented; splash clears invalid tokens. Backend `requireAuth` verifies the JWT and sets `req.userId`.

## Visibility and ownership

Content visibility is `private`, `friendsOnly`, or `public`. Backend helpers in `friends.routes.ts` are the authority:

- Owners always have access.
- Public content is available to authenticated viewers.
- Friends-only content requires an accepted friendship.
- Private content is owner-only.

Mutation routes separately require ownership. `allowCopy` currently has a working document-copy route; equivalent subject/topic/quiz copy operations are not implemented.

## Shared UI system

Colors and themes live under `lib/core/theme/`. Reusable controls include buttons, cards, fields, avatars, confirmation dialogs, empty/error states, shimmer loaders, list cards, score circles, stats, section headers, and visibility badges. Feature pages should reuse these before adding local variants.
