import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskstack/features/task_stack/domain/entities/goal.dart';
import 'package:taskstack/features/task_stack/domain/repositories/goal_repository.dart';
import 'package:taskstack/features/task_stack/domain/usecases/delete_goal_usecase.dart';
import 'package:taskstack/features/task_stack/presentation/providers/goal_providers.dart';
import 'package:taskstack/core/constants/app_spacing.dart';

class GoalsListScreen extends ConsumerWidget {
  const GoalsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        centerTitle: true,
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading goals: $err')),
        data: (goals) {
          if (goals.isEmpty) {
            return _EmptyState(cs: cs);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.md,
            ),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              return _GoalCard(goal: goal);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/goal/new'),
        tooltip: 'New Goal',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 64,
            color: cs.onSurfaceVariant.withAlpha(100),
            semanticLabel: 'No goals icon',
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No goals yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Create a goal to link your tasks together.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final committedAsync = ref.watch(committedMinutesProvider(goal.id));

    IconData typeIcon;
    String typeLabel;

    switch (goal.type) {
      case GoalType.project:
        typeIcon = Icons.account_tree_outlined;
        typeLabel = goal.isGoal ? 'Project Goal' : 'Project';
        break;
      case GoalType.habit:
        typeIcon = Icons.repeat;
        typeLabel = goal.isGoal ? 'Habit Goal' : 'Habit';
        break;
      case GoalType.noTime:
        typeIcon = Icons.all_inclusive;
        typeLabel = goal.isGoal ? 'Ongoing Goal' : 'Ongoing';
        break;
    }

    final goalIcon = goal.iconId != null
        ? _parseMaterialIcon(goal.iconId!)
        : typeIcon;

    final goalColor = goal.colorArgb != null
        ? Color(goal.colorArgb!)
        : cs.primary;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: cs.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.push('/goal/${goal.id}/edit'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: goalColor.withAlpha(30),
                    child: Icon(goalIcon, color: goalColor),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              typeLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                            ),
                            if (goal.durationHours != null) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '\u2022',
                                style:
                                    TextStyle(color: cs.onSurfaceVariant),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${goal.durationHours} hrs',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                              ),
                            ]
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: cs.error),
                    tooltip: 'Delete Goal',
                    onPressed: () => _confirmDelete(context, ref, goal),
                  ),
                ],
              ),
              if (goal.durationHours != null) ...[
                const SizedBox(height: AppSpacing.md),
                committedAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (committedMinutes) {
                    final committedHours = (committedMinutes ?? 0) / 60.0;
                    final totalHours = goal.durationHours!.toDouble();
                    final progress =
                        (committedHours / totalHours).clamp(0.0, 1.0);
                    final remainingHours =
                        (totalHours - committedHours).clamp(0.0, totalHours);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${committedHours.toStringAsFixed(1)} / ${totalHours.toStringAsFixed(0)} hrs',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: goalColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: cs.surfaceContainerHighest,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(goalColor),
                          ),
                        ),
                        if (remainingHours > 0) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${remainingHours.toStringAsFixed(1)} hrs remaining',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _ThirtyDayTimeline(goalId: goal.id),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Goal goal,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text(
          'Are you sure you want to delete "${goal.title}"? \n\nTasks associated with this goal will remain, but the link will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor:
                  Theme.of(context).colorScheme.onErrorContainer,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final deleteUseCase = ref.read(deleteGoalUseCaseProvider);
      await deleteUseCase.execute(goal.id);
    }
  }
}

class _ThirtyDayTimeline extends ConsumerWidget {
  const _ThirtyDayTimeline({required this.goalId});
  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tasksAsync = ref.watch(goalTasksProvider(goalId));

    return tasksAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (tasks) {
        if (tasks.isEmpty) return const SizedBox.shrink();

        final now = DateTime.now();
        final days = List.generate(30, (i) {
          final d = now.subtract(Duration(days: 29 - i));
          return d.toIso8601String().substring(0, 10);
        });

        final dayMap = <String, List<GoalTaskInfo>>{};
        for (final t in tasks) {
          dayMap.putIfAbsent(t.taskDate, () => []).add(t);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 30 days',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 32,
              child: Row(
                children: days.map((day) {
                  final dayTasks = dayMap[day] ?? [];
                  final completedCount = dayTasks
                      .where((t) => t.status == 'completed')
                      .length;
                  final totalCount = dayTasks.length;

                  Color dotColor;
                  if (completedCount > 0 && totalCount > 0) {
                    dotColor = cs.primary;
                  } else if (totalCount > 0) {
                    dotColor = cs.outlineVariant;
                  } else {
                    dotColor = cs.surfaceContainerHighest;
                  }

                  return Expanded(
                    child: Tooltip(
                      message:
                          '$day: $completedCount/$totalCount completed',
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: dotColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

IconData _parseMaterialIcon(String iconId) {
  const map = <String, IconData>{
    'flag': Icons.flag_outlined,
    'fitness_center': Icons.fitness_center_outlined,
    'school': Icons.school_outlined,
    'work': Icons.work_outline,
    'code': Icons.code_outlined,
    'palette': Icons.palette_outlined,
    'music_note': Icons.music_note_outlined,
    'menu_book': Icons.menu_book_outlined,
    'savings': Icons.savings_outlined,
    'flight': Icons.flight_outlined,
    'home': Icons.home_outlined,
    'family_restroom': Icons.family_restroom_outlined,
    'self_improvement': Icons.self_improvement_outlined,
    'language': Icons.language_outlined,
    'eco': Icons.eco_outlined,
    'pets': Icons.pets_outlined,
    'restaurant': Icons.restaurant_outlined,
    'directions_run': Icons.directions_run_outlined,
    'construction': Icons.construction_outlined,
    'business': Icons.business_outlined,
  };
  return map[iconId] ?? Icons.flag_outlined;
}
