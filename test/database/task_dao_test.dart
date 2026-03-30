import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskstack/database/app_database.dart';

void main() {
  group('TaskDao.watchTasksForDate', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'includes the first overnight occurrence of a recurring parent task on the next day',
      () async {
        final createdAt = DateTime(2026, 3, 29, 22);

        await database.taskDao.insertTask(
          TasksTableCompanion.insert(
            id: 'sleep-parent',
            title: 'Sleep',
            startMinutes: const Value(23 * 60),
            durationMinutes: const Value(7 * 60),
            recurrenceType: const Value('daily'),
            createdAt: createdAt,
            updatedAt: createdAt,
            taskDate: '2026-03-29',
          ),
        );

        await database.taskDao.insertTask(
          TasksTableCompanion.insert(
            id: 'sleep-next',
            title: 'Sleep',
            startMinutes: const Value(23 * 60),
            durationMinutes: const Value(7 * 60),
            recurrenceType: const Value('daily'),
            createdAt: createdAt,
            updatedAt: createdAt,
            parentTaskId: const Value('sleep-parent'),
            taskDate: '2026-03-30',
          ),
        );

        final tasks =
            await database.taskDao.watchTasksForDate('2026-03-30').first;

        expect(
          tasks.map((task) => task.id),
          containsAll(['sleep-parent', 'sleep-next']),
        );
      },
    );
  });
}
