# Smart Study architecture

## Runtime stack

- Flutter with Dart SDK constraint `^3.0.0` and Material 3.
- Riverpod (`flutter_riverpod`) with `ProviderScope`, `StateNotifierProvider`, `StateProvider`, and `Provider.family`.
- GoRouter with a root navigator and a shell navigator for the five-tab authenticated area.
- Dio singleton for REST calls; `flutter_secure_storage` stores the bearer token.
- Equatable domain models with manual `fromJson`, `toJson`, and `copyWith` methods.
- Google Fonts Inter theme, shared color tokens, reusable UI widgets, fl_chart, cached images, file/image pickers, and animation helpers.

## Project map

```text
lib/
  main.dart                         app bootstrap and ProviderScope
  core/
    constants/                      URLs, storage keys, limits, copy
    network/                        Dio client and error translation
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

## Navigation map

Authentication: `/splash`, `/login`, `/register`, `/forgot-password`.

Shell tabs: `/home/dashboard`, `/home/subjects`, `/home/exams`, `/home/friends`, `/home/profile`.

Drill-down routes include subject create/detail/edit; topic create/detail/edit; document upload/view; quiz list/create/attempt/result; AI quiz; exam create/attempt/result; friend requests and user profile; notifications, performance dashboard, settings, and profile edit.

Keep route parameter names aligned with screen constructor requirements. Add specific static routes before overlapping parameterized routes when route matching could be ambiguous.

## State and screen conventions

- State objects are immutable classes with defaults and `copyWith`.
- Notifiers often load on construction; avoid duplicate network loads caused by additional screen lifecycle calls.
- Providers retain lists and expose entity/filter selectors through `Provider.family`.
- Screens render loading, error, empty, and content states and offer retry or pull-to-refresh when appropriate.
- Forms own `TextEditingController`, selection, and validation state locally, then delegate mutations to a notifier.
- Shared widgets include app buttons, cards, text fields, bottom navigation, avatars, confirmation dialogs, empty/error states, shimmer loaders, cards/tiles, badges, score circles, stats, and section headers.

## Design language

- Primary indigo `#4F46E5`; accent/success emerald `#10B981`; warning amber; error red.
- Light scaffold uses slate-50 and white cards; dark scaffold uses slate-900 and slate-800 cards.
- Inter typography, rounded 12px controls, rounded 16px cards, restrained elevation, and full-width 52px primary actions.
- Use theme colors instead of hard-coded light-only colors. Preserve responsive scrolling and avoid fixed layouts that overflow small phones or text scaling.
