import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../subjects/presentation/providers/subject_provider.dart';
import '../../../topics/presentation/providers/topic_provider.dart';
import '../providers/document_provider.dart';

class DocumentUploadScreen extends ConsumerStatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  ConsumerState<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  String? _subjectId;
  String? _topicId;
  PlatformFile? _pickedFile;
  ContentVisibility _visibility = ContentVisibility.private;
  bool _allowCopy = false;
  bool _uploading = false;
  double _uploadProgress = 0;

  @override
  void dispose() { _titleCtrl.dispose(); super.dispose(); }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null) setState(() => _pickedFile = result.files.first);
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file'), backgroundColor: AppColors.error));
      return;
    }
    setState(() { _uploading = true; _uploadProgress = 0; });
    final ok = await ref.read(documentProvider.notifier).upload(
      title: _titleCtrl.text.trim(),
      subjectId: _subjectId!,
      topicId: _topicId,
      visibility: _visibility,
      allowCopy: _allowCopy,
      filePath: _pickedFile!.path!,
      fileName: _pickedFile!.name,
      onProgress: (p) { if (mounted) setState(() => _uploadProgress = p); },
    );
    if (!mounted) return;
    setState(() => _uploading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded successfully!'), backgroundColor: AppColors.success));
      context.pop();
    } else {
      final error = ref.read(documentProvider).error ?? 'Could not upload document';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectProvider).subjects;
    final topics = _subjectId != null ? ref.watch(topicsBySubjectProvider(_subjectId!)) : <dynamic>[];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Document')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(label: 'Document Title *', controller: _titleCtrl, prefixIcon: Icons.title, validator: (v) => Validators.required(v, 'Title')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _subjectId,
                  hint: const Text('Select Subject'),
                  decoration: InputDecoration(labelText: 'Subject *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true),
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
                  hint: const Text('Select Topic (optional)'),
                  decoration: InputDecoration(labelText: 'Topic', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true),
                  items: topics.map((t) => DropdownMenuItem<String>(value: t.id, child: Text(t.name))).toList(),
                  onChanged: (v) => setState(() => _topicId = v),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: _pickedFile != null ? AppColors.primary : AppColors.divider, style: BorderStyle.solid, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                      color: _pickedFile != null ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
                    ),
                    child: _pickedFile != null
                        ? Column(
                            children: [
                              Icon(_getFileIcon(_pickedFile!.extension ?? ''), size: 40, color: AppColors.primary),
                              const SizedBox(height: 8),
                              Text(_pickedFile!.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                              Text('${(_pickedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              TextButton(onPressed: _pickFile, child: const Text('Change file')),
                            ],
                          )
                        : Column(
                            children: [
                              const Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              const Text('Tap to select file', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              const Text('PDF, JPG, PNG, JPEG • Max 10MB', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                  ),
                ),
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
                SwitchListTile(value: _allowCopy, onChanged: (v) => setState(() => _allowCopy = v), title: const Text('Allow Copy', style: TextStyle(fontWeight: FontWeight.w600)), activeColor: AppColors.primary, contentPadding: EdgeInsets.zero),
                if (_uploading) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: _uploadProgress, backgroundColor: AppColors.divider, color: AppColors.primary),
                  const SizedBox(height: 4),
                  Text('Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
                const SizedBox(height: 28),
                AppButton(label: 'Upload Document', onPressed: _uploading ? null : _upload, isLoading: _uploading, icon: Icons.cloud_upload_outlined),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png': return Icons.image_outlined;
      default: return Icons.attach_file;
    }
  }
}
