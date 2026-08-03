# Smart Study Developer Wiki

This wiki describes the Flutter frontend and the production FastAPI backend in the sibling `../smart_study_backend/`. The legacy Express/Prisma repository at `../backend/` is historical read-only evidence; its production runtime has been removed. See [FastAPI migration](fastapi-migration.md) for the completed cutover record.

## Wiki map

- [Architecture](architecture.md): runtime stack, application lifecycle, state, navigation, security, and repository layout.
- [Frontend modules](frontend-modules.md): every screen, provider, model, route, and important interaction grouped by feature.
- [Backend and API](backend-api.md): server modules and endpoint contracts grouped by feature.
- [Data model](data-model.md): Prisma entities, relationships, enums, cascade behavior, and Dart DTO mapping.
- [Development guide](development-guide.md): how to add features safely, local and Android release setup, testing, known gaps, and priorities.
- [FastAPI migration](fastapi-migration.md): compatibility rules, implementation record, production cutover, commands, and operational guarantees.

## System at a glance

```text
Flutter UI
  -> Riverpod feature notifier + typed domain models
  -> Dio + access token / rotating refresh session
  -> FastAPI router + Pydantic validation
  -> service + SQLAlchemy repository
  -> PostgreSQL

Backend notification service
  -> persist notification
  -> Socket.IO event to authenticated user room
  -> Riverpod merges the event into visible app state

Uploads -> FastAPI multipart/signature validation -> private uploads -> authenticated document file route
AI quiz -> multipart upload -> PDF/image extraction -> selected OpenAI/Gemini provider -> editable questions -> quiz creation
Performance -> completion-dated backend aggregates -> typed PerformanceReport -> charts, rankings, memory actions
Exam builder -> owned quiz-question catalog -> grouped selected/available picker -> locked published paper
Subject copy -> visibility/copy authorization -> private nested copy with creator provenance
```

The app is feature-first. A normal change should update the feature screen, provider, shared model, backend route/schema, serializer, and tests together.

## Source roots

- [Frontend bootstrap](../../lib/main.dart)
- [Navigation](../../lib/core/router/app_router.dart)
- [Frontend features](../../lib/features/)
- [Shared models](../../lib/shared/models/)
- [Shared widgets](../../lib/shared/widgets/)
- [FastAPI application](../../../smart_study_backend/app/main.py)
- [API router](../../../smart_study_backend/app/api/router.py)
- [Backend routers](../../../smart_study_backend/app/routers/)
- [Backend services](../../../smart_study_backend/app/services/)
- [Backend repositories](../../../smart_study_backend/app/repositories/)
- [FastAPI README](../../../smart_study_backend/README.md)
- [Legacy database schema](../../../backend/prisma/schema.prisma)

## Module source map

| Module | Frontend | Backend |
|---|---|---|
| Authentication | [auth](../../lib/features/auth/) | [FastAPI auth](../../../smart_study_backend/app/routers/auth.py) |
| Profile/settings | [profile](../../lib/features/profile/), [settings](../../lib/features/settings/) | [FastAPI users](../../../smart_study_backend/app/routers/users.py) |
| Dashboard | [dashboard](../../lib/features/dashboard/) | [FastAPI dashboard](../../../smart_study_backend/app/routers/dashboard.py) |
| Subjects | [subjects](../../lib/features/subjects/) | [FastAPI subjects](../../../smart_study_backend/app/routers/subjects.py) |
| Topics | [topics](../../lib/features/topics/) | [FastAPI topics](../../../smart_study_backend/app/routers/topics.py) |
| Documents | [documents](../../lib/features/documents/) | [FastAPI documents](../../../smart_study_backend/app/routers/documents.py) |
| Quizzes | [quizzes](../../lib/features/quizzes/) | [FastAPI quizzes](../../../smart_study_backend/app/routers/quizzes.py) |
| AI quiz | [AI quiz](../../lib/features/ai_quiz/) | [FastAPI AI quiz](../../../smart_study_backend/app/routers/ai_quiz.py) |
| Exams | [exams](../../lib/features/exams/) | [FastAPI exams](../../../smart_study_backend/app/routers/exams.py) |
| Friends | [friends](../../lib/features/friends/) | [FastAPI friends](../../../smart_study_backend/app/routers/friends.py) |
| Notifications | [notifications](../../lib/features/notifications/) | [FastAPI notifications](../../../smart_study_backend/app/routers/notifications.py) |

## Current development rules

1. Preserve the API response envelopes (`user`, `subjects`, `quiz`, `attempt`, and so on).
2. Keep enum conversion aligned between Dart camel-case values and PostgreSQL uppercase values.
3. Enforce ownership and visibility on the server, not only in the UI.
4. Update Riverpod collections immutably after mutations so changes appear immediately.
5. Use `ApiClient().dio`; it injects the access token and serializes refresh-token rotation before one retry.
6. Keep file limits aligned: PDF/JPG/JPEG/PNG, maximum 10 MB.
7. Never expose `.env`, JWT secrets, database credentials, or AI keys.
8. Keep user-visible failure details selectable through `AppMessage.error` or `ErrorState` so diagnostics can be copied directly.
