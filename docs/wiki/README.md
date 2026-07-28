# Smart Study Developer Wiki

This wiki describes the Flutter frontend in `my_app/` and the Express/Prisma backend in `../backend/` as reviewed on 2026-07-28. It is the starting point for future development.

## Wiki map

- [Architecture](architecture.md): runtime stack, application lifecycle, state, navigation, security, and repository layout.
- [Frontend modules](frontend-modules.md): every screen, provider, model, route, and important interaction grouped by feature.
- [Backend and API](backend-api.md): server modules and endpoint contracts grouped by feature.
- [Data model](data-model.md): Prisma entities, relationships, enums, cascade behavior, and Dart DTO mapping.
- [Development guide](development-guide.md): how to add features safely, local setup, testing, known gaps, and priorities.

## System at a glance

```text
Flutter UI
  -> Riverpod feature notifier
  -> Dio + bearer token
  -> Express route + Zod validation
  -> Prisma
  -> PostgreSQL

Backend notification service
  -> persist notification
  -> Socket.IO event to authenticated user room
  -> Riverpod merges the event into visible app state

Uploads -> Multer -> backend/uploads -> /uploads static URL
AI quiz -> multipart upload -> PDF/image extraction -> selected OpenAI/Gemini provider -> editable questions -> quiz creation
```

The app is feature-first. A normal change should update the feature screen, provider, shared model, backend route/schema, serializer, and tests together.

## Source roots

- [Frontend bootstrap](../../lib/main.dart)
- [Navigation](../../lib/core/router/app_router.dart)
- [Frontend features](../../lib/features/)
- [Shared models](../../lib/shared/models/)
- [Shared widgets](../../lib/shared/widgets/)
- [Backend application](../../../backend/src/app.ts)
- [Backend routes](../../../backend/src/routes/)
- [Database schema](../../../backend/prisma/schema.prisma)
- [Backend README](../../../backend/README.md)
- [Production deployment](../../../backend/DEPLOYMENT.md)

## Module source map

| Module | Frontend | Backend |
|---|---|---|
| Authentication | [auth](../../lib/features/auth/) | [auth routes](../../../backend/src/routes/auth.routes.ts) |
| Profile/settings | [profile](../../lib/features/profile/), [settings](../../lib/features/settings/) | [user routes](../../../backend/src/routes/users.routes.ts) |
| Dashboard | [dashboard](../../lib/features/dashboard/) | [dashboard routes](../../../backend/src/routes/dashboard.routes.ts) |
| Subjects | [subjects](../../lib/features/subjects/) | [subject routes](../../../backend/src/routes/subjects.routes.ts) |
| Topics | [topics](../../lib/features/topics/) | [topic routes](../../../backend/src/routes/topics.routes.ts) |
| Documents | [documents](../../lib/features/documents/) | [document routes](../../../backend/src/routes/documents.routes.ts) |
| Quizzes | [quizzes](../../lib/features/quizzes/) | [quiz routes](../../../backend/src/routes/quizzes.routes.ts) |
| AI quiz | [AI quiz](../../lib/features/ai_quiz/) | [AI route](../../../backend/src/routes/aiQuiz.routes.ts), [AI service](../../../backend/src/services/ai.service.ts) |
| Exams | [exams](../../lib/features/exams/) | [exam routes](../../../backend/src/routes/exams.routes.ts) |
| Friends | [friends](../../lib/features/friends/) | [friend routes](../../../backend/src/routes/friends.routes.ts) |
| Notifications | [notifications](../../lib/features/notifications/) | [notification routes](../../../backend/src/routes/notifications.routes.ts) |

## Current development rules

1. Preserve the API response envelopes (`user`, `subjects`, `quiz`, `attempt`, and so on).
2. Keep enum conversion aligned between Dart camel-case values and Prisma uppercase values.
3. Enforce ownership and visibility on the server, not only in the UI.
4. Update Riverpod collections immutably after mutations so changes appear immediately.
5. Use `ApiClient().dio`; it injects the secure bearer token.
6. Keep file limits aligned: PDF/JPG/JPEG/PNG, maximum 10 MB.
7. Never expose `.env`, JWT secrets, database credentials, or AI keys.
