# Development Guide

## Local startup

FastAPI backend directory: sibling `..\smart_study_backend`

```powershell
cd ..\smart_study_backend
python -m venv .venv
.venv\Scripts\python.exe -m pip install -r requirements-dev.txt
Copy-Item .env.example .env
.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 4000 --reload
```

Set `DATABASE_URL`, `JWT_SECRET`, `CORS_ORIGIN`, and `PUBLIC_BASE_URL` in `.env`.
The replacement service uses the existing PostgreSQL schema. Do not run schema
changes from both Prisma and a future Python migration tool.

Create the repeatable large development dataset when testing discovery and scrolling from the FastAPI backend:

```powershell
.venv\Scripts\python.exe scripts\seed_test_users.py --database-url-env TEST_DATABASE_URL --require-test-database
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
flutter build apk --release --dart-define=API_BASE_URL=https://chatbot.kadaima.com/smart-study
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

The latest verified direct-install build used:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://chatbot.kadaima.com/smart-study
```

It passed `flutter analyze` and all 14 Flutter tests, produced a 59.7 MB APK at
`build/app/outputs/flutter-apk/app-release.apk`, and verified with APK Signature
Scheme v2. It is release mode but debug-certificate signed, so it is not the final
Play Store artifact.

## Adding or changing a module

1. Confirm the existing PostgreSQL entity, relation, and enum representation.
2. Avoid schema changes until an Alembic baseline is introduced; never edit production data manually.
3. Validate input with Pydantic and enforce ownership/visibility in a domain service.
4. Keep database access in an explicit SQLAlchemy repository and HTTP details in a thin router.
5. Return the existing serializer envelope without changing Flutter contracts.
6. Update the corresponding Dart model only when adding a product feature, not for the migration itself.
7. Put REST work in the feature notifier through `ApiClient().dio`.
8. Update local state immutably after success.
9. Add loading, error, empty, and populated UI states.
10. Test route authorization, response parity, and frontend provider/model behavior.

## Validation commands

Frontend:

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Backend:

```powershell
.venv\Scripts\python.exe -m ruff format --check app tests
.venv\Scripts\python.exe -m ruff check app tests
.venv\Scripts\python.exe -m compileall -q app tests
.venv\Scripts\python.exe -m pytest -q
```

Current focused coverage includes compact-phone navigation/exam/performance widgets, exam and performance DTO parsing, spaced-repetition transitions, exam lifecycle/scoring/release rules, safe error mapping, rate limiting, and enum mapping. Continue adding route-level authorization and database integration coverage.

## Known gaps and risks

High priority:

- Replace the Android release debug signing configuration with a protected upload keystore before external distribution.
- Configure a newly rotated Gemini or OpenAI key in production before relying on AI quiz generation.
- Expand utility/widget coverage with database-backed integration tests for authentication, visibility, refresh rotation, quizzes, exams, documents, and friendships.
- Account deletion still needs an explicit physical-upload retention/cleanup policy; individual document deletion cleans the final file reference.
- Add database constraints ensuring a question belongs to exactly one quiz or exam.

Functional gaps:

- Password reset has hashed expiring tokens but no production email delivery.
- Settings font size, notification toggles, default visibility, terms, and privacy are not fully implemented.
- Notifications use authenticated foreground Socket.IO events, not OS push; closed apps receive nothing.
- Document viewing depends on external URL/open behavior; offline caching is absent.
- Home's small summary statistics still use a map; performance analytics are typed. Documents and long activity histories still need incremental/aggregate query optimization.

Security/data notes:

- All content APIs require authentication, including public content.
- Uploads validate supported extensions and PDF/PNG/JPEG signatures, then require authenticated file access.
- Development may allow broad CORS; restrict production to explicit origins before enabling a browser client.
- Password reset tokens are hashed and expire; successful reset revokes refresh sessions.
- Account and subject deletion cascade broadly; keep confirmations and add integration tests.

## Recommended next development order

1. Add a production email provider for password-reset delivery.
2. Expand database-backed API and end-to-end Flutter coverage.
3. Complete settings persistence, upload cleanup, and database constraints.
4. Replace Android debug signing/package identity with a protected production upload key and final application ID.

## Production deployment

FastAPI production is live at `https://chatbot.kadaima.com/smart-study`. Source is cloned at `/opt/smart-study-backend-v2`; immutable runtime releases, backups, shared `.env`, and uploads live at `/opt/smart-study-backend`. A push to backend `main` automatically runs Python 3.12 formatting, lint, compilation, entry-point import, and tests before uploading/activating the commit over the restricted `deploy` account. Monitor the GitHub Actions `validate` and `deploy` jobs and confirm the public `/health/ready` response. Use systemd for the web/scheduler, never edit `current` directly, and do not bypass a failed workflow with manual source edits. Express/PM2 and port `4001` were removed after cutover. See [the completed migration record](fastapi-migration.md) and backend `DEPLOYMENT.md` for rollback details.

## Keeping this wiki current

Any feature PR should update the relevant module section, endpoint list, data-model notes, and known gaps. Treat the wiki as part of the feature definition, not a one-time report.
