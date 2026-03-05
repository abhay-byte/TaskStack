import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/core/theme/app_theme.dart';
import 'package:taskstack/core/router/app_router.dart';
import 'package:taskstack/features/auth/presentation/providers/auth_provider.dart';
import 'package:taskstack/features/settings/presentation/providers/settings_provider.dart';

class TaskStackApp extends ConsumerWidget {
  const TaskStackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final settings = ref.watch(settingsProvider);
    final themeMode = switch (settings.themeMode) {
      1 => ThemeMode.light,
      2 => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    // ── Splash: block router until session restore completes ──────────────
    // AuthInitial means _restore() is still running (reading secure storage).
    // Showing the router now would let redirect return null and briefly
    // display the app shell before redirecting to /login.
    if (authState is AuthInitial) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'TaskStack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
