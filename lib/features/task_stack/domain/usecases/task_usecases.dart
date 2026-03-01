import 'package:uuid/uuid.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/domain/repositories/task_repository.dart';
import 'package:taskstack/features/notifications/notification_scheduler.dart';

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
    } else if (newTask.recurrenceType != RecurrenceType.none &&
        newTask.recurrenceType != RecurrenceType.repeatToday) {
      final instances = generateFutureInstances(newTask);
      await _repository.insertTasks(instances);
      // Schedule notifications for only the first 20 instances to prevent freezing the UI
      final notificationsToSchedule = instances.take(20);
      for (final inst in notificationsToSchedule) {
        if (inst.notificationEnabled) {
          await _scheduler.scheduleFor(inst);
        }
      }
    }
  }

  static List<Task> generateFutureInstances(
    Task parent, {
    String? forceParentId,
  }) {
    final instances = <Task>[];
    // Generate up to 2 years ahead or max instances limits, whichever is smaller
    for (var i = 1; i <= 365 * 2; i++) {
      DateTime nextDate;
      if (parent.recurrenceType == RecurrenceType.daily) {
        nextDate = parent.taskDate.add(Duration(days: i));
        if (instances.length >= 365) break; // 1 year limit
      } else if (parent.recurrenceType == RecurrenceType.weekly) {
        nextDate = parent.taskDate.add(Duration(days: 7 * i));
        if (instances.length >= 104) break; // 2 years limit
      } else if (parent.recurrenceType == RecurrenceType.custom) {
        nextDate = parent.taskDate.add(Duration(days: i));
        if (!parent.customRecurrenceDays.contains(nextDate.weekday)) {
          continue; // skip days that aren't selected
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
          completedAt: null,
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
    final endOfDay = 23 * 60 + 59;
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
          completedAt: null,
        ),
      );
      nextStart += interval;
      index++;
      if (index > 48) break; // safety cap
    }
    return instances;
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

      // Regenerate future instances using the updated task as a template
      final template = updated.copyWith(parentTaskId: actualParentId);
      final instances =
          template.recurrenceType == RecurrenceType.repeatToday
              ? CreateTaskUseCase.generateRepeatInstances(
                template,
                forceParentId: actualParentId,
              )
              : CreateTaskUseCase.generateFutureInstances(
                template,
                forceParentId: actualParentId,
              );

      if (instances.isNotEmpty) {
        await _repository.insertTasks(instances);
        for (final inst in instances.take(20)) {
          if (inst.notificationEnabled) {
            await _scheduler.scheduleFor(inst);
          }
        }
      }
    }
  }
}

class DeleteTaskUseCase {
  DeleteTaskUseCase(this._repository, this._scheduler);
  final TaskRepository _repository;
  final NotificationScheduler _scheduler;

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
        inclusive: true,
      );
    } else {
      await _repository.deleteTask(task.id);
    }
  }
}

class CompleteTaskUseCase {
  CompleteTaskUseCase(this._repository);
  final TaskRepository _repository;

  Future<void> execute(String id) async {
    await _repository.updateStatus(
      id,
      status: TaskStatus.done.name,
      completedAt: DateTime.now(),
    );
  }

  Future<void> undo(String id) async {
    await _repository.updateStatus(id, status: TaskStatus.pending.name);
  }
}

class DuplicateTaskUseCase {
  DuplicateTaskUseCase(this._repository);
  final TaskRepository _repository;

  Future<void> execute(Task original) async {
    final copy = original.copyWith(
      id: _uuid.v4(),
      status: TaskStatus.pending,
      completedAt: null,
      parentTaskId: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repository.insertTask(copy);
  }
}
