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

Open the **Home** tab and look for the **Due for Revision** section. It shows
the five nearest quizzes whose revision date is due within the next three days,
including overdue revisions. Selecting a card starts that quiz again.

Source:
`lib/features/dashboard/presentation/screens/home_dashboard_screen.dart`

### Performance Dashboard

From Home, select the **Dashboard** quick action. The **Upcoming Revisions**
section lists future quiz revision dates. The same page can show an insight when
revisions have been missed.

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
