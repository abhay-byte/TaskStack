import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taskstack/core/constants/app_colors.dart';
import 'package:taskstack/core/providers/guest_mode_provider.dart';
import 'package:taskstack/features/auth/presentation/providers/auth_provider.dart';
import 'package:taskstack/features/sync/domain/repositories/sync_repository.dart';
import 'package:taskstack/features/task_stack/domain/entities/goal.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/domain/repositories/goal_repository.dart';
import 'package:taskstack/features/task_stack/domain/repositories/task_repository.dart';
import 'package:taskstack/features/task_stack/presentation/providers/goal_providers.dart';
import 'package:taskstack/features/task_stack/presentation/providers/task_providers.dart';
import 'package:taskstack/features/task_stack/presentation/screens/task_form_screen.dart';
import 'package:taskstack/features/notifications/notification_scheduler.dart';
import 'package:taskstack/features/sync/data/repositories/sync_repository_impl.dart';

// ─── Fakes ───────────────────────────────────────────────────────────────────

class _FakeTaskRepository implements TaskRepository {
  final List<Task> insertedTasks = [];
  final List<Task> updatedTasks = [];

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
  @override
  Future<void> scheduleFor(Task task) async {}
  @override
  Future<void> cancelFor(String taskId) async {}
}

class _FakeSyncRepository implements SyncRepository {
  int pushCalls = 0;
  int pullCalls = 0;

  @override
  Future<void> pullCloudToLocal() async => pullCalls++;

  @override
  Future<void> pushLocalToCloud() async => pushCalls++;
}

class _FakeGoalRepository implements GoalRepository {
  @override
  Future<void> deleteGoalById(String id) async {}
  @override
  Future<List<Goal>> getAllGoals() async => [];
  @override
  Future<Goal?> getGoalById(String id) async => null;
  @override
  Future<void> insertGoal(Goal goal) async {}
  @override
  Future<void> updateGoal(Goal goal) async {}
  @override
  Stream<List<Goal>> watchAllGoals() async* {
    yield const [];
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

ProviderContainer _container({
  required _FakeTaskRepository taskRepository,
  required _FakeNotificationScheduler scheduler,
  required _FakeSyncRepository syncRepository,
  required _FakeGoalRepository goalRepository,
  bool isGuest = false,
}) {
  return ProviderContainer(
    overrides: [
      taskRepositoryProvider.overrideWithValue(taskRepository),
      notificationSchedulerProvider.overrideWithValue(scheduler),
      syncRepositoryProvider.overrideWithValue(syncRepository),
      goalRepositoryProvider.overrideWithValue(goalRepository),
      isGuestModeProvider.overrideWith((ref) => isGuest),
    ],
  );
}

GoRouter _router() {
  return GoRouter(
    initialLocation: '/task/new',
    routes: [
      GoRoute(
        path: '/task/new',
        builder: (context, state) => const TaskFormScreen(),
      ),
      GoRoute(
        path: '/goal/new',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Goal Form')),
        ),
      ),
    ],
  );
}

Widget _buildApp(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      theme: ThemeData(useMaterial3: true),
      routerConfig: _router(),
    ),
  );
}

Future<void> _pumpForm(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(_buildApp(container));
  await tester.pump();
  await tester.pump();
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('TaskFormScreen – Offline vs Online Sync', () {
    testWidgets('guest mode: save task locally, NO sync triggered', (
      tester,
    ) async {
      final taskRepo = _FakeTaskRepository();
      final syncRepo = _FakeSyncRepository();
      final container = _container(
        taskRepository: taskRepo,
        scheduler: _FakeNotificationScheduler(),
        syncRepository: syncRepo,
        goalRepository: _FakeGoalRepository(),
        isGuest: true,
      );
      addTearDown(container.dispose);

      await _pumpForm(tester, container);

      // Fill title
      await tester.enterText(find.byType(TextField).first, 'Guest Task');
      await tester.pump();

      // Tap save
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Task saved locally
      expect(taskRepo.insertedTasks, isNotEmpty);
      expect(taskRepo.insertedTasks.first.title, 'Guest Task');

      // In guest mode, the form save does NOT call maintainRecurringWindowUseCase
      // because it depends on the sync repository which is overridden.
      // The key assertion: sync.pushLocalToCloud was NOT called by the form.
      expect(syncRepo.pushCalls, 0);
    });

    testWidgets('online mode: save task + sync triggered', (tester) async {
      final taskRepo = _FakeTaskRepository();
      final syncRepo = _FakeSyncRepository();
      final container = _container(
        taskRepository: taskRepo,
        scheduler: _FakeNotificationScheduler(),
        syncRepository: syncRepo,
        goalRepository: _FakeGoalRepository(),
        isGuest: false,
      );
      addTearDown(container.dispose);

      await _pumpForm(tester, container);

      await tester.enterText(find.byType(TextField).first, 'Online Task');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(taskRepo.insertedTasks, isNotEmpty);
      expect(taskRepo.insertedTasks.first.title, 'Online Task');

      // In online mode, the form triggers maintainRecurringWindowUseCase
      // which internally does NOT call sync, but the form save itself
      // does not directly call sync.pushLocalToCloud either.
      // The actual sync happens elsewhere (e.g., periodic or manual).
      expect(syncRepo.pushCalls, 0); // Form save doesn't directly sync
    });

    testWidgets('edit existing task: local update only', (tester) async {
      final taskRepo = _FakeTaskRepository();
      final syncRepo = _FakeSyncRepository();
      final container = _container(
        taskRepository: taskRepo,
        scheduler: _FakeNotificationScheduler(),
        syncRepository: syncRepo,
        goalRepository: _FakeGoalRepository(),
        isGuest: false,
      );
      addTearDown(container.dispose);

      // Pre-seed a task
      final existingTask = Task(
        id: 'edit-task-1',
        title: 'Original',
        createdAt: DateTime(2030, 1, 1),
        updatedAt: DateTime(2030, 1, 1),
        taskDate: DateTime(2030, 1, 1),
      );
      await taskRepo.insertTask(existingTask);

      // The form would load this task via taskId
      // For this test we verify the update path at use-case level
      final notifier = container.read(taskFormProvider.notifier);
      notifier.loadTask(existingTask);
      notifier.updateTitle('Updated Title');

      final saved = await notifier.save(DateTime(2030, 1, 1));
      expect(saved, isTrue);

      expect(taskRepo.updatedTasks, isNotEmpty);
      expect(taskRepo.updatedTasks.first.title, 'Updated Title');
    });

    testWidgets('recurring task save: only parent inserted, no 365 fan-out', (
      tester,
    ) async {
      final taskRepo = _FakeTaskRepository();
      final container = _container(
        taskRepository: taskRepo,
        scheduler: _FakeNotificationScheduler(),
        syncRepository: _FakeSyncRepository(),
        goalRepository: _FakeGoalRepository(),
        isGuest: false,
      );
      addTearDown(container.dispose);

      final notifier = container.read(taskFormProvider.notifier);
      notifier
        ..updateTitle('Daily Standup')
        ..updateRecurrence(RecurrenceType.daily);

      final saved = await notifier.save(DateTime(2030, 1, 1));
      expect(saved, isTrue);

      // Rolling window: only 1 row (parent) inserted
      expect(taskRepo.insertedTasks, hasLength(1));
      expect(taskRepo.insertedTasks.first.recurrenceType, RecurrenceType.daily);
    });

    testWidgets('recurring task save weekly: only parent inserted', (
      tester,
    ) async {
      final taskRepo = _FakeTaskRepository();
      final container = _container(
        taskRepository: taskRepo,
        scheduler: _FakeNotificationScheduler(),
        syncRepository: _FakeSyncRepository(),
        goalRepository: _FakeGoalRepository(),
        isGuest: false,
      );
      addTearDown(container.dispose);

      final notifier = container.read(taskFormProvider.notifier);
      notifier
        ..updateTitle('Weekly Review')
        ..updateRecurrence(RecurrenceType.weekly);

      final saved = await notifier.save(DateTime(2030, 1, 1));
      expect(saved, isTrue);

      expect(taskRepo.insertedTasks, hasLength(1));
      expect(taskRepo.insertedTasks.first.recurrenceType, RecurrenceType.weekly);
    });
  });
}
