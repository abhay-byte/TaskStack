import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskstack/features/auth/presentation/providers/auth_provider.dart';
import 'package:taskstack/features/auth/presentation/screens/login_screen.dart';
import 'package:taskstack/features/auth/presentation/screens/signup_screen.dart';
import 'package:taskstack/features/groups/presentation/screens/groups_list_screen.dart';
import 'package:taskstack/features/groups/presentation/screens/create_group_screen.dart';
import 'package:taskstack/features/groups/presentation/screens/group_detail_screen.dart';
import 'package:taskstack/features/groups/presentation/screens/invite_screen.dart';
import 'package:taskstack/features/groups/presentation/screens/join_group_screen.dart';
import 'package:taskstack/features/profile/presentation/screens/my_profile_screen.dart';
import 'package:taskstack/features/profile/presentation/screens/user_profile_screen.dart';
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

/// Paths that do NOT require authentication.
const _publicPaths = {'/login', '/signup', '/onboarding'};

/// Bridges Riverpod auth + settings state changes into a [ChangeNotifier]
/// so GoRouter re-evaluates its redirect whenever either provider changes.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authNotifierProvider, (_, __) => notifyListeners());
    ref.listen<AppSettings>(settingsProvider, (_, __) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _RouterRefreshNotifier(ref);

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) async {
      final path = state.uri.path;

      // ── Onboarding guard ─────────────────────────────────────────────
      final isFirst = ref.read(settingsProvider).isFirstLaunch;
      if (isFirst && path != '/onboarding') return '/onboarding';

      // ── Auth guard ───────────────────────────────────────────────────
      final authState = ref.read(authNotifierProvider);

      // Still initialising (AuthInitial) → do nothing yet
      if (authState is AuthInitial) return null;

      // Guest and Authenticated users both have access to the app shell
      final loggedIn =
          authState is AuthAuthenticated || authState is AuthGuest;
      final isPublic = _publicPaths.contains(path);

      if (!loggedIn && !isPublic) return '/login';
      if (loggedIn && isPublic) return '/';

      return null;
    },
    routes: [
      // ── Auth ───────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignupScreen(),
      ),

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
          GoRoute(path: '/social', builder: (_, __) => const GroupsListScreen()),
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

      // ── Groups ─────────────────────────────────────────────────────────
      GoRoute(
        path: '/groups/new',
        builder: (_, __) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/groups/join',
        builder: (_, __) => const JoinGroupScreen(),
      ),
      GoRoute(
        path: '/groups/:id',
        builder: (context, state) =>
            GroupDetailScreen(groupId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/groups/:id/qr',
        builder: (context, state) =>
            InviteScreen(groupId: state.pathParameters['id']!),
      ),

      // ── Profiles ───────────────────────────────────────────────────────
      GoRoute(
        path: '/profile/me',
        builder: (_, __) => const MyProfileScreen(),
      ),
      GoRoute(
        path: '/profile/:id',
        builder: (context, state) =>
            UserProfileScreen(userId: state.pathParameters['id']!),
      ),
    ],
  );

  // Wire notification deep-link
  NotificationService.onNotificationTapped = (taskId) {
    router.push('/task/$taskId');
  };

  return router;
});
