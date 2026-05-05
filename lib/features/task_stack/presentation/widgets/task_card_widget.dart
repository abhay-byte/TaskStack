import 'package:flutter/material.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/core/constants/app_spacing.dart';
import 'package:taskstack/core/widgets/animated_graphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/features/task_stack/presentation/providers/goal_providers.dart';
import 'package:taskstack/core/extensions/int_extensions.dart';

class TaskCardWidget extends StatelessWidget {
  const TaskCardWidget({
    super.key,
    required this.task,
    required this.isInProgress,
    required this.onTap,
    required this.onDone,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
  });

  final Task task;
  final bool isInProgress;
  final VoidCallback onTap;
  final VoidCallback onDone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDone = task.isDone;

    final accent =
        task.colorArgb != null
            ? Color(task.colorArgb!)
            : isInProgress
            ? cs.primary
            : cs.secondaryContainer;

    return Dismissible(
      key: ValueKey(task.id),
      direction: isDone ? DismissDirection.none : DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        onDone();
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: cs.onPrimaryContainer),
            const SizedBox(width: AppSpacing.sm),
            Text('Done', style: TextStyle(color: cs.onPrimaryContainer)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(
            vertical: 2,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isDone ? cs.surfaceContainerLow : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDone ? cs.outlineVariant : accent,
              width: isInProgress ? 2 : 1,
            ),
            boxShadow:
                isInProgress
                    ? [
                      BoxShadow(
                        color: accent.withAlpha(60),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                    : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final hasGraphic = task.graphicImage != null;
              final contentWidget = _buildContent(
                context,
                cs,
                accent,
                isDone,
                hasGraphic,
              );

              return Stack(
                children: [
                  // 1. Full-card Animated Graphic Background
                  if (hasGraphic)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedGraphic(
                          assetPath: task.graphicImage!,
                        ),
                      ),
                    ),

                  // 2. Gradient Overlay
                  if (hasGraphic)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withAlpha(150),
                              Colors.black.withAlpha(80),
                              Colors.black.withAlpha(180),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),

                  // 3. Content — static, no scroll tracking
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: contentWidget,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy_outlined),
                  title: const Text('Duplicate'),
                  onTap: () {
                    Navigator.pop(context);
                    onDuplicate();
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Delete',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme cs,
    Color accent,
    bool isDone,
    bool hasGraphic,
  ) {
    final primaryTextColor =
        hasGraphic
            ? Colors.white
            : (isDone ? cs.onSurfaceVariant : cs.onSurface);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status icon
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(
              isDone
                  ? Icons.check_circle
                  : isInProgress
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color:
                  hasGraphic
                      ? Colors.white
                      : (isDone
                          ? cs.primary
                          : (isInProgress ? accent : cs.outline)),
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: primaryTextColor,
                  ),
                ),
                if (task.goalId != null)
                  Consumer(
                    builder: (context, ref, _) {
                      final goalsOuter = ref.watch(goalsProvider);
                      return goalsOuter.maybeWhen(
                        data: (goals) {
                          final goal =
                              goals
                                  .where((g) => g.id == task.goalId)
                                  .firstOrNull;
                          if (goal == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              'Goal: ${goal.title}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(
                                context,
                              ).textTheme.labelSmall?.copyWith(
                                color: hasGraphic ? Colors.white70 : cs.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      );
                    },
                  ),
                if (task.tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children:
                        task.tags
                            .take(3)
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      hasGraphic
                                          ? Colors.white24
                                          : cs.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelSmall?.copyWith(
                                    color:
                                        hasGraphic
                                            ? Colors.white
                                            : cs.onPrimaryContainer,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ],
            ),
          ),

          // Duration chip
          if (task.durationMinutes != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasGraphic ? Colors.black45 : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                task.durationMinutes!.toFormattedDuration(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: hasGraphic ? Colors.white : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
