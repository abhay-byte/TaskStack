import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/core/theme/app_theme.dart';
import 'package:taskstack/core/router/app_router.dart';
import 'package:taskstack/features/settings/presentation/providers/settings_provider.dart';

class TaskStackApp extends ConsumerStatefulWidget {
  const TaskStackApp({super.key});

  @override
  ConsumerState<TaskStackApp> createState() => _TaskStackAppState();
}

class _TaskStackAppState extends ConsumerState<TaskStackApp> {
  @override
  Widget build(BuildContext context) {
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
      showPerformanceOverlay: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
