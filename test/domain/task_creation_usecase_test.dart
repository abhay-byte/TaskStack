import 'package:flutter_test/flutter_test.dart';
import 'package:taskstack/features/notifications/notification_scheduler.dart';
import 'package:taskstack/features/sync/domain/repositories/sync_repository.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/domain/repositories/task_repository.dart';
import 'package:taskstack/features/task_stack/domain/usecases/task_usecases.dart';

class _FakeTaskRepository implements TaskRepository {
  final List<Task> insertedTasks = [];
  final List<Task> updatedTasks = [];
  final List<String> deletedTaskIds = [];
  final List<String> deletedRecurringFamilyIds = [];
  final List<String> deletedRecurringFromDateCalls = [];

  @override
  Future<void> deleteRecurringFamily(String parentId) async {
    deletedRecurringFamilyIds.add(parentId);
  }

  @override
  Future<void> deleteRecurringTasksFromDate(
    String parentId,
    DateTime date, {
    bool inclusive = true,
  }) async {
    deletedRecurringFromDateCalls.add(
      '$parentId:${date.toIso8601String()}:$inclusive',
    );
  }

  @override
  Future<void> deleteTask(String id) async {
    deletedTaskIds.add(id);
  }

  @override
  Future<Task?> getTaskById(String id) async => null;

  @override
  Future<List<Task>> getTasksInRange(DateTime from, DateTime to) async => [];

  @override
  Future<void> insertTask(Task task) async {
    insertedTasks.add(task);
  }

  @override
  Future<void> insertTasks(List<Task> tasks) async {
    insertedTasks.addAll(tasks);
  }

  @override
  Stream<List<Task>> watchTasksForDate(DateTime date) async* {
    yield const [];
  }

  @override
  Future<void> updateStatus(
    String id, {
    required String status,
    DateTime? completedAt,
  }) async {}

  @override
  Future<void> updateTask(Task task) async {
    updatedTasks.add(task);
  }

  @override
  Future<List<Task>> getRecurringParents() async => [];

  @override
  Future<List<String>> getInstanceDatesInRange(
    String parentId,
    DateTime from,
    DateTime to,
  ) async => [];

  @override
  Future<void> deleteOldPendingInstances(String parentId, DateTime before) async {}
}

class _FakeNotificationScheduler extends NotificationScheduler {
  final List<String> scheduledTaskIds = [];
  final List<String> cancelledTaskIds = [];

  @override
  Future<void> scheduleFor(Task task) async {
    scheduledTaskIds.add(task.id);
  }

  @override
  Future<void> cancelFor(String taskId) async {
    cancelledTaskIds.add(taskId);
  }
}

class _FakeSyncRepository implements SyncRepository {
  var pushCalls = 0;

  @override
  Future<void> pullCloudToLocal() async {}

  @override
  Future<void> pushLocalToCloud() async {
    pushCalls += 1;
  }
}

Task _task({
  required String id,
  required String title,
  required DateTime taskDate,
  RecurrenceType recurrenceType = RecurrenceType.none,
  String? recurrenceRule,
  int? repeatIntervalMinutes,
  int? startMinutes,
  int? durationMinutes = 30,
  bool notificationEnabled = false,
  String? parentTaskId,
}) {
  final now = DateTime(2030, 1, 1, 12);
  return Task(
    id: id,
    title: title,
    createdAt: now,
    updatedAt: now,
    taskDate: taskDate,
    recurrenceType: recurrenceType,
    recurrenceRule: recurrenceRule,
    repeatIntervalMinutes: repeatIntervalMinutes,
    startMinutes: startMinutes,
    durationMinutes: durationMinutes,
    notificationEnabled: notificationEnabled,
    parentTaskId: parentTaskId,
  );
}

void main() {
  group('CreateTaskUseCase', () {
    test('inserts a single task when recurrence is none', () async {
      final repository = _FakeTaskRepository();
      final scheduler = _FakeNotificationScheduler();
      final useCase = CreateTaskUseCase(repository, scheduler);

      await useCase.execute(
        _task(
          id: '',
          title: 'Write tests',
          taskDate: DateTime(2030, 1, 1),
          startMinutes: 9 * 60,
          notificationEnabled: false,
        ),
      );

      expect(repository.insertedTasks, hasLength(1));
      expect(repository.insertedTasks.single.title, 'Write tests');
      expect(repository.insertedTasks.single.recurrenceType, RecurrenceType.none);
      expect(repository.insertedTasks.single.id, isNotEmpty);
      expect(scheduler.scheduledTaskIds, isEmpty);
    });

    test(
      'generateRepeatInstances creates same-day copies until midnight',
      () async {
        final parent = _task(
          id: 'repeat-parent',
          title: 'Pomodoro',
          taskDate: DateTime(2030, 1, 1),
          recurrenceType: RecurrenceType.repeatToday,
          repeatIntervalMinutes: 120,
          startMinutes: 9 * 60,
          durationMinutes: 30,
        );

        final instances = CreateTaskUseCase.generateRepeatInstances(parent);

        expect(instances, hasLength(7));
        expect(
          instances.map((task) => task.startMinutes).toList(),
          [11 * 60, 13 * 60, 15 * 60, 17 * 60, 19 * 60, 21 * 60, 23 * 60],
        );
        expect(instances.every((task) => task.parentTaskId == 'repeat-parent'), isTrue);
        expect(
          instances.every((task) => task.recurrenceType == RecurrenceType.repeatToday),
          isTrue,
        );
        expect(instances.every((task) => task.taskDate == parent.taskDate), isTrue);
      },
    );

    test(
      'generateFutureInstances creates 365 daily instances and preserves the weekday cadence',
      () async {
        final parent = _task(
          id: 'daily-parent',
          title: 'Daily standup',
          taskDate: DateTime(2030, 1, 1),
          recurrenceType: RecurrenceType.daily,
          startMinutes: 8 * 60,
        );

        final instances = CreateTaskUseCase.generateFutureInstances(parent);

        expect(instances, hasLength(365));
        expect(instances.first.taskDate, DateTime(2030, 1, 2));
        expect(instances.last.taskDate, DateTime(2031, 1, 1));
        expect(instances.every((task) => task.parentTaskId == 'daily-parent'), isTrue);
      },
    );

    test(
      'generateFutureInstances creates 104 weekly instances',
      () async {
        final parent = _task(
          id: 'weekly-parent',
          title: 'Weekly review',
          taskDate: DateTime(2030, 1, 1),
          recurrenceType: RecurrenceType.weekly,
          startMinutes: 18 * 60,
        );

        final instances = CreateTaskUseCase.generateFutureInstances(parent);

        expect(instances, hasLength(104));
        expect(instances.first.taskDate, DateTime(2030, 1, 8));
        expect(instances.last.taskDate, DateTime(2031, 12, 30));
        expect(instances.every((task) => task.parentTaskId == 'weekly-parent'), isTrue);
      },
    );

    test(
      'generateFutureInstances creates only selected custom weekdays',
      () async {
        final parent = _task(
          id: 'custom-parent',
          title: 'Gym',
          taskDate: DateTime(2026, 3, 30),
          recurrenceType: RecurrenceType.custom,
          recurrenceRule: '1,3,5,abc,9',
          startMinutes: 7 * 60,
        );

        final instances = CreateTaskUseCase.generateFutureInstances(parent);

        expect(instances, hasLength(313));
        expect(instances.take(3).map((task) => task.taskDate.weekday), [3, 5, 1]);
        expect(
          instances.every(
            (task) => const [1, 3, 5].contains(task.taskDate.weekday),
          ),
          isTrue,
        );
        expect(instances.every((task) => task.parentTaskId == 'custom-parent'), isTrue);
      },
    );
  });
}
