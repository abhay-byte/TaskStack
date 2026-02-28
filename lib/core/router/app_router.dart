import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskstack/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:taskstack/features/task_stack/presentation/screens/task_stack_screen.dart';
import 'package:taskstack/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:taskstack/features/settings/presentation/screens/settings_screen.dart';
import 'package:taskstack/core/widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const TaskStackScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
