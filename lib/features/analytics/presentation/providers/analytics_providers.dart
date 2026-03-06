import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/data/repositories/task_repository_impl.dart';

/// Lists this week's tasks grouped by weekday index (0=Mon…6=Sun).
final weeklyTasksProvider = FutureProvider<List<List<Task>>>((ref) async {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final repo = ref.watch(taskRepositoryProvider);
  final days = await Future.wait(
    List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return repo.getTasksInRange(day, day);
    }),
  );
  return days;
});

/// Monthly tasks keyed by day-of-month.
final monthlyTasksProvider = FutureProvider<Map<int, List<Task>>>((ref) async {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0);
  final repo = ref.watch(taskRepositoryProvider);
  final tasks = await repo.getTasksInRange(start, end);
  final map = <int, List<Task>>{};
  for (final t in tasks) {
    final day = t.taskDate.day;
    map.putIfAbsent(day, () => []).add(t);
  }
  return map;
});

/// 365 productivity scores (0.0–1.0) for the current year.
final yearlyTasksProvider = FutureProvider<List<double>>((ref) async {
  final now = DateTime.now();
  final start = DateTime(now.year, 1, 1);
  final end = DateTime(now.year, 12, 31);
  final repo = ref.watch(taskRepositoryProvider);
  final tasks = await repo.getTasksInRange(start, end);

  final daysInYear = (end.difference(start).inDays + 1);
  final scores = List<double>.filled(daysInYear, 0.0);

  for (var i = 0; i < daysInYear; i++) {
    final day = start.add(Duration(days: i));
    final dayTasks =
        tasks
            .where(
              (t) =>
                  t.taskDate.year == day.year &&
                  t.taskDate.month == day.month &&
                  t.taskDate.day == day.day,
            )
            .toList();
    if (dayTasks.isEmpty) continue;
    final done = dayTasks.where((t) => t.isDone).length;
    scores[i] = done / dayTasks.length;
  }
  return scores;
});

/// Monthly average score for a given month (1–12).
final monthlyAvgProvider = Provider.family<double, int>((ref, month) {
  final yearly = ref.watch(yearlyTasksProvider).value;
  if (yearly == null) return 0;
  final now = DateTime.now();
  final start = DateTime(now.year, month, 1);
  final daysInMonth = DateUtils.getDaysInMonth(now.year, month);
  final startIdx = start.difference(DateTime(now.year, 1, 1)).inDays;
  final slice = yearly.skip(startIdx).take(daysInMonth).toList();
  if (slice.isEmpty) return 0;
  return slice.reduce((a, b) => a + b) / slice.length * 10; // scale to 0-10
});
