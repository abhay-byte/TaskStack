import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskstack/features/notifications/notification_scheduler.dart';
import 'package:taskstack/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:taskstack/features/sync/domain/repositories/sync_repository.dart';
import 'package:taskstack/features/task_stack/data/repositories/task_repository_impl.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/domain/repositories/task_repository.dart';
import 'package:taskstack/features/task_stack/domain/usecases/task_usecases.dart';
import 'package:taskstack/features/task_stack/presentation/providers/task_providers.dart';

class _FakeTaskRepository implements TaskRepository {
  final List<Task> insertedTasks = [];

  @override
  Future<void> deleteRecurringFamily(String parentId) async {}

  @override
  Future<void> deleteRecurringTasksFromDate(
    String parentId,
    DateTime date, {
    bool inclusive = true,
  }) async {}

  @override
  Future<void> deleteTask(String id) async {}

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
  final List<String> scheduledTaskIds = [];

  @override
  Future<NotificationScheduleResult> scheduleFor(Task task) async {
    scheduledTaskIds.add(task.id);
    return NotificationScheduleResult.scheduled;
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

ProviderContainer _container({
  required _FakeTaskRepository repository,
  required _FakeNotificationScheduler scheduler,
  required _FakeSyncRepository sync,
}) {
  return ProviderContainer(
    overrides: [
      taskRepositoryProvider.overrideWithValue(repository),
      notificationSchedulerProvider.overrideWithValue(scheduler),
      syncRepositoryProvider.overrideWithValue(sync),
    ],
  );
}

void main() {
  group('TaskFormNotifier', () {
    test('rejects repeatToday when repeat interval is shorter than duration', () async {
      final repository = _FakeTaskRepository();
      final scheduler = _FakeNotificationScheduler();
      final sync = _FakeSyncRepository();
      final container = _container(
        repository: repository,
        scheduler: scheduler,
        sync: sync,
      );
      addTearDown(container.dispose);

      final sub = container.listen(taskFormProvider, (_, __) {}, fireImmediately: true);
      addTearDown(sub.close);

      final notifier = container.read(taskFormProvider.notifier);
      notifier
        ..updateTitle('Hydration')
        ..updateStartMinutes(9 * 60)
        ..updateDuration(30)
        ..updateRecurrence(RecurrenceType.repeatToday)
        ..updateRepeatInterval(15);

      final saved = await notifier.save(DateTime(2030, 1, 1));

      expect(saved, isFalse);
      expect(container.read(taskFormProvider).error, contains('overlap'));
      expect(repository.insertedTasks, isEmpty);
      expect(scheduler.scheduledTaskIds, isEmpty);
      expect(sync.pushCalls, 0);
    });

    test('serializes custom recurrence days into recurrenceRule', () async {
      final repository = _FakeTaskRepository();
      final scheduler = _FakeNotificationScheduler();
      final sync = _FakeSyncRepository();
      final container = _container(
        repository: repository,
        scheduler: scheduler,
        sync: sync,
      );
      addTearDown(container.dispose);

      final sub = container.listen(taskFormProvider, (_, __) {}, fireImmediately: true);
      addTearDown(sub.close);

      final notifier = container.read(taskFormProvider.notifier);
      notifier
        ..updateTitle('  Custom recurrence  ')
        ..updateStartMinutes(7 * 60)
        ..updateDuration(30)
        ..updateRecurrence(RecurrenceType.custom)
        ..toggleCustomDay(1)
        ..toggleCustomDay(3)
        ..toggleCustomDay(5)
        ..updateNotificationEnabled(false);

      final saved = await notifier.save(DateTime(2026, 3, 30));

      expect(saved, isTrue);
      expect(repository.insertedTasks, isNotEmpty);
      final parent = repository.insertedTasks.first;
      expect(parent.title, 'Custom recurrence');
      expect(parent.recurrenceType, RecurrenceType.custom);
      expect(parent.recurrenceRule, '1,3,5');
      // Only parent is inserted; rolling window maintenance handles instances
      expect(repository.insertedTasks.length, 1);
      expect(sync.pushCalls, 1);
    });

    test('creates a plain task with trimmed title and null optional fields', () async {
      final repository = _FakeTaskRepository();
      final scheduler = _FakeNotificationScheduler();
      final sync = _FakeSyncRepository();
      final container = _container(
        repository: repository,
        scheduler: scheduler,
        sync: sync,
      );
      addTearDown(container.dispose);

      final sub = container.listen(taskFormProvider, (_, __) {}, fireImmediately: true);
      addTearDown(sub.close);

      final notifier = container.read(taskFormProvider.notifier);
      notifier
        ..updateTitle('  Write spec  ')
        ..updateDescription('')
        ..updatePurpose('')
        ..updateNotificationEnabled(false);

      final saved = await notifier.save(DateTime(2030, 1, 1));

      expect(saved, isTrue);
      expect(repository.insertedTasks, hasLength(1));
      final task = repository.insertedTasks.single;
      expect(task.title, 'Write spec');
      expect(task.description, isNull);
      expect(task.purpose, isNull);
      expect(task.recurrenceType, RecurrenceType.none);
      expect(task.recurrenceRule, isNull);
      expect(task.repeatIntervalMinutes, 60);
      expect(scheduler.scheduledTaskIds, isEmpty);
      expect(sync.pushCalls, 1);
    });
  });

  group('TaskFormNotifier save matrix', () {
    test(
      'saves a plain task with goal, tags, color, and reminder offset',
      () async {
        final repository = _FakeTaskRepository();
        final scheduler = _FakeNotificationScheduler();
        final sync = _FakeSyncRepository();
        final container = _container(
          repository: repository,
          scheduler: scheduler,
          sync: sync,
        );
        addTearDown(container.dispose);

        final sub = container.listen(
          taskFormProvider,
          (_, __) {},
          fireImmediately: true,
        );
        addTearDown(sub.close);

        final notifier = container.read(taskFormProvider.notifier);
        notifier
          ..updateTitle('  Personal admin  ')
          ..updateGoalId('goal-1')
          ..updateTags(['home', 'life', 'money', 'focus', 'errands'])
          ..updateColor(0xFF22C55E)
          ..updateNotificationEnabled(true)
          ..updateNotificationOffset(30);

        final saved = await notifier.save(DateTime(2030, 1, 1));

        expect(saved, isTrue);
        expect(repository.insertedTasks, hasLength(1));
        final task = repository.insertedTasks.single;
        expect(task.title, 'Personal admin');
        expect(task.goalId, 'goal-1');
        expect(task.tags, ['home', 'life', 'money', 'focus', 'errands']);
        expect(task.colorArgb, 0xFF22C55E);
        expect(task.notificationEnabled, isTrue);
        expect(task.notificationOffsetMinutes, 30);
        expect(task.recurrenceType, RecurrenceType.none);
        expect(scheduler.scheduledTaskIds, hasLength(1));
        expect(sync.pushCalls, 1);
      },
    );

    test(
      'saves repeatToday tasks and schedules every generated instance when notifications are on',
      () async {
        final repository = _FakeTaskRepository();
        final scheduler = _FakeNotificationScheduler();
        final sync = _FakeSyncRepository();
        final container = _container(
          repository: repository,
          scheduler: scheduler,
          sync: sync,
        );
        addTearDown(container.dispose);

        final sub = container.listen(
          taskFormProvider,
          (_, __) {},
          fireImmediately: true,
        );
        addTearDown(sub.close);

        final notifier = container.read(taskFormProvider.notifier);
        notifier
          ..updateTitle('Hydration')
          ..updateStartMinutes(9 * 60)
          ..updateDuration(30)
          ..updateRecurrence(RecurrenceType.repeatToday)
          ..updateRepeatInterval(120)
          ..updateNotificationEnabled(true);

        final saved = await notifier.save(DateTime(2030, 1, 1));

        expect(saved, isTrue);
        expect(repository.insertedTasks, hasLength(8));
        expect(scheduler.scheduledTaskIds, hasLength(8));
        expect(repository.insertedTasks.first.recurrenceType, RecurrenceType.repeatToday);
        expect(
          repository.insertedTasks.skip(1).every(
            (task) => task.parentTaskId == repository.insertedTasks.first.id,
          ),
          isTrue,
        );
      },
    );

    test(
      'rejects repeatToday overlap before any insert or schedule happens',
      () async {
        final repository = _FakeTaskRepository();
        final scheduler = _FakeNotificationScheduler();
        final sync = _FakeSyncRepository();
        final container = _container(
          repository: repository,
          scheduler: scheduler,
          sync: sync,
        );
        addTearDown(container.dispose);

        final sub = container.listen(
          taskFormProvider,
          (_, __) {},
          fireImmediately: true,
        );
        addTearDown(sub.close);

        final notifier = container.read(taskFormProvider.notifier);
        notifier
          ..updateTitle('Hydration')
          ..updateStartMinutes(9 * 60)
          ..updateDuration(30)
          ..updateRecurrence(RecurrenceType.repeatToday)
          ..updateRepeatInterval(15);

        final saved = await notifier.save(DateTime(2030, 1, 1));

        expect(saved, isFalse);
        expect(container.read(taskFormProvider).error, contains('overlap'));
        expect(repository.insertedTasks, isEmpty);
        expect(scheduler.scheduledTaskIds, isEmpty);
        expect(sync.pushCalls, 0);
      },
    );

    test(
      'saves only parent for daily, weekly, and custom recurring tasks',
      () async {
        final cases = <({
          String name,
          Task task,
        })>[
          (
            name: 'daily',
            task: Task(
              id: '',
              title: 'Daily standup',
              startMinutes: 8 * 60,
              recurrenceType: RecurrenceType.daily,
              notificationEnabled: true,
              notificationOffsetMinutes: 10,
              createdAt: DateTime(2030, 1, 1, 12),
              updatedAt: DateTime(2030, 1, 1, 12),
              taskDate: DateTime(2030, 1, 1),
            ),
          ),
          (
            name: 'weekly',
            task: Task(
              id: '',
              title: 'Weekly review',
              startMinutes: 18 * 60,
              recurrenceType: RecurrenceType.weekly,
              notificationEnabled: true,
              notificationOffsetMinutes: 15,
              createdAt: DateTime(2030, 1, 1, 12),
              updatedAt: DateTime(2030, 1, 1, 12),
              taskDate: DateTime(2030, 1, 1),
            ),
          ),
          (
            name: 'custom',
            task: Task(
              id: '',
              title: 'Gym',
              startMinutes: 7 * 60,
              recurrenceType: RecurrenceType.custom,
              recurrenceRule: '1,3,5',
              notificationEnabled: true,
              notificationOffsetMinutes: 5,
              createdAt: DateTime(2026, 3, 30, 12),
              updatedAt: DateTime(2026, 3, 30, 12),
              taskDate: DateTime(2026, 3, 30),
            ),
          ),
          (
            name: 'custom-no-days',
            task: Task(
              id: '',
              title: 'Unscheduled custom',
              recurrenceType: RecurrenceType.custom,
              recurrenceRule: '',
              notificationEnabled: true,
              notificationOffsetMinutes: 5,
              createdAt: DateTime(2026, 3, 30, 12),
              updatedAt: DateTime(2026, 3, 30, 12),
              taskDate: DateTime(2026, 3, 30),
            ),
          ),
        ];

        for (final testCase in cases) {
          final repository = _FakeTaskRepository();
          final scheduler = _FakeNotificationScheduler();
          final sync = _FakeSyncRepository();
          final useCase = CreateTaskUseCase(repository, scheduler);

          await useCase.execute(testCase.task);

          // Only the parent task is inserted; rolling window maintenance
          // populates instances separately.
          expect(
            repository.insertedTasks,
            hasLength(1),
            reason: testCase.name,
          );
          expect(
            scheduler.scheduledTaskIds,
            hasLength(1),
            reason: testCase.name,
          );
        }
      },
    );
  });
}
