import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/notifications/push_notification_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_message.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authProvider.notifier)
        .login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    final state = ref.read(authProvider);
    if (state.isAuthenticated) {
      context.go('/home/dashboard');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PushNotificationService.instance.openPendingNotification();
      });
    } else if (state.error != null) {
      AppMessage.error(context, state.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    final dark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 330,
            decoration: const BoxDecoration(
              gradient: AppColors.premiumGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(42)),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -65,
                  top: -55,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.07),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageGutter,
                24,
                AppSpacing.pageGutter,
                32,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.school_rounded,
                              color: Colors.white, size: 25),
                        ),
                        const SizedBox(width: 12),
                        const Text('Smart Study',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 19)),
                      ],
                    ),
                    const SizedBox(height: 38),
                    const Text('Learn with\nclarity.',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            height: 1.08,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1)),
                    const SizedBox(height: 10),
                    Text('Your focused space for smarter progress.',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 14)),
                    const SizedBox(height: 34),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      decoration: BoxDecoration(
                        color: dark ? AppColors.darkCardBg : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                            color: dark ? AppColors.darkDivider : Colors.white),
                        boxShadow: AppColors.floatingShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back',
                              style: theme.textTheme.headlineMedium),
                          const SizedBox(height: 5),
                          Text('Sign in and continue where you stopped.',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 24),
                          AppTextField(
                            label: 'Email address',
                            hint: 'you@example.com',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.alternate_email_rounded,
                            validator: Validators.email,
                          ),
                          const SizedBox(height: 15),
                          AppTextField(
                            label: 'Password',
                            controller: _passwordCtrl,
                            obscureText: true,
                            showToggle: true,
                            prefixIcon: Icons.lock_outline_rounded,
                            textInputAction: TextInputAction.done,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Password is required'
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          const SizedBox(height: 4),
                          AppButton(
                            label: 'Continue',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: authState.isLoading ? null : _submit,
                            isLoading: authState.isLoading,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('New to Smart Study? ',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary)),
                              GestureDetector(
                                onTap: () => context.push('/register'),
                                child: const Text('Create account',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 15, color: AppColors.textMuted),
                          SizedBox(width: 6),
                          Text('Secure, private learning workspace',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
