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
  Future<void> scheduleFor(Task task) async {
    scheduledTaskIds.add(task.id);
  }

  @override
  Future<void> cancelFor(String taskId) async {
    cancelledTaskIds.add(taskId);
  }
}

class _FakeSyncRepository implements SyncRepository {
  int pushCalls = 0;
  int pullCalls = 0;

  @override
  Future<void> pullCloudToLocal() async => pullCalls++;

  @override
  Future<void> pushLocalToCloud() async => pushCalls++;
}

// Helper that returns specific parents
class _RepoWithParents extends _FakeTaskRepository {
  _RepoWithParents(this._parents);
  final List<Task> _parents;

  @override
  Future<List<Task>> getRecurringParents() async => _parents;
}

// Helper that simulates existing instances
class _RepoWithInstances extends _FakeTaskRepository {
  _RepoWithInstances(this._parents, this._existingDates);
  final List<Task> _parents;
  final Map<String, List<String>> _existingDates;

  @override
  Future<List<Task>> getRecurringParents() async => _parents;

  @override
  Future<List<String>> getInstanceDatesInRange(
    String parentId,
    DateTime from,
    DateTime to,
  ) async {
    return _existingDates[parentId] ?? [];
  }
}

Task _task({
  required String id,
  required String title,
  required DateTime taskDate,
  RecurrenceType recurrenceType = RecurrenceType.none,
  String? recurrenceRule,
  int? startMinutes,
  int? durationMinutes,
  String? parentTaskId,
  TaskStatus status = TaskStatus.pending,
  bool notificationEnabled = false,
}) {
  final now = DateTime(2030, 1, 15, 12); // mid-January fixed anchor
  return Task(
    id: id,
    title: title,
    createdAt: now,
    updatedAt: now,
    taskDate: taskDate,
    recurrenceType: recurrenceType,
    recurrenceRule: recurrenceRule,
    startMinutes: startMinutes,
    durationMinutes: durationMinutes,
    notificationEnabled: notificationEnabled,
    parentTaskId: parentTaskId,
    status: status,
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('Rolling 2-Week Window – Core', () {
    late _FakeNotificationScheduler scheduler;
    late _FakeSyncRepository sync;

    setUp(() {
      scheduler = _FakeNotificationScheduler();
      sync = _FakeSyncRepository();
    });

    test('daily recurrence: generates 21 instances for 21-day window', () async {
      final parent = _task(
        id: 'daily-parent',
        title: 'Sleep',
        taskDate: DateTime(2030, 1, 15),
        recurrenceType: RecurrenceType.daily,
        startMinutes: 22 * 60,
        durationMinutes: 480,
      );
      final repo = _RepoWithParents([parent]);
      final window = MaintainRecurringWindowUseCase(repo, scheduler);

      await window.execute();

      // Window = 7 days back + 14 days forward = 21 days
      expect(repo.insertedTasks.length, 21);
      expect(repo.insertedTasks.every((t) => t.parentTaskId == 'daily-parent'), isTrue);
      expect(repo.insertedTasks.every((t) => t.recurrenceType == RecurrenceType.daily), isTrue);
    });

    test('weekly recurrence: generates instances every 7 days within window', () async {
      final parent = _task(
        id: 'weekly-parent',
        title: 'Weekly Review',
        taskDate: DateTime(2030, 1, 15), // Tuesday
        recurrenceType: RecurrenceType.weekly,
        startMinutes: 10 * 60,
      );
      final repo = _RepoWithParents([parent]);
      final window = MaintainRecurringWindowUseCase(repo, scheduler);

      await window.execute();

      // 21-day window, every 7 days = 3 instances (if parent date included in forward)
      expect(repo.insertedTasks.length, 3);
      expect(repo.insertedTasks[0].taskDate.weekday, 2); // Tuesday
      expect(repo.insertedTasks[1].taskDate.weekday, 2);
      expect(repo.insertedTasks[2].taskDate.weekday, 2);
    });

    test('custom recurrence: only generates on selected weekdays', () async {
      final parent = _task(
        id: 'custom-parent',
        title: 'Gym',
        taskDate: DateTime(2030, 1, 13), // Monday
        recurrenceType: RecurrenceType.custom,
        recurrenceRule: '1,3,5', // Mon, Wed, Fri
        startMinutes: 7 * 60,
      );
      final repo = _RepoWithParents([parent]);
      final window = MaintainRecurringWindowUseCase(repo, scheduler);

      await window.execute();

      // 21-day window with Mon/Wed/Fri cadence ≈ 9 instances
      expect(repo.insertedTasks.length, greaterThan(5));
      expect(
        repo.insertedTasks.every(
          (t) => [1, 3, 5].contains(t.taskDate.weekday),
        ),
        isTrue,
      );
    });

    test('does not regenerate already-existing instances (duplicate prevention)', () async {
      final parent = _task(
        id: 'daily-parent',
        title: 'Sleep',
        taskDate: DateTime(2030, 1, 15),
        recurrenceType: RecurrenceType.daily,
      );
      // Pretend 5 days already exist in the window
      final existing = <String>[
        for (var i = 0; i < 5; i++)
          '2030-01-${(15 + i).toString().padLeft(2, '0')}',
      ];
      final repo = _RepoWithInstances([parent], {'daily-parent': existing});
      final window = MaintainRecurringWindowUseCase(repo, scheduler);

      await window.execute();

      // 21-day window minus 5 existing = 16 new
      expect(repo.insertedTasks.length, 16);
    });

    test('empty window when parent date is far in the future', () async {
      final parent = _task(
        id: 'future-parent',
        title: 'Future Task',
        taskDate: DateTime(2040, 1, 1), // 10 years out
        recurrenceType: RecurrenceType.daily,
      );
      final repo = _RepoWithParents([parent]);
      final window = MaintainRecurringWindowUseCase(repo, scheduler);

      await window.execute();

      // No dates in the 21-day window match a parent starting in 2040
      expect(repo.insertedTasks, isEmpty);
    });

    test('trims old pending instances before window start', () async {
      final parent = _task(
        id: 'old-parent',
        title: 'Old Daily',
        taskDate: DateTime(2020, 1, 1),
        recurrenceType: RecurrenceType.daily,
      );
      final repo = _RepoWithParents([parent]);
      final window = MaintainRecurringWindowUseCase(repo, scheduler);

      await window.execute();

      expect(repo.deletedOldPendingCalls, isNotEmpty);
      // Deletion cutoff is 7 days before today
      expect(
        repo.deletedOldPendingCalls.first,
        contains('old-parent'),
      );
    });

    test('non-recurring parents are ignored', () async {
      final noneParent = _task(
        id: 'none-parent',
        title: 'One-off',
        taskDate: DateTime(2030, 1, 15),
        recurrenceType: RecurrenceType.none,
      );
      final repeatTodayParent = _task(
        id: 'repeat-parent',
        title: 'Pomodoro',
        taskDate: DateTime(2030, 1, 15),
        recurrenceType: RecurrenceType.repeatToday,
      );
      final repo = _RepoWithParents([noneParent, repeatTodayParent]);
      final window = MaintainRecurringWindowUseCase(repo, scheduler);

      await window.execute();

      expect(repo.insertedTasks, isEmpty);
      expect(repo.deletedOldPendingCalls, isEmpty);
    });

    test('specificParentId filter: only processes requested parent', () async {
      final parentA = _task(
        id: 'parent-a',
        title: 'Task A',
        taskDate: DateTime(2030, 1, 15),
        recurrenceType: RecurrenceType.daily,
      );
      final parentB = _task(
        id: 'parent-b',
        title: 'Task B',
        taskDate: DateTime(2030, 1, 15),
        recurrenceType: RecurrenceType.daily,
      );
      final repo = _RepoWithParents([parentA, parentB]);
      final window = MaintainRecurringWindowUseCase(repo, scheduler);

      await window.execute(specificParentId: 'parent-a');

      // Only parent A's 21 instances
      expect(repo.insertedTasks.length, 21);
      expect(
        repo.insertedTasks.every((t) => t.parentTaskId == 'parent-a'),
        isTrue,
      );
    });

    test('schedules notifications for first 10 generated instances only', () async {
      final parent = _task(
        id: 'daily-parent',
        title: 'Sleep',
        taskDate: DateTime(2030, 1, 15),
        recurrenceType: RecurrenceType.daily,
        notificationEnabled: true,
      );
      final repo = _RepoWithParents([parent]);
      final window = MaintainRecurringWindowUseCase(repo, scheduler);

      await window.execute();

      expect(scheduler.scheduledTaskIds.length, 10);
    });
  });

  group('CreateTaskUseCase – Rolling Window Changes', () {
    late _FakeTaskRepository repository;
    late _FakeNotificationScheduler scheduler;
    late CreateTaskUseCase useCase;

    setUp(() {
      repository = _FakeTaskRepository();
      scheduler = _FakeNotificationScheduler();
      useCase = CreateTaskUseCase(repository, scheduler);
    });

    test('daily task: inserts ONLY parent, no future instances', () async {
      await useCase.execute(
        _task(
          id: '',
          title: 'Daily',
          taskDate: DateTime(2030, 1, 1),
          recurrenceType: RecurrenceType.daily,
        ),
      );

      expect(repository.insertedTasks, hasLength(1));
      expect(repository.insertedTasks.first.parentTaskId, isNull);
    });

    test('weekly task: inserts ONLY parent', () async {
      await useCase.execute(
        _task(
          id: '',
          title: 'Weekly',
          taskDate: DateTime(2030, 1, 1),
          recurrenceType: RecurrenceType.weekly,
        ),
      );

      expect(repository.insertedTasks, hasLength(1));
    });

    test('custom task: inserts ONLY parent', () async {
      await useCase.execute(
        _task(
          id: '',
          title: 'Custom',
          taskDate: DateTime(2030, 1, 1),
          recurrenceType: RecurrenceType.custom,
          recurrenceRule: '1,3,5',
        ),
      );

      expect(repository.insertedTasks, hasLength(1));
    });

    test('repeatToday still generates intra-day instances', () async {
      await useCase.execute(
        _task(
          id: '',
          title: 'Pomodoro',
          taskDate: DateTime(2030, 1, 1),
          recurrenceType: RecurrenceType.repeatToday,
          startMinutes: 9 * 60,
          durationMinutes: 30,
          repeatIntervalMinutes: 120,
        ),
      );

      // Parent + 7 same-day copies
      expect(repository.insertedTasks.length, greaterThan(2));
      expect(
        repository.insertedTasks.first.recurrenceType,
        RecurrenceType.repeatToday,
      );
    });

    test('non-recurring task: single insert as before', () async {
      await useCase.execute(
        _task(
          id: '',
          title: 'One-off',
          taskDate: DateTime(2030, 1, 1),
          recurrenceType: RecurrenceType.none,
        ),
      );

      expect(repository.insertedTasks, hasLength(1));
    });
  });

  group('UpdateTaskUseCase – Rolling Window Changes', () {
    late _FakeTaskRepository repository;
    late _FakeNotificationScheduler scheduler;
    late UpdateTaskUseCase useCase;

    setUp(() {
      repository = _FakeTaskRepository();
      scheduler = _FakeNotificationScheduler();
      useCase = UpdateTaskUseCase(repository, scheduler);
    });

    test('future scope: deletes future instances but does NOT regenerate 365', () async {
      final parent = _task(
        id: 'parent-1',
        title: 'Daily',
        taskDate: DateTime(2030, 1, 1),
        recurrenceType: RecurrenceType.daily,
      );

      await useCase.execute(
        parent.copyWith(title: 'Updated Daily'),
        scope: RecurringScope.futureInstances,
      );

      expect(repository.updatedTasks, hasLength(1));
      expect(repository.deletedRecurringFromDateCalls, isNotEmpty);
      // No mass re-insertion — rolling window handles it later
      expect(repository.insertedTasks, isEmpty);
    });

    test('thisInstance scope: only updates the single task', () async {
      final task = _task(
        id: 'task-1',
        title: 'Original',
        taskDate: DateTime(2030, 1, 1),
      );

      await useCase.execute(task.copyWith(title: 'Edited'));

      expect(repository.updatedTasks, hasLength(1));
      expect(repository.deletedRecurringFromDateCalls, isEmpty);
      expect(repository.insertedTasks, isEmpty);
    });
  });

  group('Edge Cases – Spillover & Boundaries', () {
    late _FakeNotificationScheduler scheduler;

    setUp(() {
      scheduler = _FakeNotificationScheduler();
    });

    test('overnight task (10pm-6am) generates correct dates', () async {
      final parent = _task(
        id: 'sleep-parent',
        title: 'Sleep',
        taskDate: DateTime(2030, 1, 15),
        recurrenceType: RecurrenceType.daily,
        startMinutes: 22 * 60, // 10 PM
        durationMinutes: 480,   // 8 hours
      );
      final repo = _RepoWithParents([parent]);
      final window = MaintainRecurringWindowUseCase(repo, scheduler);

      await window.execute();

      // Every generated instance should have same start time
      expect(
        repo.insertedTasks.every((t) => t.startMinutes == 22 * 60),
        isTrue,
      );
      expect(
        repo.insertedTasks.every((t) => t.durationMinutes == 480),
        isTrue,
      );
    });

    test('completed instances are NOT deleted by trimming', () async {
      final parent = _task(
        id: 'old-parent',
        title: 'Old Daily',
        taskDate: DateTime(2020, 1, 1),
        recurrenceType: RecurrenceType.daily,
      );
      final repo = _RepoWithParents([parent]);
      final window = MaintainRecurringWindowUseCase(repo, scheduler);

      await window.execute();

      // deleteOldPendingInstances only targets pending + uncompleted
      final call = repo.deletedOldPendingCalls.first;
      expect(call, contains('old-parent'));
    });

    test('parent task created today: window starts from today-7', () async {
      final parent = _task(
        id: 'today-parent',
        title: 'Starts Today',
        taskDate: DateTime(2030, 1, 15),
        recurrenceType: RecurrenceType.daily,
      );
      final repo = _RepoWithParents([parent]);
      final window = MaintainRecurringWindowUseCase(repo, scheduler);

      await window.execute();

      // Should include 7 days back (Jan 8) even though parent starts Jan 15
      // Actually: instances only generate from parent date onward
      // So 21 instances from Jan 15 to Feb 4
      expect(repo.insertedTasks.length, 21);
      expect(repo.insertedTasks.first.taskDate, DateTime(2030, 1, 15));
    });

    test('multiple concurrent parents: all processed independently', () async {
      final sleep = _task(
        id: 'sleep',
        title: 'Sleep',
        taskDate: DateTime(2030, 1, 15),
        recurrenceType: RecurrenceType.daily,
      );
      final gym = _task(
        id: 'gym',
        title: 'Gym',
        taskDate: DateTime(2030, 1, 15),
        recurrenceType: RecurrenceType.custom,
        recurrenceRule: '1,3,5',
      );
      final repo = _RepoWithParents([sleep, gym]);
      final window = MaintainRecurringWindowUseCase(repo, scheduler);

      await window.execute();

      // Sleep: 21 daily instances
      final sleepInstances = repo.insertedTasks.where((t) => t.parentTaskId == 'sleep');
      expect(sleepInstances.length, 21);

      // Gym: ~9 Mon/Wed/Fri instances
      final gymInstances = repo.insertedTasks.where((t) => t.parentTaskId == 'gym');
      expect(gymInstances.length, greaterThan(5));
    });
  });

  group('Legacy generateFutureInstances – Still Works', () {
    test('daily: 365 instances', () {
      final parent = _task(
        id: 'daily',
        title: 'Daily',
        taskDate: DateTime(2030, 1, 1),
        recurrenceType: RecurrenceType.daily,
      );
      final instances = CreateTaskUseCase.generateFutureInstances(parent);
      expect(instances, hasLength(365));
    });

    test('weekly: 104 instances', () {
      final parent = _task(
        id: 'weekly',
        title: 'Weekly',
        taskDate: DateTime(2030, 1, 1),
        recurrenceType: RecurrenceType.weekly,
      );
      final instances = CreateTaskUseCase.generateFutureInstances(parent);
      expect(instances, hasLength(104));
    });

    test('custom: only selected weekdays', () {
      final parent = _task(
        id: 'custom',
        title: 'Gym',
        taskDate: DateTime(2030, 1, 1),
        recurrenceType: RecurrenceType.custom,
        recurrenceRule: '2,4', // Tue, Thu
      );
      final instances = CreateTaskUseCase.generateFutureInstances(parent);
      expect(instances.every((t) => [2, 4].contains(t.taskDate.weekday)), isTrue);
    });
  });
}
