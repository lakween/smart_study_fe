---
name: build-smart-study-mobile-app
description: Build, extend, debug, review, deploy, or test the Smart Study Flutter application and its paired Express/Prisma backend. Use for Dart, Flutter, TypeScript, REST, Socket.IO, Riverpod, GoRouter, Dio, authentication, subjects, topics, documents, quizzes, spaced repetition, AI quiz generation, exams, friends, profiles, real-time notifications, dashboards, settings, theming, GitHub Actions deployment, or Android/iOS/web/desktop behavior in Smart Study.
---

# Build Smart Study Mobile App

## Start with repository evidence

1. Work from the Flutter project root containing `pubspec.yaml` and `lib/main.dart`. The paired backend is the separate Git repository at `../backend`.
2. Inspect the files related to the requested feature before changing code. Do not assume generic Flutter conventions override repository patterns.
3. Read [architecture.md](references/architecture.md) for module placement, state flow, navigation, and UI conventions.
4. Read [domain-and-api.md](references/domain-and-api.md) when changing models, providers, authentication, networking, uploads, or backend contracts.
5. Check `git status --short` in the frontend and, for backend work, `git -C ../backend status --short`. Preserve unrelated user changes in both repositories.

## Implement changes

- Keep the feature-first structure: place screens and feature-owned providers under `lib/features/<feature>/presentation/`; place cross-feature models and widgets under `lib/shared/`; place network, routing, theme, constants, and utilities under `lib/core/`.
- Use `ConsumerWidget` for read-only Riverpod views and `ConsumerStatefulWidget` only for local lifecycle, controllers, timers, form state, or animation state.
- Follow the existing `StateNotifier<State>` pattern. Model loading and error state explicitly, clear stale errors before requests, parse responses into typed models, and update local collections immutably.
- Access the backend through the initialized `ApiClient().dio`. Reuse `apiErrorMessage` for user-facing failures. Preserve bearer-token injection and secure storage.
- For real-time notifications, reuse `SocketClient`, authenticate the Socket.IO handshake with the stored JWT, keep user events scoped to `user:<userId>`, and retain REST only for history/manual refresh. Connect after authentication and disconnect on sign-out.
- Persist appearance choices through the settings provider and `SharedPreferences`; load saved theme state before rendering `MaterialApp` to avoid a light-theme flash.
- Treat backend JSON as a contract. Update model parsing, serialization, provider requests, and affected UI together. Convert numeric JSON through `num` before `toInt()` or `toDouble()`.
- Register new screens in `lib/core/router/app_router.dart`. Use `context.go` for replacing the current navigation location or switching shell tabs; use `context.push` for drill-down flows that should return.
- Reuse shared widgets and theme tokens before adding one-off styles. Support both light and dark themes and use Material 3 semantics.
- Preserve mounted checks after asynchronous work before navigation or UI access.
- Keep exam ownership based on the backend `mine` result and locally created exam IDs, not only `organizerId`, so new exams appear immediately.
- Treat spaced-repetition scheduling as backend-owned. Quiz submission updates `[1, 3, 7, 14, 30]` day intervals at a 60% pass threshold; Flutter displays `nextRevisionDate` but does not calculate it.
- Keep performance analytics server-authoritative and typed through `PerformanceReport`. Compare equal rolling periods, build activity from actual quiz attempts and submitted exam attempts, filter exam history by `submittedAt`, expose stored memory intervals/stages, and never invent a retention percentage. Preserve `/dashboard?section=memory` as the Home Memory Plan deep link.
- Keep destructive actions behind confirmation and keep private/friends/public visibility and `allowCopy` rules intact.
- Treat **My Subjects** as owner-only. `GET /subjects` returns only the authenticated user's subjects; keep cross-user discovery in explicit social/discovery flows.
- Preserve parent context in nested creation flows. Subject-scoped topic creation must not ask for a subject; topic-scoped quiz creation must not ask for a subject or topic.
- Keep quiz ownership controls server-authoritative. Owned quiz cards may edit/delete; edit replaces the current question set, and deletion requires confirmation.
- Keep practice timing server-authoritative through `QuizSession`; submit `sessionId`, never client elapsed seconds. Hide solutions from non-owners until submission and preserve resumable local answer drafts.
- Preserve rotating refresh-session behavior in `ApiClient`: serialize refresh, rotate the secure refresh token, retry once, and revoke on sign-out/password reset.
- Keep growing quiz, friend, subject, and notification collections paginated. Friendship mutations must emit `friendship:changed` to both user rooms.
- Serve document uploads only through authenticated document authorization. Verify magic bytes, parent ownership/visibility, and delete the physical file only after its final reference is gone. Do not expose the raw uploads directory; give avatars a separate explicit delivery policy.
- Quiz time limits are optional whole minutes from 1 to 180. Before an attempt, offer timed practice when a limit exists and always offer untimed practice; start timing only after mode selection.
- Normalize user-authored subject, topic, quiz, question, option, and explanation text before PostgreSQL writes; remove NUL characters and validate the normalized value.
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

Run available checks from the Flutter project root:

```text
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

For backend changes, also run from `../backend`:

```text
npm run build
npm audit --omit=dev
```

Use `npm run seed:test-users` when development needs the repeatable 100-user dataset. It replaces only `seed.user###@smartstudy.test` accounts and creates subjects, topics, quizzes, and questions for pagination/content testing.

Run `dart format lib test` when formatting changes are authorized. For platform-specific work, also run the relevant build or launch command. Use `--dart-define=API_BASE_URL=<url>` for non-default backend locations; Android emulator localhost maps to `10.0.2.2`.

Before finishing, inspect both repository diffs when applicable, confirm imports/routes/socket lifecycle, verify async mounted safety, and report checks that could not run. For production socket changes, confirm the `/smart-study/socket.io` reverse-proxy upgrade configuration documented in `../backend/DEPLOYMENT.md`.
