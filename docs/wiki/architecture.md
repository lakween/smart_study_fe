# Architecture

## Frontend stack

- Flutter and Material 3, with light and dark themes.
- Riverpod `StateNotifierProvider` for feature state and `Provider.family` for entity/filter selectors.
- GoRouter with a five-tab authenticated shell.
- Dio for REST and multipart requests.
- `flutter_secure_storage` for access and rotating refresh tokens.
- `shared_preferences` for the persisted dark-mode choice.
- Firebase Core/Messaging for Android/iOS push-token lifecycle and notification-tap routing.
- Equatable immutable domain models with manual JSON parsing.

`main.dart` initializes Flutter, reads the saved theme, initializes the API singleton and native Firebase configuration, overrides the theme provider, and starts `MaterialApp.router`.

## Backend stack

- Python, FastAPI, Uvicorn, Pydantic 2, async SQLAlchemy/Psycopg 3, PostgreSQL.
- The existing Prisma-created schema and data are reused; the legacy Express runtime has been removed after cutover.
- `python-socketio` runs on the same ASGI origin for authenticated foreground events.
- Firebase Admin sends best-effort FCM pushes to registered Android/iOS devices after notification transactions commit.
- JWT bearer authentication; passwords use bcrypt.
- FastAPI multipart handlers validate upload size, extension, and magic bytes. Documents use authenticated delivery; avatars use a separate explicit public route.
- Environment-selected OpenAI/Gemini quiz generation is implemented; production requires a rotated provider key in the shared `.env`.
- Central JSON errors use `{ "error": "message" }`.

Required backend variables are `DATABASE_URL` and `JWT_SECRET`. Production should use an explicit `CORS_ORIGIN` before serving browser clients and a high-entropy JWT secret. Session/reset lifetime is controlled by `JWT_EXPIRES_IN`, `REFRESH_TOKEN_EXPIRES_DAYS`, and `PASSWORD_RESET_TTL_MINUTES`. Mobile push additionally uses `PUSH_NOTIFICATIONS_ENABLED`, `FIREBASE_PROJECT_ID`, and either `FIREBASE_SERVICE_ACCOUNT_JSON` or `GOOGLE_APPLICATION_CREDENTIALS`.

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
- Exams: `/exams/create`, `/exams/:examId`, `/exams/:examId/contribute`, `/exams/:examId/attempt`, `/exams/:examId/result`
- Social/profile: `/friends/requests`, `/friends/find`, `/users/:userId/profile`, `/profile/edit`
- Messages: `/messages`, `/messages/:friendId`
- Utility: `/notifications`, `/dashboard`, `/dashboard?section=memory`, `/settings`

`/dashboard` and its memory deep link are children of the authenticated shell, even though they are not separate dock destinations. The performance view keeps the floating bottom dock visible and resolves to the Home item.

Exam detail and result routes are also children of the shell and resolve to the Exams dock item. Exam creation, individual question building, friend contribution, and active attempts stay outside the shell to preserve a focused workflow.

Conversation and chat routes are children of the shell and resolve to the Friends dock item. Open a conversation with `push` so system back returns to its owning Friends/messages flow instead of exiting the app.

There is no global GoRouter redirect. Splash performs the token check and navigates to login or the dashboard.

## State flow

Feature notifiers generally load in their constructors. Screens watch state and render loading, error, empty, or content UI. Create/update/delete calls modify local collections after a successful API response.

Topic state is a merged per-subject cache. Quiz state separates its entity cache from the active paginated management/discovery list. Friend, message, and notification state paginate independently and refresh from authenticated Socket.IO events. Message history is PostgreSQL-authoritative, is restricted to accepted friends, and is cleared on account changes. Notification state also registers the authenticated mobile FCM token; foreground push refreshes the relevant REST state and background/terminated taps deep-link after authentication. Performance state owns a typed `PerformanceReport`; Home deep-links to its memory section while all calculations remain backend-owned.

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

Dio reads `auth_token` before each request. On an authenticated `401`, one shared refresh operation rotates `refresh_token`, retries the original request once, and signs out only if rotation/retry fails. Logout and password reset revoke server-side refresh sessions. FastAPI's authentication dependency verifies the access JWT and confirms the user still exists.

The socket client uses the same backend origin and derives its path from the API URL. It sends the access JWT in the handshake and reconnects automatically. An expired socket JWT first rotates the refresh session and reconnects with the new access token; invalid sessions trigger sign-out. Authenticated rooms receive `notification:new`, `friendship:changed`, `exam:changed`, and recipient-only `message:new` events.

The push client uses `android/app/google-services.json` for package `com.example.my_app` and `ios/Runner/GoogleService-Info.plist` for bundle `com.example.myApp`. Login/register and token refresh call `POST /notifications/devices`; sign-out calls `DELETE /notifications/devices` before deleting the local token. PostgreSQL history is authoritative, Socket.IO handles foreground immediacy, and FCM covers background/terminated delivery.

## Production deployment

FastAPI production is live at `https://chatbot.kadaima.com/smart-study`. Nginx proxies to loopback port `4000`; the web and scheduler run as `smart-study-fastapi.service` and `smart-study-scheduler.service`. Releases are immutable under `/opt/smart-study-backend/releases`, while `.env` and uploads are shared. The preferred Firebase credential is complete one-line JSON in `FIREBASE_SERVICE_ACCOUNT_JSON`, wrapped in single quotes with private-key newlines preserved as `\n`; inline JSON takes priority over the optional credential-file path. The shared `.env` must remain mode `600`. Backend `main` pushes run the installed GitHub Actions validation/deploy workflow; activation runs checksum migrations and `/health/ready`, then atomically updates `/opt/smart-study-backend/current`. The former Express PM2 process and port `4001` are removed.

Flutter produces direct-install APKs under
`build/app/outputs/flutter-apk/` and Google Play bundles under
`build/app/outputs/bundle/release/`. The current release build uses the debug
signing key and is not ready for store distribution until a protected upload
keystore is configured.

## Visibility and ownership

Content visibility is `private`, `friendsOnly`, or `public`. FastAPI authorization services and repositories are the authority:

- Owners always have access.
- Public content is available to authenticated viewers.
- Friends-only content requires an accepted friendship.
- Private content is owner-only.

Mutation routes separately require ownership. Subject, topic, quiz, and document copy routes enforce visibility and `allowCopy`. A subject deep copy creates a private destination and includes only independently visible/copyable nested content while preserving original-creator provenance.

## Shared UI system

Colors, themes, and spacing tokens live under `lib/core/theme/`. `AppSpacing`
defines the shared 20px page gutter, 12px item gap, 24px section gap, and
screen insets for forms, filters, lists, and FAB layouts. Smaller padding is
reserved for content inside cards, chips, and buttons. Reusable controls
include buttons, cards, fields, avatars, confirmation dialogs, empty/error
states, shimmer loaders, list cards, score circles, stats, section headers,
and visibility badges. Feature pages should reuse these before adding local
variants.

Action failures use the shared `AppMessage.error` snackbar: the backend message is selectable, remains visible until dismissed, and includes close/swipe dismissal. Persistent error-state messages also use selectable text, so users can copy diagnostics without a dedicated Copy button.
