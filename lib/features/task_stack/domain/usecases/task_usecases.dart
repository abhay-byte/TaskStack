import 'package:uuid/uuid.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/domain/repositories/task_repository.dart';
import 'package:taskstack/features/notifications/notification_scheduler.dart';
import 'package:taskstack/features/sync/domain/repositories/sync_repository.dart';

const _uuid = Uuid();

enum RecurringScope { thisInstance, futureInstances }

class CreateTaskUseCase {
  CreateTaskUseCase(this._repository, this._scheduler);
  final TaskRepository _repository;
  final NotificationScheduler _scheduler;

  Future<void> execute(Task task) async {
    final now = DateTime.now();
    final newTask = task.copyWith(
      id: task.id.isEmpty ? _uuid.v4() : task.id,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.insertTask(newTask);
    if (newTask.notificationEnabled) {
      await _scheduler.scheduleFor(newTask);
    }

    // Generate intra-day repeat instances if repeatToday
    if (newTask.recurrenceType == RecurrenceType.repeatToday &&
        newTask.repeatIntervalMinutes != null &&
        newTask.startMinutes != null) {
      final instances = generateRepeatInstances(newTask);
      await _repository.insertTasks(instances);
      for (final inst in instances) {
        if (inst.notificationEnabled) {
          await _scheduler.scheduleFor(inst);
        }
      }
    }
    // NOTE: daily/weekly/custom NO LONGER generate 365 rows here.
    // A rolling 2-week window is maintained separately by
    // MaintainRecurringWindowUseCase.
  }

  /// Legacy helper — kept for reference but no longer called on creation.
  /// UpdateTaskUseCase uses MaintainRecurringWindowUseCase instead.
  static List<Task> generateFutureInstances(
    Task parent, {
    String? forceParentId,
  }) {
    final instances = <Task>[];
    for (var i = 1; i <= 365 * 2; i++) {
      DateTime nextDate;
      if (parent.recurrenceType == RecurrenceType.daily) {
        nextDate = DateTime(
          parent.taskDate.year,
          parent.taskDate.month,
          parent.taskDate.day + i,
        );
        if (instances.length >= 365) break;
      } else if (parent.recurrenceType == RecurrenceType.weekly) {
        nextDate = DateTime(
          parent.taskDate.year,
          parent.taskDate.month,
          parent.taskDate.day + (7 * i),
        );
        if (instances.length >= 104) break;
      } else if (parent.recurrenceType == RecurrenceType.custom) {
        nextDate = DateTime(
          parent.taskDate.year,
          parent.taskDate.month,
          parent.taskDate.day + i,
        );
        if (!parent.customRecurrenceDays.contains(nextDate.weekday)) {
          continue;
        }
        if (instances.length >= 365) break;
      } else {
        break;
      }

      instances.add(
        parent.copyWith(
          id: _uuid.v4(),
          taskDate: nextDate,
          parentTaskId: forceParentId ?? parent.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: TaskStatus.pending,
        ),
      );
    }
    return instances;
  }

  static List<Task> generateRepeatInstances(
    Task parent, {
    String? forceParentId,
  }) {
    final instances = <Task>[];
    final interval = parent.repeatIntervalMinutes!;
    var nextStart = parent.startMinutes! + interval;
    const endOfDay = 23 * 60 + 59;
    var index = 1;

    while (nextStart + (parent.durationMinutes ?? 30) <= endOfDay) {
      instances.add(
        parent.copyWith(
          id: _uuid.v4(),
          startMinutes: nextStart,
          parentTaskId: forceParentId ?? parent.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: TaskStatus.pending,
        ),
      );
      nextStart += interval;
      index++;
      if (index > 48) break; // safety cap
    }
    return instances;
  }
}

/// Maintains a rolling 2-week window of recurring task instances.
///   back:  7 days  (to cover spillover / recent history)
///   forward: 14 days (so next week is always ready)
/// Old pending/unmodified instances outside the window are deleted.
class MaintainRecurringWindowUseCase {
  MaintainRecurringWindowUseCase(this._repository, this._scheduler);
  final TaskRepository _repository;
  final NotificationScheduler _scheduler;

  static const _windowBackDays = 7;
  static const _windowForwardDays = 14;

  Future<void> execute({String? specificParentId}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final windowStart = today.subtract(
      const Duration(days: _windowBackDays),
    );
    final windowEnd = today.add(const Duration(days: _windowForwardDays));

    final parents =
        specificParentId != null
            ? [
              await _repository.getTaskById(specificParentId),
            ].whereType<Task>()
            : await _repository.getRecurringParents();

    for (final parent in parents) {
      if (parent.recurrenceType == RecurrenceType.none ||
          parent.recurrenceType == RecurrenceType.repeatToday) {
        continue;
      }

      // 1. Expected dates in window
      final expected = _expectedDates(parent, windowStart, windowEnd);
      if (expected.isEmpty) continue;

      // 2. Existing instances in window
      final existing = await _repository.getInstanceDatesInRange(
        parent.id,
        windowStart,
        windowEnd,
      );
      final existingSet = existing
          .map((s) => DateTime.parse(s))
          .map(_normalize)
          .toSet();

      // 3. Insert missing
      final missing = expected.where((d) => !existingSet.contains(d));
      final instances =
          missing
              .map(
                (d) => parent.copyWith(
                  id: _uuid.v4(),
                  taskDate: d,
                  parentTaskId: parent.id,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  status: TaskStatus.pending,
                ),
              )
              .toList();

      if (instances.isNotEmpty) {
        await _repository.insertTasks(instances);
        for (final inst in instances.take(10)) {
          if (inst.notificationEnabled) {
            await _scheduler.scheduleFor(inst);
          }
        }
      }

      // 4. Trim old unmodified instances outside window
      await _repository.deleteOldPendingInstances(parent.id, windowStart);
    }
  }

  List<DateTime> _expectedDates(Task parent, DateTime from, DateTime to) {
    final result = <DateTime>[];
    var current = _normalize(from);
    final parentDate = _normalize(parent.taskDate);

    while (!current.isAfter(to)) {
      if (!current.isBefore(parentDate)) {
        final daysSince = current.difference(parentDate).inDays;
        bool matches = false;
        switch (parent.recurrenceType) {
          case RecurrenceType.daily:
            matches = true;
          case RecurrenceType.weekly:
            matches = daysSince >= 0 && daysSince % 7 == 0;
          case RecurrenceType.custom:
            matches = parent.customRecurrenceDays.contains(current.weekday);
          default:
            matches = false;
        }
        if (matches) result.add(current);
      }
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);
}

class CreateDayTodoUseCase {
  CreateDayTodoUseCase(this._createTask, this._syncRepository);
  final CreateTaskUseCase _createTask;
  final SyncRepository _syncRepository;

  Future<void> execute({
    required String title,
    required DateTime taskDate,
  }) async {
    final normalizedDate = DateTime(
      taskDate.year,
      taskDate.month,
      taskDate.day,
    );
    final now = DateTime.now();

    await _createTask.execute(
      Task(
        id: '',
        title: title.trim(),
        createdAt: now,
        updatedAt: now,
        taskDate: normalizedDate,
        notificationEnabled: false,
      ),
    );
    await _syncRepository.pushLocalToCloud();
  }
}

class GetTasksForDateUseCase {
  GetTasksForDateUseCase(this._repository);
  final TaskRepository _repository;

  Stream<List<Task>> execute(DateTime date) =>
      _repository.watchTasksForDate(date);
}

class UpdateTaskUseCase {
  UpdateTaskUseCase(this._repository, this._scheduler);
  final TaskRepository _repository;
  final NotificationScheduler _scheduler;

  Future<void> execute(
    Task task, {
    RecurringScope scope = RecurringScope.thisInstance,
  }) async {
    final updated = task.copyWith(updatedAt: DateTime.now());
    await _repository.updateTask(updated);
    await _scheduler.cancelFor(task.id);
    if (updated.notificationEnabled) {
      await _scheduler.scheduleFor(updated);
    }

    if (scope == RecurringScope.futureInstances &&
        (task.parentTaskId != null ||
            task.recurrenceType != RecurrenceType.none)) {
      final actualParentId = task.parentTaskId ?? task.id;
      // Delete future instances (non-inclusive of this updated instance)
      await _repository.deleteRecurringTasksFromDate(
        actualParentId,
        task.taskDate,
        inclusive: false,
      );
      // Rolling window maintenance will repopulate on next run.
      // We intentionally do NOT regenerate 365 rows here anymore.
    }
  }
}

class DeleteTaskUseCase {
  DeleteTaskUseCase(this._repository, this._scheduler, this._syncRepository);
  final TaskRepository _repository;
  final NotificationScheduler _scheduler;
  final SyncRepository _syncRepository;

  Future<void> execute(
    Task task, {
    RecurringScope scope = RecurringScope.thisInstance,
  }) async {
    await _scheduler.cancelFor(task.id);
    if (scope == RecurringScope.futureInstances &&
        (task.parentTaskId != null ||
            task.recurrenceType != RecurrenceType.none)) {
      final actualParentId = task.parentTaskId ?? task.id;
      await _repository.deleteRecurringTasksFromDate(
        actualParentId,
        task.taskDate,
      );
    } else {
      await _repository.deleteTask(task.id);
    }
    await _syncRepository.pushLocalToCloud();
  }
}

class CompleteTaskUseCase {
  CompleteTaskUseCase(this._repository, this._syncRepository);
  final TaskRepository _repository;
  final SyncRepository _syncRepository;

  Future<void> execute(Task task) async {
    // Validate deadline
    if (task.startMinutes != null) {
      final now = DateTime.now();

      // Calculate start time in terms of today
      final taskStart = DateTime(
        task.taskDate.year,
        task.taskDate.month,
        task.taskDate.day,
        task.startMinutes! ~/ 60,
        task.startMinutes! % 60,
      );

      final taskDuration = Duration(minutes: task.durationMinutes ?? 30);
      final deadline = taskStart.add(taskDuration);

      // If we attempt to finish it early, throw StateError
      if (now.isBefore(deadline)) {
        throw StateError('Cannot complete a task before its deadline.');
      }
    }

    await _repository.updateStatus(
      task.id,
      status: TaskStatus.done.name,
      completedAt: DateTime.now(),
    );
    await _syncRepository.pushLocalToCloud();
  }

  Future<void> undo(String id) async {
    await _repository.updateStatus(id, status: TaskStatus.pending.name);
    await _syncRepository.pushLocalToCloud();
  }
}

class DuplicateTaskUseCase {
  DuplicateTaskUseCase(this._repository);
  final TaskRepository _repository;

  Future<void> execute(Task original) async {
    final copy = original.copyWith(
      id: _uuid.v4(),
      status: TaskStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repository.insertTask(copy);
  }
}
