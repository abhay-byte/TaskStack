import 'package:flutter/material.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/core/constants/app_spacing.dart';
import 'package:taskstack/core/widgets/animated_graphic.dart'; // Ensure this import is present

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
        return false; // Don't actually remove from list — DB stream handles it
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
              final cardHeight =
                  constraints.hasBoundedHeight ? constraints.maxHeight : 140.0;
              final hasGraphic = task.graphicImage != null;
              final headerHeight = cardHeight < 120 ? cardHeight : 100.0;

              return Stack(
                children: [
                  // 1. Full-width Animated Graphic Header
                  if (hasGraphic)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: headerHeight,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Opacity(
                          opacity: 0.4, // Increased visibility
                          child: IgnorePointer(
                            child: AnimatedGraphic(
                              assetPath: task.graphicImage!,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 2. Gradient Overlay for readability (Bottom-to-Top)
                  if (hasGraphic)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: headerHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              (isDone
                                      ? cs.surfaceContainerLow
                                      : cs.surfaceContainerHigh)
                                  .withAlpha(200),
                              isDone
                                  ? cs.surfaceContainerLow
                                  : cs.surfaceContainerHigh,
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),

                  // 3. Content (Shifted down if graphic is present)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      hasGraphic
                          ? (cardHeight < 120
                              ? AppSpacing.sm
                              : headerHeight - 10)
                          : AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        // Status icon
                        Icon(
                          isDone
                              ? Icons.check_circle
                              : isInProgress
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color:
                              isDone
                                  ? cs.primary
                                  : isInProgress
                                  ? accent
                                  : cs.outline,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleSmall?.copyWith(
                                  decoration:
                                      isDone
                                          ? TextDecoration.lineThrough
                                          : null,
                                  color:
                                      isDone
                                          ? cs.onSurfaceVariant
                                          : cs.onSurface,
                                ),
                              ),
                              if (task.tags.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Wrap(
                                  spacing: 4,
                                  children:
                                      task.tags
                                          .take(3)
                                          .map(
                                            (tag) => Text(
                                              '#$tag',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(color: cs.primary),
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
                          Text(
                            '${task.durationMinutes}m',
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(color: cs.outline),
                          ),
                      ],
                    ),
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
}
