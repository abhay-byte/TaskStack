import 'package:flutter_test/flutter_test.dart';
import 'package:taskstack/features/notifications/notification_scheduler.dart';
import 'package:taskstack/features/sync/domain/repositories/sync_repository.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/domain/repositories/task_repository.dart';
import 'package:taskstack/features/task_stack/domain/usecases/task_usecases.dart';

class _FakeTaskRepository implements TaskRepository {
  final List<String> deletedTaskIds = [];
  final List<String> deletedFamilyIds = [];

  @override
  Future<void> deleteRecurringFamily(String parentId) async {
    deletedFamilyIds.add(parentId);
  }

  @override
  Future<void> deleteRecurringTasksFromDate(
    String parentId,
    DateTime date, {
    bool inclusive = true,
  }) async {
    deletedFamilyIds.add('$parentId:${date.toIso8601String()}:$inclusive');
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
  Future<void> insertTask(Task task) async {}

  @override
  Future<void> insertTasks(List<Task> tasks) async {}

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
  Future<void> updateTask(Task task) async {}

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
  final List<String> cancelledIds = [];

  @override
  Future<void> cancelFor(String taskId) async {
    cancelledIds.add(taskId);
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
  RecurrenceType recurrenceType = RecurrenceType.none,
  String? parentTaskId,
}) {
  final now = DateTime(2026, 3, 30, 10);
  return Task(
    id: id,
    title: 'Task',
    recurrenceType: recurrenceType,
    parentTaskId: parentTaskId,
    createdAt: now,
    updatedAt: now,
    taskDate: DateTime(2026, 3, 30),
  );
}

void main() {
  group('DeleteTaskUseCase', () {
    test('pushes sync immediately after deleting a single task', () async {
      final repository = _FakeTaskRepository();
      final scheduler = _FakeNotificationScheduler();
      final syncRepository = _FakeSyncRepository();
      final useCase = DeleteTaskUseCase(repository, scheduler, syncRepository);

      await useCase.execute(_task(id: 'task-1'));

      expect(repository.deletedTaskIds, ['task-1']);
      expect(scheduler.cancelledIds, ['task-1']);
      expect(syncRepository.pushCalls, 1);
    });

    test(
      'pushes sync immediately after deleting future recurring instances',
      () async {
        final repository = _FakeTaskRepository();
        final scheduler = _FakeNotificationScheduler();
        final syncRepository = _FakeSyncRepository();
        final useCase = DeleteTaskUseCase(
          repository,
          scheduler,
          syncRepository,
        );

        await useCase.execute(
          _task(id: 'task-2', recurrenceType: RecurrenceType.daily),
          scope: RecurringScope.futureInstances,
        );

        expect(repository.deletedFamilyIds, hasLength(1));
        expect(syncRepository.pushCalls, 1);
      },
    );
  });
}
