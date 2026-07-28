import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/providers/theme_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final savedDarkMode = preferences.getBool(AppConstants.darkModeKey) ?? false;
  ApiClient().initialize();
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
      if (next.sessionExpired && previous?.sessionExpired != true) {
        appRouter.go('/login');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = rootNavigatorKey.currentContext;
          if (context == null) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your session is no longer valid. Please sign in again.'),
            ),
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
