import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskstack/features/auth/presentation/providers/auth_provider.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/domain/usecases/task_usecases.dart';
import 'package:taskstack/features/task_stack/presentation/providers/task_providers.dart';
import 'package:taskstack/features/task_stack/presentation/widgets/task_card_widget.dart';
import 'package:taskstack/features/task_stack/presentation/widgets/time_indicator_widget.dart';
import 'package:taskstack/core/constants/app_spacing.dart';
import 'package:taskstack/features/sync/presentation/sync_status_indicator.dart';
import 'package:taskstack/features/sync/domain/repositories/sync_repository.dart';
import 'package:taskstack/features/sync/data/repositories/sync_repository_impl.dart';

const double _kPixelsPerHour = 120.0;
const double _kMinuteHeight = _kPixelsPerHour / 60;
const double _kDayBlockHeight = 24 * _kPixelsPerHour;

class TaskStackScreen extends ConsumerStatefulWidget {
  const TaskStackScreen({super.key});

  @override
  ConsumerState<TaskStackScreen> createState() => _TaskStackScreenState();
}

class _TaskStackScreenState extends ConsumerState<TaskStackScreen> {
  late final ScrollController _scrollController;
  late Timer _timer;

  // Base date around which the infinite list revolves (Index 10000 = this date)
  DateTime? _initialDate;

  // Track the currently visible day index so we don't spam state updates
  int _currentVisibleIndex = 10000;

  @override
  void initState() {
    super.initState();

    // Start at a large index so we can scroll up and down infinitely
    const initialScrollOffset = 10000 * _kDayBlockHeight;
    _scrollController = ScrollController(
      initialScrollOffset: initialScrollOffset,
    );

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
    // Update time indicator every 30s
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _initialDate == null) return;

    // Determine which day index is most visible (centered on the screen)
    final scrollOffset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;
    final visibleIndex =
        ((scrollOffset + viewportHeight / 2) / _kDayBlockHeight).floor();

    if (visibleIndex != _currentVisibleIndex) {
      _currentVisibleIndex = visibleIndex;
      final daysOffset = visibleIndex - 10000;
      final newDate = DateTime(
        _initialDate!.year,
        _initialDate!.month,
        _initialDate!.day + daysOffset,
      );

      // Update the date provider without rebuilding the whole list immediately
      Future.microtask(() {
        if (mounted) {
          ref.read(selectedStackDateProvider.notifier).state = newDate;
        }
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToNow() {
    if (!_scrollController.hasClients || _initialDate == null) return;
    final now = DateTime.now();

    // Calculate the dynamic scroll target relative to the locked _initialDate
    final todayMidnight = DateTime.utc(now.year, now.month, now.day);
    final initialMidnight = DateTime.utc(
      _initialDate!.year,
      _initialDate!.month,
      _initialDate!.day,
    );
    final daysOffset = todayMidnight.difference(initialMidnight).inDays;

    final dayBaseOffset = (10000 + daysOffset) * _kDayBlockHeight;
    final timeOffset =
        (now.hour * 60 + now.minute) * _kMinuteHeight -
        MediaQuery.of(context).size.height * 0.35;

    _scrollController.animateTo(
      dayBaseOffset + timeOffset.clamp(0.0, _kDayBlockHeight),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedStackDateProvider);
    final isToday = _isToday(selectedDate);
    final now = DateTime.now();
    final isGuest = ref.watch(isGuestProvider);

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/app_icon_foreground.png',
          width: 48,
          height: 48,
        ),
        actions: [
          const SyncStatusIndicator(),
          if (!isToday)
            TextButton.icon(
              onPressed: () {
                final today = DateTime.now();
                ref.read(selectedStackDateProvider.notifier).state = DateTime(
                  today.year,
                  today.month,
                  today.day,
                );
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToNow(),
                );
              },
              icon: const Icon(Icons.today_outlined, size: 18),
              label: const Text('Today'),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Guest offline banner ──────────────────────────────────────
          if (isGuest)
            MaterialBanner(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              content: const Text("You're using TaskStack offline"),
              leading: const Icon(Icons.cloud_off_rounded),
              actions: [
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Sign In'),
                ),
              ],
            ),
          // ── Sync error banner ──────────────────────────────────────────
          if (!isGuest)
            Consumer(
              builder: (context, ref, _) {
                final errorMsg = ref.watch(syncErrorMessageProvider);
                if (errorMsg == null) return const SizedBox.shrink();
                return MaterialBanner(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  content: Text(
                    errorMsg,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  leading: Icon(
                    Icons.cloud_off_rounded,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        ref.read(syncRepositoryProvider).pushLocalToCloud();
                      },
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(syncErrorMessageProvider.notifier).state = null;
                      },
                      child: Text(
                        'Dismiss',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          // Date navigation bar
          _DateNavBar(
            selectedDate: selectedDate,
            onPrev: () {
              final previousOffset =
                  _scrollController.offset - _kDayBlockHeight;
              _scrollController.animateTo(
                previousOffset,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            onNext: () {
              final nextOffset = _scrollController.offset + _kDayBlockHeight;
              _scrollController.animateTo(
                nextOffset,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemExtent: _kDayBlockHeight,
              itemBuilder: (context, index) {
                // Initialize _initialDate on first build if needed
                _initialDate ??= ref.read(selectedStackDateProvider);

                final daysOffset = index - 10000;
                final pageDate = DateTime(
                  _initialDate!.year,
                  _initialDate!.month,
                  _initialDate!.day + daysOffset,
                );
                final isPageToday = _isToday(pageDate);

                return _DayViewBlock(
                  pageDate: pageDate,
                  now: now,
                  isPageToday: isPageToday,
                );
              },
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

class _DayViewBlock extends ConsumerWidget {
  const _DayViewBlock({
    required this.pageDate,
    required this.now,
    required this.isPageToday,
  });

  final DateTime pageDate;
  final DateTime now;
  final bool isPageToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTasks = ref.watch(tasksForDateProvider(pageDate));
    final tasks = asyncTasks.valueOrNull ?? [];

    // Process tasks locally to sort and split
    final sortedTasks = [...tasks]..sort((a, b) {
      if (a.startMinutes == null && b.startMinutes == null) return 0;
      if (a.startMinutes == null) return 1;
      if (b.startMinutes == null) return -1;
      return a.startMinutes!.compareTo(b.startMinutes!);
    });

    final scheduled = sortedTasks.where((t) => t.startMinutes != null).toList();
    final unscheduled =
        sortedTasks.where((t) => t.startMinutes == null).toList();

    return SizedBox(
      height: _kDayBlockHeight,
      child: Stack(
        children: [
          // Hour slots
          ...List.generate(24, (h) => _HourSlotWidget(hour: h)),

          // Task cards
          ...scheduled.map(
            (task) => _PositionedTaskCard(
              task: task,
              now: now,
              isToday: isPageToday,
              pageDate: pageDate,
            ),
          ),

          // Unscheduled section below timeline
          // Only show unscheduled if they exist for this specific day
          if (unscheduled.isNotEmpty)
            Positioned(
              top: 24 * _kPixelsPerHour + 16,
              left: 0,
              right: 0,
              child: _UnscheduledSection(tasks: unscheduled),
            ),

          // Current time indicator (only for today)
          if (isPageToday) TimeIndicatorWidget(now: now),

          // Date Divider (floats exactly centered in the 50px space before 12 AM)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                (() {
                  final nextDate = pageDate.add(const Duration(days: 1));
                  const days = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ];
                  const months = [
                    'Jan',
                    'Feb',
                    'Mar',
                    'Apr',
                    'May',
                    'Jun',
                    'Jul',
                    'Aug',
                    'Sep',
                    'Oct',
                    'Nov',
                    'Dec',
                  ];
                  return '${days[nextDate.weekday - 1]}, ${months[nextDate.month - 1]} ${nextDate.day}';
                })(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final daysDiff = current.difference(today).inDays;

    late String label;
    if (daysDiff == 0) {
      label = 'Today';
    } else if (daysDiff == 1) {
      label = 'Tomorrow';
    } else if (daysDiff == -1) {
      label = 'Yesterday';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      label =
          '${_weekday(selectedDate)}, ${months[selectedDate.month - 1]} ${selectedDate.day}';
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
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
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }
}

// ── Hour Slot ─────────────────────────────────────────────────────────────

class _HourSlotWidget extends StatelessWidget {
  const _HourSlotWidget({required this.hour});
  final int hour;

  @override
  Widget build(BuildContext context) {
    final label =
        hour == 0
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
    required this.pageDate,
  });

  final Task task;
  final DateTime now;
  final bool isToday;
  final DateTime pageDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tzPageDate = DateTime(pageDate.year, pageDate.month, pageDate.day);
    final tzTaskDate = DateTime(
      task.taskDate.year,
      task.taskDate.month,
      task.taskDate.day,
    );
    final isYesterdayTask = tzPageDate.difference(tzTaskDate).inDays == 1;

    double top;
    double height;

    if (isYesterdayTask) {
      top = 0;
      final overflowMins =
          task.startMinutes! + (task.durationMinutes ?? 30) - 1440;
      height = (overflowMins * _kMinuteHeight).clamp(40.0, double.infinity);
    } else {
      top = task.startMinutes! * _kMinuteHeight;
      final endMins = task.startMinutes! + (task.durationMinutes ?? 30);
      double rawHeightMins = (task.durationMinutes ?? 30).toDouble();
      if (endMins > 1440) {
        rawHeightMins = (1440 - task.startMinutes!).toDouble();
      }
      height = (rawHeightMins * _kMinuteHeight).clamp(40.0, double.infinity);
    }

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
          try {
            await ref.read(completeTaskUseCaseProvider).execute(task);
          } on StateError catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
        onEdit: () => context.push('/task/${task.id}/edit'),
        onDelete: () async {
          final isRecurring =
              task.recurrenceType != RecurrenceType.none ||
              task.parentTaskId != null;
          if (isRecurring) {
            final scope = await _confirmRecurringDelete(context);
            if (scope != null) {
              await ref
                  .read(deleteTaskUseCaseProvider)
                  .execute(task, scope: scope);
            }
          } else {
            final confirm = await _confirmDelete(context);
            if (confirm) {
              await ref.read(deleteTaskUseCaseProvider).execute(task);
            }
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

  Future<RecurringScope?> _confirmRecurringDelete(BuildContext context) async {
    return await showDialog<RecurringScope>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Recurring Task'),
            content: const Text(
              'Do you want to delete this instance only, or all upcoming instances as well?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.pop(ctx, RecurringScope.thisInstance),
                child: const Text('This instance only'),
              ),
              FilledButton(
                onPressed:
                    () => Navigator.pop(ctx, RecurringScope.futureInstances),
                child: const Text('All upcoming'),
              ),
            ],
          ),
    );
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
