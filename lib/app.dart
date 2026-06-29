import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/core/theme/app_theme.dart';
import 'package:taskstack/core/router/app_router.dart';
import 'package:taskstack/features/settings/presentation/providers/settings_provider.dart';

class TaskStackApp extends ConsumerWidget {
  const TaskStackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeMode = switch (settings.themeMode) {
      1 => ThemeMode.light,
      2 => ThemeMode.dark,
      _ => ThemeMode.system,
    };

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
