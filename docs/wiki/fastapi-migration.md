# FastAPI Backend Migration

## Goal

The Express/TypeScript backend in `../backend` has been replaced by the Python
service in the sibling `../smart_study_backend` without changing the Flutter wire
contract. PostgreSQL data was preserved, production traffic was switched after
readiness testing, and the Express PM2 runtime was removed.

## Target stack

- FastAPI and Uvicorn for HTTP/ASGI.
- Pydantic 2 for request validation.
- SQLAlchemy 2 async sessions with Psycopg 3.
- PostgreSQL using the existing Prisma-created schema and data.
- PyJWT and bcrypt-compatible password hashes.
- `python-socketio` for the existing Socket.IO client protocol.
- Firebase Admin for authenticated Android/iOS background and terminated push delivery.
- Pytest/HTTPX for contract and integration tests.
- Ruff for formatting and linting.

The FastAPI backend uses a simple layered structure:

```text
smart_study_backend/
  app/
    api/             router composition
    routers/         HTTP parsing, status codes, response envelopes
    schemas/         Pydantic request validation
    services/        authorization and business rules
    repositories/    SQLAlchemy database access
    config.py        environment configuration
    database.py      async engine and request sessions
    errors.py        public error mapping
    security.py      JWT authentication
    serializers.py   database-to-wire DTO mapping
  tests/             contract, rule, and integration tests
```

Keep routers thin. Put reusable rules in services and database operations in
domain repositories. Avoid generic base repositories when explicit code is
clearer.

## Contract rules

Flutter must not change for this migration. Preserve:

1. Paths and HTTP methods.
2. Bearer and Socket.IO JWT behavior.
3. Request JSON and multipart field names.
4. Status codes and `{ "error": "..." }` failures.
5. Response envelopes, keys, enum spellings, nullability, and timestamps.
6. Pagination fields and ordering.
7. Ownership, visibility, copying, and solution-release rules.
8. Socket.IO path, rooms, and event names.
9. Server-authoritative quiz/exam timing and spaced repetition.

The service connects to the existing database. Do not replay Prisma migrations
against a new schema or run two applications that mutate schema concurrently.
Prisma files remain the current historical migration record until an Alembic
baseline is deliberately introduced.

## Migration status

Implemented in FastAPI:

- Health, shared errors/security headers, CORS, and configuration.
- Authentication: register, login, current user, refresh rotation, logout, and
  forgot/reset password.
- Subjects: listing, detail, create, update, delete, and visibility-aware deep copy with nested copy rules and immutable creator provenance.
- Topics: listing, detail, create, update, delete, and copy.
- Documents: listing, detail, validated upload, authenticated delivery, update,
  delete with final-reference cleanup, and copy.
- Quizzes: discovery, detail, CRUD, deep copy, timed/untimed sessions,
  authoritative submissions, attempt review, notifications, and spaced repetition.
- Users: profile/privacy updates, cache-safe avatar and cover-photo upload/delivery,
  password/email changes, account deletion, and visibility-filtered social profiles.
- Friends: accepted/search/request lists and send, accept, decline, cancel, and
  remove mutations with durable friend notifications.
- Messages: accepted-friend-only text conversations, paginated durable history,
  read tracking, recipient-only `message:new` delivery, and FCM chat deep links.
- Notifications: paginated history, mark one/all read, dismiss, authenticated FCM
  device-token register/unregister, unique token ownership, best-effort post-commit
  delivery, and stale-token cleanup.
- Socket.IO: JWT-authenticated connections, per-user rooms, and live notification,
  friendship, and exam event emitters. Friend mutations publish live friendship
  changes and friend notifications after commit; quiz completion publishes its
  durable notification after the attempt transaction commits.
- Dashboards: home statistics, revision summary/queue, recent activity and last
  context; typed performance summaries, equal rolling-period comparison, score
  trends, real activity/streaks, stored memory stages, rankings, recommendations,
  and completion-dated exam history.
- AI quiz generation: validated transient PDF/JPEG/PNG uploads, PDF text
  extraction, OpenAI/Gemini structured generation, regeneration with duplicate
  avoidance, grounded question validation, and durable/live AI notifications.
- Exams phase 2: owned/invited lists, detail, draft create/edit/delete, optional
  classification/scheduling, organizer-owned quiz-library question selection,
  accepted-friend invitations, invitation responses,
  cancellation, durable notifications, and live `exam:changed` events.
- Exams phase 3: unique start/resume attempts, server clock/deadlines, scoped
  answer autosave, idempotent scoring/submission, participant completion,
  conditional solution release, results, submission notifications, and the
  legacy-compatible start endpoint.
- Exam lifecycle scheduler: PostgreSQL-locked periodic scans start scheduled
  exams, claim and score expired attempts, expire unanswered invitations, close
  exams, persist notifications, and publish post-commit live events safely
  across multiple workers.
- Revision reminder scheduler: PostgreSQL-locked due-review scans atomically
  apply each user's enabled/day-based lead preference, atomically claim each stored
  revision date, persist one reminder, and emit it after commit without duplicating
  delivery across workers. The exam lifecycle scan similarly claims one reminder
  per user+exam+scheduled start using the user's hour-based lead preference.
- Rate limiting: per-client `/auth` and `/ai-quiz` request windows preserve the
  Express limits, headers, error response, trusted-proxy option, and scope isolation.
- Database integration foundation: a guarded `_test`-only PostgreSQL preparation
  command applies the historical Prisma migrations; registration/login and owned
  subject CRUD now run through real FastAPI requests and PostgreSQL transactions.
  The same flow covers topic ownership, protected document upload/download,
  public quiz visibility, hidden solutions, practice sessions, scoring, and
  spaced-repetition persistence. It also caught and fixed Prisma-text/UUID binding
  mismatches and naive/aware quiz-session timestamp arithmetic.
  Social database coverage now verifies request/accept transitions, durable friend
  notifications, accepted-friend listings, friends-only topic access versus
  non-friends, private copy output with original-creator provenance, and scoped
  notification read/delete behavior.
  Subject database coverage also verifies deep-copy counts, private destinations,
  nested visibility/copy filtering, cloned quiz questions, safe document references,
  and immutable original-creator provenance.
  Dashboard and lifecycle coverage verifies real home/performance aggregation,
  revision reminder persistence and exact-once claiming, and an individual exam's
  publish/start/answer/submit/score/solution-release journey. These tests also fixed
  dashboard timestamp comparisons, exam UUID/text bindings, and UTC writes into
  Prisma `TIMESTAMP(3)` columns on non-UTC database hosts.
  Friend-exam coverage now verifies accepted and unanswered invitations, answer
  autosave, deadline auto-submission and scoring, invitation expiry, exam closure,
  post-close result release, durable/live lifecycle events, and an idempotent second
  scheduler scan against PostgreSQL.
  AI quiz database coverage verifies authenticated multipart generation, upload
  signatures, generation-option and regeneration avoidance contracts, durable/live
  AI notifications, saving reviewed output as an AI-generated quiz, and practicing
  that persisted quiz. Only the external model response is stubbed in this test.
- Python database operations: the migration command applies the ordered historical
  SQL under a PostgreSQL advisory lock, recognizes existing Prisma/test ledgers,
  records checksums, rejects edited applied migrations, and is idempotent. The seed
  command reproduces the generated test-user/content catalog with bcrypt-compatible
  credentials and replaces only `seed.user###@smartstudy.test` accounts. Both commands
  support an explicit `_test` database guard for automation.
- Production deployment bundle: hardened systemd units separate the single FastAPI/
  Socket.IO web process from the scheduler worker; Nginx preserves the
  `/smart-study/socket.io` upgrade path; immutable releases share environment/uploads,
  run self-contained checksum migrations, use database-aware readiness, atomically
  roll the application symlink back on failure, and emit request-correlated JSON logs.

## Production cutover completed

- Ubuntu host `84.247.138.71` runs immutable releases under
  `/opt/smart-study-backend`; source is cloned at `/opt/smart-study-backend-v2`.
- Production traffic uses `https://chatbot.kadaima.com/smart-study` through Nginx
  to loopback port `4000`, including `/smart-study/socket.io` upgrades.
- `smart-study-fastapi.service` and `smart-study-scheduler.service` are enabled,
  active, and configured to start automatically after reboot.
- PostgreSQL was backed up before migration; checksum migrations are current and
  `/health/ready` reports the database ready.
- The Express PM2 entry was deleted, the empty PM2 state was saved, its daemon was
  stopped, and port `4001` is closed.
- `.github/workflows/deploy.yml` is live with GitHub production secrets and a
  dedicated restricted SSH key. The first verified automatic deployment activated
  release `b97dfd36c5d99ca3a831d8377734eee4ba6dcb9f`; validation, upload, migrations,
  systemd restart, and public database readiness all passed.

Remaining product operations are not migration blockers: configure a newly rotated
AI-provider key, finish production Firebase/APNs secret configuration, add production
password-reset email delivery, and replace Android debug signing before store
distribution.

## Local commands

```powershell
cd ..\smart_study_backend
.\scripts\dev.ps1
.venv\Scripts\python.exe -m pip install -r requirements-dev.txt
.venv\Scripts\python.exe -m ruff format --check app tests
.venv\Scripts\python.exe -m ruff check app tests
.venv\Scripts\python.exe -m compileall -q app tests
.venv\Scripts\python.exe -m pytest -q
.venv\Scripts\python.exe scripts\migrate_database.py
.venv\Scripts\python.exe scripts\seed_test_users.py
.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 4000 --reload
```

Copy `.env.example` to `.env` and point `DATABASE_URL` at the development database.
Set `TEST_DATABASE_URL` to a separate database whose name ends in `_test`, then run
`python scripts/prepare_test_database.py`; the command refuses non-test database names.
For guarded direct operations, pass `--database-url-env TEST_DATABASE_URL
--require-test-database` to the migration or seed command.
Use Flutter's `API_BASE_URL` define when testing a non-default local or staging host.

## Definition of done

A module is complete only when its routes are implemented, formatter/linter/tests
pass, database behavior is exercised, and its contract is compared against Express.
The overall migration completed after Socket.IO and schedulers worked, the Flutter
workflow passed against FastAPI, production data was backed up, immutable deployment
and readiness checks succeeded, Nginx traffic moved to port `4000`, and Express was
permanently removed. Future changes must preserve those operational guarantees.
