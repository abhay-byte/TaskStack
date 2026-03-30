import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskstack/database/app_database.dart';
import 'package:taskstack/features/task_stack/data/repositories/task_repository_impl.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';

Task _makeTask({required String id, required DateTime taskDate}) {
  final now = DateTime(2026, 3, 30, 10);
  return Task(
    id: id,
    title: 'Task $id',
    createdAt: now,
    updatedAt: now,
    taskDate: taskDate,
  );
}

void main() {
  group('Task deletion tombstones', () {
    late AppDatabase database;
    late TaskRepositoryImpl repository;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      repository = TaskRepositoryImpl(database.taskDao);
    });

    tearDown(() async {
      await database.close();
    });

    test('deleteTask records a tombstone and removes the row', () async {
      await repository.insertTask(
        _makeTask(id: 'task-1', taskDate: DateTime(2026, 3, 30)),
      );

      await repository.deleteTask('task-1');

      expect(await repository.getTaskById('task-1'), isNull);
      final tombstones = await database.taskDao.getDeletedTaskTombstones();
      expect(tombstones.map((t) => t.id), contains('task-1'));
    });

    test('upsert clears an existing tombstone for the same task id', () async {
      await database.taskDao.recordTaskDeletions(['task-2']);

      await database.taskDao.upsertTask(
        TasksTableCompanion.insert(
          id: 'task-2',
          title: 'Restored',
          createdAt: DateTime(2026, 3, 30, 11),
          updatedAt: DateTime(2026, 3, 30, 11),
          taskDate: '2026-03-30',
        ),
      );

      final tombstones = await database.taskDao.getDeletedTaskTombstones();
      expect(tombstones.where((t) => t.id == 'task-2'), isEmpty);
    });
  });
}
