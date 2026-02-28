import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:taskstack/features/settings/presentation/providers/settings_provider.dart';
import 'package:taskstack/features/notifications/notification_service.dart';
import 'package:taskstack/core/constants/app_spacing.dart';

const _pages = [
  _OnboardPage(
    icon: Icons.view_agenda_outlined,
    title: 'The 24-Hour Stack',
    body:
        'Visualise your entire day as a living timeline. Every task has its place, from midnight to midnight.',
  ),
  _OnboardPage(
    icon: Icons.add_task_outlined,
    title: 'Create Rich Tasks',
    body:
        'Add title, description, purpose, tags, time, colour, and icon. Every task tells a story.',
  ),
  _OnboardPage(
    icon: Icons.check_circle_outline,
    title: 'Intentional Completion',
    body:
        'Tasks are never auto-marked done. You decide when you\'re truly finished — swipe or tap to complete.',
  ),
  _OnboardPage(
    icon: Icons.bar_chart_outlined,
    title: 'Life Analytics',
    body:
        'Daily, weekly, monthly, and yearly insights. Understand how you spend your time and grow.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _ctrl;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLast = _current == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextButton(
                  onPressed: _complete,
                  child: const Text('Skip'),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _current = i),
                children: _pages
                    .map(
                      (p) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg * 1.5,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(p.icon,
                                size: 96, color: cs.primary),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              p.title,
                              style: Theme.of(context).textTheme.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              p.body,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            // Page indicator
            SmoothPageIndicator(
              controller: _ctrl,
              count: _pages.length,
              effect: WormEffect(
                activeDotColor: cs.primary,
                dotColor: cs.surfaceContainerHigh,
                dotHeight: 8,
                dotWidth: 8,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // CTA button
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLast
                      ? _complete
                      : () {
                          _ctrl.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                  child: Text(isLast ? 'Get Started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _complete() async {
    await NotificationService.requestPermissions();
    await ref.read(settingsProvider.notifier).completeOnboarding();
    if (mounted) context.go('/');
  }
}

class _OnboardPage {
  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
