# Smart Study Flutter App

Smart Study is a Flutter learning application for organizing subjects and
topics, uploading study material, creating manual or AI-assisted quizzes,
taking exams with friends, tracking performance, and scheduling revision with
spaced repetition.

The application uses Riverpod for state, GoRouter for navigation, Dio for the
REST API, Socket.IO for real-time in-app notifications, secure storage for
authentication, and Material 3 light/dark themes.

The personal Subjects area contains only the signed-in user's subjects. Topic
creation inherits its subject, and quiz creation launched from a topic inherits
both subject and topic. Owned quizzes can be edited or deleted. Quiz creators
may configure an optional 1-180 minute limit; learners choose timed or untimed
practice before each attempt.

Dark-mode selection is stored on the device and restored before the first app
screen is rendered. Notifications are delivered through an authenticated
Socket.IO connection while the app is open; they are in-app events, not Android
or iOS push notifications, so a closed app will not receive them.

Authentication uses short-lived JWT access tokens plus rotating refresh
sessions stored in secure storage. Quiz practice is started on the server;
timed deadlines and elapsed time are server-authoritative, while an in-progress
answer draft is saved locally so practice can resume after navigation or an app
restart. Answer keys are returned to non-owners only after submission.

Quiz, friend, and notification lists load incrementally. Subjects support
search, sorting, visibility filters, and archive/restore. Friendship changes
arrive live through Socket.IO in addition to durable notification history.

## Run the application

Install packages and start Flutter from this directory:

```powershell
flutter pub get
flutter run
```

Override the backend when required:

```powershell
flutter run --dart-define=API_BASE_URL=http://YOUR_BACKEND:4000
```

Debug Android builds use `http://10.0.2.2:4000` by default. Release builds
automatically use the deployed HTTPS backend from
`lib/core/config/app_environment.dart`. A non-empty `API_BASE_URL` Dart define
overrides both defaults.

## Build an Android release

Build a release APK for direct installation:

```powershell
flutter build apk --release
```

The output is `build/app/outputs/flutter-apk/app-release.apk`. URL and Android
manifest changes are compiled into the APK, so rebuild and reinstall after
changing them. The main Android manifest must contain
`android.permission.INTERNET`; having it only in the debug/profile manifests
produces a release app that cannot reach the API.

For Google Play, build an app bundle:

```powershell
flutter build appbundle --release
```

The current Android release configuration still signs with the debug key. It
is suitable for release-mode testing but must be replaced with a protected
upload keystore before Play Store or external production distribution.

## How spaced repetition works

Spaced repetition schedules quiz revision at gradually increasing intervals.
It helps learners review difficult material sooner while allowing well-known
material to wait longer before the next review.

The backend calculates the schedule after every submitted quiz attempt. The
Flutter app receives the calculated `nextRevisionDate`; it does not calculate
or modify the interval locally.

The interval ladder is:

```text
1 day -> 3 days -> 7 days -> 14 days -> 30 days
```

- A score of 60% or higher advances the learner through the ladder.
- The first passing attempt schedules revision after one day.
- A score below 60% resets the interval to one day.
- Passing after reaching 30 days keeps the interval at 30 days.

Example:

```text
75% -> revise in 1 day
80% -> revise in 3 days
90% -> revise in 7 days
45% -> reset and revise in 1 day
```

## Where revision schedules appear in the app

### Home

Open the **Home** tab and look for **Memory plan**. It summarizes reviews due
now, reviews coming in the next three days, and all active memory plans. The
**Revision queue** shows the five nearest quizzes, including overdue reviews,
with their last recall score, current interval stage, and next-review timing.
Selecting a revision card starts that quiz again.

Source:
`lib/features/dashboard/presentation/screens/home_dashboard_screen.dart`

### Performance Dashboard

Select **View insights** from Home to open **My Performance**. Opening it from
the Memory Plan scrolls directly to **Memory & revision**, which shows due,
overdue, upcoming, and active plans, the five interval stages, and actionable
review cards. The dashboard also provides period comparisons, real daily study
consistency, subject/topic rankings, completion-dated exam history, score
trends, and personalized next actions. It does not invent a retention
percentage.

Source:
`lib/features/dashboard/presentation/screens/performance_dashboard_screen.dart`

### Subject topic cards

Open **Subjects**, select a subject, and view its topic cards. A topic with a
scheduled revision displays a `Revision:` label.

Source: `lib/shared/widgets/topic_card.dart`

### Topic Details

Open a topic from a subject. When revision data exists, the topic header shows
the last score and a **Next revision** label.

Source:
`lib/features/topics/presentation/screens/topic_detail_screen.dart`

## Data flow

```text
Quiz submitted
    -> backend calculates score
    -> backend updates SpacedRepetition record
    -> dashboard/topic API returns nextRevisionDate
    -> Riverpod provider parses the response
    -> Flutter displays the revision schedule
```

Related frontend files:

- `lib/shared/models/quiz_model.dart`
- `lib/shared/models/topic_model.dart`
- `lib/features/dashboard/presentation/providers/dashboard_provider.dart`
- `lib/features/dashboard/presentation/providers/performance_provider.dart`
- `lib/core/utils/helpers.dart`

The **Spaced Repetition** switch currently shown under Settings is UI-only.
Changing it does not yet enable or disable backend scheduling.

## Developer documentation

The module-wise developer wiki starts at
[`docs/wiki/README.md`](docs/wiki/README.md). It covers frontend modules,
backend endpoints, data models, architecture, known gaps, and the recommended
development workflow.

Production backend setup and automatic deployment are documented in
[`../backend/DEPLOYMENT.md`](../backend/DEPLOYMENT.md).
