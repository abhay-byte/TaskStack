import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/presentation/providers/task_providers.dart';
import 'package:taskstack/features/task_stack/presentation/widgets/task_card_widget.dart';
import 'package:taskstack/features/task_stack/presentation/widgets/time_indicator_widget.dart';
import 'package:taskstack/core/constants/app_spacing.dart';

const double _kPixelsPerHour = 120.0;
const double _kMinuteHeight = _kPixelsPerHour / 60;

class TaskStackScreen extends ConsumerStatefulWidget {
  const TaskStackScreen({super.key});

  @override
  ConsumerState<TaskStackScreen> createState() => _TaskStackScreenState();
}

class _TaskStackScreenState extends ConsumerState<TaskStackScreen> {
  late final ScrollController _scrollController;
  late Timer _timer;
  final _timelineKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
    // Update time indicator every 30s
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToNow() {
    if (!_scrollController.hasClients) return;
    final now = DateTime.now();
    final offset = (now.hour * 60 + now.minute) * _kMinuteHeight -
        MediaQuery.of(context).size.height * 0.35;
    _scrollController.animateTo(
      offset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedStackDateProvider);
    final scheduled = ref.watch(scheduledTasksProvider);
    final unscheduled = ref.watch(unscheduledTasksProvider);
    final isToday = _isToday(selectedDate);
    final now = DateTime.now();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskStack'),
        actions: [
          if (!isToday)
            TextButton.icon(
              onPressed: () {
                final today = DateTime.now();
                ref.read(selectedStackDateProvider.notifier).state =
                    DateTime(today.year, today.month, today.day);
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
              },
              icon: const Icon(Icons.today_outlined, size: 18),
              label: const Text('Today'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Date navigation bar
          _DateNavBar(
            selectedDate: selectedDate,
            onPrev: () => ref.read(selectedStackDateProvider.notifier).state =
                selectedDate.subtract(const Duration(days: 1)),
            onNext: () => ref.read(selectedStackDateProvider.notifier).state =
                selectedDate.add(const Duration(days: 1)),
          ),
          Expanded(
            child: Stack(
              children: [
                // Timeline scroll view
                SingleChildScrollView(
                  controller: _scrollController,
                  child: SizedBox(
                    height: 24 * _kPixelsPerHour + 200,
                    child: Stack(
                      children: [
                        // Hour slots
                        ...List.generate(24, (h) => _HourSlotWidget(hour: h)),

                        // Task cards
                        ...scheduled.map((task) => _PositionedTaskCard(
                              task: task,
                              now: now,
                              isToday: isToday,
                            )),

                        // Unscheduled section below timeline
                        if (unscheduled.isNotEmpty)
                          Positioned(
                            top: 24 * _kPixelsPerHour + 16,
                            left: 0,
                            right: 0,
                            child: _UnscheduledSection(tasks: unscheduled),
                          ),

                        // Current time indicator (only for today)
                        if (isToday)
                          TimeIndicatorWidget(now: now),
                      ],
                    ),
                  ),
                ),

                // Empty state
                if (scheduled.isEmpty && unscheduled.isEmpty)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wb_sunny_outlined,
                            size: 64, color: colorScheme.outline),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No tasks for this day',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Tap + to add your first task',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/task/new', extra: selectedDate),
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

// ── Date Navigation Bar ───────────────────────────────────────────────────

class _DateNavBar extends StatelessWidget {
  const _DateNavBar({
    required this.selectedDate,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime selectedDate;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    final label =
        '${_weekday(selectedDate)}, ${months[selectedDate.month - 1]} ${selectedDate.day}';

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrev,
            tooltip: 'Previous day',
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
            tooltip: 'Next day',
          ),
        ],
      ),
    );
  }

  String _weekday(DateTime d) {
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return days[d.weekday - 1];
  }
}

// ── Hour Slot ─────────────────────────────────────────────────────────────

class _HourSlotWidget extends StatelessWidget {
  const _HourSlotWidget({required this.hour});
  final int hour;

  @override
  Widget build(BuildContext context) {
    final label = hour == 0
        ? '12 AM'
        : hour < 12
            ? '$hour AM'
            : hour == 12
                ? '12 PM'
                : '${hour - 12} PM';

    return Positioned(
      top: hour * _kPixelsPerHour,
      left: 0,
      right: 0,
      height: _kPixelsPerHour,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: Text(
                label,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Positioned Task Card ──────────────────────────────────────────────────

class _PositionedTaskCard extends ConsumerWidget {
  const _PositionedTaskCard({
    required this.task,
    required this.now,
    required this.isToday,
  });

  final Task task;
  final DateTime now;
  final bool isToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = task.startMinutes! * _kMinuteHeight;
    final height = ((task.durationMinutes ?? 30) * _kMinuteHeight).clamp(40.0, double.infinity);

    return Positioned(
      top: top,
      left: 64,
      right: 8,
      height: height,
      child: TaskCardWidget(
        task: task,
        isInProgress: isToday && task.isInProgress(now),
        onTap: () => context.push('/task/${task.id}'),
        onDone: () async {
          await ref.read(completeTaskUseCaseProvider).execute(task.id);
        },
        onEdit: () => context.push('/task/${task.id}/edit'),
        onDelete: () async {
          final confirm = await _confirmDelete(context);
          if (confirm) {
            await ref.read(deleteTaskUseCaseProvider).execute(task.id);
          }
        },
        onDuplicate: () async {
          await ref.read(duplicateTaskUseCaseProvider).execute(task);
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
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
}

// ── Unscheduled Section ───────────────────────────────────────────────────

class _UnscheduledSection extends StatefulWidget {
  const _UnscheduledSection({required this.tasks});
  final List<Task> tasks;

  @override
  State<_UnscheduledSection> createState() => _UnscheduledSectionState();
}

class _UnscheduledSectionState extends State<_UnscheduledSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(
            _expanded ? Icons.expand_less : Icons.expand_more,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            'Unscheduled (${widget.tasks.length})',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded)
          ...widget.tasks.map(
            (t) => ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: Text(t.title),
              onTap: () => context.push('/task/${t.id}'),
            ),
          ),
      ],
    );
  }
}
