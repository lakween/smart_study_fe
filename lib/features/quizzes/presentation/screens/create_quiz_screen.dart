import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/question_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../subjects/presentation/providers/subject_provider.dart';
import '../../../topics/presentation/providers/topic_provider.dart';
import '../providers/quiz_provider.dart';

class _QuestionForm {
  final String id;
  TextEditingController text = TextEditingController();
  TextEditingController optA = TextEditingController();
  TextEditingController optB = TextEditingController();
  TextEditingController optC = TextEditingController();
  TextEditingController optD = TextEditingController();
  TextEditingController explanation = TextEditingController();
  AnswerOption correct = AnswerOption.a;

  _QuestionForm({required this.id});

  void dispose() { text.dispose(); optA.dispose(); optB.dispose(); optC.dispose(); optD.dispose(); explanation.dispose(); }
}

class CreateQuizScreen extends ConsumerStatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  ConsumerState<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends ConsumerState<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _timeLimitCtrl = TextEditingController();
  String? _subjectId, _topicId;
  ContentVisibility _visibility = ContentVisibility.private;
  bool _allowCopy = false;
  bool _saving = false;
  final List<_QuestionForm> _questions = [];

  @override
  void dispose() {
    _titleCtrl.dispose(); _timeLimitCtrl.dispose();
    for (final q in _questions) q.dispose();
    super.dispose();
  }

  void _addQuestion() => setState(() => _questions.add(_QuestionForm(id: const Uuid().v4())));
  void _removeQuestion(int i) { _questions[i].dispose(); setState(() => _questions.removeAt(i)); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one question'), backgroundColor: AppColors.error));
      return;
    }
    if (_topicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a topic'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _saving = true);
    final ok = await ref.read(quizProvider.notifier).createQuiz(
      title: _titleCtrl.text.trim(),
      subjectId: _subjectId!,
      topicId: _topicId!,
      visibility: _visibility,
      allowCopy: _allowCopy,
      isAiGenerated: false,
      timeLimitMinutes: _timeLimitCtrl.text.trim().isEmpty ? null : int.tryParse(_timeLimitCtrl.text.trim()),
      questions: _questions.map((q) => QuestionModel(
            id: q.id,
            text: q.text.text.trim(),
            optionA: q.optA.text.trim(),
            optionB: q.optB.text.trim(),
            optionC: q.optC.text.trim(),
            optionD: q.optD.text.trim(),
            correctAnswer: q.correct,
            explanation: q.explanation.text.trim().isEmpty ? null : q.explanation.text.trim(),
          )).toList(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz created!'), backgroundColor: AppColors.success));
      context.pop();
    } else {
      final error = ref.read(quizProvider).error ?? 'Could not create quiz';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectProvider).subjects;
    final topics = _subjectId != null ? ref.watch(topicsBySubjectProvider(_subjectId!)) : [];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Quiz')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(label: 'Quiz Title *', controller: _titleCtrl, prefixIcon: Icons.quiz_outlined, validator: Validators.quizTitle),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _subjectId,
                  hint: const Text('Select Subject *'),
                  decoration: InputDecoration(labelText: 'Subject', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true),
                  items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (v) {
                    setState(() { _subjectId = v; _topicId = null; });
                    if (v != null) ref.read(topicProvider.notifier).loadForSubject(v);
                  },
                  validator: (v) => v == null ? 'Please select a subject' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _topicId,
                  hint: const Text('Select Topic'),
                  decoration: InputDecoration(labelText: 'Topic', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true),
                  items: topics.map((t) => DropdownMenuItem<String>(value: t.id, child: Text(t.name))).toList(),
                  onChanged: (v) => setState(() => _topicId = v),
                ),
                const SizedBox(height: 16),
                AppTextField(label: 'Time Limit (minutes, optional)', controller: _timeLimitCtrl, keyboardType: TextInputType.number, prefixIcon: Icons.timer_outlined),
                const SizedBox(height: 20),
                Text('Visibility', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: ContentVisibility.values.map((v) {
                    final selected = _visibility == v;
                    Color c;
                    switch(v) {
                      case ContentVisibility.private: c = AppColors.privateColor;
                      case ContentVisibility.friendsOnly: c = AppColors.friendsColor;
                      case ContentVisibility.public: c = AppColors.publicColor;
                    }
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _visibility = v),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(color: selected ? c : c.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withOpacity(selected ? 1 : 0.3))),
                          child: Text(v.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : c), textAlign: TextAlign.center),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SwitchListTile(value: _allowCopy, onChanged: (v) => setState(() => _allowCopy = v), title: const Text('Allow Copy'), activeColor: AppColors.primary, contentPadding: EdgeInsets.zero),
                const Divider(height: 32),
                Row(
                  children: [
                    Text('Questions (${_questions.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton.icon(icon: const Icon(Icons.add, size: 18), label: const Text('Add'), onPressed: _addQuestion),
                  ],
                ),
                const SizedBox(height: 8),
                ..._questions.asMap().entries.map((e) {
                  final i = e.key; final q = e.value;
                  return _QuestionCard(
                    index: i, form: q,
                    onDelete: () => _removeQuestion(i),
                    onCorrectChanged: (ans) => setState(() => q.correct = ans),
                  );
                }),
                if (_questions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(12), color: AppColors.primary.withOpacity(0.02)),
                    child: Center(child: Column(children: [
                      const Icon(Icons.help_outline, size: 40, color: AppColors.textMuted),
                      const SizedBox(height: 8),
                      const Text('No questions yet', style: TextStyle(color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      TextButton.icon(icon: const Icon(Icons.add), label: const Text('Add First Question'), onPressed: _addQuestion),
                    ])),
                  ),
                const SizedBox(height: 24),
                AppButton(label: 'Save Quiz', onPressed: _saving ? null : _save, isLoading: _saving),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final _QuestionForm form;
  final VoidCallback onDelete;
  final ValueChanged<AnswerOption> onCorrectChanged;

  const _QuestionCard({required this.index, required this.form, required this.onDelete, required this.onCorrectChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primary.withOpacity(0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Question ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20), onPressed: onDelete, padding: EdgeInsets.zero),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(controller: form.text, maxLines: 2, decoration: InputDecoration(labelText: 'Question text *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), filled: true), validator: Validators.questionText),
          const SizedBox(height: 10),
          ...AnswerOption.values.map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Radio<AnswerOption>(value: opt, groupValue: form.correct, onChanged: (v) => onCorrectChanged(v!), activeColor: AppColors.primary),
                Expanded(
                  child: TextFormField(
                    controller: switch(opt) { AnswerOption.a => form.optA, AnswerOption.b => form.optB, AnswerOption.c => form.optC, AnswerOption.d => form.optD },
                    decoration: InputDecoration(labelText: 'Option ${opt.label} *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), filled: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    validator: Validators.option,
                  ),
                ),
              ],
            ),
          )),
          TextFormField(controller: form.explanation, decoration: InputDecoration(labelText: 'Explanation (optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), filled: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
        ],
      ),
    );
  }
}
