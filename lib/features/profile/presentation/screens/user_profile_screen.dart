import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/features/profile/domain/entities/user_profile.dart';
import 'package:taskstack/features/profile/presentation/providers/profile_provider.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return profileAsync.when(
      loading:
          () => Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const Center(child: CircularProgressIndicator()),
          ),
      error: (e, _) {
        final isPrivate = e.toString().contains('private');
        return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPrivate ? Icons.lock_outline : Icons.error_outline,
                  size: 64,
                  color: cs.outlineVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  isPrivate ? 'Profile is private' : 'Failed to load profile',
                  style: tt.titleMedium,
                ),
                if (isPrivate)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 32, right: 32),
                    child: Text(
                      'You need to be in the same group to view this profile.',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      data:
          (profile) => DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Profile'),
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Overview'),
                    Tab(text: 'Timeline'),
                    Tab(text: 'Stats'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  _ProfileOverviewTab(profile: profile, userId: userId),
                  _MemberTimelineTab(userId: userId),
                  _MemberStatsTab(userId: userId),
                ],
              ),
            ),
          ),
    );
  }
}

class _ProfileOverviewTab extends ConsumerWidget {
  const _ProfileOverviewTab({required this.profile, required this.userId});

  final UserProfile profile;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(memberTasksProvider(userId));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (e, _) => _ProfileOverviewContent(
            profile: profile,
            activeTask: null,
            tasksError: e.toString(),
          ),
      data: (tasks) {
        final activeTask = _activeTaskForNow(tasks);
        return _ProfileOverviewContent(
          profile: profile,
          activeTask: activeTask,
          cs: cs,
          tt: tt,
        );
      },
    );
  }
}

class _ProfileOverviewContent extends StatelessWidget {
  const _ProfileOverviewContent({
    required this.profile,
    required this.activeTask,
    this.tasksError,
    this.cs,
    this.tt,
  });

  final UserProfile profile;
  final Task? activeTask;
  final String? tasksError;
  final ColorScheme? cs;
  final TextTheme? tt;

  @override
  Widget build(BuildContext context) {
    final colors = cs ?? Theme.of(context).colorScheme;
    final text = tt ?? Theme.of(context).textTheme;
    final bio = profile.bio?.trim();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          elevation: 0,
          color: colors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: colors.primaryContainer,
                      backgroundImage:
                          profile.avatarUrl != null
                              ? NetworkImage(profile.avatarUrl!)
                              : null,
                      child:
                          profile.avatarUrl == null
                              ? Text(
                                profile.username.isNotEmpty
                                    ? profile.username[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 28,
                                  color: colors.onPrimaryContainer,
                                ),
                              )
                              : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.displayName,
                            style: text.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${profile.username}',
                            style: text.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                label: Text(
                                  profile.isPublic ? 'Public' : 'Private',
                                ),
                                avatar: Icon(
                                  profile.isPublic ? Icons.public : Icons.lock,
                                  size: 16,
                                ),
                                backgroundColor:
                                    profile.isPublic
                                        ? colors.secondaryContainer
                                        : colors.surfaceContainerHighest,
                              ),
                              Chip(
                                label: Text(
                                  'Member since ${profile.createdAt.year}',
                                ),
                                avatar: const Icon(
                                  Icons.event_outlined,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (bio != null && bio.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Bio', style: text.labelLarge),
                  const SizedBox(height: 8),
                  Text(bio, style: text.bodyLarge),
                ] else ...[
                  const SizedBox(height: 16),
                  Text(
                    'No bio yet.',
                    style: text.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (activeTask != null)
          _SectionCard(
            title: 'Working On Now',
            icon: Icons.bolt_outlined,
            child: _TaskSpotlight(task: activeTask!, accent: colors.primary),
          )
        else
          _SectionCard(
            title: 'Working On Now',
            icon: Icons.bolt_outlined,
            child: Text(
              'No active task right now.',
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        if (tasksError != null) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Timeline',
            icon: Icons.schedule,
            child: Text(
              tasksError!,
              style: text.bodyMedium?.copyWith(color: colors.error),
            ),
          ),
        ],
      ],
    );
  }
}

class _MemberTimelineTab extends ConsumerWidget {
  const _MemberTimelineTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(memberTasksProvider(userId));

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (tasks) {
        final now = DateTime.now();
        final windowStart = DateTime(
          now.year,
          now.month,
          now.day,
          now.hour,
        ).subtract(const Duration(hours: 3));
        final windowEnd = windowStart.add(const Duration(hours: 6));
        final activeTask = _activeTaskForNow(tasks);
        final windowTasks =
            tasks
                .where(
                  (task) => _taskOverlapsWindow(task, windowStart, windowEnd),
                )
                .toList();
        final unscheduled =
            tasks.where((task) {
              final isToday =
                  task.taskDate.year == now.year &&
                  task.taskDate.month == now.month &&
                  task.taskDate.day == now.day;
              return isToday && task.startMinutes == null;
            }).toList();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionCard(
              title: '6 Hour Timeline',
              icon: Icons.timeline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatHourLabel(windowStart)} to ${_formatHourLabel(windowEnd)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (activeTask != null) ...[
                    _TaskSpotlight(
                      task: activeTask,
                      accent: Theme.of(context).colorScheme.primary,
                      subtitle: 'Active now',
                    ),
                    const SizedBox(height: 16),
                  ],
                  for (var i = 0; i < 6; i++) ...[
                    _TimelineHourRow(
                      hourStart: windowStart.add(Duration(hours: i)),
                      tasks:
                          windowTasks
                              .where(
                                (task) => _taskOverlapsWindow(
                                  task,
                                  windowStart.add(Duration(hours: i)),
                                  windowStart.add(Duration(hours: i + 1)),
                                ),
                              )
                              .toList(),
                    ),
                    if (i < 5) const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            if (unscheduled.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Unscheduled Today',
                icon: Icons.event_note_outlined,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      unscheduled
                          .map(
                            (task) => Chip(
                              label: Text(task.title),
                              avatar: Icon(
                                task.isDone
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                size: 16,
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
            if (windowTasks.isEmpty && unscheduled.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  'No tasks in this 6 hour window.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MemberStatsTab extends ConsumerWidget {
  const _MemberStatsTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(memberProfileStatsProvider(userId));

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (stats) {
        final cs = Theme.of(context).colorScheme;
        final text = Theme.of(context).textTheme;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatCard(
                  label: 'Total',
                  value: '${stats.totalTasks}',
                  icon: Icons.checklist_outlined,
                  color: cs.primaryContainer,
                  onColor: cs.onPrimaryContainer,
                ),
                _StatCard(
                  label: 'Done',
                  value: '${stats.completedTasks}',
                  icon: Icons.check_circle_outline,
                  color: cs.secondaryContainer,
                  onColor: cs.onSecondaryContainer,
                ),
                _StatCard(
                  label: 'Rate',
                  value: '${(stats.completionRate * 100).round()}%',
                  icon: Icons.trending_up,
                  color: cs.tertiaryContainer,
                  onColor: cs.onTertiaryContainer,
                ),
                _StatCard(
                  label: 'Scheduled',
                  value: '${stats.scheduledTasks}',
                  icon: Icons.schedule,
                  color: cs.surfaceContainerHighest,
                  onColor: cs.onSurfaceVariant,
                ),
                _StatCard(
                  label: 'Active',
                  value: '${stats.inProgressTasks}',
                  icon: Icons.bolt_outlined,
                  color: cs.surfaceContainerHighest,
                  onColor: cs.onSurfaceVariant,
                ),
                _StatCard(
                  label: 'This Week',
                  value: '${stats.createdThisWeek}',
                  icon: Icons.event_available,
                  color: cs.surfaceContainerHighest,
                  onColor: cs.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Highlights',
              icon: Icons.insights_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HighlightRow(
                    label: 'Favorite tag',
                    value: stats.topTag == null ? 'None' : '#${stats.topTag}',
                  ),
                  const SizedBox(height: 12),
                  _HighlightRow(
                    label: 'Busiest hour',
                    value:
                        stats.mostActiveHour == null
                            ? 'None'
                            : _formatHourLabel(
                              DateTime(2026, 1, 1, stats.mostActiveHour!),
                            ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completion',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: stats.completionRate,
                      minHeight: 10,
                      backgroundColor: cs.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${(stats.completionRate * 100).toStringAsFixed(1)}% finished',
                      style: text.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: cs.primary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _TaskSpotlight extends StatelessWidget {
  const _TaskSpotlight({
    required this.task,
    required this.accent,
    this.subtitle,
  });

  final Task task;
  final Color accent;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withAlpha(18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null) ...[
            Text(
              subtitle!,
              style: text.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            task.title,
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            _taskTimeLabel(task),
            style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          if (task.purpose != null && task.purpose!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              task.purpose!,
              style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineHourRow extends StatelessWidget {
  const _TimelineHourRow({required this.hourStart, required this.tasks});

  final DateTime hourStart;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            child: Text(
              _formatHourLabel(hourStart),
              style: text.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child:
                tasks.isEmpty
                    ? Text(
                      'Open',
                      style: text.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          tasks
                              .map(
                                (task) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _TimelineTaskTile(task: task),
                                ),
                              )
                              .toList(),
                    ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTaskTile extends StatelessWidget {
  const _TimelineTaskTile({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final accent = task.colorArgb != null ? Color(task.colorArgb!) : cs.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withAlpha(16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (task.isDone)
                Chip(
                  label: const Text('Done'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: cs.secondaryContainer,
                )
              else if (task.isInProgress(DateTime.now()))
                Chip(
                  label: const Text('Now'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: cs.primaryContainer,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _taskTimeLabel(task),
            style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Card(
        elevation: 0,
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: onColor, size: 20),
              const SizedBox(height: 10),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: onColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: onColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

Task? _activeTaskForNow(List<Task> tasks) {
  final now = DateTime.now();
  for (final task in tasks) {
    if (task.taskDate.year != now.year ||
        task.taskDate.month != now.month ||
        task.taskDate.day != now.day) {
      continue;
    }
    if (task.isInProgress(now)) return task;
  }
  return null;
}

bool _taskOverlapsWindow(Task task, DateTime start, DateTime end) {
  if (task.startMinutes == null) return false;
  final taskStart = DateTime(
    task.taskDate.year,
    task.taskDate.month,
    task.taskDate.day,
    task.startMinutes! ~/ 60,
    task.startMinutes! % 60,
  );
  final taskEnd = taskStart.add(Duration(minutes: task.durationMinutes ?? 30));
  return taskStart.isBefore(end) && taskEnd.isAfter(start);
}

String _taskTimeLabel(Task task) {
  if (task.startMinutes == null) {
    return task.isDone ? 'Unscheduled task' : 'Unscheduled';
  }
  final start = _minutesToLabel(task.startMinutes!);
  final endMinutes = task.startMinutes! + (task.durationMinutes ?? 30);
  final end = _minutesToLabel(endMinutes);
  return '$start - $end';
}

String _formatHourLabel(DateTime dateTime) {
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final suffix = dateTime.hour < 12 ? 'AM' : 'PM';
  return '$hour $suffix';
}

String _minutesToLabel(int minutes) {
  final hour24 = (minutes ~/ 60) % 24;
  final minute = minutes % 60;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final suffix = hour24 < 12 ? 'AM' : 'PM';
  final minuteText = minute.toString().padLeft(2, '0');
  return '$hour12:$minuteText $suffix';
}
