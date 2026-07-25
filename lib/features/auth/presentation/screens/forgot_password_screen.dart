import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _success = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).sendPasswordReset(_emailCtrl.text.trim()); // TODO: Connect to real API endpoint
    if (mounted) setState(() => _success = true);
  }

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
              const SizedBox(height: 24),
              if (!_success) ...[
                Text('Reset Password', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  "Enter your email address and we'll send you a link to reset your password.",
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: AppTextField(
                    label: 'Email', controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: Validators.email,
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Send Reset Link',
                  onPressed: authState.isLoading ? null : _submit,
                  isLoading: authState.isLoading,
                ),
              ] else ...[
                const SizedBox(height: 60),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 96, height: 96,
                        decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.success),
                      ),
                      const SizedBox(height: 24),
                      Text('Check your email', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 12),
                      Text(
                        "We've sent a password reset link to ${_emailCtrl.text}",
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      AppButton(label: 'Back to Sign In', onPressed: () => context.pop()),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
