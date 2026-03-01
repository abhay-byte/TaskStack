import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/presentation/providers/task_providers.dart';
import 'package:taskstack/core/constants/app_spacing.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the currently selected date's task stream to find this task
    final date = ref.watch(selectedStackDateProvider);
    final tasksAsync = ref.watch(tasksForDateProvider(date));

    return tasksAsync.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (tasks) {
        // Also search other dates if not found in selected date
        final task = tasks.where((t) => t.id == taskId).firstOrNull;

        if (task == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Task not found')),
          );
        }

        return _TaskDetailView(task: task);
      },
    );
  }
}

class _TaskDetailView extends ConsumerWidget {
  const _TaskDetailView({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    String timeLabel = 'No time set';
    if (task.startMinutes != null) {
      final h = task.startMinutes! ~/ 60;
      final m = task.startMinutes! % 60;
      final period = h < 12 ? 'AM' : 'PM';
      final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      timeLabel =
          '$displayH:${m.toString().padLeft(2, '0')} $period — ${task.durationMinutes ?? 30} min';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => context.push('/task/${task.id}/edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Header: icon + title
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    task.colorArgb != null
                        ? Color(task.colorArgb!).withAlpha(40)
                        : cs.primaryContainer,
                radius: 28,
                child: Icon(
                  Icons.task_alt,
                  color:
                      task.colorArgb != null
                          ? Color(task.colorArgb!)
                          : cs.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(task.title, style: tt.headlineSmall)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Status chip
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              Chip(
                avatar: Icon(
                  task.isDone ? Icons.check_circle : Icons.schedule,
                  size: 16,
                  color: task.isDone ? cs.primary : cs.outline,
                ),
                label: Text(task.isDone ? 'Done' : 'Pending'),
              ),
              if (task.recurrenceType != RecurrenceType.none)
                Chip(
                  avatar: const Icon(Icons.repeat, size: 16),
                  label: Text(_recurrenceLabel(task.recurrenceType)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Time
          _InfoTile(icon: Icons.access_time, label: 'Time', value: timeLabel),

          // Tags
          if (task.tags.isNotEmpty)
            _InfoTile(
              icon: Icons.label_outline,
              label: 'Tags',
              value: task.tags.map((t) => '#$t').join('  '),
            ),

          // Description
          if (task.description?.isNotEmpty == true)
            _InfoTile(
              icon: Icons.notes,
              label: 'Description',
              value: task.description!,
            ),

          // Purpose
          if (task.purpose?.isNotEmpty == true)
            _InfoTile(
              icon: Icons.lightbulb_outline,
              label: 'Purpose',
              value: task.purpose!,
            ),

          // Notification
          _InfoTile(
            icon:
                task.notificationEnabled
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
            label: 'Notification',
            value:
                task.notificationEnabled
                    ? '${task.notificationOffsetMinutes} min before'
                    : 'Off',
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Delete
              OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await _confirmDelete(context);
                  if (confirm && context.mounted) {
                    await ref.read(deleteTaskUseCaseProvider).execute(task.id);
                    if (context.mounted) context.pop();
                  }
                },
                icon: Icon(Icons.delete_outline, color: cs.error),
                label: Text('Delete', style: TextStyle(color: cs.error)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: cs.error),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child:
                    task.isDone
                        ? FilledButton.tonal(
                          onPressed: () async {
                            await ref
                                .read(completeTaskUseCaseProvider)
                                .undo(task.id);
                          },
                          child: const Text('Undo Completion'),
                        )
                        : FilledButton.icon(
                          onPressed: () async {
                            await ref
                                .read(completeTaskUseCaseProvider)
                                .execute(task.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Task marked as done! ✓'),
                                  duration: const Duration(seconds: 4),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed:
                                        () => ref
                                            .read(completeTaskUseCaseProvider)
                                            .undo(task.id),
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Mark as Done'),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Delete Task'),
                content: const Text('This task will be permanently deleted.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  String _recurrenceLabel(RecurrenceType r) => switch (r) {
    RecurrenceType.none => 'None',
    RecurrenceType.repeatToday => 'Repeat today',
    RecurrenceType.daily => 'Daily',
    RecurrenceType.weekly => 'Weekly',
    RecurrenceType.custom => 'Custom',
  };
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
