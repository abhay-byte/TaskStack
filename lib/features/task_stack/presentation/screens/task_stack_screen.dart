import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/domain/usecases/task_usecases.dart';
import 'package:taskstack/features/task_stack/presentation/providers/task_providers.dart';
import 'package:taskstack/features/task_stack/presentation/screens/day_todo_sheet.dart';
import 'package:taskstack/features/task_stack/presentation/widgets/calendar_sheet.dart';
import 'package:taskstack/features/task_stack/presentation/widgets/task_card_widget.dart';
import 'package:taskstack/features/task_stack/presentation/widgets/time_indicator_widget.dart';
import 'package:taskstack/core/constants/app_spacing.dart';

const double _kPixelsPerHour = 120.0;
const double _kMinuteHeight = _kPixelsPerHour / 60;
const double _kDayBlockHeight = 24 * _kPixelsPerHour;
const double _kDayFocusAnchor = 0.35;
const double _kHourLabelWidth = 60;

// Sliding window — keeps the list small so scroll physics work correctly.
// Instead of 20,001 virtual items (the center-index approach), we maintain
// a ~41-item window centered on today and expand it gradually as the user
// scrolls near either edge. Total scroll extent stays ~120,000px instead of
// ~57,600,000px, giving natural-feeling fling deceleration.
const int _kWindowSize = 41;
const int _kExpandThreshold = 5;
const int _kExpandBy = 10;

enum _ExpandDir { prev, next }

const _kWeekdays = [
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];

const _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

bool _isToday(DateTime d) {
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month && d.day == now.day;
}

class TaskStackScreen extends ConsumerStatefulWidget {
  const TaskStackScreen({super.key});

  @override
  ConsumerState<TaskStackScreen> createState() => _TaskStackScreenState();
}

class _TaskStackScreenState extends ConsumerState<TaskStackScreen> {
  late final ScrollController _scrollController;
  Timer? _recurringTimer;

  // The sliding window of visible dates. Grows monotonically as the user
  // scrolls — never shrinks — so today always stays in-range.
  List<DateTime> _windowDates = [];
  int _currentVisibleIndex = 0;
  bool _isExpandingWindow = false;

  @override
  void initState() {
    super.initState();
    _buildInitialWindow();
    _scrollController = ScrollController(
      initialScrollOffset: (_windowDates.length ~/ 2) * _kDayBlockHeight,
    );
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToNow();
      ref.read(maintainRecurringWindowUseCaseProvider).execute();
    });

    _scheduleRecurringMaintenance();
  }

  void _buildInitialWindow() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _windowDates = List.generate(_kWindowSize, (i) {
      return DateTime(
        today.year,
        today.month,
        today.day + (i - _kWindowSize ~/ 2),
      );
    });
  }

  /// Fires only on the hour (when `:00` rolls around). The first tick
  /// computes the exact delay to the next `:00` so we never waste ticks.
  void _scheduleRecurringMaintenance() {
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour)
        .add(const Duration(hours: 1));
    final delay = nextHour.difference(now);
    _recurringTimer = Timer(delay, () {
      try {
        ref.read(maintainRecurringWindowUseCaseProvider).execute();
      } catch (_) {
        // Silently swallow — recurring window maintenance is best-effort.
      }
      _recurringTimer = Timer.periodic(
        const Duration(hours: 1),
        (_) {
          try {
            ref.read(maintainRecurringWindowUseCaseProvider).execute();
          } catch (_) {}
        },
      );
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isExpandingWindow) return;
    if (_windowDates.isEmpty) return;

    final offset = _scrollController.offset;
    final viewport = _scrollController.position.viewportDimension;
    final visibleIndex =
        ((offset + viewport * _kDayFocusAnchor) / _kDayBlockHeight).floor();

    if (visibleIndex != _currentVisibleIndex &&
        visibleIndex >= 0 &&
        visibleIndex < _windowDates.length) {
      _currentVisibleIndex = visibleIndex;
      final newDate = _windowDates[visibleIndex];
      Future.microtask(() {
        if (mounted) {
          ref.read(selectedStackDateProvider.notifier).state = newDate;
        }
      });
    }

    // Expand the window when the user scrolls near either edge.
    if (visibleIndex <= _kExpandThreshold) {
      _expandWindow(_ExpandDir.prev);
    } else if (visibleIndex >= _windowDates.length - _kExpandThreshold - 1) {
      _expandWindow(_ExpandDir.next);
    }
  }

  void _expandWindow(_ExpandDir dir) {
    _isExpandingWindow = true;
    try {
      setState(() {
        if (dir == _ExpandDir.prev) {
          final first = _windowDates.first;
          for (var i = _kExpandBy; i >= 1; i--) {
            _windowDates.insert(
              0,
              DateTime(first.year, first.month, first.day - i),
            );
          }
        } else {
          final last = _windowDates.last;
          for (var i = 1; i <= _kExpandBy; i++) {
            _windowDates.add(DateTime(last.year, last.month, last.day + i));
          }
        }
      });
      // When prepending, jump the scroll offset forward so the visible
      // content stays in-place — new items were inserted above the viewport.
      if (dir == _ExpandDir.prev) {
        _scrollController.jumpTo(
          _scrollController.offset + _kExpandBy * _kDayBlockHeight,
        );
      }
    } finally {
      _isExpandingWindow = false;
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
    if (!_scrollController.hasClients || _windowDates.isEmpty) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayIndex = _windowDates.indexWhere(
      (d) =>
          d.year == today.year && d.month == today.month && d.day == today.day,
    );
    if (todayIndex < 0) return;

    final dayBaseOffset = todayIndex * _kDayBlockHeight;
    final timeOffset =
        (now.hour * 60 + now.minute) * _kMinuteHeight -
        _scrollController.position.viewportDimension * _kDayFocusAnchor;
    final target = (dayBaseOffset + timeOffset).clamp(
      0.0,
      (_windowDates.length - 1) * _kDayBlockHeight,
    );
    _scrollController.animateTo(
      target,
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
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Calendar',
            onPressed: _openCalendarSheet,
          ),
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
              windowDates: _windowDates,
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
    final todayDate = DateTime(today.year, today.month, today.day);
    ref.read(selectedStackDateProvider.notifier).state = todayDate;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
  }

  void _openCalendarSheet() async {
    final selectedDate = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (_) => CalendarSheet(
        initialDate: ref.read(selectedStackDateProvider),
      ),
    );
    if (selectedDate != null && mounted) {
      _scrollToDate(selectedDate);
    }
  }

  void _scrollToDate(DateTime target) {
    if (!_scrollController.hasClients || _windowDates.isEmpty) return;
    _ensureDateInWindow(target);

    final targetMidnight = DateTime(target.year, target.month, target.day);
    final dateIndex = _windowDates.indexWhere(
      (d) =>
          d.year == targetMidnight.year &&
          d.month == targetMidnight.month &&
          d.day == targetMidnight.day,
    );
    if (dateIndex < 0) return;

    final targetOffset = dateIndex * _kDayBlockHeight;
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
    ref.read(selectedStackDateProvider.notifier).state = targetMidnight;
  }

  void _ensureDateInWindow(DateTime target) {
    final targetMidnight = DateTime(target.year, target.month, target.day);
    for (var safety = 0; safety < 10; safety++) {
      final first = _windowDates.first;
      final last = _windowDates.last;
      final firstMidnight = DateTime(first.year, first.month, first.day);
      final lastMidnight = DateTime(last.year, last.month, last.day);

      if (targetMidnight.isBefore(firstMidnight)) {
        _expandWindow(_ExpandDir.prev);
      } else if (targetMidnight.isAfter(lastMidnight)) {
        _expandWindow(_ExpandDir.next);
      } else {
        return;
      }
    }
  }

  DateTime _composeDate() {
    if (!_scrollController.hasClients || _windowDates.isEmpty) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
    final focusOffset =
        _scrollController.offset +
        _scrollController.position.viewportDimension * _kDayFocusAnchor;
    final visibleIndex = (focusOffset / _kDayBlockHeight).floor();
    if (visibleIndex < 0 || visibleIndex >= _windowDates.length) {
      return _windowDates[_windowDates.length ~/ 2];
    }
    return _windowDates[visibleIndex];
  }

}

/// Bounded ListView wrapping the sliding window of dates.
/// Uses the memoized [goalTitleMapProvider] so individual cards never
/// re-watch the goals stream — the lookup map is built once and cached
/// until goals actually change.
class _InfiniteDayList extends ConsumerWidget {
  const _InfiniteDayList({
    required this.scrollController,
    required this.windowDates,
  });

  final ScrollController scrollController;
  final List<DateTime> windowDates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalById = ref.watch(goalTitleMapProvider);

    return ListView.builder(
      controller: scrollController,
      itemExtent: _kDayBlockHeight,
      addAutomaticKeepAlives: false,
      scrollCacheExtent: const ScrollCacheExtent.pixels(_kDayBlockHeight * 2),
      itemCount: windowDates.length,
      itemBuilder: (context, index) {
        final pageDate = windowDates[index];
        return _DayViewBlock(
          pageDate: pageDate,
          isPageToday: _isToday(pageDate),
          goalById: goalById,
        );
      },
    );
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
          // Hour grid painted by a single CustomPainter instead of 24 widgets.
          Positioned.fill(
            child: CustomPaint(
              painter: _HourGridPainter(
                outlineColor: cs.outlineVariant,
                labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.outlineVariant,
                ) ??
                    const TextStyle(fontSize: 11),
              ),
            ),
          ),
          // Task cards
          for (final task in scheduled)
            _PositionedTaskCard(
              task: task,
              isToday: isPageToday,
              pageDate: pageDate,
              goalTitle:
                  task.goalId == null ? null : goalById[task.goalId!],
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

// ── Hour Grid Painter (CustomPainter, single render object) ──────────────

class _HourGridPainter extends CustomPainter {
  _HourGridPainter({
    required this.outlineColor,
    required this.labelStyle,
  });

  final Color outlineColor;
  final TextStyle labelStyle;

  static const _kLabels = <String>[
    '12 AM', '1 AM', '2 AM', '3 AM', '4 AM', '5 AM',
    '6 AM', '7 AM', '8 AM', '9 AM', '10 AM', '11 AM',
    '12 PM', '1 PM', '2 PM', '3 PM', '4 PM', '5 PM',
    '6 PM', '7 PM', '8 PM', '9 PM', '10 PM', '11 PM',
  ];

  // Cache laid-out TextPainters keyed by style hash to avoid re-layout
  // on every repaint. This is the single biggest UI-thread win for
  // the stack page (~24 text layouts → 0 after first paint).
  static final Map<int, List<TextPainter>> _textCache = {};

  List<TextPainter> _getCachedPainters(TextStyle style) {
    final key = style.hashCode ^ _kLabels.length;
    final cached = _textCache[key];
    if (cached != null) return cached;

    final painters = <TextPainter>[];
    for (final label in _kLabels) {
      final tp = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      )..layout(maxWidth: _kHourLabelWidth - 8);
      painters.add(tp);
    }
    _textCache[key] = painters;
    return painters;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = outlineColor
      ..strokeWidth = 0.5;

    final hourHeight = size.height / 24;
    final painters = _getCachedPainters(labelStyle);

    for (var h = 0; h < 24; h++) {
      final y = h * hourHeight;
      // Grid line from label edge to right edge
      canvas.drawLine(Offset(_kHourLabelWidth, y), Offset(size.width, y), paint);

      // Hour label — uses pre-cached TextPainter
      painters[h].paint(canvas, Offset(0, y + 4));
    }
  }

  @override
  bool shouldRepaint(_HourGridPainter oldDelegate) =>
      oldDelegate.outlineColor != outlineColor ||
      oldDelegate.labelStyle != labelStyle;
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
    return '${_kWeekdays[selectedDate.weekday - 1]}, '
        '${_kMonths[selectedDate.month - 1]} ${selectedDate.day}';
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

// ── Day Divider Label ─────────────────────────────────────────────────────

class _DayDividerLabel extends StatelessWidget {
  const _DayDividerLabel({required this.pageDate, required this.cs});
  final DateTime pageDate;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final next = pageDate.add(const Duration(days: 1));
    return Text(
      '${_kWeekdays[next.weekday - 1]}, ${_kMonths[next.month - 1]} ${next.day}',
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

  Future<void> _onDone(BuildContext context, WidgetRef ref, Task task) async {
    try {
      await ref.read(completeTaskUseCaseProvider).execute(task);
    } on StateError catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref, Task task) async {
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
