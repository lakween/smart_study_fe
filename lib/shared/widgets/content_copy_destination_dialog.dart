import 'package:flutter/material.dart';

import '../models/subject_model.dart';
import '../models/topic_model.dart';

class QuizCopyDestination {
  final String subjectId;
  final String? topicId;
  final bool createTopic;

  const QuizCopyDestination._({
    required this.subjectId,
    this.topicId,
    this.createTopic = false,
  });

  const QuizCopyDestination.copy({
    required String subjectId,
    required String topicId,
  }) : this._(subjectId: subjectId, topicId: topicId);

  const QuizCopyDestination.createTopic(String subjectId)
      : this._(subjectId: subjectId, createTopic: true);
}

Future<String?> showTopicCopyDestinationDialog({
  required BuildContext context,
  required String topicName,
  required List<SubjectModel> subjects,
}) {
  var selectedSubjectId = subjects.first.id;
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        icon: const Icon(Icons.content_copy_outlined),
        title: const Text('Copy topic'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '“$topicName” will be added as a private, editable topic.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: selectedSubjectId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'My subject',
                prefixIcon: Icon(Icons.book_outlined),
              ),
              items: subjects
                  .map((subject) => DropdownMenuItem(
                        value: subject.id,
                        child: Text(
                          subject.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (value) => setDialogState(
                () => selectedSubjectId = value ?? selectedSubjectId,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, selectedSubjectId),
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text('Copy topic'),
          ),
        ],
      ),
    ),
  );
}

Future<QuizCopyDestination?> showQuizCopyDestinationDialog({
  required BuildContext context,
  required String quizTitle,
  required List<SubjectModel> subjects,
  required List<TopicModel> topics,
  String? initialSubjectId,
}) {
  var selectedSubjectId = initialSubjectId != null &&
          subjects.any((subject) => subject.id == initialSubjectId)
      ? initialSubjectId
      : subjects.first.id;
  var availableTopics = topics
      .where(
          (topic) => topic.subjectId == selectedSubjectId && !topic.isArchived)
      .toList();
  String? selectedTopicId =
      availableTopics.isEmpty ? null : availableTopics.first.id;

  return showDialog<QuizCopyDestination>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        icon: const Icon(Icons.account_tree_outlined),
        title: const Text('Choose destination'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '“$quizTitle” will be copied privately and remain fully editable.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: selectedSubjectId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: '1. My subject',
                  prefixIcon: Icon(Icons.book_outlined),
                ),
                items: subjects
                    .map((subject) => DropdownMenuItem(
                          value: subject.id,
                          child: Text(
                            subject.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() {
                    selectedSubjectId = value;
                    availableTopics = topics
                        .where((topic) =>
                            topic.subjectId == value && !topic.isArchived)
                        .toList();
                    selectedTopicId = availableTopics.isEmpty
                        ? null
                        : availableTopics.first.id;
                  });
                },
              ),
              const SizedBox(height: 14),
              if (availableTopics.isNotEmpty)
                DropdownButtonFormField<String>(
                  key: ValueKey(selectedSubjectId),
                  initialValue: selectedTopicId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: '2. Topic',
                    prefixIcon: Icon(Icons.topic_outlined),
                  ),
                  items: availableTopics
                      .map((topic) => DropdownMenuItem(
                            value: topic.id,
                            child: Text(
                              topic.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedTopicId = value),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No active topics in this subject',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 4),
                      Text(
                          'Create a topic, then the quiz can be copied into it.'),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          if (availableTopics.isEmpty)
            FilledButton.icon(
              onPressed: () => Navigator.pop(
                dialogContext,
                QuizCopyDestination.createTopic(selectedSubjectId),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Create topic'),
            )
          else
            FilledButton.icon(
              onPressed: selectedTopicId == null
                  ? null
                  : () => Navigator.pop(
                        dialogContext,
                        QuizCopyDestination.copy(
                          subjectId: selectedSubjectId,
                          topicId: selectedTopicId!,
                        ),
                      ),
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('Copy quiz'),
            ),
        ],
      ),
    ),
  );
}
