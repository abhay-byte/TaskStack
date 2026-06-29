import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskstack/features/profile/presentation/screens/my_profile_screen.dart';
import 'package:taskstack/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:taskstack/features/task_stack/presentation/screens/task_stack_screen.dart';
import 'package:taskstack/features/task_stack/presentation/screens/task_detail_screen.dart';
import 'package:taskstack/features/task_stack/presentation/screens/task_form_screen.dart';
import 'package:taskstack/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:taskstack/features/settings/presentation/screens/settings_screen.dart';
import 'package:taskstack/core/widgets/app_shell.dart';
import 'package:taskstack/features/settings/presentation/providers/settings_provider.dart';
import 'package:taskstack/features/notifications/notification_service.dart';
import 'package:taskstack/features/task_stack/presentation/screens/goal_form_screen.dart';
import 'package:taskstack/features/task_stack/presentation/screens/goals_list_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Bridges Riverpod settings state changes into a [ChangeNotifier]
/// so GoRouter re-evaluates its redirect whenever the provider changes.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AppSettings>(settingsProvider, (_, __) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _RouterRefreshNotifier(ref);

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final path = state.uri.path;

      // ── Onboarding guard ─────────────────────────────────────────────
      final isFirst = ref.read(settingsProvider).isFirstLaunch;
      if (isFirst && path != '/onboarding') return '/onboarding';

      return null;
    },
    routes: [
      // ── Onboarding ─────────────────────────────────────────────────────
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),

      // ── Main Shell (bottom nav) ─────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const TaskStackScreen()),
          GoRoute(path: '/goals', builder: (_, __) => const GoalsListScreen()),
          GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),

      // ── Tasks ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/task/new',
        builder: (context, state) =>
            TaskFormScreen(prefilledDate: state.extra as DateTime?),
      ),
      GoRoute(
        path: '/task/:id',
        builder: (context, state) =>
            TaskDetailScreen(taskId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/task/:id/edit',
        builder: (context, state) =>
            TaskFormScreen(taskId: state.pathParameters['id']),
      ),

      // ── Goals ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/goal/new',
        builder: (_, __) => const GoalFormScreen(),
      ),
      GoRoute(
        path: '/goal/:id/edit',
        builder: (context, state) =>
            GoalFormScreen(goalId: state.pathParameters['id']),
      ),

      // ── Profile ───────────────────────────────────────────────────────
      GoRoute(
        path: '/profile/me',
        builder: (_, __) => const MyProfileScreen(),
      ),
    ],
  );

  // Wire notification deep-link
  NotificationService.onNotificationTapped = (taskId) {
    router.push('/task/$taskId');
  };

  return router;
});
