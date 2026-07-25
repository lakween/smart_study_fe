import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../providers/subject_provider.dart';

class CreateEditSubjectScreen extends ConsumerStatefulWidget {
  final String? subjectId;
  const CreateEditSubjectScreen({super.key, this.subjectId});

  @override
  ConsumerState<CreateEditSubjectScreen> createState() => _CreateEditSubjectScreenState();
}

class _CreateEditSubjectScreenState extends ConsumerState<CreateEditSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  ContentVisibility _visibility = ContentVisibility.private;
  bool _allowCopy = false;
  bool _saving = false;

  bool get isEditing => widget.subjectId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final subject = ref.read(subjectByIdProvider(widget.subjectId!));
        if (subject != null) {
          _nameCtrl.text = subject.name;
          _descCtrl.text = subject.description ?? '';
          setState(() { _visibility = subject.visibility; _allowCopy = subject.allowCopy; });
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
      final subject = ref.read(subjectByIdProvider(widget.subjectId!))!;
      await ref.read(subjectProvider.notifier).updateSubject(
        subject.copyWith(name: _nameCtrl.text.trim(), description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(), visibility: _visibility, allowCopy: _allowCopy),
      );
    } else {
      await ref.read(subjectProvider.notifier).createSubject(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        visibility: _visibility, allowCopy: _allowCopy,
      );
    }
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Subject updated!' : 'Subject created!'), backgroundColor: AppColors.success));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Subject' : 'Create Subject')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(label: 'Subject Name *', controller: _nameCtrl, prefixIcon: Icons.book_outlined, validator: Validators.subjectName),
                const SizedBox(height: 16),
                AppTextField(label: 'Description (optional)', controller: _descCtrl, maxLines: 3, prefixIcon: Icons.description_outlined),
                const SizedBox(height: 20),
                Text('Visibility', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: ContentVisibility.values.map((v) {
                    final selected = _visibility == v;
                    Color c;
                    IconData ic;
                    switch(v) {
                      case ContentVisibility.private: c = AppColors.privateColor; ic = Icons.lock_outline;
                      case ContentVisibility.friendsOnly: c = AppColors.friendsColor; ic = Icons.people_outline;
                      case ContentVisibility.public: c = AppColors.publicColor; ic = Icons.public;
                    }
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _visibility = v),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? c : c.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: c.withOpacity(selected ? 1 : 0.3)),
                          ),
                          child: Column(
                            children: [
                              Icon(ic, size: 18, color: selected ? Colors.white : c),
                              const SizedBox(height: 4),
                              Text(v.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : c), textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  value: _allowCopy,
                  onChanged: (v) => setState(() => _allowCopy = v),
                  title: const Text('Allow Copy', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Allow other users to copy this content to their account'),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 28),
                AppButton(label: isEditing ? 'Save Changes' : 'Create Subject', onPressed: _saving ? null : _save, isLoading: _saving),
                if (isEditing) ...[
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Delete Subject',
                    variant: AppButtonVariant.outlined,
                    onPressed: () async {
                      final ok = await ConfirmDialog.show(context, title: 'Delete Subject', message: 'This will permanently delete the subject and all its content.', confirmLabel: 'Delete', isDestructive: true);
                      if (ok == true && mounted) {
                        ref.read(subjectProvider.notifier).deleteSubject(widget.subjectId!);
                        context.pop();
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
