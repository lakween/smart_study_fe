import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_message.dart';
import '../providers/exam_provider.dart';

class IndividualExamQuestionsScreen extends ConsumerStatefulWidget {
  final String examId;
  const IndividualExamQuestionsScreen({super.key, required this.examId});

  @override
  ConsumerState<IndividualExamQuestionsScreen> createState() => _State();
}

class _State extends ConsumerState<IndividualExamQuestionsScreen> {
  List<Map<String, dynamic>> _questions = [];
  final Set<String> _selected = {};
  String? _subject, _topic, _quiz;
  bool _loading = true, _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await ref.read(examProvider.notifier).loadQuestionBank(widget.examId);
    if (!mounted) return;
    setState(() {
      _questions = rows ?? [];
      _selected
        ..clear()
        ..addAll(_questions.where((q) => q['selected'] == true).map((q) => q['id'] as String));
      _loading = false;
    });
  }

  List<String> _values(String key, [bool Function(Map<String, dynamic>)? test]) =>
      (_questions.where(test ?? (_) => true).map((q) => q[key] as String).toSet().toList()..sort());

  List<Map<String, dynamic>> get _visible => _questions.where((q) =>
      (_subject == null || q['subjectName'] == _subject) &&
      (_topic == null || q['topicName'] == _topic) &&
      (_quiz == null || q['quizTitle'] == _quiz)).toList();

  Future<void> _save({bool publish = false}) async {
    if (_selected.isEmpty) {
      AppMessage.error(context, 'Select at least one question');
      return;
    }
    setState(() => _saving = true);
    final saved = await ref.read(examProvider.notifier).saveQuestionSelection(widget.examId, _selected.toList());
    if (saved && publish) {
      final published = await ref.read(examProvider.notifier).publishCollaborativeExam(widget.examId);
      if (published && mounted) context.go('/exams/${widget.examId}');
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (!saved) AppMessage.error(context, ref.read(examProvider).error ?? 'Could not save questions');
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Scaffold(
      appBar: AppBar(title: const Text('Build your exam')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Column(children: [
        Container(
          margin: const EdgeInsets.all(AppSpacing.pageGutter),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(gradient: AppColors.premiumGradient, borderRadius: BorderRadius.circular(24)),
          child: Row(children: [const Icon(Icons.auto_awesome_rounded, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text('${_selected.length} questions selected\nFilter your quiz library or browse everything', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
          child: Row(children: [
            Expanded(child: _filter('Subject', _subject, _values('subjectName'), (v) => setState(() { _subject=v; _topic=null; _quiz=null; }))),
            const SizedBox(width: 8),
            Expanded(child: _filter('Topic', _topic, _values('topicName', (q) => _subject==null || q['subjectName']==_subject), (v) => setState(() { _topic=v; _quiz=null; }))),
            const SizedBox(width: 8),
            Expanded(child: _filter('Quiz', _quiz, _values('quizTitle', (q) => (_subject==null || q['subjectName']==_subject) && (_topic==null || q['topicName']==_topic)), (v) => setState(() => _quiz=v))),
          ]),
        ),
        const SizedBox(height: 10),
        Expanded(child: visible.isEmpty ? const Center(child: Text('No quiz questions found')) : ListView.builder(
          padding: const EdgeInsets.fromLTRB(AppSpacing.pageGutter, 0, AppSpacing.pageGutter, 110),
          itemCount: visible.length,
          itemBuilder: (_, i) { final q=visible[i]; final id=q['id'] as String; final selected=_selected.contains(id); return Card(child: CheckboxListTile(value:selected, onChanged:(v)=>setState(() => v==true ? _selected.add(id) : _selected.remove(id)), title:Text(q['text'] as String, maxLines:3, overflow:TextOverflow.ellipsis), subtitle:Text('${q['subjectName']} • ${q['topicName']} • ${q['quizTitle']}'), secondary:CircleAvatar(backgroundColor:selected?AppColors.primary:AppColors.primary.withValues(alpha:.1), child:Icon(selected?Icons.check:Icons.quiz_outlined, color:selected?Colors.white:AppColors.primary)))); },
        )),
      ]),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: OutlinedButton(onPressed:_saving?null:()=>_save(), child:const Text('Save draft'))), const SizedBox(width:10), Expanded(child:FilledButton.icon(onPressed:_saving?null:()=>_save(publish:true), icon:const Icon(Icons.rocket_launch_rounded), label:const Text('Publish')))]))),
    );
  }

  Widget _filter(String hint, String? value, List<String> values, ValueChanged<String?> changed) => DropdownButtonFormField<String>(value:value, isExpanded:true, decoration:InputDecoration(labelText:hint, contentPadding:const EdgeInsets.symmetric(horizontal:10, vertical:8)), items:[const DropdownMenuItem(value:null, child:Text('All')), ...values.map((v)=>DropdownMenuItem(value:v, child:Text(v, overflow:TextOverflow.ellipsis)))], onChanged:changed);
}
