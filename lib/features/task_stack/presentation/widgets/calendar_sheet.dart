import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/features/task_stack/data/repositories/task_repository_impl.dart';

class CalendarSheet extends ConsumerStatefulWidget {
  const CalendarSheet({super.key, required this.initialDate});

  final DateTime initialDate;

  @override
  ConsumerState<CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends ConsumerState<CalendarSheet> {
  late DateTime _viewMonth;
  final Map<String, int> _taskCounts = {};
  bool _loading = true;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      1,
    );
    _loadTaskCounts();
  }

  void _loadTaskCounts() {
    setState(() => _loading = true);
    _taskCounts.clear();
    final firstDay = _viewMonth;
    final lastDay = DateTime(_viewMonth.year, _viewMonth.month + 1, 0);
    ref
        .read(taskRepositoryProvider)
        .getTasksInRange(firstDay, lastDay)
        .then((tasks) {
      for (final t in tasks) {
        final key = t.taskDate.toIso8601String().substring(0, 10);
        _taskCounts[key] = (_taskCounts[key] ?? 0) + 1;
      }
      if (mounted) setState(() => _loading = false);
    });
  }

  void _previousMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1, 1);
    });
    _loadTaskCounts();
  }

  void _nextMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 1);
    });
    _loadTaskCounts();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final daysInMonth =
        DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final firstWeekday = _viewMonth.weekday; // 1=Mon ... 7=Sun
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final selectedStr =
        '${widget.initialDate.year}-${widget.initialDate.month.toString().padLeft(2, '0')}-${widget.initialDate.day.toString().padLeft(2, '0')}';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: prev / Month Year / next
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                ),
                Text(
                  '${_months[_viewMonth.month - 1]} ${_viewMonth.year}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Day-of-week headers
            Row(
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 4),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              _buildGrid(
                daysInMonth,
                firstWeekday,
                todayStr,
                selectedStr,
                cs,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(
    int daysInMonth,
    int firstWeekday,
    String todayStr,
    String selectedStr,
    ColorScheme cs,
  ) {
    final cells = <Widget>[];

    // Empty cells before the 1st
    for (var i = 1; i < firstWeekday; i++) {
      cells.add(const Expanded(child: SizedBox(height: 44)));
    }

    // Day cells
    for (var day = 1; day <= daysInMonth; day++) {
      final dateStr =
          '${_viewMonth.year}-${_viewMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final count = _taskCounts[dateStr] ?? 0;
      final date = DateTime(_viewMonth.year, _viewMonth.month, day);
      cells.add(
        _DayCell(
          day: day,
          count: count,
          isToday: dateStr == todayStr,
          isSelected: dateStr == selectedStr,
          isPast: date.isBefore(DateTime.now().subtract(const Duration(days: 1))),
          onTap: () => Navigator.pop(context, date),
        ),
      );
    }

    // Fill remaining cells in the last row
    while (cells.length % 7 != 0) {
      cells.add(const Expanded(child: SizedBox(height: 44)));
    }

    return Column(
      children: List.generate(cells.length ~/ 7, (i) {
        return Row(children: cells.sublist(i * 7, (i + 1) * 7));
      }),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.count,
    required this.isToday,
    required this.isSelected,
    required this.isPast,
    required this.onTap,
  });

  final int day;
  final int count;
  final bool isToday;
  final bool isSelected;
  final bool isPast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: isSelected ? cs.primaryContainer : null,
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color:
                      isToday
                          ? cs.primary
                          : isPast
                          ? cs.onSurfaceVariant.withAlpha(100)
                          : cs.onSurface,
                  fontSize: 14,
                ),
              ),
              if (count > 0)
                Positioned(
                  top: 3,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: cs.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(minWidth: 16),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
