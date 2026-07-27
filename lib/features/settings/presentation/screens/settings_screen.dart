import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final darkModeProvider = StateProvider<bool>((ref) => false);
final fontSizeProvider = StateProvider<double>((ref) => 14.0);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _quizReminders = true;
  bool _examReminders = true;
  bool _friendRequests = true;
  bool _spacedRepetition = true;

  Future<void> _signOut() async {
    final ok = await ConfirmDialog.show(context, title: 'Sign Out', message: 'Are you sure you want to sign out?', confirmLabel: 'Sign Out', isDestructive: true);
    if (ok == true && mounted) {
      await ref.read(authProvider.notifier).signOut();
      if (mounted) context.go('/login');
    }
  }

  Future<void> _changePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: currentCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current password'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            TextFormField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New password'), validator: Validators.password),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.of(dialogContext).pop(true); }, child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ApiClient().dio.post('/users/me/change-password', data: {'currentPassword': currentCtrl.text, 'newPassword': newCtrl.text});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e)), backgroundColor: AppColors.error));
    }
  }

  Future<void> _updateEmail() async {
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update Email'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'New email'), validator: Validators.email),
            const SizedBox(height: 12),
            TextFormField(controller: passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current password'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.of(dialogContext).pop(true); }, child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final res = await ApiClient().dio.post('/users/me/change-email', data: {'newEmail': emailCtrl.text.trim(), 'password': passwordCtrl.text});
      ref.read(authProvider.notifier).setUser(UserModel.fromJson(res.data['user'] as Map<String, dynamic>));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email updated'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e)), backgroundColor: AppColors.error));
    }
  }

  Future<void> _deleteAccount() async {
    final ok = await ConfirmDialog.show(context, title: 'Delete Account', message: 'This will permanently delete your account and all data.', confirmLabel: 'Delete', isDestructive: true);
    if (ok != true || !mounted) return;
    try {
      await ApiClient().dio.delete('/users/me');
      await ref.read(authProvider.notifier).signOut();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e)), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(darkModeProvider);
    final fontSize = ref.watch(fontSizeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionTitle('Account'),
          _SettingsTile(icon: Icons.lock_outline, title: 'Change Password', onTap: _changePassword),
          _SettingsTile(icon: Icons.email_outlined, title: 'Update Email', onTap: _updateEmail),
          _SettingsTile(icon: Icons.delete_outline, title: 'Delete Account', textColor: AppColors.error, iconColor: AppColors.error, onTap: _deleteAccount),
          const Divider(),
          const _SectionTitle('Appearance'),
          SwitchListTile(
            value: isDark,
            onChanged: (v) => ref.read(darkModeProvider.notifier).state = v,
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            activeThumbColor: AppColors.primary,
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Font Size'),
            subtitle: Slider(
              value: fontSize,
              min: 12, max: 18, divisions: 3,
              label: '${fontSize.toInt()}pt',
              onChanged: (v) => ref.read(fontSizeProvider.notifier).state = v,
              activeColor: AppColors.primary,
            ),
          ),
          const Divider(),
          const _SectionTitle('Notifications'),
          SwitchListTile(value: _quizReminders, onChanged: (v) => setState(() => _quizReminders = v), secondary: const Icon(Icons.quiz_outlined), title: const Text('Quiz Reminders'), activeThumbColor: AppColors.primary),
          SwitchListTile(value: _examReminders, onChanged: (v) => setState(() => _examReminders = v), secondary: const Icon(Icons.assignment_outlined), title: const Text('Exam Reminders'), activeThumbColor: AppColors.primary),
          SwitchListTile(value: _friendRequests, onChanged: (v) => setState(() => _friendRequests = v), secondary: const Icon(Icons.person_add_outlined), title: const Text('Friend Requests'), activeThumbColor: AppColors.primary),
          SwitchListTile(value: _spacedRepetition, onChanged: (v) => setState(() => _spacedRepetition = v), secondary: const Icon(Icons.refresh), title: const Text('Spaced Repetition'), activeThumbColor: AppColors.primary),
          const Divider(),
          const _SectionTitle('Privacy'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Default Content Visibility'),
            trailing: DropdownButton<String>(
              value: 'Private', underline: const SizedBox(),
              items: ['Private', 'Friends Only', 'Public'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (_) {},
            ),
          ),
          const Divider(),
          const _SectionTitle('About'),
          const ListTile(leading: Icon(Icons.info_outline), title: Text('App Version'), trailing: Text(AppConstants.appVersion, style: TextStyle(color: AppColors.textMuted))),
          _SettingsTile(icon: Icons.article_outlined, title: 'Terms of Service', onTap: () {}),
          _SettingsTile(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: () {}),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.5)),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon; final String title; final VoidCallback onTap;
  final Color? textColor; final Color? iconColor;
  const _SettingsTile({required this.icon, required this.title, required this.onTap, this.textColor, this.iconColor});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: iconColor),
    title: Text(title, style: TextStyle(color: textColor)),
    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
    onTap: onTap,
  );
}
