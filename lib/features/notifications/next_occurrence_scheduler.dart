import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/features/notifications/notification_scheduler.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/domain/repositories/task_repository.dart';
import 'package:taskstack/features/task_stack/data/repositories/task_repository_impl.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Called after a task is marked done.
/// If the task is a recurring (daily/weekly) type, schedules the next occurrence
/// notification so the user stays informed even without opening the app.
class NextOccurrenceScheduler {
  NextOccurrenceScheduler(this._repo, this._scheduler);

  final TaskRepository _repo;
  final NotificationScheduler _scheduler;

  Future<void> scheduleNextOccurrenceFor(Task completedTask) async {
    if (completedTask.recurrenceType == RecurrenceType.none ||
        completedTask.recurrenceType == RecurrenceType.repeatToday) {
      return; // no next-occurrence needed
    }

    final nextDate = _nextDate(completedTask);
    if (nextDate == null) return;

    // Check if instance already exists for next date to avoid duplicates
    final existing = await _repo.getTasksInRange(nextDate, nextDate);
    final alreadyExists = existing.any(
      (t) => t.parentTaskId == completedTask.id || t.id == completedTask.id,
    );
    if (alreadyExists) return;

    final nextTask = completedTask.copyWith(
      id: _uuid.v4(),
      status: TaskStatus.pending,
      completedAt: null,
      taskDate: nextDate,
      parentTaskId: completedTask.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repo.insertTask(nextTask);
    if (nextTask.notificationEnabled) {
      await _scheduler.scheduleFor(nextTask);
    }
  }

  DateTime? _nextDate(Task task) {
    return switch (task.recurrenceType) {
      RecurrenceType.daily =>
        task.taskDate.add(const Duration(days: 1)),
      RecurrenceType.weekly =>
        task.taskDate.add(const Duration(days: 7)),
      _ => null,
    };
  }
}

final nextOccurrenceSchedulerProvider =
    Provider<NextOccurrenceScheduler>((ref) {
  return NextOccurrenceScheduler(
    ref.watch(taskRepositoryProvider),
    ref.watch(notificationSchedulerProvider),
  );
});
