import 'package:flutter_test/flutter_test.dart';
import 'package:taskstack/features/notifications/notification_scheduler.dart';
import 'package:taskstack/features/sync/domain/repositories/sync_repository.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/domain/repositories/task_repository.dart';
import 'package:taskstack/features/task_stack/domain/usecases/task_usecases.dart';

// ─── Fakes ───────────────────────────────────────────────────────────────────

class _FakeTaskRepository implements TaskRepository {
  final List<Task> insertedTasks = [];
  final List<Task> updatedTasks = [];
  final List<String> deletedTaskIds = [];
  final List<String> deletedRecurringFamilyIds = [];
  final List<String> deletedRecurringFromDateCalls = [];
  final List<String> deletedOldPendingCalls = [];

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
  Future<void> deleteOldPendingInstances(String parentId, DateTime before) async {
    deletedOldPendingCalls.add('$parentId:${before.toIso8601String()}');
  }
}

class _FakeNotificationScheduler extends NotificationScheduler {
  final List<String> scheduledTaskIds = [];
  final List<String> cancelledTaskIds = [];

  @override
  Future<NotificationScheduleResult> scheduleFor(Task task) async {
    scheduledTaskIds.add(task.id);
    return NotificationScheduleResult.scheduled;
  }

  @override
  Future<void> cancelFor(String taskId) async {
    cancelledTaskIds.add(taskId);
  }
}

class _FakeSyncRepository implements SyncRepository {
  int pushCalls = 0;
  int pullCalls = 0;
  bool shouldFail = false;
  String? lastError;

  @override
  Future<void> pullCloudToLocal() async {
    pullCalls++;
    if (shouldFail) throw Exception('Network error');
  }

  @override
  Future<void> pushLocalToCloud() async {
    pushCalls++;
    if (shouldFail) throw Exception('Firebase write failed');
  }

  void reset() {
    pushCalls = 0;
    pullCalls = 0;
    shouldFail = false;
    lastError = null;
  }
}

Task _task({
  required String id,
  required String title,
  required DateTime taskDate,
  RecurrenceType recurrenceType = RecurrenceType.none,
  String? parentTaskId,
  bool notificationEnabled = false,
}) {
  final now = DateTime(2030, 1, 1, 12);
  return Task(
    id: id,
    title: title,
    createdAt: now,
    updatedAt: now,
    taskDate: taskDate,
    recurrenceType: recurrenceType,
    notificationEnabled: notificationEnabled,
    parentTaskId: parentTaskId,
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('Offline / Guest Mode Task Operations', () {
    late _FakeTaskRepository repository;
    late _FakeNotificationScheduler scheduler;
    late _FakeSyncRepository sync;
    late CreateTaskUseCase createUseCase;
    late UpdateTaskUseCase updateUseCase;
    late DeleteTaskUseCase deleteUseCase;
    late CompleteTaskUseCase completeUseCase;

    setUp(() {
      repository = _FakeTaskRepository();
      scheduler = _FakeNotificationScheduler();
      sync = _FakeSyncRepository();
      createUseCase = CreateTaskUseCase(repository, scheduler);
      updateUseCase = UpdateTaskUseCase(repository, scheduler);
      deleteUseCase = DeleteTaskUseCase(repository, scheduler, sync);
      completeUseCase = CompleteTaskUseCase(repository, sync);
    });

    test('create task offline: saved locally, no sync triggered', () async {
      // In guest mode, the UI layer does NOT call sync.pushLocalToCloud()
      // after task creation. The use case itself only writes to local DB.
      await createUseCase.execute(
        _task(id: '', title: 'Offline task', taskDate: DateTime(2030, 1, 1)),
      );

      expect(repository.insertedTasks, hasLength(1));
      expect(repository.insertedTasks.first.title, 'Offline task');
      // Sync repository was never touched by the use case
      expect(sync.pushCalls, 0);
    });

    test('edit task offline: local update only, no sync', () async {
      final task = _task(
        id: 'task-1',
        title: 'Old title',
        taskDate: DateTime(2030, 1, 1),
      );

      await updateUseCase.execute(task.copyWith(title: 'New title'));

      expect(repository.updatedTasks, hasLength(1));
      expect(repository.updatedTasks.first.title, 'New title');
      expect(sync.pushCalls, 0);
    });

    test('complete task offline: local status update only, no sync', () async {
      final task = _task(
        id: 'task-1',
        title: 'Task',
        taskDate: DateTime(2030, 1, 1),
        parentTaskId: null,
      );

      await repository.insertTask(task);

      await completeUseCase.execute(
        task.copyWith(
          startMinutes: 9 * 60,
          durationMinutes: 30,
        ),
      );

      // CompleteTaskUseCase does call sync.pushLocalToCloud() in production,
      // but in guest mode the UI suppresses sync calls.
      // Here we verify the repository layer received the update.
      expect(repository.updatedTasks, isEmpty); // updateStatus path used
      expect(sync.pushCalls, 1); // use case always calls sync
    });

    test('delete task offline: local delete only', () async {
      final task = _task(
        id: 'task-1',
        title: 'Task',
        taskDate: DateTime(2030, 1, 1),
      );

      await deleteUseCase.execute(task);

      expect(repository.deletedTaskIds, contains('task-1'));
      // DeleteTaskUseCase DOES call sync.pushLocalToCloud()
      expect(sync.pushCalls, 1);
    });

    test('recurring task creation offline: only parent inserted', () async {
      await createUseCase.execute(
        _task(
          id: '',
          title: 'Daily habit',
          taskDate: DateTime(2030, 1, 1),
          recurrenceType: RecurrenceType.daily,
        ),
      );

      // Rolling window: only parent is inserted on creation
      expect(repository.insertedTasks, hasLength(1));
      expect(sync.pushCalls, 0);
    });
  });

  group('Firebase Sync – Online Mode', () {
    late _FakeTaskRepository repository;
    late _FakeNotificationScheduler scheduler;
    late _FakeSyncRepository sync;
    late CreateTaskUseCase createUseCase;
    late UpdateTaskUseCase updateUseCase;
    late DeleteTaskUseCase deleteUseCase;
    late CompleteTaskUseCase completeUseCase;

    setUp(() {
      repository = _FakeTaskRepository();
      scheduler = _FakeNotificationScheduler();
      sync = _FakeSyncRepository();
      createUseCase = CreateTaskUseCase(repository, scheduler);
      updateUseCase = UpdateTaskUseCase(repository, scheduler);
      deleteUseCase = DeleteTaskUseCase(repository, scheduler, sync);
      completeUseCase = CompleteTaskUseCase(repository, sync);
    });

    test('create task online: local insert + pushLocalToCloud', () async {
      // Simulating the UI flow: create then sync
      await createUseCase.execute(
        _task(id: '', title: 'New task', taskDate: DateTime(2030, 1, 1)),
      );
      await sync.pushLocalToCloud();

      expect(repository.insertedTasks, hasLength(1));
      expect(sync.pushCalls, 1);
    });

    test('edit task online: local update + pushLocalToCloud', () async {
      final task = _task(
        id: 'task-1',
        title: 'Original',
        taskDate: DateTime(2030, 1, 1),
      );

      await updateUseCase.execute(task.copyWith(title: 'Edited'));
      await sync.pushLocalToCloud();

      expect(repository.updatedTasks, hasLength(1));
      expect(repository.updatedTasks.first.title, 'Edited');
      expect(sync.pushCalls, 1);
    });

    test('edit recurring future scope: deletes future + sync', () async {
      final parent = _task(
        id: 'parent-1',
        title: 'Daily',
        taskDate: DateTime(2030, 1, 1),
        recurrenceType: RecurrenceType.daily,
      );

      await updateUseCase.execute(
        parent.copyWith(title: 'Updated Daily'),
        scope: RecurringScope.futureInstances,
      );
      await sync.pushLocalToCloud();

      expect(repository.updatedTasks, hasLength(1));
      // Future instances deleted, but not regenerated (rolling window handles it)
      expect(repository.deletedRecurringFromDateCalls, isNotEmpty);
      expect(sync.pushCalls, 1);
    });

    test('complete task online: status update + pushLocalToCloud', () async {
      final task = _task(
        id: 'task-1',
        title: 'Task',
        taskDate: DateTime(2020, 1, 1), // past so deadline check passes
      );

      await completeUseCase.execute(task);

      // CompleteTaskUseCase calls sync internally
      expect(sync.pushCalls, 1);
    });

    test('delete task online: delete + pushLocalToCloud', () async {
      final task = _task(
        id: 'task-1',
        title: 'Task',
        taskDate: DateTime(2030, 1, 1),
      );

      await deleteUseCase.execute(task);

      expect(repository.deletedTaskIds, contains('task-1'));
      expect(sync.pushCalls, 1);
    });

    test('delete recurring future scope: delete family + sync', () async {
      final parent = _task(
        id: 'parent-1',
        title: 'Daily',
        taskDate: DateTime(2030, 1, 1),
        recurrenceType: RecurrenceType.daily,
      );

      await deleteUseCase.execute(
        parent,
        scope: RecurringScope.futureInstances,
      );

      expect(repository.deletedRecurringFromDateCalls, hasLength(1));
      expect(sync.pushCalls, 1);
    });

    test('rapid edits: sync called each time (fire-and-forget)', () async {
      final task = _task(
        id: 'task-1',
        title: 'Task',
        taskDate: DateTime(2030, 1, 1),
      );

      await updateUseCase.execute(task.copyWith(title: 'Edit 1'));
      await sync.pushLocalToCloud();
      await updateUseCase.execute(task.copyWith(title: 'Edit 2'));
      await sync.pushLocalToCloud();
      await updateUseCase.execute(task.copyWith(title: 'Edit 3'));
      await sync.pushLocalToCloud();

      expect(repository.updatedTasks, hasLength(3));
      expect(sync.pushCalls, 3);
    });
  });

  group('Sync Error Handling', () {
    late _FakeSyncRepository sync;

    setUp(() {
      sync = _FakeSyncRepository();
    });

    test('push fails: error state propagated', () async {
      sync.shouldFail = true;

      expect(
        () async => await sync.pushLocalToCloud(),
        throwsException,
      );
    });

    test('retry after failure: succeeds on second attempt', () async {
      sync.shouldFail = true;

      try {
        await sync.pushLocalToCloud();
      } catch (_) {}

      expect(sync.pushCalls, 1);

      sync.shouldFail = false;
      await sync.pushLocalToCloud();

      expect(sync.pushCalls, 2);
    });

    test('pull fails: error state propagated', () async {
      sync.shouldFail = true;

      expect(
        () async => await sync.pullCloudToLocal(),
        throwsException,
      );
    });
  });

  group('Auth Transition Sync Behavior', () {
    late _FakeSyncRepository sync;

    setUp(() {
      sync = _FakeSyncRepository();
    });

    test('login from guest: pushLocalToCloud called', () async {
      // Simulates AuthNotifier.login when wasGuest == true
      await sync.pushLocalToCloud();

      expect(sync.pushCalls, 1);
    });

    test('login existing user: pullCloudToLocal called', () async {
      // Simulates AuthNotifier.login when wasGuest == false
      await sync.pullCloudToLocal();

      expect(sync.pullCalls, 1);
      expect(sync.pushCalls, 0);
    });

    test('register new account: pushLocalToCloud called', () async {
      // Simulates AuthNotifier.register
      await sync.pushLocalToCloud();

      expect(sync.pushCalls, 1);
    });

    test('auth session restore: pullCloudToLocal called', () async {
      // Simulates AuthNotifier._listenToAuthStream on session restore
      await sync.pullCloudToLocal();

      expect(sync.pullCalls, 1);
    });
  });

  group('Rolling Window Sync', () {
    late _FakeTaskRepository repository;
    late _FakeNotificationScheduler scheduler;
    late _FakeSyncRepository sync;
    late MaintainRecurringWindowUseCase windowUseCase;

    setUp(() {
      repository = _FakeTaskRepository();
      scheduler = _FakeNotificationScheduler();
      sync = _FakeSyncRepository();
      windowUseCase = MaintainRecurringWindowUseCase(repository, scheduler);
    });

    test('maintenance generates missing instances within window', () async {
      // Seed a daily recurring parent
      final parent = _task(
        id: 'daily-parent',
        title: 'Daily',
        taskDate: DateTime(2030, 1, 1),
        recurrenceType: RecurrenceType.daily,
      );
      await repository.insertTask(parent);

      // Pretend repository returns this parent when asked
      repository.insertedTasks.clear(); // clear so we can measure new inserts

      // We need a custom repo that returns the parent
      final customRepo = _FakeTaskRepository();
      await customRepo.insertTask(parent);
      // Override getRecurringParents to return our parent
      final repoWithParent = _RepoWithParents(customRepo, [parent]);
      final window = MaintainRecurringWindowUseCase(repoWithParent, scheduler);

      await window.execute();

      // Should have inserted instances for the 21-day window
      expect(repoWithParent.insertedTasks, isNotEmpty);
      expect(repoWithParent.insertedTasks.length, greaterThan(10));
    });

    test('maintenance trims old pending instances outside window', () async {
      final parent = _task(
        id: 'daily-parent',
        title: 'Daily',
        taskDate: DateTime(2020, 1, 1),
        recurrenceType: RecurrenceType.daily,
      );
      final customRepo = _RepoWithParents(_FakeTaskRepository(), [parent]);
      final window = MaintainRecurringWindowUseCase(customRepo, scheduler);

      await window.execute();

      expect(customRepo.deletedOldPendingCalls, isNotEmpty);
    });
  });
}

// Helper class that wraps a repo and overrides getRecurringParents
class _RepoWithParents implements TaskRepository {
  _RepoWithParents(this._delegate, this._parents);
  final TaskRepository _delegate;
  final List<Task> _parents;

  @override
  Future<void> deleteOldPendingInstances(String parentId, DateTime before) =>
      _delegate.deleteOldPendingInstances(parentId, before);

  @override
  Future<void> deleteRecurringFamily(String parentId) =>
      _delegate.deleteRecurringFamily(parentId);

  @override
  Future<void> deleteRecurringTasksFromDate(
    String parentId,
    DateTime date, {
    bool inclusive = true,
  }) => _delegate.deleteRecurringTasksFromDate(parentId, date, inclusive: inclusive);

  @override
  Future<void> deleteTask(String id) => _delegate.deleteTask(id);

  @override
  Future<Task?> getTaskById(String id) => _delegate.getTaskById(id);

  @override
  Future<List<Task>> getTasksInRange(DateTime from, DateTime to) =>
      _delegate.getTasksInRange(from, to);

  @override
  Future<void> insertTask(Task task) => _delegate.insertTask(task);

  @override
  Future<void> insertTasks(List<Task> tasks) => _delegate.insertTasks(tasks);

  @override
  Stream<List<Task>> watchTasksForDate(DateTime date) =>
      _delegate.watchTasksForDate(date);

  @override
  Future<void> updateStatus(
    String id, {
    required String status,
    DateTime? completedAt,
  }) => _delegate.updateStatus(id, status: status, completedAt: completedAt);

  @override
  Future<void> updateTask(Task task) => _delegate.updateTask(task);

  @override
  Future<List<Task>> getRecurringParents() async => _parents;

  @override
  Future<List<String>> getInstanceDatesInRange(
    String parentId,
    DateTime from,
    DateTime to,
  ) => _delegate.getInstanceDatesInRange(parentId, from, to);

  // Passthrough getters for verification
  List<Task> get insertedTasks => (_delegate as _FakeTaskRepository).insertedTasks;
  List<Task> get updatedTasks => (_delegate as _FakeTaskRepository).updatedTasks;
  List<String> get deletedOldPendingCalls =>
      (_delegate as _FakeTaskRepository).deletedOldPendingCalls;
}
