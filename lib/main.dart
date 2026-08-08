import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'core/network/api_client.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/providers/theme_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/providers/user_session_cache.dart';
import 'shared/widgets/app_message.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final savedDarkMode = preferences.getBool(AppConstants.darkModeKey) ?? false;
  ApiClient().initialize();
  await PushNotificationService.instance.initialize();
  runApp(
    ProviderScope(
      overrides: [
        darkModeProvider.overrideWith(
          (ref) => DarkModeNotifier(savedDarkMode),
        ),
      ],
      child: const SmartStudyApp(),
    ),
  );
}

class SmartStudyApp extends ConsumerWidget {
  const SmartStudyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(darkModeProvider);
    ref.listen<AuthState>(authProvider, (previous, next) {
      final previousUserId = previous?.user?.id;
      final nextUserId = next.user?.id;
      final startedUserSession = next.isAuthenticated &&
          nextUserId != null &&
          (previous?.isAuthenticated != true || previousUserId != nextUserId);
      final endedUserSession = previous?.isAuthenticated == true &&
          (!next.isAuthenticated || nextUserId == null);

      if (startedUserSession) {
        // Login/register completes before navigation, so the destination screen
        // can only observe caches created for the newly authenticated user.
        invalidateUserSessionCache(ref);
      } else if (endedUserSession) {
        // Let the logout navigation remove authenticated screens first. This
        // avoids disposed screens recreating auto-loading providers without a
        // token while still ensuring old account data leaves memory.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          invalidateUserSessionCache(ref);
        });
      }

      if (next.sessionExpired && previous?.sessionExpired != true) {
        appRouter.go('/login');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = rootNavigatorKey.currentContext;
          if (context == null) return;
          AppMessage.error(
            context,
            'Your session is no longer valid. Please sign in again.',
          );
        });
      }
    });

    return MaterialApp.router(
      title: 'Smart Study',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
