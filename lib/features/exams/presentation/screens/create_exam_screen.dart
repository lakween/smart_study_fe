import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/exam_model.dart';
import '../../../../shared/widgets/app_button.dart';
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
  String? _subjectId, _topicId;
  ExamType _type = ExamType.individual;
  int _duration = 30;
  int _questionCount = 20;
  int _passPercent = 60;
  bool _shuffleQuestions = true;
  DateTime? _startTime;
  final Set<String> _selectedFriends = {};
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Select at least one friend to invite'),
          backgroundColor: AppColors.error));
      return;
    }
    setState(() => _saving = true);
    final ok = await ref.read(examProvider.notifier).createExam(
          title: _titleCtrl.text.trim(),
          subjectId: _subjectId!,
          topicId: _topicId!,
          type: _type,
          durationMinutes: _duration,
          questionCount: _questionCount,
          passPercent: _passPercent,
          shuffleQuestions: _shuffleQuestions,
          startTime: _startTime,
          participantIds: _type == ExamType.friendExam
              ? _selectedFriends.toList()
              : const [],
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Exam created!'), backgroundColor: AppColors.success));
      context.pop();
    } else {
      final error = ref.read(examProvider).error ?? 'Could not create exam';
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error));
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
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Title is required'
                        : null),
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
                  items: subjects
                      .map((s) =>
                          DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _subjectId = v;
                      _topicId = null;
                    });
                    if (v != null) {
                      ref.read(topicProvider.notifier).loadForSubject(v);
                    }
                  },
                  validator: (v) =>
                      v == null ? 'Please select a subject' : null,
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
                  items: topics
                      .map((t) => DropdownMenuItem<String>(
                          value: t.id, child: Text(t.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _topicId = v),
                  validator: (v) => v == null ? 'Please select a topic' : null,
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
                        onTap: () => setState(() => _type = t),
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
                Text('Questions',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [10, 20, 30, 40, 50].map((count) {
                    final selected = count == _questionCount;
                    return ChoiceChip(
                      label: Text('$count'),
                      selected: selected,
                      onSelected: (_) => setState(() => _questionCount = count),
                    );
                  }).toList(),
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
                    label: 'Create & publish',
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
