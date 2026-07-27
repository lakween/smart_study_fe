import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/topic_provider.dart';
import '../../../subjects/presentation/providers/subject_provider.dart';

class CreateEditTopicScreen extends ConsumerStatefulWidget {
  final String? topicId;
  const CreateEditTopicScreen({super.key, this.topicId});

  @override
  ConsumerState<CreateEditTopicScreen> createState() => _CreateEditTopicScreenState();
}

class _CreateEditTopicScreenState extends ConsumerState<CreateEditTopicScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  ContentVisibility _visibility = ContentVisibility.private;
  bool _allowCopy = false;
  bool _saving = false;
  String? _selectedSubjectId;

  bool get isEditing => widget.topicId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(topicProvider.notifier).loadOne(widget.topicId!);
        if (!mounted) return;
        final topic = ref.read(topicByIdProvider(widget.topicId!));
        if (topic != null) {
          _nameCtrl.text = topic.name;
          _descCtrl.text = topic.description ?? '';
          setState(() { _visibility = topic.visibility; _allowCopy = topic.allowCopy; _selectedSubjectId = topic.subjectId; });
        }
      });
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    if (isEditing) {
      final topic = ref.read(topicByIdProvider(widget.topicId!))!;
      await ref.read(topicProvider.notifier).updateTopic(topic.copyWith(name: _nameCtrl.text.trim(), description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(), visibility: _visibility, allowCopy: _allowCopy));
    } else {
      await ref.read(topicProvider.notifier).createTopic(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        subjectId: _selectedSubjectId!,
        visibility: _visibility, allowCopy: _allowCopy,
      );
    }
    setState(() => _saving = false);
    if (mounted) { context.pop(); }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectProvider).subjects;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Topic' : 'Create Topic')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isEditing)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSubjectId,
                    hint: const Text('Select Subject'),
                    decoration: InputDecoration(labelText: 'Subject', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true),
                    items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: (v) => setState(() => _selectedSubjectId = v),
                    validator: (v) => v == null ? 'Please select a subject' : null,
                  ),
                if (!isEditing) const SizedBox(height: 16),
                AppTextField(label: 'Topic Name *', controller: _nameCtrl, prefixIcon: Icons.topic_outlined, validator: Validators.fullName),
                const SizedBox(height: 16),
                AppTextField(label: 'Description (optional)', controller: _descCtrl, maxLines: 3),
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
                          decoration: BoxDecoration(
                            color: selected ? c : c.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: c.withValues(alpha: selected ? 1 : 0.3)),
                          ),
                          child: Text(v.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : c), textAlign: TextAlign.center),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SwitchListTile(value: _allowCopy, onChanged: (v) => setState(() => _allowCopy = v), title: const Text('Allow Copy', style: TextStyle(fontWeight: FontWeight.w600)), activeThumbColor: AppColors.primary, contentPadding: EdgeInsets.zero),
                const SizedBox(height: 28),
                AppButton(label: isEditing ? 'Save Changes' : 'Create Topic', onPressed: _saving ? null : _save, isLoading: _saving),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
