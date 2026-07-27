import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _universityCtrl = TextEditingController();
  StudyLevel _studyLevel = StudyLevel.undergraduate;

  double _passwordStrength = 0;

  void _updatePasswordStrength(String password) {
    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[!@#\$&*~]').hasMatch(password)) strength += 0.25;
    setState(() => _passwordStrength = strength);
  }

  Color get _strengthColor {
    if (_passwordStrength <= 0.25) return AppColors.error;
    if (_passwordStrength <= 0.5) return AppColors.warning;
    if (_passwordStrength <= 0.75) return AppColors.accent;
    return AppColors.success;
  }

  String get _strengthLabel {
    if (_passwordStrength <= 0.25) return 'Weak';
    if (_passwordStrength <= 0.5) return 'Fair';
    if (_passwordStrength <= 0.75) return 'Good';
    return 'Strong';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).register(
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      university: _universityCtrl.text.trim().isEmpty ? null : _universityCtrl.text.trim(),
      studyLevel: _studyLevel,
    );
    if (!mounted) return;
    final state = ref.read(authProvider);
    if (state.isAuthenticated) {
      context.go('/home/dashboard');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passwordCtrl.dispose(); _confirmPassCtrl.dispose(); _universityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                const SizedBox(height: 8),
                Text('Create Account', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('Start your learning journey today',
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                Center(
                  child: Stack(
                    children: [
                      const AvatarWidget(name: 'New User', radius: 40),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 28, height: 28,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppTextField(label: 'Full Name', controller: _nameCtrl, prefixIcon: Icons.person_outline, validator: Validators.fullName),
                const SizedBox(height: 14),
                AppTextField(label: 'Email', controller: _emailCtrl, keyboardType: TextInputType.emailAddress, prefixIcon: Icons.email_outlined, validator: Validators.email),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Password', controller: _passwordCtrl, obscureText: true, showToggle: true, prefixIcon: Icons.lock_outline,
                  onChanged: _updatePasswordStrength,
                  validator: Validators.password,
                ),
                if (_passwordStrength > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _passwordStrength,
                            backgroundColor: AppColors.divider,
                            color: _strengthColor,
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_strengthLabel, style: TextStyle(fontSize: 11, color: _strengthColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Confirm Password', controller: _confirmPassCtrl, obscureText: true, showToggle: true, prefixIcon: Icons.lock_outline,
                  validator: (v) => Validators.confirmPassword(v, _passwordCtrl.text),
                ),
                const SizedBox(height: 14),
                AppTextField(label: 'University / Institute (optional)', controller: _universityCtrl, prefixIcon: Icons.school_outlined),
                const SizedBox(height: 14),
                DropdownButtonFormField<StudyLevel>(
                  initialValue: _studyLevel,
                  decoration: InputDecoration(
                    labelText: 'Study Level',
                    prefixIcon: const Icon(Icons.grade_outlined, size: 20, color: AppColors.textMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                  ),
                  items: StudyLevel.values.map((l) => DropdownMenuItem(value: l, child: Text(l.label))).toList(),
                  onChanged: (v) => setState(() => _studyLevel = v ?? _studyLevel),
                ),
                const SizedBox(height: 28),
                AppButton(label: 'Create Account', onPressed: authState.isLoading ? null : _submit, isLoading: authState.isLoading),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Text('Sign In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
