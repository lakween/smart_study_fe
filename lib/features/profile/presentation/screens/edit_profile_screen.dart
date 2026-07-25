import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _uniCtrl = TextEditingController();
  StudyLevel _studyLevel = StudyLevel.undergraduate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _nameCtrl.text = user.fullName;
      _bioCtrl.text = user.bio ?? '';
      _uniCtrl.text = user.university ?? '';
      _studyLevel = user.studyLevel;
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); _bioCtrl.dispose(); _uniCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await ref.read(authProvider.notifier).updateProfile(
      fullName: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
      university: _uniCtrl.text.trim().isEmpty ? null : _uniCtrl.text.trim(),
      studyLevel: _studyLevel,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!'), backgroundColor: AppColors.success));
      context.pop();
    } else {
      final error = ref.read(authProvider).error ?? 'Could not update profile';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.error));
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (picked == null) return;
    final ok = await ref.read(authProvider.notifier).uploadAvatar(picked.path);
    if (!mounted) return;
    if (!ok) {
      final error = ref.read(authProvider).error ?? 'Could not upload photo';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      AvatarWidget(name: user?.fullName ?? 'User', imageUrl: user?.profileImageUrl, radius: 44),
                      Positioned(
                        bottom: 0, right: 0,
                        child: GestureDetector(
                          onTap: _pickAvatar,
                          child: Container(
                            width: 30, height: 30,
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppTextField(label: 'Full Name *', controller: _nameCtrl, prefixIcon: Icons.person_outline, validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null),
                const SizedBox(height: 16),
                AppTextField(label: 'Bio / Description', controller: _bioCtrl, maxLines: 3, prefixIcon: Icons.edit_note),
                const SizedBox(height: 16),
                AppTextField(label: 'University / Institute', controller: _uniCtrl, prefixIcon: Icons.school_outlined),
                const SizedBox(height: 16),
                DropdownButtonFormField<StudyLevel>(
                  value: _studyLevel,
                  decoration: InputDecoration(labelText: 'Study Level', prefixIcon: const Icon(Icons.grade_outlined, size: 20, color: AppColors.textMuted), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true),
                  items: StudyLevel.values.map((l) => DropdownMenuItem(value: l, child: Text(l.label))).toList(),
                  onChanged: (v) => setState(() => _studyLevel = v ?? _studyLevel),
                ),
                const SizedBox(height: 28),
                AppButton(label: 'Save Changes', onPressed: _saving ? null : _save, isLoading: _saving),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
