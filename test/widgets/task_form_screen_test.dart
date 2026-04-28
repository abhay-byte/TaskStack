import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taskstack/core/constants/app_colors.dart';
import 'package:taskstack/features/task_stack/domain/entities/goal.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/data/repositories/goal_repository_impl.dart';
import 'package:taskstack/features/task_stack/data/repositories/task_repository_impl.dart';
import 'package:taskstack/features/task_stack/domain/repositories/goal_repository.dart';
import 'package:taskstack/features/task_stack/domain/repositories/task_repository.dart';
import 'package:taskstack/features/task_stack/presentation/providers/goal_providers.dart';
import 'package:taskstack/features/task_stack/presentation/providers/task_providers.dart';
import 'package:taskstack/features/task_stack/presentation/screens/task_form_screen.dart';
import 'package:taskstack/features/notifications/notification_scheduler.dart';
import 'package:taskstack/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:taskstack/features/sync/domain/repositories/sync_repository.dart';

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
  @override
  Future<void> pullCloudToLocal() async {}

  @override
  Future<void> pushLocalToCloud() async {}
}

class _FakeGoalRepository implements GoalRepository {
  _FakeGoalRepository(this._goals);

  final List<Goal> _goals;

  @override
  Future<void> deleteGoalById(String id) async {}

  @override
  Future<List<Goal>> getAllGoals() async => _goals;

  @override
  Future<Goal?> getGoalById(String id) async {
    for (final goal in _goals) {
      if (goal.id == id) return goal;
    }
    return null;
  }

  @override
  Future<void> insertGoal(Goal goal) async {}

  @override
  Future<void> updateGoal(Goal goal) async {}

  @override
  Stream<List<Goal>> watchAllGoals() async* {
    yield _goals;
  }

  @override
  Stream<List<GoalTaskInfo>> watchTasksForGoal(String goalId) async* {
    yield [];
  }

  @override
  Future<int?> getCommittedMinutesForGoal(String goalId) async => 0;
}

ProviderContainer _container({
  required _FakeTaskRepository taskRepository,
  required _FakeNotificationScheduler scheduler,
  required _FakeSyncRepository syncRepository,
  required _FakeGoalRepository goalRepository,
}) {
  return ProviderContainer(
    overrides: [
      taskRepositoryProvider.overrideWithValue(taskRepository),
      notificationSchedulerProvider.overrideWithValue(scheduler),
      syncRepositoryProvider.overrideWithValue(syncRepository),
      goalRepositoryProvider.overrideWithValue(goalRepository),
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

void main() {
  group('TaskFormScreen', () {
    testWidgets('renders the main add-task controls', (tester) async {
      final container = _container(
        taskRepository: _FakeTaskRepository(),
        scheduler: _FakeNotificationScheduler(),
        syncRepository: _FakeSyncRepository(),
        goalRepository: _FakeGoalRepository(const []),
      );
      addTearDown(container.dispose);

      await _pumpForm(tester, container);

      expect(find.text('New Task'), findsOneWidget);
      expect(find.byKey(const Key('task-form-goal-dropdown')), findsOneWidget);
      expect(find.byKey(const Key('task-form-color-none')), findsOneWidget);
      for (var i = 0; i < AppColors.taskAccentColors.length; i++) {
        expect(find.byKey(Key('task-form-color-$i')), findsOneWidget);
      }
      expect(find.byKey(const Key('task-form-tag-input')), findsOneWidget);
      expect(find.byKey(const Key('task-form-start-time')), findsOneWidget);
      expect(find.byKey(const Key('task-form-end-time')), findsOneWidget);
      expect(find.text('Recurrence'), findsOneWidget);
      expect(find.text('Notification'), findsOneWidget);
    });

    testWidgets('supports all accent color selections', (tester) async {
      final container = _container(
        taskRepository: _FakeTaskRepository(),
        scheduler: _FakeNotificationScheduler(),
        syncRepository: _FakeSyncRepository(),
        goalRepository: _FakeGoalRepository(const []),
      );
      addTearDown(container.dispose);

      await _pumpForm(tester, container);

      final notifier = container.read(taskFormProvider.notifier);

      notifier.updateColor(null);
      await tester.pump();
      expect(notifier.state.colorArgb, isNull);

      for (var i = 0; i < AppColors.taskAccentColors.length; i++) {
        notifier.updateColor(AppColors.taskAccentColors[i].toARGB32());
        await tester.pump();
        expect(
          notifier.state.colorArgb,
          AppColors.taskAccentColors[i].toARGB32(),
        );
      }
    });

    testWidgets('supports tag add, duplicate suppression, and cap of five', (
      tester,
    ) async {
      final container = _container(
        taskRepository: _FakeTaskRepository(),
        scheduler: _FakeNotificationScheduler(),
        syncRepository: _FakeSyncRepository(),
        goalRepository: _FakeGoalRepository(const []),
      );
      addTearDown(container.dispose);

      await _pumpForm(tester, container);

      Future<void> addTag(String tag) async {
        await tester.ensureVisible(find.byKey(const Key('task-form-tag-input')));
        await tester.enterText(
          find.byKey(const Key('task-form-tag-input')),
          tag,
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
      }

      await addTag('Work');
      await addTag('Flutter');
      await addTag('Home');
      await addTag('Focus');
      await addTag('Errands');
      await addTag('Focus');
      await addTag('Extra');

      final state = container.read(taskFormProvider);
      expect(state.tags, ['work', 'flutter', 'home', 'focus', 'errands']);
      expect(find.byKey(const ValueKey('task-form-tag-work')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('task-form-tag-extra')),
        findsNothing,
      );

      final focusChip = tester.widget<InputChip>(
        find.byKey(const ValueKey('task-form-tag-focus')),
      );
      focusChip.onDeleted?.call();
      await tester.pump();

      expect(container.read(taskFormProvider).tags, ['work', 'flutter', 'home', 'errands']);
      expect(find.byKey(const ValueKey('task-form-tag-focus')), findsNothing);
    });

    testWidgets('shows recurrence-specific fields and repeatToday validation', (
      tester,
    ) async {
      final container = _container(
        taskRepository: _FakeTaskRepository(),
        scheduler: _FakeNotificationScheduler(),
        syncRepository: _FakeSyncRepository(),
        goalRepository: _FakeGoalRepository(const []),
      );
      addTearDown(container.dispose);

      await _pumpForm(tester, container);

      final notifier = container.read(taskFormProvider.notifier);

      notifier
        ..updateTitle('Hydration')
        ..updateStartMinutes(9 * 60)
        ..updateDuration(30)
        ..updateRecurrence(RecurrenceType.repeatToday)
        ..updateRepeatInterval(15);
      await tester.pump();

      expect(find.byKey(const Key('task-form-repeat-interval')), findsOneWidget);
      expect(find.textContaining('tasks will overlap'), findsOneWidget);

      notifier.updateRepeatInterval(60);
      await tester.pump();
      expect(find.textContaining('tasks will overlap'), findsNothing);

      notifier.updateRecurrence(RecurrenceType.daily);
      await tester.pump();
      expect(find.byKey(const Key('task-form-repeat-interval')), findsNothing);
      expect(find.byKey(const ValueKey('task-form-day-1')), findsNothing);

      notifier.updateRecurrence(RecurrenceType.custom);
      await tester.pump();
      expect(find.byKey(const ValueKey('task-form-day-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('task-form-day-7')), findsOneWidget);

      notifier.toggleCustomDay(1);
      notifier.toggleCustomDay(3);
      notifier.toggleCustomDay(5);
      await tester.pump();
      expect(container.read(taskFormProvider).customRecurrenceDays, [1, 3, 5]);
    });

    testWidgets('supports all reminder offset options', (tester) async {
      final container = _container(
        taskRepository: _FakeTaskRepository(),
        scheduler: _FakeNotificationScheduler(),
        syncRepository: _FakeSyncRepository(),
        goalRepository: _FakeGoalRepository(const []),
      );
      addTearDown(container.dispose);

      await _pumpForm(tester, container);

      final notifier = container.read(taskFormProvider.notifier);
      notifier.updateNotificationEnabled(true);
      await tester.pump();

      expect(find.byKey(const Key('task-form-reminder')), findsOneWidget);

      final options = <({int minutes, String expected})>[
        (minutes: 0, expected: 'At start time'),
        (minutes: 5, expected: '5 minutes before'),
        (minutes: 10, expected: '10 minutes before'),
        (minutes: 15, expected: '15 minutes before'),
        (minutes: 30, expected: '30 minutes before'),
      ];

      for (final option in options) {
        notifier.updateNotificationOffset(option.minutes);
        await tester.pumpAndSettle();
        expect(
          container.read(taskFormProvider).notificationOffsetMinutes,
          option.minutes,
        );
        expect(find.text(option.expected), findsOneWidget);
      }
    });

    testWidgets('supports goal selection and create-new navigation', (
      tester,
    ) async {
      final goals = [
        Goal(
          id: 'goal-1',
          title: 'Work',
          createdAt: DateTime(2030, 1, 1),
          updatedAt: DateTime(2030, 1, 1),
        ),
        Goal(
          id: 'goal-2',
          title: 'Health',
          createdAt: DateTime(2030, 1, 1),
          updatedAt: DateTime(2030, 1, 1),
        ),
      ];
      final container = _container(
        taskRepository: _FakeTaskRepository(),
        scheduler: _FakeNotificationScheduler(),
        syncRepository: _FakeSyncRepository(),
        goalRepository: _FakeGoalRepository(goals),
      );
      addTearDown(container.dispose);

      await _pumpForm(tester, container);

      expect(find.text('No Goal'), findsOneWidget);

      await tester.tap(find.byKey(const Key('task-form-goal-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Work').last);
      await tester.pumpAndSettle();
      expect(container.read(taskFormProvider).goalId, 'goal-1');
      expect(find.text('Work'), findsWidgets);

      await tester.tap(find.byKey(const Key('task-form-goal-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Create New Goal').last);
      await tester.pumpAndSettle();
      expect(find.text('Goal Form'), findsOneWidget);
    });

    testWidgets('supports graphic selection and clearing', (tester) async {
      final container = _container(
        taskRepository: _FakeTaskRepository(),
        scheduler: _FakeNotificationScheduler(),
        syncRepository: _FakeSyncRepository(),
        goalRepository: _FakeGoalRepository(const []),
      );
      addTearDown(container.dispose);

      await _pumpForm(tester, container);

      await tester.tap(find.text('Select Graphic'));
      await tester.pumpAndSettle();
      expect(find.text('Gym'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();
      expect(container.read(taskFormProvider).graphicImage, isNull);
    });
  });
}
