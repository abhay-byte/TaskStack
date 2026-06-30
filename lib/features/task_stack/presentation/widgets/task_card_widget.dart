import 'package:flutter/material.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/core/constants/app_spacing.dart';
import 'package:taskstack/core/widgets/animated_graphic.dart';
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
    this.goalTitle,
  });

  final Task task;
  final bool isInProgress;
  final String? goalTitle;
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
    final hasGraphic = task.graphicImage != null;
    final primaryTextColor =
        hasGraphic
            ? Colors.white
            : (isDone ? cs.onSurfaceVariant : cs.onSurface);

    return Dismissible(
      key: ValueKey(task.id),
      direction: isDone ? DismissDirection.none : DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        onDone();
        return false;
      },
      background: _SwipeBackground(cs: cs),
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
          child: Stack(
            children: [
              if (hasGraphic)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: RepaintBoundary(
                      child: AnimatedGraphic(
                        assetPath: task.graphicImage!,
                      ),
                    ),
                  ),
                ),
              if (hasGraphic)
                const Positioned.fill(child: _GraphicOverlay()),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _CardContent(
                  task: task,
                  isInProgress: isInProgress,
                  isDone: isDone,
                  hasGraphic: hasGraphic,
                  primaryTextColor: primaryTextColor,
                  cs: cs,
                  accent: accent,
                  goalTitle: goalTitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _ContextMenu(
        onEdit: () {
          Navigator.pop(context);
          onEdit();
        },
        onDuplicate: () {
          Navigator.pop(context);
          onDuplicate();
        },
        onDelete: () {
          Navigator.pop(context);
          onDelete();
        },
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _GraphicOverlay extends StatelessWidget {
  const _GraphicOverlay();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(150, 0, 0, 0),
            Color.fromARGB(80, 0, 0, 0),
            Color.fromARGB(180, 0, 0, 0),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.task,
    required this.isInProgress,
    required this.isDone,
    required this.hasGraphic,
    required this.primaryTextColor,
    required this.cs,
    required this.accent,
    required this.goalTitle,
  });

  final Task task;
  final bool isInProgress;
  final bool isDone;
  final bool hasGraphic;
  final Color primaryTextColor;
  final ColorScheme cs;
  final Color accent;
  final String? goalTitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: primaryTextColor,
                  ),
                ),
                if (goalTitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      'Goal: $goalTitle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: hasGraphic ? Colors.white70 : cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (task.tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final tag in task.tags.take(3))
                        _TagChip(label: tag, hasGraphic: hasGraphic, cs: cs),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (task.durationMinutes != null)
            _DurationChip(
              minutes: task.durationMinutes!,
              hasGraphic: hasGraphic,
              cs: cs,
            ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.hasGraphic,
    required this.cs,
  });

  final String label;
  final bool hasGraphic;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: hasGraphic ? Colors.white24 : cs.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '#$label',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: hasGraphic ? Colors.white : cs.onPrimaryContainer,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.minutes,
    required this.hasGraphic,
    required this.cs,
  });

  final int minutes;
  final bool hasGraphic;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasGraphic ? Colors.black45 : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        minutes.toFormattedDuration(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: hasGraphic ? Colors.white : cs.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ContextMenu extends StatelessWidget {
  const _ContextMenu({
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit'),
            onTap: onEdit,
          ),
          ListTile(
            leading: const Icon(Icons.copy_outlined),
            title: const Text('Duplicate'),
            onTap: onDuplicate,
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: cs.error),
            title: Text('Delete', style: TextStyle(color: cs.error)),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}
