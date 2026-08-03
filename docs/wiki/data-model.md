# Data Model

## Enums

PostgreSQL stores uppercase enum values; FastAPI serializers/mappers convert them to frontend values. The schema was originally created by Prisma and its migrations remain historical evidence during the migration.

- `StudyLevel`: SCHOOL, UNDERGRADUATE, POSTGRADUATE, SELF_LEARNER.
- `Visibility`: PRIVATE, FRIENDS_ONLY, PUBLIC.
- `DocumentType`: PDF, JPG, JPEG, PNG.
- `AnswerOption`: A, B, C, D.
- `ExamType`: INDIVIDUAL, FRIEND_EXAM.
- `ExamStatus`: DRAFT, SCHEDULED, STARTED, COMPLETED, CANCELLED.
- `ExamInvitationStatus`: PENDING, ACCEPTED, DECLINED, EXPIRED.
- `ExamAttemptStatus`: IN_PROGRESS, SUBMITTED, AUTO_SUBMITTED.
- `ExamResultRelease`: AFTER_SUBMISSION, AFTER_CLOSE.
- `FriendshipStatus`: PENDING, ACCEPTED, DECLINED.
- `NotificationType`: QUIZ, EXAM, FRIEND, REMINDER, AI, GENERAL.

## Entity relationships

```text
User
├─ RefreshToken
├─ Subject ─ Topic ─ Document / Quiz / Exam
├─ QuizSession ─ QuizAttempt ─ QuestionAnswer
├─ SpacedRepetition
├─ ExamInvitation / ExamParticipant
├─ ExamAttempt ─ ExamAnswer
├─ Notification
└─ Friendship (requester/addressee)
```

## Entities

- `User`: authentication/profile fields, hashed expiring password-reset data, refresh sessions, ownership, attempts, and participation relations.
- `RefreshToken`: hashed rotating session token with expiry, revocation, replacement, and user relation.
- `Friendship`: directional requester/addressee pair with a unique directional constraint; application logic prevents reverse duplicates.
- `Subject`: owner-controlled container with visibility/copy flags plus `originalCreatorId`, `originalCreatorName`, and `copiedFromId` provenance for deep copies. A copied subject is private and non-copyable by default.
- `Topic`: belongs to a subject and carries its own visibility/copy fields, though access is primarily gated through its subject.
- `Document`: subject required, topic optional, URL/type/size metadata, owner and visibility.
- `Quiz`: subject/topic/owner, visibility, AI flag, optional time limit, questions and attempts.
- `Question`: belongs to either a quiz or exam by nullable foreign keys; schema does not enforce exactly one parent.
- `QuizSession`: server-authoritative timed/untimed practice start, optional deadline, and one submitted attempt.
- `QuizAttempt`: user/quiz score summary, server-recorded duration/session relation, and answer rows.
- `QuestionAnswer`: selected option and correctness for one attempted question.
- `SpacedRepetition`: one row per user+quiz, with topic, score, interval, and next date.
- `Exam`: optional subject/topic/start time, organizer, type/status/timing, snapshot questions and participants. Individual drafts select snapshots from any organizer-owned quiz; collaborative drafts snapshot each participant's private contribution on publish.
- Exam subject/topic foreign keys are nullable and use `ON DELETE SET NULL`, so a general exam needs no classification and an existing exam survives classification deletion. Indexed nullable keys support related-exam tabs.
- Collaborative exams set nullable `questionsPerParticipant` and `contributionInstructions`. `ExamQuestionContribution` stores each participant's private question/options/answer and a Unicode-normalized per-exam duplicate key until publish copies the complete set into `Question` snapshots.
- `ExamParticipant`: unique exam+user result and completion state.
- `ExamInvitation`: unique exam+invitee response with invitation/response timestamps.
- `ExamAttempt`: one server-timed attempt per exam+user with stable question order and score summary.
- `ExamAnswer`: autosaved selected option for one attempt+exam question.
- `Notification`: user-owned message, type, read state, optional related entity ID.

## Cascade behavior

Most ownership/content relations use `onDelete: Cascade`. Deleting a user or subject can remove a large connected graph. Document-topic uses `SetNull`. The UI must keep destructive confirmation for these actions.

## Serializer contract

Backend serializers are the wire-format authority. They add names/counts/statistics not stored directly in individual tables. Frontend DTO parsing expects these shapes, especially:

- `subjectName`, `topicName`, and owner display fields.
- Quiz attempt/best/average/revision fields.
- Exam participant name/image/result fields.
- User statistics.
- Performance reports are derived response models rather than database entities. They combine completion-dated quiz/exam attempts, spaced-repetition rows, period comparisons, consistency, rankings, and recommendations.

Do not edit the production schema ad hoc. A database field change requires a new ordered checksum migration, FastAPI repository/service/serializer updates, corresponding Dart model/provider/UI changes, compatibility tests, a PostgreSQL backup, and a backward-compatible deployment plan.
