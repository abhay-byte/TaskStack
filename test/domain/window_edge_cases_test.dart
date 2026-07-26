import 'package:flutter_test/flutter_test.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/domain/repositories/task_repository.dart';
import 'package:taskstack/features/task_stack/domain/usecases/task_usecases.dart';
import 'package:taskstack/features/notifications/notification_scheduler.dart';

// ─── Fakes ───────────────────────────────────────────────────────────────────

class _FakeRepo implements TaskRepository {
  final List<Task> insertedTasks = [];
  final List<Task> updatedTasks = [];
  final List<String> deletedTaskIds = [];
  final List<String> deletedRecurringFamilyIds = [];
  final List<String> deletedRecurringFromDateCalls = [];
  final List<String> deletedOldPendingCalls = [];
  final Map<String, List<String>> _instanceDates = {};
  final List<Task> _parents = [];

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
  Future<List<Task>> getRecurringParents() async => _parents;

  @override
  Future<List<String>> getInstanceDatesInRange(
    String parentId,
    DateTime from,
    DateTime to,
  ) async {
    return _instanceDates[parentId] ?? [];
  }

  @override
  Future<void> deleteOldPendingInstances(String parentId, DateTime before) async {
    deletedOldPendingCalls.add('$parentId:${before.toIso8601String()}');
  }

  void seedParent(Task parent) => _parents.add(parent);

  void seedInstances(String parentId, List<String> dates) {
    _instanceDates[parentId] = dates;
  }
}

class _FakeScheduler extends NotificationScheduler {
  final List<String> scheduledIds = [];
  @override
  Future<NotificationScheduleResult> scheduleFor(Task task) async {
    scheduledIds.add(task.id);
    return NotificationScheduleResult.scheduled;
  }
  @override
  Future<void> cancelFor(String taskId) async {}
}

Task _parent({
  required String id,
  required DateTime taskDate,
  RecurrenceType type = RecurrenceType.daily,
  String? rule,
}) => Task(
  id: id,
  title: 'Parent',
  taskDate: taskDate,
  recurrenceType: type,
  recurrenceRule: rule,
  createdAt: DateTime(2030, 1, 15),
  updatedAt: DateTime(2030, 1, 15),
);

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('MaintainRecurringWindowUseCase – Full Matrix', () {
    late _FakeRepo repo;
    late _FakeScheduler scheduler;
    late MaintainRecurringWindowUseCase window;

    setUp(() {
      repo = _FakeRepo();
      scheduler = _FakeScheduler();
      window = MaintainRecurringWindowUseCase(repo, scheduler);
    });

    test('E1: fresh daily parent, empty window → 21 inserts', () async {
      repo.seedParent(_parent(id: 'p1', taskDate: DateTime(2030, 1, 15)));

      await window.execute();

      expect(repo.insertedTasks.length, 21);
      expect(repo.deletedOldPendingCalls, isNotEmpty); // trim also runs
    });

    test('E2: all 21 days already exist → 0 inserts', () async {
      repo.seedParent(_parent(id: 'p1', taskDate: DateTime(2030, 1, 15)));
      repo.seedInstances(
        'p1',
        [for (var i = -7; i <= 14; i++) '2030-01-${(15 + i).toString().padLeft(2, '0')}'],
      );

      await window.execute();

      expect(repo.insertedTasks, isEmpty);
    });

    test('E3: partial overlap (10 exist, 11 missing) → 11 inserts', () async {
      repo.seedParent(_parent(id: 'p1', taskDate: DateTime(2030, 1, 15)));
      repo.seedInstances(
        'p1',
        [for (var i = 0; i < 10; i++) '2030-01-${(15 + i).toString().padLeft(2, '0')}'],
      );

      await window.execute();

      expect(repo.insertedTasks.length, 11);
    });

    test('E4: parent date in future beyond window → 0 inserts', () async {
      repo.seedParent(_parent(id: 'p1', taskDate: DateTime(2040, 1, 1)));

      await window.execute();

      expect(repo.insertedTasks, isEmpty);
      expect(repo.deletedOldPendingCalls, isNotEmpty);
    });

    test('E5: parent date far in past, no existing instances → 21 inserts', () async {
      repo.seedParent(_parent(id: 'p1', taskDate: DateTime(2020, 1, 1)));

      await window.execute();

      expect(repo.insertedTasks.length, 21);
    });

    test('E6: weekly parent in 21-day window → 3 inserts (week 0, 1, 2)', () async {
      repo.seedParent(
        _parent(
          id: 'p1',
          taskDate: DateTime(2030, 1, 15),
          type: RecurrenceType.weekly,
        ),
      );

      await window.execute();

      expect(repo.insertedTasks.length, 3);
      expect(repo.insertedTasks[0].taskDate, DateTime(2030, 1, 22));
      expect(repo.insertedTasks[1].taskDate, DateTime(2030, 1, 29));
      expect(repo.insertedTasks[2].taskDate, DateTime(2030, 2, 5));
    });

    test('E7: custom Mon/Wed/Fri → correct weekday filter', () async {
      repo.seedParent(
        _parent(
          id: 'p1',
          taskDate: DateTime(2030, 1, 14), // Monday
          type: RecurrenceType.custom,
          rule: '1,3,5',
        ),
      );

      await window.execute();

      expect(repo.insertedTasks.every((t) => [1, 3, 5].contains(t.taskDate.weekday)), isTrue);
    });

    test('E8: repeatToday parent is skipped by window maintenance', () async {
      repo.seedParent(
        _parent(
          id: 'p1',
          taskDate: DateTime(2030, 1, 15),
          type: RecurrenceType.repeatToday,
        ),
      );

      await window.execute();

      expect(repo.insertedTasks, isEmpty);
      expect(repo.deletedOldPendingCalls, isEmpty);
    });

    test('E9: none-recurring parent is skipped', () async {
      repo.seedParent(
        _parent(
          id: 'p1',
          taskDate: DateTime(2030, 1, 15),
          type: RecurrenceType.none,
        ),
      );

      await window.execute();

      expect(repo.insertedTasks, isEmpty);
    });

    test('E10: multiple mixed parents processed correctly', () async {
      repo.seedParent(_parent(id: 'daily', taskDate: DateTime(2030, 1, 15)));
      repo.seedParent(
        _parent(
          id: 'weekly',
          taskDate: DateTime(2030, 1, 15),
          type: RecurrenceType.weekly,
        ),
      );
      repo.seedParent(
        _parent(
          id: 'custom',
          taskDate: DateTime(2030, 1, 14),
          type: RecurrenceType.custom,
          rule: '1,3,5',
        ),
      );

      await window.execute();

      final daily = repo.insertedTasks.where((t) => t.parentTaskId == 'daily');
      final weekly = repo.insertedTasks.where((t) => t.parentTaskId == 'weekly');
      final custom = repo.insertedTasks.where((t) => t.parentTaskId == 'custom');

      expect(daily.length, 21);
      expect(weekly.length, 3);
      expect(custom.length, greaterThan(5));
    });

    test('E11: specificParentId filters to single parent', () async {
      repo.seedParent(_parent(id: 'a', taskDate: DateTime(2030, 1, 15)));
      repo.seedParent(_parent(id: 'b', taskDate: DateTime(2030, 1, 15)));

      await window.execute(specificParentId: 'b');

      expect(repo.insertedTasks.every((t) => t.parentTaskId == 'b'), isTrue);
      expect(repo.insertedTasks.length, 21);
    });

    test('E12: generated instances copy all parent fields', () async {
      repo.seedParent(
        Task(
          id: 'parent',
          title: 'Sleep',
          description: 'Deep rest',
          purpose: 'Recovery',
          colorArgb: 0xFF123456,
          tags: ['health'],
          startMinutes: 1320,
          durationMinutes: 480,
          recurrenceType: RecurrenceType.daily,
          notificationEnabled: true,
          notificationOffsetMinutes: 15,
          createdAt: DateTime(2030, 1, 1),
          updatedAt: DateTime(2030, 1, 1),
          taskDate: DateTime(2030, 1, 15),
        ),
      );

      await window.execute();

      final child = repo.insertedTasks.first;
      expect(child.title, 'Sleep');
      expect(child.description, 'Deep rest');
      expect(child.purpose, 'Recovery');
      expect(child.colorArgb, 0xFF123456);
      expect(child.tags, ['health']);
      expect(child.startMinutes, 1320);
      expect(child.durationMinutes, 480);
      expect(child.recurrenceType, RecurrenceType.daily);
      expect(child.notificationEnabled, isTrue);
      expect(child.notificationOffsetMinutes, 15);
      expect(child.parentTaskId, 'parent');
      expect(child.status, TaskStatus.pending);
    });

    test('E13: generated instances have unique IDs', () async {
      repo.seedParent(_parent(id: 'p1', taskDate: DateTime(2030, 1, 15)));

      await window.execute();

      final ids = repo.insertedTasks.map((t) => t.id).toSet();
      expect(ids.length, repo.insertedTasks.length);
    });

    test('E14: generated instance dates are correct', () async {
      repo.seedParent(_parent(id: 'p1', taskDate: DateTime(2030, 1, 15)));

      await window.execute();

      // First instance should be Jan 15, last Feb 4
      expect(repo.insertedTasks.first.taskDate, DateTime(2030, 1, 15));
      expect(repo.insertedTasks.last.taskDate, DateTime(2030, 2, 4));
    });

    test('E15: notification scheduling capped at 10', () async {
      repo.seedParent(
        _parent(
          id: 'p1',
          taskDate: DateTime(2030, 1, 15),
          type: RecurrenceType.daily,
        )
        ..copyWith(notificationEnabled: true),
      );

      await window.execute();

      // Should schedule 10 even though 21 were inserted
      expect(scheduler.scheduledIds.length, 10);
    });
  });

  group('CreateTaskUseCase – No Fan-Out', () {
    late _FakeRepo repo;
    late _FakeScheduler scheduler;
    late CreateTaskUseCase useCase;

    setUp(() {
      repo = _FakeRepo();
      scheduler = _FakeScheduler();
      useCase = CreateTaskUseCase(repo, scheduler);
    });

    test('daily: 1 insert', () async {
      await useCase.execute(Task(
        id: '',
        title: 'Daily',
        recurrenceType: RecurrenceType.daily,
        createdAt: DateTime(2030, 1, 1),
        updatedAt: DateTime(2030, 1, 1),
        taskDate: DateTime(2030, 1, 1),
      ));
      expect(repo.insertedTasks.length, 1);
    });

    test('weekly: 1 insert', () async {
      await useCase.execute(Task(
        id: '',
        title: 'Weekly',
        recurrenceType: RecurrenceType.weekly,
        createdAt: DateTime(2030, 1, 1),
        updatedAt: DateTime(2030, 1, 1),
        taskDate: DateTime(2030, 1, 1),
      ));
      expect(repo.insertedTasks.length, 1);
    });

    test('custom: 1 insert', () async {
      await useCase.execute(Task(
        id: '',
        title: 'Custom',
        recurrenceType: RecurrenceType.custom,
        recurrenceRule: '1,3,5',
        createdAt: DateTime(2030, 1, 1),
        updatedAt: DateTime(2030, 1, 1),
        taskDate: DateTime(2030, 1, 1),
      ));
      expect(repo.insertedTasks.length, 1);
    });

    test('repeatToday: parent + intra-day copies', () async {
      await useCase.execute(Task(
        id: '',
        title: 'Pomodoro',
        recurrenceType: RecurrenceType.repeatToday,
        startMinutes: 9 * 60,
        durationMinutes: 30,
        repeatIntervalMinutes: 120,
        createdAt: DateTime(2030, 1, 1),
        updatedAt: DateTime(2030, 1, 1),
        taskDate: DateTime(2030, 1, 1),
      ));
      expect(repo.insertedTasks.length, greaterThan(1));
    });

    test('none: 1 insert', () async {
      await useCase.execute(Task(
        id: '',
        title: 'One-off',
        recurrenceType: RecurrenceType.none,
        createdAt: DateTime(2030, 1, 1),
        updatedAt: DateTime(2030, 1, 1),
        taskDate: DateTime(2030, 1, 1),
      ));
      expect(repo.insertedTasks.length, 1);
    });
  });

  group('UpdateTaskUseCase – Rolling Window Aware', () {
    late _FakeRepo repo;
    late _FakeScheduler scheduler;
    late UpdateTaskUseCase useCase;

    setUp(() {
      repo = _FakeRepo();
      scheduler = _FakeScheduler();
      useCase = UpdateTaskUseCase(repo, scheduler);
    });

    test('future scope: delete old future, no mass regenerate', () async {
      final parent = Task(
        id: 'parent',
        title: 'Daily',
        recurrenceType: RecurrenceType.daily,
        createdAt: DateTime(2030, 1, 1),
        updatedAt: DateTime(2030, 1, 1),
        taskDate: DateTime(2030, 1, 15),
      );

      await useCase.execute(
        parent.copyWith(title: 'Updated'),
        scope: RecurringScope.futureInstances,
      );

      expect(repo.updatedTasks.length, 1);
      expect(repo.deletedRecurringFromDateCalls, isNotEmpty);
      expect(repo.insertedTasks, isEmpty); // No 365-row regeneration
    });

    test('thisInstance scope: single update only', () async {
      final task = Task(
        id: 'task',
        title: 'Task',
        createdAt: DateTime(2030, 1, 1),
        updatedAt: DateTime(2030, 1, 1),
        taskDate: DateTime(2030, 1, 15),
      );

      await useCase.execute(task.copyWith(title: 'Edited'));

      expect(repo.updatedTasks.length, 1);
      expect(repo.deletedRecurringFromDateCalls, isEmpty);
      expect(repo.insertedTasks, isEmpty);
    });
  });
}
