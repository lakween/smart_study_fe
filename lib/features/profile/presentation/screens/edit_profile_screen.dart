import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../../shared/widgets/profile_cover.dart';
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
  bool _uploadingMedia = false;

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
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _uniCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await ref.read(authProvider.notifier).updateProfile(
          fullName: _nameCtrl.text.trim(),
          bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
          university:
              _uniCtrl.text.trim().isEmpty ? null : _uniCtrl.text.trim(),
          studyLevel: _studyLevel,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated!'),
          backgroundColor: AppColors.success));
      context.pop();
    } else {
      final error = ref.read(authProvider).error ?? 'Could not update profile';
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error));
    }
  }

  Future<ImageSource?> _chooseImageSource(String title) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListTile(
                leading: const CircleAvatar(
                    child: Icon(Icons.photo_library_outlined)),
                title: const Text('Choose from gallery'),
                subtitle: const Text('Pick a photo already on your device'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const CircleAvatar(
                    child: Icon(Icons.photo_camera_outlined)),
                title: const Text('Take a new photo'),
                subtitle: const Text('Open your camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickMedia({required bool cover}) async {
    final source = await _chooseImageSource(
        cover ? 'Update cover photo' : 'Update profile picture');
    if (source == null || !mounted) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: cover ? 1800 : 900,
      imageQuality: 88,
    );
    if (picked == null) return;
    setState(() => _uploadingMedia = true);
    final notifier = ref.read(authProvider.notifier);
    final ok = cover
        ? await notifier.uploadCover(picked.path)
        : await notifier.uploadAvatar(picked.path);
    if (!mounted) return;
    setState(() => _uploadingMedia = false);
    if (!ok) {
      final error = ref.read(authProvider).error ?? 'Could not upload photo';
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(cover ? 'Cover photo updated' : 'Profile picture updated'),
            backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.form,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ProfileCover(
                        imageUrl: user?.coverImageUrl,
                        height: 170,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: FilledButton.tonalIcon(
                          onPressed: _uploadingMedia
                              ? null
                              : () => _pickMedia(cover: true),
                          icon: const Icon(Icons.wallpaper_outlined, size: 18),
                          label: Text(user?.coverImageUrl == null
                              ? 'Add cover'
                              : 'Change cover'),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        bottom: 0,
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                shape: BoxShape.circle,
                              ),
                              child: AvatarWidget(
                                  name: user?.fullName ?? 'User',
                                  imageUrl: user?.profileImageUrl,
                                  radius: 48),
                            ),
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: IconButton.filled(
                                tooltip: 'Change profile picture',
                                onPressed: _uploadingMedia
                                    ? null
                                    : () => _pickMedia(cover: false),
                                icon: const Icon(Icons.camera_alt_outlined,
                                    size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_uploadingMedia)
                        const Positioned.fill(
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                    label: 'Full Name *',
                    controller: _nameCtrl,
                    prefixIcon: Icons.person_outline,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Name is required'
                        : null),
                const SizedBox(height: 16),
                AppTextField(
                    label: 'Bio / Description',
                    controller: _bioCtrl,
                    maxLines: 3,
                    prefixIcon: Icons.edit_note),
                const SizedBox(height: 16),
                AppTextField(
                    label: 'University / Institute',
                    controller: _uniCtrl,
                    prefixIcon: Icons.school_outlined),
                const SizedBox(height: 16),
                DropdownButtonFormField<StudyLevel>(
                  initialValue: _studyLevel,
                  decoration: InputDecoration(
                      labelText: 'Study Level',
                      prefixIcon: const Icon(Icons.grade_outlined,
                          size: 20, color: AppColors.textMuted),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      filled: true),
                  items: StudyLevel.values
                      .map((l) =>
                          DropdownMenuItem(value: l, child: Text(l.label)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _studyLevel = v ?? _studyLevel),
                ),
                const SizedBox(height: 28),
                AppButton(
                    label: 'Save Changes',
                    onPressed: _saving ? null : _save,
                    isLoading: _saving),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
