# Architecture

## Frontend stack

- Flutter and Material 3, with light and dark themes.
- Riverpod `StateNotifierProvider` for feature state and `Provider.family` for entity/filter selectors.
- GoRouter with a five-tab authenticated shell.
- Dio for REST and multipart requests.
- `flutter_secure_storage` for access and rotating refresh tokens.
- `shared_preferences` for the persisted dark-mode choice.
- Equatable immutable domain models with manual JSON parsing.

`main.dart` initializes Flutter, reads the saved theme, initializes the API singleton, overrides the theme provider, and starts `MaterialApp.router`.

## Backend stack

- Node.js, Express, TypeScript, Zod, Prisma, PostgreSQL.
- Socket.IO on the same HTTP server for authenticated foreground events.
- JWT bearer authentication; passwords use bcrypt.
- Multer handles disk uploads and memory-only AI inputs.
- A server-side environment switch selects OpenAI Responses or Gemini for strictly structured quiz generation.
- Central JSON errors use `{ "error": "message" }`.

Required backend variables are `DATABASE_URL` and `JWT_SECRET`. Production also requires explicit `CORS_ORIGIN`; JWT secrets shorter than 32 characters and wildcard production CORS fail at startup. Session/reset lifetime is controlled by `JWT_EXPIRES_IN`, `REFRESH_TOKEN_EXPIRES_DAYS`, and `PASSWORD_RESET_TTL_MINUTES`.

## Navigation

Unauthenticated routes:

- `/splash`, `/login`, `/register`, `/forgot-password`

Shell tabs:

- `/home/dashboard`, `/home/subjects`, `/home/exams`, `/home/friends`, `/home/profile`

Drill-down routes:

- Subjects: `/subjects/create`, `/subjects/:subjectId`, `/subjects/:subjectId/edit`
- Topics: `/subjects/:subjectId/topics/create`, `/subjects/:subjectId/topics/:topicId`, `/topics/:topicId/edit`
- Documents: `/documents/upload`, `/documents/:documentId/view`
- Quizzes: `/quizzes`, `/quizzes/create`, `/quizzes/:quizId/edit`, `/quizzes/:quizId/attempt`, `/quizzes/:quizId/result/:attemptId`
- AI: `/ai-quiz`
- Exams: `/exams/create`, `/exams/:examId`, `/exams/:examId/attempt`, `/exams/:examId/result`
- Social/profile: `/friends/requests`, `/friends/find`, `/users/:userId/profile`, `/profile/edit`
- Utility: `/notifications`, `/dashboard`, `/dashboard?section=memory`, `/settings`

There is no global GoRouter redirect. Splash performs the token check and navigates to login or the dashboard.

## State flow

Feature notifiers generally load in their constructors. Screens watch state and render loading, error, empty, or content UI. Create/update/delete calls modify local collections after a successful API response.

Topic state is a merged per-subject cache. Quiz state separates its entity cache from the active paginated management/discovery list. Friend and notification state paginate independently and refresh from authenticated Socket.IO events. Performance state owns a typed `PerformanceReport`; Home deep-links to its memory section while all calculations remain backend-owned.

The visual system uses Manrope typography, warm light neutrals and ink-navy
dark surfaces, luminous indigo/violet and mint gradients, 16px controls,
20-28px elevated surfaces, and a floating Material 3 navigation dock. Shared
theme and color tokens remain the source of truth for both brightness modes.

Nested creation preserves context: subject-to-topic creation fixes the subject ID, while topic-to-quiz creation passes fixed subject/topic IDs through GoRouter `extra`. Quiz attempts show a practice-mode screen before timing begins.

## Authentication and networking

The frontend base URL is selected by `AppConstants.baseUrl`:

- `--dart-define=API_BASE_URL=...` wins.
- Every release build defaults to the deployed HTTPS URL in `AppEnvironment.productionUrl`.
- Debug Android defaults to `http://10.0.2.2:4000`.
- Debug web/desktop defaults to `http://localhost:4000`.

These values are compiled into the application. Rebuild and reinstall after a
URL change. Android release networking also requires
`android.permission.INTERNET` in `android/app/src/main/AndroidManifest.xml`;
the development-only debug/profile manifests are not merged into a release.

Dio reads `auth_token` before each request. On an authenticated `401`, one shared refresh operation rotates `refresh_token`, retries the original request once, and signs out only if rotation/retry fails. Logout and password reset revoke server-side refresh sessions. Backend `requireAuth` verifies the access JWT and confirms the user still exists.

The socket client uses the same backend origin and derives its path from the API URL. It sends the access JWT in the handshake and reconnects automatically. An expired socket JWT first rotates the refresh session and reconnects with the new access token; invalid sessions trigger sign-out. Authenticated rooms receive `notification:new`, `friendship:changed`, and `exam:changed` events.

## Production deployment

Backend pushes to `main` run the GitHub Actions deployment workflow. It builds a versioned release under `/opt/smart-study-backend`, reuses shared environment/uploads, applies Prisma migrations, switches the `current` symlink, restarts the systemd service, checks `/health`, and rolls back the symlink after a failed health check. Server bootstrap, GitHub secrets, restricted deploy-user permissions, and Nginx WebSocket proxying are documented in `backend/DEPLOYMENT.md`.

Flutter produces direct-install APKs under
`build/app/outputs/flutter-apk/` and Google Play bundles under
`build/app/outputs/bundle/release/`. The current release build uses the debug
signing key and is not ready for store distribution until a protected upload
keystore is configured.

## Visibility and ownership

Content visibility is `private`, `friendsOnly`, or `public`. Backend helpers in `friends.routes.ts` are the authority:

- Owners always have access.
- Public content is available to authenticated viewers.
- Friends-only content requires an accepted friendship.
- Private content is owner-only.

Mutation routes separately require ownership. `allowCopy` currently has a working document-copy route; equivalent subject/topic/quiz copy operations are not implemented.

## Shared UI system

Colors, themes, and spacing tokens live under `lib/core/theme/`. `AppSpacing`
defines the shared 20px page gutter, 12px item gap, 24px section gap, and
screen insets for forms, filters, lists, and FAB layouts. Smaller padding is
reserved for content inside cards, chips, and buttons. Reusable controls
include buttons, cards, fields, avatars, confirmation dialogs, empty/error
states, shimmer loaders, list cards, score circles, stats, section headers,
and visibility badges. Feature pages should reuse these before adding local
variants.
