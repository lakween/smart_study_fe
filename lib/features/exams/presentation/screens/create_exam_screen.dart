import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/exam_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_message.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../friends/presentation/providers/friend_provider.dart';
import '../../../subjects/presentation/providers/subject_provider.dart';
import '../../../topics/presentation/providers/topic_provider.dart';
import '../providers/exam_provider.dart';

class CreateExamScreen extends ConsumerStatefulWidget {
  const CreateExamScreen({super.key});

  @override
  ConsumerState<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends ConsumerState<CreateExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _questionCountCtrl = TextEditingController(text: '5');
  String? _subjectId, _topicId;
  ExamType _type = ExamType.individual;
  int _duration = 30;
  int _passPercent = 60;
  bool _shuffleQuestions = true;
  DateTime? _startTime;
  final Set<String> _selectedFriends = {};
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _instructionsCtrl.dispose();
    _questionCountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(hours: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 30)));
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
            DateTime.now().add(const Duration(hours: 1))));
    if (time == null) return;
    setState(() => _startTime =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type == ExamType.friendExam && _selectedFriends.isEmpty) {
      AppMessage.error(context, 'Select at least one friend to invite');
      return;
    }
    final questionsForEach = int.tryParse(_questionCountCtrl.text.trim());
    if (questionsForEach == null || questionsForEach < 1) {
      AppMessage.error(context, 'Enter at least one question');
      return;
    }
    setState(() => _saving = true);
    final exam = await ref.read(examProvider.notifier).createExam(
          title: _titleCtrl.text.trim(),
          subjectId: _subjectId,
          topicId: _topicId,
          type: _type,
          durationMinutes: _duration,
          questionCount: questionsForEach,
          passPercent: _passPercent,
          shuffleQuestions: _shuffleQuestions,
          startTime: _startTime,
          participantIds: _type == ExamType.friendExam
              ? _selectedFriends.toList()
              : const [],
          questionsPerParticipant:
              _type == ExamType.friendExam ? questionsForEach : null,
          contributionInstructions: _type == ExamType.friendExam
              ? _instructionsCtrl.text.trim()
              : null,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (exam != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Exam draft created!'),
          backgroundColor: AppColors.success));
      context.go(_type == ExamType.individual
          ? '/exams/${exam.id}/questions'
          : '/exams/${exam.id}');
    } else {
      final error = ref.read(examProvider).error ?? 'Could not create exam';
      AppMessage.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectProvider).subjects;
    final topics = _subjectId != null
        ? ref.watch(topicsBySubjectProvider(_subjectId!))
        : [];
    final friends = ref.watch(friendProvider).friends;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Exam')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.form,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                    label: 'Exam Title *',
                    controller: _titleCtrl,
                    prefixIcon: Icons.assignment_outlined,
                    validator: (v) {
                      final title = v?.trim() ?? '';
                      if (title.isEmpty) return 'Title is required';
                      if (title.length < 3) {
                        return 'Title must be at least 3 characters';
                      }
                      return null;
                    }),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _subjectId,
                  hint: const Text('Select Subject *'),
                  decoration: InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      filled: true),
                  items: [
                    const DropdownMenuItem(
                      value: '__none__',
                      child: Text('No subject (general exam)'),
                    ),
                    ...subjects.map((s) =>
                        DropdownMenuItem(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _subjectId = v == '__none__' ? null : v;
                      _topicId = null;
                    });
                    if (v != null && v != '__none__') {
                      ref.read(topicProvider.notifier).loadForSubject(v);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _topicId,
                  hint: const Text('Select Topic *'),
                  decoration: InputDecoration(
                      labelText: 'Topic',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      filled: true),
                  items: [
                    const DropdownMenuItem(
                      value: '__none__',
                      child: Text('No topic'),
                    ),
                    ...topics.map((t) => DropdownMenuItem<String>(
                        value: t.id, child: Text(t.name))),
                  ],
                  onChanged: _subjectId == null
                      ? null
                      : (v) =>
                          setState(() => _topicId = v == '__none__' ? null : v),
                ),
                const SizedBox(height: 20),
                Text('Exam Type',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: ExamType.values.map((t) {
                    final sel = _type == t;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          if (_type != t) {
                            _type = t;
                            _questionCountCtrl.text =
                                t == ExamType.friendExam ? '5' : '20';
                          }
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                              t == ExamType.individual
                                  ? 'Individual'
                                  : 'Friend Exam',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      sel ? Colors.white : AppColors.primary),
                              textAlign: TextAlign.center),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text('Duration',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.durationOptions.map((d) {
                    final sel = d == _duration;
                    return GestureDetector(
                      onTap: () => setState(() => _duration = d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text('${d}m',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : AppColors.primary)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text(
                    _type == ExamType.friendExam
                        ? 'Questions per participant'
                        : 'Questions',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _questionCountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Enter any positive number',
                    prefixIcon: const Icon(Icons.numbers_rounded),
                    suffixText:
                        _type == ExamType.friendExam ? 'each' : 'questions',
                  ),
                  validator: (value) {
                    final count = int.tryParse(value?.trim() ?? '');
                    return count == null || count < 1
                        ? 'Enter at least 1'
                        : null;
                  },
                ),
                const SizedBox(height: 20),
                Text('Pass mark',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Slider(
                  value: _passPercent.toDouble(),
                  min: 40,
                  max: 90,
                  divisions: 10,
                  label: '$_passPercent%',
                  onChanged: (value) =>
                      setState(() => _passPercent = value.round()),
                ),
                Row(
                  children: [
                    Text('$_passPercent%',
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                    const Spacer(),
                    Text('Required to pass',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textMuted)),
                  ],
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _shuffleQuestions,
                  onChanged: (value) =>
                      setState(() => _shuffleQuestions = value),
                  title: const Text('Shuffle question order'),
                  subtitle: const Text(
                      'Everyone receives the same questions in a stable shuffled order.'),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDateTime,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: AppColors.textMuted, size: 20),
                        const SizedBox(width: 12),
                        Text(
                            _startTime != null
                                ? '${_startTime!.day}/${_startTime!.month}/${_startTime!.year} ${_startTime!.hour}:${_startTime!.minute.toString().padLeft(2, '0')}'
                                : 'Select start time',
                            style: TextStyle(
                                color: _startTime != null
                                    ? null
                                    : AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
                if (_type == ExamType.friendExam) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppColors.primary.withValues(alpha: .13),
                        AppColors.accent.withValues(alpha: .08),
                      ]),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: .22)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.visibility_off_rounded,
                          color: AppColors.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Everyone contributes equally. Questions stay secret, even from the host, until the exam begins.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _instructionsCtrl,
                    maxLength: 500,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Question instructions',
                      hintText:
                          'Example: Divide the chapter by topic and avoid repeated definitions.',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Invite Friends',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text(
                      'Friends must accept the invitation before they can begin.',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 10),
                  if (_selectedFriends.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedFriends.map((id) {
                        final f = friends.firstWhere((fr) => fr.id == id);
                        return Chip(
                          avatar: AvatarWidget(name: f.fullName, radius: 10),
                          label: Text(f.fullName.split(' ').first),
                          onDeleted: () =>
                              setState(() => _selectedFriends.remove(id)),
                          deleteIconColor: AppColors.textMuted,
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 8),
                  ...friends.map((f) => CheckboxListTile(
                        value: _selectedFriends.contains(f.id),
                        onChanged: (v) => setState(() {
                          if (v!) {
                            _selectedFriends.add(f.id);
                          } else {
                            _selectedFriends.remove(f.id);
                          }
                        }),
                        title: Text(f.fullName),
                        subtitle:
                            f.university != null ? Text(f.university!) : null,
                        secondary: AvatarWidget(name: f.fullName, radius: 18),
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      )),
                ],
                const SizedBox(height: 28),
                AppButton(
                    label: _type == ExamType.friendExam
                        ? 'Create private lobby'
                        : 'Create & publish',
                    onPressed: _saving ? null : _create,
                    isLoading: _saving),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
