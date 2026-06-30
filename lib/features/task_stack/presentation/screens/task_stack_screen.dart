import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/domain/usecases/task_usecases.dart';
import 'package:taskstack/features/task_stack/presentation/providers/goal_providers.dart';
import 'package:taskstack/features/task_stack/presentation/providers/task_providers.dart';
import 'package:taskstack/features/task_stack/presentation/screens/day_todo_sheet.dart';
import 'package:taskstack/features/task_stack/presentation/widgets/task_card_widget.dart';
import 'package:taskstack/features/task_stack/presentation/widgets/time_indicator_widget.dart';
import 'package:taskstack/core/constants/app_spacing.dart';

const double _kPixelsPerHour = 120.0;
const double _kMinuteHeight = _kPixelsPerHour / 60;
const double _kDayBlockHeight = 24 * _kPixelsPerHour;
const double _kDayFocusAnchor = 0.35;
const int _kCenterIndex = 10000;
const double _kHourLabelWidth = 60;

class TaskStackScreen extends ConsumerStatefulWidget {
  const TaskStackScreen({super.key});

  @override
  ConsumerState<TaskStackScreen> createState() => _TaskStackScreenState();
}

class _TaskStackScreenState extends ConsumerState<TaskStackScreen> {
  late final ScrollController _scrollController;
  Timer? _recurringTimer;

  // Base date around which the infinite list revolves.
  DateTime? _initialDate;
  int _currentVisibleIndex = _kCenterIndex;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: _kCenterIndex * _kDayBlockHeight,
    );
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToNow();
      ref.read(maintainRecurringWindowUseCaseProvider).execute();
    });

    // Recurring-window maintenance only — does NOT call setState.
    _recurringTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      final now = DateTime.now();
      if (now.minute == 0) {
        ref.read(maintainRecurringWindowUseCaseProvider).execute();
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _initialDate == null) return;
    final scrollOffset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;
    final visibleIndex =
        ((scrollOffset + viewportHeight * _kDayFocusAnchor) / _kDayBlockHeight)
            .floor();

    if (visibleIndex != _currentVisibleIndex) {
      _currentVisibleIndex = visibleIndex;
      final daysOffset = visibleIndex - _kCenterIndex;
      final newDate = DateTime(
        _initialDate!.year,
        _initialDate!.month,
        _initialDate!.day + daysOffset,
      );
      Future.microtask(() {
        if (mounted) {
          ref.read(selectedStackDateProvider.notifier).state = newDate;
        }
      });
    }
  }

  @override
  void dispose() {
    _recurringTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToNow() {
    if (!_scrollController.hasClients || _initialDate == null) return;
    final now = DateTime.now();
    final todayMidnight = DateTime.utc(now.year, now.month, now.day);
    final initialMidnight = DateTime.utc(
      _initialDate!.year,
      _initialDate!.month,
      _initialDate!.day,
    );
    final daysOffset = todayMidnight.difference(initialMidnight).inDays;
    final dayBaseOffset = (_kCenterIndex + daysOffset) * _kDayBlockHeight;
    final timeOffset =
        (now.hour * 60 + now.minute) * _kMinuteHeight -
        MediaQuery.of(context).size.height * _kDayFocusAnchor;
    _scrollController.animateTo(
      (dayBaseOffset + timeOffset).clamp(0.0, double.infinity),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedStackDateProvider);
    final isToday = _isToday(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/app_icon_foreground.png',
          width: 48,
          height: 48,
        ),
        actions: [
          TextButton.icon(
            onPressed: () => DayTodoSheet.open(context, date: _composeDate()),
            icon: const Icon(Icons.checklist_rounded, size: 18),
            label: const Text('Todo'),
          ),
          if (!isToday)
            TextButton.icon(
              onPressed: _onJumpToToday,
              icon: const Icon(Icons.today_outlined, size: 18),
              label: const Text('Today'),
            ),
        ],
      ),
      body: Column(
        children: [
          _DateNavBar(
            selectedDate: selectedDate,
            onPrev: () => _scrollController.animateTo(
              _scrollController.offset - _kDayBlockHeight,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
            onNext: () => _scrollController.animateTo(
              _scrollController.offset + _kDayBlockHeight,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
          Expanded(
            child: _InfiniteDayList(
              scrollController: _scrollController,
              onInitialDate: (d) => _initialDate ??= d,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/task/new', extra: _composeDate()),
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _onJumpToToday() {
    final today = DateTime.now();
    ref.read(selectedStackDateProvider.notifier).state = DateTime(
      today.year,
      today.month,
      today.day,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
  }

  DateTime _composeDate() {
    if (!_scrollController.hasClients || _initialDate == null) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
    final focusOffset =
        _scrollController.offset +
        _scrollController.position.viewportDimension * _kDayFocusAnchor;
    final visibleIndex = (focusOffset / _kDayBlockHeight).floor();
    final daysOffset = visibleIndex - _kCenterIndex;
    final date = DateTime(
      _initialDate!.year,
      _initialDate!.month,
      _initialDate!.day + daysOffset,
    );
    return DateTime(date.year, date.month, date.day);
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

/// ListView wrapper. Owns the goal lookup ONCE per visible page so that
/// individual cards do not re-watch the goals provider.
class _InfiniteDayList extends ConsumerStatefulWidget {
  const _InfiniteDayList({
    required this.scrollController,
    required this.onInitialDate,
  });

  final ScrollController scrollController;
  final ValueChanged<DateTime> onInitialDate;

  @override
  ConsumerState<_InfiniteDayList> createState() => _InfiniteDayListState();
}

class _InfiniteDayListState extends ConsumerState<_InfiniteDayList> {
  late final DateTime _initialDate;

  @override
  void initState() {
    super.initState();
    _initialDate = ref.read(selectedStackDateProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onInitialDate(_initialDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Goals map for the visible window — listen once here so individual
    // cards never re-watch the goals provider.
    final goalsAsync = ref.watch(goalsProvider);
    final goalById = <String, String>{};
    goalsAsync.whenData((goals) {
      for (final g in goals) {
        goalById[g.id] = g.title;
      }
    });

    return ListView.builder(
      controller: widget.scrollController,
      itemExtent: _kDayBlockHeight,
      itemBuilder: (context, index) {
        final pageDate = DateTime(
          _initialDate.year,
          _initialDate.month,
          _initialDate.day + (index - _kCenterIndex),
        );
        final isPageToday = _isToday(pageDate);
        return _DayViewBlock(
          pageDate: pageDate,
          isPageToday: isPageToday,
          goalById: goalById,
        );
      },
    );
  }

  static bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

class _DayViewBlock extends ConsumerWidget {
  const _DayViewBlock({
    required this.pageDate,
    required this.isPageToday,
    required this.goalById,
  });

  final DateTime pageDate;
  final bool isPageToday;
  final Map<String, String> goalById;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final sortedTasks = ref.watch(sortedTasksForDateProvider(pageDate));
    final scheduled = <Task>[];
    final unscheduled = <Task>[];
    for (final t in sortedTasks) {
      if (t.startMinutes != null) {
        scheduled.add(t);
      } else {
        unscheduled.add(t);
      }
    }

    return SizedBox(
      width: double.infinity,
      height: _kDayBlockHeight,
      child: Stack(
        children: [
          // Hour grid: a single Column of 24 rows. One render object
          // instead of 24 Positioned widgets.
          Positioned.fill(
            child: _HourGrid(outline: cs.outlineVariant),
          ),
          // Task cards
          for (final task in scheduled)
            _PositionedTaskCard(
              task: task,
              isToday: isPageToday,
              pageDate: pageDate,
              goalTitle: task.goalId == null
                  ? null
                  : goalById[task.goalId!],
            ),
          if (unscheduled.isNotEmpty)
            Positioned(
              top: 24 * _kPixelsPerHour + 16,
              left: 0,
              right: 0,
              child: _UnscheduledSection(tasks: unscheduled),
            ),
          if (isPageToday) const TimeIndicatorWidget(),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(child: _DayDividerLabel(pageDate: pageDate, cs: cs)),
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

  static const _months = [
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
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String _labelFor(DateTime selectedDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final daysDiff = current.difference(today).inDays;
    if (daysDiff == 0) return 'Today';
    if (daysDiff == 1) return 'Tomorrow';
    if (daysDiff == -1) return 'Yesterday';
    return '${_weekdays[selectedDate.weekday - 1]}, '
        '${_months[selectedDate.month - 1]} ${selectedDate.day}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = _labelFor(selectedDate);
    return Container(
      color: cs.surface,
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
                color: cs.onSurface,
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
}

// ── Hour Grid (single render object) ──────────────────────────────────────

class _HourGrid extends StatelessWidget {
  const _HourGrid({required this.outline});
  final Color outline;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var h = 0; h < 24; h++)
          _HourRow(hour: h, outline: outline),
      ],
    );
  }
}

class _HourRow extends StatelessWidget {
  const _HourRow({required this.hour, required this.outline});
  final int hour;
  final Color outline;

  static const _kLabels = <String>[
    '12 AM',
    '1 AM',
    '2 AM',
    '3 AM',
    '4 AM',
    '5 AM',
    '6 AM',
    '7 AM',
    '8 AM',
    '9 AM',
    '10 AM',
    '11 AM',
    '12 PM',
    '1 PM',
    '2 PM',
    '3 PM',
    '4 PM',
    '5 PM',
    '6 PM',
    '7 PM',
    '8 PM',
    '9 PM',
    '10 PM',
    '11 PM',
  ];

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    return SizedBox(
      height: _kPixelsPerHour,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _kHourLabelWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: Text(
                _kLabels[hour],
                textAlign: TextAlign.right,
                style: labelStyle?.copyWith(color: outline),
              ),
            ),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: outline, width: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Day Divider Label ─────────────────────────────────────────────────────

class _DayDividerLabel extends StatelessWidget {
  const _DayDividerLabel({required this.pageDate, required this.cs});
  final DateTime pageDate;
  final ColorScheme cs;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
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

  @override
  Widget build(BuildContext context) {
    final next = pageDate.add(const Duration(days: 1));
    return Text(
      '${_weekdays[next.weekday - 1]}, ${_months[next.month - 1]} ${next.day}',
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: cs.outline,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// ── Positioned Task Card ──────────────────────────────────────────────────

class _PositionedTaskCard extends ConsumerWidget {
  const _PositionedTaskCard({
    required this.task,
    required this.isToday,
    required this.pageDate,
    required this.goalTitle,
  });

  final Task task;
  final bool isToday;
  final DateTime pageDate;
  final String? goalTitle;

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
      var rawHeightMins = (task.durationMinutes ?? 30).toDouble();
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
        isInProgress: isToday && task.isInProgress(DateTime.now()),
        goalTitle: goalTitle,
        onTap: () => context.push('/task/${task.id}'),
        onDone: () => _onDone(context, ref, task),
        onEdit: () => context.push('/task/${task.id}/edit'),
        onDelete: () => _onDelete(context, ref, task),
        onDuplicate: () => ref.read(duplicateTaskUseCaseProvider).execute(task),
      ),
    );
  }

  Future<void> _onDone(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
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
  }

  Future<void> _onDelete(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
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
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return (await showDialog<bool>(
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
        )) ??
        false;
  }

  Future<RecurringScope?> _confirmRecurringDelete(BuildContext context) async {
    return showDialog<RecurringScope>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recurring Task'),
        content: const Text(
          'Do you want to delete this instance only, or all upcoming instances as well?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, RecurringScope.thisInstance),
            child: const Text('This instance only'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, RecurringScope.futureInstances),
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
    final cs = Theme.of(context).colorScheme;
    final tasks = widget.tasks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(
            _expanded ? Icons.expand_less : Icons.expand_more,
            color: cs.primary,
          ),
          title: Text(
            'Unscheduled (${tasks.length})',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child:
              _expanded
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final t in tasks)
                      ListTile(
                        leading: const Icon(Icons.schedule_outlined),
                        title: Text(t.title),
                        onTap: () => context.push('/task/${t.id}'),
                      ),
                  ],
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}
