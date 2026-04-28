import 'package:flutter_test/flutter_test.dart';
import 'package:taskstack/features/task_stack/domain/entities/goal.dart';
import 'package:taskstack/features/task_stack/domain/repositories/goal_repository.dart';
import 'package:taskstack/features/task_stack/data/repositories/goal_repository_impl.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:taskstack/database/app_database.dart';

void main() {
  group('GoalRepositoryImpl', () {
    late AppDatabase database;
    late GoalRepository repository;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      repository = GoalRepositoryImpl(database.goalDao);
    });

    tearDown(() async {
      await database.close();
    });

    test('inserts and retrieves goal with new fields', () async {
      final now = DateTime.now();
      final goal = Goal(
        id: 'g1',
        title: 'Test Goal',
        type: GoalType.habit,
        durationHours: 50,
        iconId: 'fitness_center',
        graphicImage: 'gym.svg',
        colorArgb: 0xFF22C55E,
        isGoal: false,
        createdAt: now,
        updatedAt: now,
      );

      await repository.insertGoal(goal);
      final fetched = await repository.getGoalById('g1');

      expect(fetched, isNotNull);
      expect(fetched!.id, 'g1');
      expect(fetched.title, 'Test Goal');
      expect(fetched.type, GoalType.habit);
      expect(fetched.durationHours, 50);
      expect(fetched.iconId, 'fitness_center');
      expect(fetched.graphicImage, 'gym.svg');
      expect(fetched.colorArgb, 0xFF22C55E);
      expect(fetched.isGoal, false);
    });

    test('watchAllGoals emits goals with new fields', () async {
      final now = DateTime.now();
      await repository.insertGoal(Goal(
        id: 'g2',
        title: 'Watch Goal',
        iconId: 'school',
        colorArgb: 0xFF3B82F6,
        isGoal: true,
        createdAt: now,
        updatedAt: now,
      ));

      final goals = await repository.watchAllGoals().first;
      expect(goals.length, 1);
      expect(goals.first.iconId, 'school');
      expect(goals.first.colorArgb, 0xFF3B82F6);
      expect(goals.first.isGoal, true);
    });

    test('getCommittedMinutesForGoal returns correct sum', () async {
      final now = DateTime.now();
      final dateStr = now.toIso8601String().substring(0, 10);

      await repository.insertGoal(Goal(
        id: 'g3',
        title: 'Committed Goal',
        createdAt: now,
        updatedAt: now,
      ));

      // Insert 2 completed tasks = 90 min
      await database.taskDao.insertTask(TasksTableCompanion.insert(
        id: 't1',
        title: 'Task 1',
        durationMinutes: const Value(45),
        status: const Value('completed'),
        goalId: const Value('g3'),
        createdAt: now,
        updatedAt: now,
        taskDate: dateStr,
      ));

      await database.taskDao.insertTask(TasksTableCompanion.insert(
        id: 't2',
        title: 'Task 2',
        durationMinutes: const Value(45),
        status: const Value('completed'),
        goalId: const Value('g3'),
        createdAt: now,
        updatedAt: now,
        taskDate: dateStr,
      ));

      // Insert pending task (should not count)
      await database.taskDao.insertTask(TasksTableCompanion.insert(
        id: 't3',
        title: 'Task 3',
        durationMinutes: const Value(30),
        status: const Value('pending'),
        goalId: const Value('g3'),
        createdAt: now,
        updatedAt: now,
        taskDate: dateStr,
      ));

      final committed = await repository.getCommittedMinutesForGoal('g3');
      expect(committed, 90);
    });

    test('watchTasksForGoal emits linked tasks', () async {
      final now = DateTime.now();
      final dateStr = now.toIso8601String().substring(0, 10);

      await repository.insertGoal(Goal(
        id: 'g4',
        title: 'Linked Goal',
        createdAt: now,
        updatedAt: now,
      ));

      await database.taskDao.insertTask(TasksTableCompanion.insert(
        id: 't4',
        title: 'Linked Task',
        goalId: const Value('g4'),
        status: const Value('completed'),
        createdAt: now,
        updatedAt: now,
        taskDate: dateStr,
      ));

      final tasks = await repository.watchTasksForGoal('g4').first;
      expect(tasks.length, 1);
      expect(tasks.first.id, 't4');
      expect(tasks.first.status, 'completed');
    });

    test('updateGoal updates new fields', () async {
      final now = DateTime.now();
      await repository.insertGoal(Goal(
        id: 'g5',
        title: 'Original',
        createdAt: now,
        updatedAt: now,
      ));

      await repository.updateGoal(Goal(
        id: 'g5',
        title: 'Updated',
        iconId: 'palette',
        colorArgb: 0xFFEC4899,
        isGoal: false,
        createdAt: now,
        updatedAt: now,
      ));

      final fetched = await repository.getGoalById('g5');
      expect(fetched!.title, 'Updated');
      expect(fetched.iconId, 'palette');
      expect(fetched.colorArgb, 0xFFEC4899);
      expect(fetched.isGoal, false);
    });

    test('deleteGoalById removes goal', () async {
      final now = DateTime.now();
      await repository.insertGoal(Goal(
        id: 'g6',
        title: 'To Delete',
        createdAt: now,
        updatedAt: now,
      ));

      await repository.deleteGoalById('g6');
      final fetched = await repository.getGoalById('g6');
      expect(fetched, isNull);
    });
  });
}
