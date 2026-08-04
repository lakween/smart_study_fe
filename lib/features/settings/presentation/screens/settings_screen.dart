import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/notification_preferences.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/app_message.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/theme_provider.dart';

final fontSizeProvider = StateProvider<double>((ref) => 14.0);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _examReminderHours = [1, 3, 6, 12, 24, 48, 72, 168];
  static const _revisionReminderDays = [0, 1, 2, 3, 7];

  NotificationPreferences _notificationPreferences =
      const NotificationPreferences();
  bool _loadingNotifications = true;
  bool _savingNotifications = false;
  String? _notificationError;
  bool _showFriendsOnlyPlaceholders = true;
  bool _savingPrivacy = false;

  @override
  void initState() {
    super.initState();
    _showFriendsOnlyPlaceholders =
        ref.read(authProvider).user?.showFriendsOnlyPlaceholders ?? true;
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    if (mounted) {
      setState(() {
        _loadingNotifications = true;
        _notificationError = null;
      });
    }
    try {
      final response = await ApiClient().dio.get(
            '/users/me/notification-preferences',
          );
      final preferences = NotificationPreferences.fromJson(
        response.data['preferences'] as Map<String, dynamic>,
      );
      if (mounted) {
        setState(() => _notificationPreferences = preferences);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _notificationError = apiErrorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _loadingNotifications = false);
    }
  }

  Future<void> _saveNotificationPreferences(
    NotificationPreferences next,
  ) async {
    if (_savingNotifications || _loadingNotifications) return;
    final previous = _notificationPreferences;
    setState(() {
      _notificationPreferences = next;
      _savingNotifications = true;
      _notificationError = null;
    });
    try {
      final response = await ApiClient().dio.patch(
            '/users/me/notification-preferences',
            data: next.toJson(),
          );
      final saved = NotificationPreferences.fromJson(
        response.data['preferences'] as Map<String, dynamic>,
      );
      if (mounted) setState(() => _notificationPreferences = saved);
    } catch (error) {
      if (mounted) {
        setState(() {
          _notificationPreferences = previous;
          _notificationError = apiErrorMessage(error);
        });
        AppMessage.error(context, apiErrorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _savingNotifications = false);
    }
  }

  String _examLeadTimeLabel(int hours) {
    if (hours < 24) return '$hours ${hours == 1 ? 'hour' : 'hours'} before';
    final days = hours ~/ 24;
    return '$days ${days == 1 ? 'day' : 'days'} before';
  }

  String _revisionLeadTimeLabel(int days) {
    if (days == 0) return 'When due';
    return '$days ${days == 1 ? 'day' : 'days'} before';
  }

  Future<void> _setLockedPlaceholders(bool value) async {
    if (_savingPrivacy) return;
    setState(() {
      _showFriendsOnlyPlaceholders = value;
      _savingPrivacy = true;
    });
    try {
      final response = await ApiClient().dio.patch(
        '/users/me',
        data: {'showFriendsOnlyPlaceholders': value},
      );
      ref.read(authProvider.notifier).setUser(
            UserModel.fromJson(response.data['user'] as Map<String, dynamic>),
          );
    } catch (error) {
      if (mounted) {
        setState(() => _showFriendsOnlyPlaceholders = !value);
        AppMessage.error(context, apiErrorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _savingPrivacy = false);
    }
  }

  Future<void> _signOut() async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign Out',
      isDestructive: true,
    );
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
                validator: Validators.password,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ApiClient().dio.post(
        '/users/me/change-password',
        data: {
          'currentPassword': currentCtrl.text,
          'newPassword': newCtrl.text,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppMessage.error(context, apiErrorMessage(e));
      }
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'New email'),
                validator: Validators.email,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final res = await ApiClient().dio.post(
        '/users/me/change-email',
        data: {
          'newEmail': emailCtrl.text.trim(),
          'password': passwordCtrl.text,
        },
      );
      ref.read(authProvider.notifier).setUser(
            UserModel.fromJson(res.data['user'] as Map<String, dynamic>),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email updated'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppMessage.error(context, apiErrorMessage(e));
      }
    }
  }

  Future<void> _deleteAccount() async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Delete Account',
      message: 'This will permanently delete your account and all data.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (ok != true || !mounted) return;
    try {
      await ApiClient().dio.delete('/users/me');
      await ref.read(authProvider.notifier).signOut();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        AppMessage.error(context, apiErrorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(darkModeProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final examReminderHours = {
      ..._examReminderHours,
      _notificationPreferences.examReminderHoursBefore,
    }.toList()
      ..sort();
    final revisionReminderDays = {
      ..._revisionReminderDays,
      _notificationPreferences.revisionReminderDaysBefore,
    }.toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionTitle('Account'),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: _changePassword,
          ),
          _SettingsTile(
            icon: Icons.email_outlined,
            title: 'Update Email',
            onTap: _updateEmail,
          ),
          _SettingsTile(
            icon: Icons.delete_outline,
            title: 'Delete Account',
            textColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: _deleteAccount,
          ),
          const Divider(),
          const _SectionTitle('Appearance'),
          SwitchListTile(
            value: isDark,
            onChanged: (v) =>
                ref.read(darkModeProvider.notifier).setDarkMode(v),
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            activeThumbColor: AppColors.primary,
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Font Size'),
            subtitle: Slider(
              value: fontSize,
              min: 12,
              max: 18,
              divisions: 3,
              label: '${fontSize.toInt()}pt',
              onChanged: (v) => ref.read(fontSizeProvider.notifier).state = v,
              activeColor: AppColors.primary,
            ),
          ),
          const Divider(),
          const _SectionTitle('Notifications'),
          if (_loadingNotifications)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
              child: LinearProgressIndicator(),
            )
          else if (_notificationError != null)
            ListTile(
              leading: const Icon(Icons.error_outline, color: AppColors.error),
              title: const Text('Could not load reminder settings'),
              subtitle: SelectableText(_notificationError!),
              trailing: TextButton(
                onPressed: _loadNotificationPreferences,
                child: const Text('Retry'),
              ),
            )
          else ...[
            SwitchListTile(
              value: _notificationPreferences.examRemindersEnabled,
              onChanged: _savingNotifications
                  ? null
                  : (value) => _saveNotificationPreferences(
                        _notificationPreferences.copyWith(
                          examRemindersEnabled: value,
                        ),
                      ),
              secondary: const Icon(Icons.assignment_outlined),
              title: const Text('Exam reminders'),
              subtitle: const Text(
                'Get one reminder before each scheduled exam.',
              ),
              activeThumbColor: AppColors.primary,
            ),
            ListTile(
              enabled: _notificationPreferences.examRemindersEnabled &&
                  !_savingNotifications,
              contentPadding: const EdgeInsets.only(
                left: 72,
                right: AppSpacing.pageGutter,
              ),
              title: const Text('Remind me'),
              trailing: DropdownButton<int>(
                value: _notificationPreferences.examReminderHoursBefore,
                underline: const SizedBox(),
                items: examReminderHours
                    .map(
                      (hours) => DropdownMenuItem(
                        value: hours,
                        child: Text(_examLeadTimeLabel(hours)),
                      ),
                    )
                    .toList(),
                onChanged: !_notificationPreferences.examRemindersEnabled ||
                        _savingNotifications
                    ? null
                    : (hours) {
                        if (hours == null) return;
                        _saveNotificationPreferences(
                          _notificationPreferences.copyWith(
                            examReminderHoursBefore: hours,
                          ),
                        );
                      },
              ),
            ),
            SwitchListTile(
              value: _notificationPreferences.revisionRemindersEnabled,
              onChanged: _savingNotifications
                  ? null
                  : (value) => _saveNotificationPreferences(
                        _notificationPreferences.copyWith(
                          revisionRemindersEnabled: value,
                        ),
                      ),
              secondary: const Icon(Icons.refresh),
              title: const Text('Revision reminders'),
              subtitle: const Text(
                'Spaced-repetition dates remain calculated by your quiz results.',
              ),
              activeThumbColor: AppColors.primary,
            ),
            ListTile(
              enabled: _notificationPreferences.revisionRemindersEnabled &&
                  !_savingNotifications,
              contentPadding: const EdgeInsets.only(
                left: 72,
                right: AppSpacing.pageGutter,
              ),
              title: const Text('Remind me'),
              trailing: DropdownButton<int>(
                value: _notificationPreferences.revisionReminderDaysBefore,
                underline: const SizedBox(),
                items: revisionReminderDays
                    .map(
                      (days) => DropdownMenuItem(
                        value: days,
                        child: Text(_revisionLeadTimeLabel(days)),
                      ),
                    )
                    .toList(),
                onChanged: !_notificationPreferences.revisionRemindersEnabled ||
                        _savingNotifications
                    ? null
                    : (days) {
                        if (days == null) return;
                        _saveNotificationPreferences(
                          _notificationPreferences.copyWith(
                            revisionReminderDaysBefore: days,
                          ),
                        );
                      },
              ),
            ),
          ],
          const Divider(),
          const _SectionTitle('Privacy'),
          SwitchListTile(
            value: _showFriendsOnlyPlaceholders,
            onChanged: _savingPrivacy ? null : _setLockedPlaceholders,
            secondary: const Icon(Icons.visibility_off_outlined),
            title: const Text('Show locked content cards'),
            subtitle: const Text(
              'Non-friends see generic placeholders for friends-only content. Private content always stays hidden.',
            ),
            activeThumbColor: AppColors.primary,
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Default Content Visibility'),
            trailing: DropdownButton<String>(
              value: 'Private',
              underline: const SizedBox(),
              items: [
                'Private',
                'Friends Only',
                'Public',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (_) {},
            ),
          ),
          const Divider(),
          const _SectionTitle('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('App Version'),
            trailing: Text(
              AppConstants.appVersion,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          _SettingsTile(
            icon: Icons.article_outlined,
            title: 'Terms of Service',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {},
          ),
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
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageGutter,
          20,
          AppSpacing.pageGutter,
          8,
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 0.5,
          ),
        ),
      );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: TextStyle(color: textColor)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: AppColors.textMuted,
        ),
        onTap: onTap,
      );
}
