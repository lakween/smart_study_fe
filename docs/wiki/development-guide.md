# Development Guide

## Local startup

Backend directory: `C:\Users\lakwe\Downloads\Smart_Study_App\Smart_Study_App\backend`

```powershell
npm install
npx prisma generate
npx prisma migrate dev
npm run dev
```

Create the repeatable large development dataset when testing discovery and scrolling:

```powershell
npm run seed:test-users
```

This replaces only `seed.user001@smartstudy.test` through `seed.user100@smartstudy.test`. Every generated account uses password `test@123` and receives 6 subjects, 12 topics, and 24 quizzes.

Flutter directory: `C:\Users\lakwe\Downloads\Smart_Study_App\Smart_Study_App\my_app`

```powershell
flutter pub get
flutter run
```

Android emulator uses `10.0.2.2:4000`. For a physical phone, run with a reachable computer LAN address:

```powershell
flutter run --dart-define=API_BASE_URL=http://YOUR_COMPUTER_IP:4000
```

`PUBLIC_BASE_URL` must use the same reachable host or uploaded images/files will point at localhost.

## Android release build

Release mode automatically selects the deployed HTTPS URL from
`AppEnvironment.productionUrl`. Use an explicit compile-time override only for
a different production or staging backend:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com/smart-study
```

Without an override, build with:

```powershell
flutter build apk --release
```

Install `build/app/outputs/flutter-apk/app-release.apk`. Rebuild and reinstall
after changing a Dart define or manifest because an already-installed APK
retains the old compiled values.

Before handing off an APK:

1. Confirm the production `/health` endpoint returns HTTP 200.
2. Confirm `android/app/src/main/AndroidManifest.xml` contains `android.permission.INTERNET`.
3. Require the build command to succeed and confirm the APK timestamp changed.
4. Inspect the compiled APK with Android Build Tools: `aapt dump permissions build/app/outputs/flutter-apk/app-release.apk`.
5. Install the new artifact and check Android logs for DNS, connection, and TLS errors.

For Google Play, use `flutter build appbundle --release`. The current Gradle
release configuration uses the debug signing key; configure and securely back
up a production upload keystore before publishing.

## Adding or changing a module

1. Confirm the Prisma entity and enum representation.
2. Add a migration for schema changes; do not edit production data manually.
3. Validate backend input with Zod and enforce ownership/visibility server-side.
4. Return a stable serializer envelope.
5. Update the corresponding Dart model with tolerant nullable/numeric parsing.
6. Put REST work in the feature notifier through `ApiClient().dio`.
7. Update local state immutably after success.
8. Add loading, error, empty, and populated UI states.
9. Register routes in `app_router.dart`; place static routes before overlapping parameter routes.
10. Test backend route authorization and frontend provider/model behavior.

## Validation commands

Frontend:

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Backend:

```powershell
npm run build
npm test
npm audit --omit=dev
```

Current focused coverage includes compact-phone navigation/exam/performance widgets, exam and performance DTO parsing, spaced-repetition transitions, exam lifecycle/scoring/release rules, safe error mapping, rate limiting, and enum mapping. Continue adding route-level authorization and database integration coverage.

## Known gaps and risks

High priority:

- Replace the Android release debug signing configuration with a protected upload keystore before external distribution.
- Expand utility/widget coverage with database-backed integration tests for authentication, visibility, refresh rotation, quizzes, exams, documents, and friendships.
- Replace legacy avatar `/uploads/...` URLs with a dedicated, explicitly authorized or intentionally public avatar delivery route.
- Account deletion still needs an explicit physical-upload retention/cleanup policy; individual document deletion cleans the final file reference.
- Add database constraints ensuring a question belongs to exactly one quiz or exam.

Functional gaps:

- Password reset has hashed expiring tokens but no production email delivery.
- Subject/topic/quiz `allowCopy` is displayed/stored but copy endpoints are absent; only documents can be copied.
- Settings font size, notification toggles, default visibility, terms, and privacy are not fully implemented.
- Notifications use authenticated foreground Socket.IO events, not OS push; closed apps receive nothing.
- Document viewing depends on external URL/open behavior; offline caching is absent.
- Home's small summary statistics still use a map; performance analytics are typed. Documents and long activity histories still need incremental/aggregate query optimization.

Security/data notes:

- All content APIs require authentication, including public content.
- Uploads validate supported extensions and PDF/PNG/JPEG signatures, then require authenticated file access.
- Development may allow broad CORS; production requires explicit configured origins.
- Password reset tokens are hashed and expire; successful reset revokes refresh sessions.
- Account and subject deletion cascade broadly; keep confirmations and add integration tests.

## Recommended next development order

1. Database-backed API integration tests.
2. Complete settings persistence and application.
3. Add a production email provider for password-reset delivery; development may return/log the reset token.
4. Copy workflows for subjects/topics/quizzes, or remove unused flags.
5. Aggregate/paginate large document and analytics histories.
6. Account-level physical-upload cleanup and the question-parent database constraint.

## Production deployment

The backend repository contains `.github/workflows/deploy.yml` for automatic deployment after `main` passes validation. It uses versioned releases, shared production data, Prisma migrations, a restricted deployment user, systemd, a health check, and automatic application rollback. Follow [`backend/DEPLOYMENT.md`](../../../backend/DEPLOYMENT.md) for the required Ubuntu, SSH, GitHub secret, and Nginx WebSocket configuration.

## Keeping this wiki current

Any feature PR should update the relevant module section, endpoint list, data-model notes, and known gaps. Treat the wiki as part of the feature definition, not a one-time report.
