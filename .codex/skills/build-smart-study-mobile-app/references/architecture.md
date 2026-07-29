# Smart Study architecture

## Runtime stack

- Flutter with Dart SDK constraint `^3.0.0` and Material 3.
- Riverpod (`flutter_riverpod`) with `ProviderScope`, `StateNotifierProvider`, `StateProvider`, and `Provider.family`.
- GoRouter with a root navigator and a shell navigator for the five-tab authenticated area.
- Dio singleton for REST calls; `flutter_secure_storage` stores the bearer token.
- Socket.IO client for authenticated foreground events. `AppConstants` derives the socket origin and path from `API_BASE_URL`; production resolves to origin `https://84.247.138.71` and path `/smart-study/socket.io`.
- Shared preferences restore dark mode before the application renders.
- Equatable domain models with manual `fromJson`, `toJson`, and `copyWith` methods.
- Google Fonts Manrope theme, shared color/gradient/elevation tokens, reusable UI widgets, fl_chart, cached images, file/image pickers, and animation helpers.

## Project map

```text
lib/
  main.dart                         app bootstrap and ProviderScope
  core/
    constants/                      URLs, storage keys, limits, copy
    network/                        Dio client, Socket.IO client, error translation
    router/app_router.dart          all GoRouter routes
    theme/                          light/dark Material 3 theme and colors
    utils/                          validation and formatting helpers
  features/<feature>/presentation/
    providers/                      State, StateNotifier, derived providers
    screens/                        Consumer UI and local interaction state
  shared/
    models/                         cross-feature domain contracts
    widgets/                        reusable design-system components
```

Features: auth, dashboard, subjects, topics, documents, quizzes, ai_quiz, exams, friends, profile, notifications, and settings.

The paired backend is a separate repository at `../backend`: Express/TypeScript, Prisma/PostgreSQL, JWT authentication, Multer uploads, environment-selected OpenAI/Gemini quiz generation, Socket.IO, and a versioned GitHub Actions deployment workflow.

## Navigation map

Authentication: `/splash`, `/login`, `/register`, `/forgot-password`.

Shell tabs: `/home/dashboard`, `/home/subjects`, `/home/exams`, `/home/friends`, `/home/profile`.

Drill-down routes include subject create/detail/edit; subject-scoped topic create/detail and topic edit; quiz list/create/edit/attempt/result; document upload/view; AI quiz; exam create/detail/attempt/result; friend requests, friend discovery, and user profile; notifications, performance dashboard, settings, and profile edit.

Keep route parameter names aligned with screen constructor requirements. Add specific static routes before overlapping parameterized routes when route matching could be ambiguous.

## State and screen conventions

- State objects are immutable classes with defaults and `copyWith`.
- Notifiers often load on construction; avoid duplicate network loads caused by additional screen lifecycle calls.
- Providers retain lists and expose entity/filter selectors through `Provider.family`.
- `notificationProvider` performs one REST history load and then consumes `notification:new` Socket.IO events. It starts/stops with authentication and merges notifications by ID and creation time; do not reintroduce periodic REST polling.
- `ApiClient` emits a guarded session-expired event for authenticated `401` responses. `authProvider` clears authentication state and Socket.IO, while the app root redirects to login and shows the session message.
- `examProvider` retains sanitized exam summaries plus active attempts/results, and an `ownedExamIds` set populated from the `mine` endpoint and successful creation responses. The Exams shell tab derives dashboard totals, search/status filters, organizer invitation/submission progress, and released performance metrics from this cache. Attempt screens use the server clock/deadline and provider-owned autosave/submission calls.
- `subjectProvider` owns only the authenticated user's subjects. Nested topic/quiz creation carries parent IDs through navigation instead of asking users to select context again.
- Quiz attempts begin with a timed/untimed mode choice. The configured 1-180 minute countdown is optional and starts only after the learner chooses timed practice.
- `darkModeProvider` persists the user's choice and is overridden at startup with the saved value.
- Screens render loading, error, empty, and content states and offer retry or pull-to-refresh when appropriate.
- Forms own `TextEditingController`, selection, and validation state locally, then delegate mutations to a notifier.
- Shared widgets include app buttons, cards, text fields, bottom navigation, avatars, confirmation dialogs, empty/error states, shimmer loaders, cards/tiles, badges, score circles, stats, and section headers.

## Design language

- Primary luminous indigo `#5B5BEF` with deep-indigo/violet hero gradients; accent/success mint `#19BFA0`; warning amber; error rose.
- Light scaffold uses a warm blue-gray neutral and bordered white cards; dark scaffold uses ink navy with elevated blue-gray surfaces.
- Manrope typography, rounded 16px controls, rounded 20-28px elevated surfaces, restrained layered shadows, and full-width 52px primary actions.
- The authenticated shell uses a floating rounded `NavigationBar` dock. The home screen leads with a gradient focus hero, compact metrics, two high-value quick actions, a Memory Plan summary, revision queue, and rich recent-learning cards. Memory Plan shows real due/upcoming/active schedule counts; revision cards display the backend interval stage, last recall score, and next-review timing. The newest attempt is featured; compact history cards preserve score, subject/topic, correctness, duration, AI origin, and practice mode.
- My Performance uses typed report models and real server aggregates for prior-period comparison, daily consistency, streaks, memory stages, actionable reviews, rankings, and completion-dated exam history. Home opens `/dashboard?section=memory` when the learner selects Memory Plan.
- Use theme colors instead of hard-coded light-only colors. Preserve responsive scrolling and avoid fixed layouts that overflow small phones or text scaling.
- Use `AppSpacing` for screen-level layout: 20px page gutters, 12px item gaps, and 24px section gaps. Keep smaller spacing values inside components rather than using them at page edges.

## Branding and documentation

- Installed display name is **Smart Study**; the Dart package identifier remains `my_app` because Dart identifiers cannot contain spaces.
- Launcher artwork source is `assets/branding/smart_study_app_icon.png`; platform icons are generated by `flutter_launcher_icons`.
- Frontend overview and spaced-repetition UI locations are in `README.md`.
- The module wiki starts at `docs/wiki/README.md`.

## Deployment shape

The backend workflow `.github/workflows/deploy.yml` validates `main`, uploads an immutable release as the restricted `deploy` user, runs `prisma migrate deploy`, switches the `current` symlink, restarts `smart-study-backend.service`, checks `/health`, and rolls back the symlink on failure. Production `.env` and uploads live under `/opt/smart-study-backend/shared/`.
