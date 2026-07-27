# Data Model

## Enums

Prisma uses uppercase values; serializers/mappers convert to frontend values.

- `StudyLevel`: SCHOOL, UNDERGRADUATE, POSTGRADUATE, SELF_LEARNER.
- `Visibility`: PRIVATE, FRIENDS_ONLY, PUBLIC.
- `DocumentType`: PDF, JPG, JPEG, PNG.
- `AnswerOption`: A, B, C, D.
- `ExamType`: INDIVIDUAL, FRIEND_EXAM.
- `ExamStatus`: DRAFT, SCHEDULED, STARTED, COMPLETED, CANCELLED.
- `FriendshipStatus`: PENDING, ACCEPTED, DECLINED.
- `NotificationType`: QUIZ, EXAM, FRIEND, REMINDER, AI, GENERAL.

## Entity relationships

```text
User
├─ Subject ─┬─ Topic ─┬─ Document
│           │         ├─ Quiz ─ Question
│           │         └─ Exam ─ Question
│           ├─ Document
│           ├─ Quiz
│           └─ Exam
├─ QuizAttempt ─ QuestionAnswer
├─ SpacedRepetition
├─ ExamParticipant
├─ Notification
└─ Friendship (requester/addressee)
```

## Entities

- `User`: authentication/profile fields, optional password reset token, ownership and participation relations.
- `Friendship`: directional requester/addressee pair with a unique directional constraint; application logic prevents reverse duplicates.
- `Subject`: owner-controlled container with visibility and copy flag.
- `Topic`: belongs to a subject and carries its own visibility/copy fields, though access is primarily gated through its subject.
- `Document`: subject required, topic optional, URL/type/size metadata, owner and visibility.
- `Quiz`: subject/topic/owner, visibility, AI flag, optional time limit, questions and attempts.
- `Question`: belongs to either a quiz or exam by nullable foreign keys; schema does not enforce exactly one parent.
- `QuizAttempt`: user/quiz score summary and answer rows.
- `QuestionAnswer`: selected option and correctness for one attempted question.
- `SpacedRepetition`: one row per user+quiz, with topic, score, interval, and next date.
- `Exam`: subject/topic, organizer, type/status/timing, copied questions and participants.
- `ExamParticipant`: unique exam+user result and completion state.
- `Notification`: user-owned message, type, read state, optional related entity ID.

## Cascade behavior

Most ownership/content relations use `onDelete: Cascade`. Deleting a user or subject can remove a large connected graph. Document-topic uses `SetNull`. The UI must keep destructive confirmation for these actions.

## Serializer contract

Backend serializers are the wire-format authority. They add names/counts/statistics not stored directly in individual tables. Frontend DTO parsing expects these shapes, especially:

- `subjectName`, `topicName`, and owner display fields.
- Quiz attempt/best/average/revision fields.
- Exam participant name/image/result fields.
- User statistics.

When adding a database field, update Prisma migration, route include/select, serializer, Dart model, provider, and affected UI together.

