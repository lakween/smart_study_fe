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
```

The current frontend test is only a template-level widget test; meaningful module tests still need to be added. The backend has no automated test script.

## Known gaps and risks

High priority:

- Add backend/frontend automated tests for authentication, visibility, quiz scoring, exam participation, and friendships.
- Handle Zod errors as 400 responses rather than generic 500 errors.
- Refresh tokens do not exist. Authenticated REST `401` responses and Socket.IO authentication failures automatically clear the session and return the user to login.
- Remove sensitive Dio request/response body logging from release builds.
- Delete physical upload files when their records/account are removed, or document retention policy.
- Add database constraints ensuring a question belongs to exactly one quiz or exam.

Functional gaps:

- Password reset has no email delivery or token expiry.
- Subject/topic/quiz `allowCopy` is displayed/stored but copy endpoints are absent; only documents can be copied.
- Settings font size, notification toggles, default visibility, terms, and privacy are not fully implemented.
- Notifications use authenticated foreground Socket.IO events, not OS push; closed apps receive nothing.
- Friends/request collections are separate from the notification stream and still require their own refresh after an incoming request.
- Document viewing depends on external URL/open behavior; offline caching is absent.
- Dashboard uses dynamic maps instead of typed models.
- Friend discovery is paginated. Pagination is still absent for growing subjects, documents, quizzes, notifications, and activity histories.

Security/data notes:

- All content APIs require authentication, including public content.
- File validation is extension-based; add MIME/signature checks for stronger upload security.
- CORS defaults to all origins.
- Password reset tokens are stored as plain values in development and have no expiration.
- Account and subject deletion cascade broadly; keep confirmations and add integration tests.

## Recommended next development order

1. Tests and Zod error handling.
2. Complete settings persistence and application.
3. Synchronize friend/request collections when related Socket.IO events arrive.
4. Copy workflows for subjects/topics/quizzes, or remove unused flags.
5. Pagination and typed dashboard models.
6. Production password reset, logging hardening, and upload cleanup.

## Production deployment

The backend repository contains `.github/workflows/deploy.yml` for automatic deployment after `main` passes validation. It uses versioned releases, shared production data, Prisma migrations, a restricted deployment user, systemd, a health check, and automatic application rollback. Follow [`backend/DEPLOYMENT.md`](../../../backend/DEPLOYMENT.md) for the required Ubuntu, SSH, GitHub secret, and Nginx WebSocket configuration.

## Keeping this wiki current

Any feature PR should update the relevant module section, endpoint list, data-model notes, and known gaps. Treat the wiki as part of the feature definition, not a one-time report.
