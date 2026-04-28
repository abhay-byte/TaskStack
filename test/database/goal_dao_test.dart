import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskstack/database/app_database.dart';

void main() {
  group('GoalDao', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('inserts and retrieves a goal with all new fields', () async {
      final now = DateTime.now();
      await database.goalDao.insertGoal(
        GoalsTableCompanion.insert(
          id: 'goal-1',
          title: 'Learn Flutter',
          type: const Value('project'),
          durationHours: const Value(100),
          iconId: const Value('school'),
          graphicImage: const Value('study.svg'),
          colorArgb: const Value(0xFF3B82F6),
          isGoal: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final goal = await database.goalDao.getGoalById('goal-1');
      expect(goal, isNotNull);
      expect(goal!.title, 'Learn Flutter');
      expect(goal.iconId, 'school');
      expect(goal.graphicImage, 'study.svg');
      expect(goal.colorArgb, 0xFF3B82F6);
      expect(goal.isGoal, true);
    });

    test('getCommittedMinutesForGoal sums completed task durations', () async {
      final now = DateTime.now();
      await database.goalDao.insertGoal(
        GoalsTableCompanion.insert(
          id: 'goal-2',
          title: 'Fitness',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Insert completed task linked to goal
      await database.taskDao.insertTask(
        TasksTableCompanion.insert(
          id: 'task-1',
          title: 'Run 5k',
          durationMinutes: const Value(60),
          status: const Value('completed'),
          goalId: const Value('goal-2'),
          createdAt: now,
          updatedAt: now,
          taskDate: now.toIso8601String().substring(0, 10),
        ),
      );

      // Insert pending task linked to goal (should not count)
      await database.taskDao.insertTask(
        TasksTableCompanion.insert(
          id: 'task-2',
          title: 'Stretch',
          durationMinutes: const Value(15),
          status: const Value('pending'),
          goalId: const Value('goal-2'),
          createdAt: now,
          updatedAt: now,
          taskDate: now.toIso8601String().substring(0, 10),
        ),
      );

      // Insert completed task NOT linked to goal (should not count)
      await database.taskDao.insertTask(
        TasksTableCompanion.insert(
          id: 'task-3',
          title: 'Read book',
          durationMinutes: const Value(30),
          status: const Value('completed'),
          createdAt: now,
          updatedAt: now,
          taskDate: now.toIso8601String().substring(0, 10),
        ),
      );

      final committed = await database.goalDao.getCommittedMinutesForGoal('goal-2');
      expect(committed, 60);
    });

    test('getCommittedMinutesForGoal returns null when no tasks', () async {
      final committed = await database.goalDao.getCommittedMinutesForGoal('nonexistent');
      expect(committed, isNull);
    });

    test('watchTasksForGoal emits tasks linked to goal', () async {
      final now = DateTime.now();
      final dateStr = now.toIso8601String().substring(0, 10);

      await database.goalDao.insertGoal(
        GoalsTableCompanion.insert(
          id: 'goal-3',
          title: 'Study',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await database.taskDao.insertTask(
        TasksTableCompanion.insert(
          id: 'task-4',
          title: 'Math',
          goalId: const Value('goal-3'),
          createdAt: now,
          updatedAt: now,
          taskDate: dateStr,
        ),
      );

      await database.taskDao.insertTask(
        TasksTableCompanion.insert(
          id: 'task-5',
          title: 'Science',
          goalId: const Value('goal-3'),
          createdAt: now,
          updatedAt: now,
          taskDate: dateStr,
        ),
      );

      await database.taskDao.insertTask(
        TasksTableCompanion.insert(
          id: 'task-6',
          title: 'History',
          createdAt: now,
          updatedAt: now,
          taskDate: dateStr,
        ),
      );

      final tasks = await database.goalDao.watchTasksForGoal('goal-3').first;
      expect(tasks.length, 2);
      expect(tasks.map((t) => t.id), containsAll(['task-4', 'task-5']));
    });

    test('getTasksForGoalInRange returns only tasks in date range', () async {
      final now = DateTime(2026, 4, 15);

      await database.goalDao.insertGoal(
        GoalsTableCompanion.insert(
          id: 'goal-4',
          title: 'Work',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await database.taskDao.insertTask(
        TasksTableCompanion.insert(
          id: 'task-7',
          title: 'Meeting',
          goalId: const Value('goal-4'),
          createdAt: now,
          updatedAt: now,
          taskDate: '2026-04-10',
        ),
      );

      await database.taskDao.insertTask(
        TasksTableCompanion.insert(
          id: 'task-8',
          title: 'Code review',
          goalId: const Value('goal-4'),
          createdAt: now,
          updatedAt: now,
          taskDate: '2026-04-20',
        ),
      );

      final tasks = await database.goalDao.getTasksForGoalInRange(
        'goal-4',
        '2026-04-15',
        '2026-04-25',
      );
      expect(tasks.length, 1);
      expect(tasks.first.id, 'task-8');
    });
  });
}
