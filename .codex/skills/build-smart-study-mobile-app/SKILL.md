---
name: build-smart-study-mobile-app
description: Build, extend, debug, review, migrate, deploy, or test the Smart Study Flutter application and its FastAPI/PostgreSQL backend. Use for Dart, Flutter, Python, FastAPI, SQLAlchemy, Pydantic, REST, Socket.IO, Firebase Cloud Messaging, Riverpod, GoRouter, Dio, authentication, subjects, topics, documents, quizzes, spaced repetition, AI quiz generation, exams, friends, profiles, real-time notifications, dashboards, settings, theming, deployment, or Android/iOS/web/desktop behavior in Smart Study.
---

# Build Smart Study Mobile App

## Start with repository evidence

1. Work from the Flutter project root containing `pubspec.yaml` and `lib/main.dart`. The production backend source is the sibling `../smart_study_backend/`. The legacy Express repository at `../backend` is historical read-only migration evidence; its production PM2 process has been permanently removed.
2. Inspect the files related to the requested feature before changing code. Do not assume generic Flutter conventions override repository patterns.
3. Read [architecture.md](references/architecture.md) for module placement, state flow, navigation, and UI conventions.
4. Read [domain-and-api.md](references/domain-and-api.md) when changing models, providers, authentication, networking, uploads, or backend contracts.
5. Read [fastapi-migration.md](../../../docs/wiki/fastapi-migration.md) before backend work. Check `git status --short` and preserve unrelated user changes. Do not modify `../backend` unless the user explicitly requests legacy maintenance.

## Implement changes

- Keep the feature-first structure: place screens and feature-owned providers under `lib/features/<feature>/presentation/`; place cross-feature models and widgets under `lib/shared/`; place network, routing, theme, constants, and utilities under `lib/core/`.
- Use `ConsumerWidget` for read-only Riverpod views and `ConsumerStatefulWidget` only for local lifecycle, controllers, timers, form state, or animation state.
- Follow the existing `StateNotifier<State>` pattern. Model loading and error state explicitly, clear stale errors before requests, parse responses into typed models, and update local collections immutably.
- Access the backend through the initialized `ApiClient().dio`. Reuse `apiErrorMessage` for user-facing failures. Preserve bearer-token injection and secure storage.
- Show action failures through `AppMessage.error`: keep the message selectable, visible until dismissed, closable, and horizontally dismissible. Render persistent error-state details with `SelectableText`; users must be able to select and copy the original backend message without a dedicated Copy button.
- Keep notification delivery layered: PostgreSQL/REST is authoritative history, authenticated `SocketClient` handles immediate foreground events in `user:<userId>`, and `PushNotificationService`/Firebase Cloud Messaging handles background or terminated Android/iOS delivery. Start both transports after authentication, register refreshed FCM tokens through `POST /notifications/devices`, unregister the current token before sign-out, suppress duplicate foreground system banners, and defer terminated-app tap navigation until authentication is restored.
- Keep FCM server delivery best-effort and post-commit: a Firebase outage must not roll back the originating quiz, exam, friend, AI, or revision operation. Store unique device tokens in `push_device_tokens`, remove tokens rejected as unregistered or sender-mismatched, and preserve REST inbox delivery even when push is disabled.
- Keep scheduler polling cadence separate from user intent. `EXAM_LIFECYCLE_INTERVAL_SECONDS` and `REVISION_REMINDER_INTERVAL_SECONDS` are server-worker intervals and must not appear in user settings. Persist per-user exam lead time in hours and revision lead time in days through `/users/me/notification-preferences`; scheduler scans apply those preferences and claim each exam/revision reminder exactly once.
- Persist appearance choices through the settings provider and `SharedPreferences`; load saved theme state before rendering `MaterialApp` to avoid a light-theme flash.
- Treat backend JSON as a contract. Update model parsing, serialization, provider requests, and affected UI together. Convert numeric JSON through `num` before `toInt()` or `toDouble()`.
- Register new screens in `lib/core/router/app_router.dart`. Use `context.go` for replacing the current navigation location or switching shell tabs; use `context.push` for drill-down flows that should return.
- Keep `/dashboard`, including `/dashboard?section=memory`, inside the authenticated `ShellRoute` so My Performance retains the bottom navigation dock. Treat it as Home-owned when resolving the selected dock item.
- Keep read-only exam detail and result routes inside the authenticated `ShellRoute` so the bottom dock remains visible with Exams selected. Keep create, question-building, friend-contribution, and active-attempt routes outside the shell as focused workflows.
- Reuse shared widgets and theme tokens before adding one-off styles. Support both light and dark themes and use Material 3 semantics.
- Preserve mounted checks after asynchronous work before navigation or UI access.
- Keep exam ownership based on the backend `mine` result and locally created exam IDs, not only `organizerId`, so new exams appear immediately.
- Keep collaborative friend exams blind and equal: the organizer participates and contributes the same quota, contributors can retrieve only their own draft questions, lobby views expose counts but never content, and publish requires every invitation resolved and every remaining participant ready. Reject normalized duplicates without revealing the existing question.
- Keep both individual and collaborative exam subject/topic classification optional. If selected, expose accessible related exams in those detail views. Use a positive numeric questions-per-participant field rather than capped presets; do not impose product-level participant or contribution-list caps.
- Build individual exam papers from any questions in the organizer's own quizzes, not only a selected topic. Reuse `ExamQuestionLibraryPicker` as the primary friend-contribution screen too: support search plus collapsible subject/topic/quiz filters, whole-quiz and per-question selection, separate Selected quizzes and Available quiz library sections, and exact-quota selection. Keep these as sections in one view, not tab controls, and preserve usable list height on compact phones. Do not force a review step for quiz-library contributions; enable direct private submission when the quota is full. Show an existing private contribution as a selected `Current private questions` group so it can be retained, removed, or replaced. Keep `Write new` as a secondary manual editor that prefills selected quiz questions, supports completing remaining slots, validates four unique options and local duplicates, and warns before discarding unsaved work. After an individual exam is published, lock its question paper; allow cancellation through the normal published-exam lifecycle only.
- Treat spaced-repetition scheduling as backend-owned. Quiz submission updates `[1, 3, 7, 14, 30]` day intervals at a 60% pass threshold; Flutter displays `nextRevisionDate` but does not calculate it.
- Keep performance analytics server-authoritative and typed through `PerformanceReport`. Compare equal rolling periods, build activity from actual quiz attempts and submitted exam attempts, filter exam history by `submittedAt`, expose stored memory intervals/stages, and never invent a retention percentage. Preserve `/dashboard?section=memory` as the Home Memory Plan deep link.
- Keep destructive actions behind confirmation and keep private/friends/public visibility and `allowCopy` rules intact.
- Preserve deep subject copying through `POST /subjects/:id/copy`. Require source visibility and source `allowCopy` for non-owners; create a private, editable, non-copyable destination subject; copy only visible nested topics, quizzes, and documents whose own `allowCopy` is enabled; clone quiz questions, preserve immutable creator provenance, and safely share document file references.
- Treat **My Subjects** as owner-only. `GET /subjects` returns only the authenticated user's subjects; keep cross-user discovery in explicit social/discovery flows.
- Treat subject ownership as a hard write boundary. Never let a viewer create, upload, edit, delete, archive, or move topics, quizzes, or documents inside another user's subject or topic. In foreign content, expose only authorized view, practice, friendship, and copy-to-my-content actions. Enforce the same rule in both Flutter action visibility and backend authorization; never trust route IDs or hidden buttons alone.
- Make social context unmistakable. A user profile and every foreign subject/topic detail view must visibly identify the owner and explain that the viewer is in shared content, not My Subjects. Keep owner-only FABs, empty-state actions, menus, and create routes absent from foreign views.
- Preserve parent context in nested creation flows. Subject-scoped topic creation must not ask for a subject; topic-scoped quiz creation must not ask for a subject or topic.
- Keep quiz ownership controls server-authoritative. Owned quiz cards may edit/delete; edit replaces the current question set, and deletion requires confirmation.
- Keep practice timing server-authoritative through `QuizSession`; submit `sessionId`, never client elapsed seconds. Hide solutions from non-owners until submission and preserve resumable local answer drafts.
- Preserve rotating refresh-session behavior in `ApiClient`: serialize refresh, rotate the secure refresh token, retry once, and revoke on sign-out/password reset.
- Keep growing quiz, friend, subject, and notification collections paginated. Friendship mutations must emit `friendship:changed` to both user rooms.
- Serve document uploads only through authenticated document authorization. Verify magic bytes, parent ownership/visibility, and delete the physical file only after its final reference is gone. Do not expose the raw uploads directory; give avatars a separate explicit delivery policy.
- Quiz time limits are optional whole minutes from 1 to 180. Before an attempt, offer timed practice when a limit exists and always offer untimed practice; start timing only after mode selection.
- Normalize user-authored subject, topic, quiz, question, option, and explanation text before PostgreSQL writes; remove NUL characters and validate the normalized value.
- Build backend behavior in `../smart_study_backend/app/` with thin routers, Pydantic schemas, domain services, and focused SQLAlchemy repositories. Prefer explicit domain code over generic base repositories.
- Configure Firebase Admin with `PUSH_NOTIFICATIONS_ENABLED`, `FIREBASE_PROJECT_ID`, and either `FIREBASE_SERVICE_ACCOUNT_JSON` or `GOOGLE_APPLICATION_CREDENTIALS`. Inline JSON takes priority, must remain one physical line with private-key newlines encoded as `\n`, and must never be committed. Keep the credential file and the shared production `.env` mode `600`.
- Preserve the existing PostgreSQL schema and enum values during migration. Prisma migrations remain historical schema evidence; FastAPI uses async SQLAlchemy with Psycopg 3 and must not create a parallel database.
- Preserve every Flutter-facing path, method, status code, response envelope, JSON key, enum spelling, timestamp, pagination shape, upload field, and Socket.IO event. Do not mark a module migrated until parity tests cover its critical behavior.
- Keep raw document files private behind authenticated delivery. Keep avatars under a separate, explicit public profile-media policy.
- Do not add a new state-management, routing, HTTP, persistence, serialization, or design-system library unless the request requires it.

## Add a feature consistently

1. Define or extend an Equatable domain model in `lib/shared/models/` when data crosses screens or features.
2. Add a feature state and notifier with typed success/error transitions.
3. Add derived `Provider.family` selectors when screens need entity lookup or filtered collections.
4. Build loading, error, empty, and populated UI states with existing shared components.
5. Add routes and connect navigation from the owning flow.
6. Confirm request paths, payload keys, response envelopes, enum encoding, nullable fields, and date formats against existing contracts or backend evidence.
7. Add focused tests for parsing, notifier behavior, validation, or critical widget interactions.

## Validate proportionally

Before running automated checks for any ownership-aware feature, write and verify an action matrix for owner, friend, and non-friend viewers across private, friends-only, and public content. Confirm each visible action against its endpoint. At minimum, verify:

- Owner: create/edit/delete/upload actions target only owned subjects and topics.
- Friend/non-friend: no create/edit/delete/upload action appears in foreign content, including empty states, FABs, menus, and deep-linked forms.
- Copy: source and every parent are visible, `allowCopy` is respected, the destination is owned and active, and the copy is private/editable with immutable original-creator attribution.
- Context: profile and foreign detail screens show whose space/content is being viewed.
- API: direct requests with guessed foreign subject/topic IDs return `403`, even when the Flutter control is hidden.

Run available checks from the Flutter project root:

```text
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

For FastAPI backend changes, run from `../smart_study_backend/`:

```text
.venv/Scripts/python.exe -m ruff format --check app tests
.venv/Scripts/python.exe -m ruff check app tests
.venv/Scripts/python.exe -m compileall -q app tests
.venv/Scripts/python.exe -m pytest -q
```

Use `scripts/seed_test_users.py` for generated development data. Require the explicit test-database guard in automation; never run seed or migration experiments against production.

Run `dart format lib test` when formatting changes are authorized. For platform-specific work, also run the relevant build or launch command. Use `--dart-define=API_BASE_URL=<url>` for non-default backend locations; Android emulator localhost maps to `10.0.2.2`.

For Android release work, keep `android.permission.INTERNET` in `android/app/src/main/AndroidManifest.xml`; debug/profile manifests do not contribute it to a release APK. Release mode defaults to `AppEnvironment.productionUrl`, while a non-empty `API_BASE_URL` remains the highest-priority compile-time override. Rebuild and reinstall after changing either value because an installed APK retains its compiled URL. Verify the generated APK manifest with `aapt dump permissions` and require a successful build plus a newly updated artifact before reporting completion.

For mobile push work, require the Android Firebase app ID `com.example.my_app` and `android/app/google-services.json`. The iOS Firebase app ID is `com.example.myApp`; add `ios/Runner/GoogleService-Info.plist` to the Runner target, enable Push Notifications and Background Modes > Remote notifications, upload the APNs key in Firebase Console, and test Apple delivery on a physical device. Rebuild/reinstall after changing native Firebase files.

Before finishing, inspect the diff, confirm imports/routes/session transactions/socket lifecycle, verify async mounted safety, and report checks that could not run. For historical contract questions, compare with `../backend/src/` without modifying it. Production is served at `https://chatbot.kadaima.com/smart-study`; preserve the `/smart-study/socket.io` reverse-proxy path. Successful pushes to backend `main` automatically validate on Python 3.12 and deploy through `.github/workflows/deploy.yml`. Monitor both jobs and verify the public `/health/ready` response; never edit `/opt/smart-study-backend/current` directly. Runtime services are `smart-study-fastapi.service` and `smart-study-scheduler.service`.
