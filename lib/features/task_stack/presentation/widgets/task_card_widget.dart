import 'package:flutter/material.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/core/constants/app_spacing.dart';
import 'package:taskstack/core/widgets/animated_graphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/features/task_stack/presentation/providers/goal_providers.dart';
import 'package:taskstack/core/extensions/int_extensions.dart';

class TaskCardWidget extends StatefulWidget {
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
  State<TaskCardWidget> createState() => _TaskCardWidgetState();
}

class _TaskCardWidgetState extends State<TaskCardWidget> {
  /// Key on the Stack so we can measure the card's initial global position.
  final _cardKey = GlobalKey();

  /// Card's global top-Y the moment [_baseScrollOffset] was recorded.
  double _baseCardTop = 0.0;

  /// Scroll offset at the moment the baseline was last recorded.
  double _baseScrollOffset = 0.0;

  /// Whether the baseline has been measured at least once.
  bool _hasMeasured = false;

  ScrollPosition? _scrollPos;

  /// Approximate height of the content row (icon + title + duration chip).
  static const double _kContentH = 52.0;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pos = Scrollable.maybeOf(context)?.position;
    if (pos != _scrollPos) {
      _scrollPos = pos;
    }
    // Measure after first layout.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureBaseline());
  }

  @override
  void didUpdateWidget(covariant TaskCardWidget old) {
    super.didUpdateWidget(old);
    // Re-measure if the task (and thus potentially card size) changed.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureBaseline());
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ── Measurement ──────────────────────────────────────────────────────────

  /// Records the card's current global Y and the scroll offset at this moment.
  /// Called once post-frame; subsequent position updates are computed via math.
  void _measureBaseline() {
    if (!mounted) return;
    final box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final newCardTop = box.localToGlobal(Offset.zero).dy;
    final newScrollOffset = _scrollPos?.pixels ?? 0.0;

    // Only trigger a setState if the values actually changed to avoid extra rebuilds.
    if (!_hasMeasured ||
        (newCardTop - newScrollOffset) != (_baseCardTop - _baseScrollOffset)) {
      if (mounted) {
        setState(() {
          _baseCardTop = newCardTop;
          _baseScrollOffset = newScrollOffset;
          _hasMeasured = true;
        });
      }
    }
  }

  // ── Offset computation (called inside AnimatedBuilder, no layout calls) ──

  /// Computes how far from the top of the card the content row should sit
  /// so it always tries to be vertically centered on the screen,
  /// clamped to [0 .. cardHeight - contentHeight].
  ///
  /// All values are derived mathematically — no [findRenderObject] here.
  double _computeContentOffset(double cardHeight, double screenHeight) {
    if (!_hasMeasured || _scrollPos == null) return 0.0;

    // Where the card's top edge is right now in global coordinates.
    final scrollDelta = _scrollPos!.pixels - _baseScrollOffset;
    final cardTopNow = _baseCardTop - scrollDelta;

    // Ideal top of the content so its midpoint sits at screen center.
    final screenCenterY = screenHeight / 2.0;
    final idealTop = screenCenterY - (_kContentH / 2.0) - cardTopNow;

    // Clamp: can't go above card top (0) or push content below card bottom.
    return idealTop.clamp(
      0.0,
      (cardHeight - _kContentH).clamp(0.0, cardHeight),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDone = widget.task.isDone;

    final accent =
        widget.task.colorArgb != null
            ? Color(widget.task.colorArgb!)
            : widget.isInProgress
            ? cs.primary
            : cs.secondaryContainer;

    return Dismissible(
      key: ValueKey(widget.task.id),
      direction: isDone ? DismissDirection.none : DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        widget.onDone();
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
        onTap: widget.onTap,
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
              width: widget.isInProgress ? 2 : 1,
            ),
            boxShadow:
                widget.isInProgress
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
              final hasGraphic = widget.task.graphicImage != null;
              // Use LayoutBuilder's height for math — no extra RenderBox reads.
              final cardHeight =
                  constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : 200.0;

              final contentWidget = _buildContent(
                context,
                cs,
                accent,
                isDone,
                hasGraphic,
              );

              return Stack(
                key: _cardKey,
                children: [
                  // 1. Full-card Animated Graphic Background
                  if (hasGraphic)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedGraphic(
                          assetPath: widget.task.graphicImage!,
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

                  // 3. Content — tracks scroll synchronously via math.
                  //    AnimatedBuilder fires on every scroll frame; offset
                  //    is computed from the cached baseline + scroll delta,
                  //    so there are zero findRenderObject() calls here.
                  if (_hasMeasured && _scrollPos != null)
                    AnimatedBuilder(
                      animation: _scrollPos!,
                      builder: (ctx, child) {
                        final screenH = MediaQuery.of(ctx).size.height;
                        final offset = _computeContentOffset(
                          cardHeight,
                          screenH,
                        );
                        return Positioned(
                          top: offset,
                          left: 0,
                          right: 0,
                          child: child!,
                        );
                      },
                      child: contentWidget,
                    )
                  else
                    // Before first measurement: render at the top normally.
                    Positioned(top: 0, left: 0, right: 0, child: contentWidget),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

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
                    widget.onEdit();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy_outlined),
                  title: const Text('Duplicate'),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onDuplicate();
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
                    widget.onDelete();
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
                  : widget.isInProgress
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color:
                  hasGraphic
                      ? Colors.white
                      : (isDone
                          ? cs.primary
                          : (widget.isInProgress ? accent : cs.outline)),
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
                  widget.task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: primaryTextColor,
                  ),
                ),
                if (widget.task.goalId != null)
                  Consumer(
                    builder: (context, ref, _) {
                      final goalsOuter = ref.watch(goalsProvider);
                      return goalsOuter.maybeWhen(
                        data: (goals) {
                          final goal =
                              goals
                                  .where((g) => g.id == widget.task.goalId)
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
                if (widget.task.tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children:
                        widget.task.tags
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
          if (widget.task.durationMinutes != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasGraphic ? Colors.black45 : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.task.durationMinutes!.toFormattedDuration(),
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
