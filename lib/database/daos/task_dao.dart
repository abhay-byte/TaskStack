import 'package:drift/drift.dart';
import 'package:taskstack/database/app_database.dart';
import 'package:taskstack/database/tables/tasks_table.dart';

part 'task_dao.g.dart';

class DeletedTaskTombstone {
  const DeletedTaskTombstone({required this.id, required this.deletedAt});

  final String id;
  final DateTime deletedAt;
}

@DriftAccessor(tables: [TasksTable])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  /// Watch all tasks for a given date (yyyy-MM-dd), including overnight spillovers.
  /// Recurring parent tasks must also be allowed to spill into the next day so
  /// the first occurrence of an overnight schedule stays visible after midnight.
  Stream<List<TasksTableData>> watchTasksForDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final prevDateStr = DateTime(
      date.year,
      date.month,
      date.day - 1,
    ).toIso8601String().substring(0, 10);

    return (select(tasksTable)
          ..where((t) {
            final isToday = t.taskDate.equals(dateStr);
            final isYesterday = t.taskDate.equals(prevDateStr);

            // Safe addition across nullable int columns in sqlite
            final startAndDur =
                t.startMinutes +
                coalesce(
                  [
                    t.durationMinutes,
                    const Constant(30),
                  ].cast<Expression<int>>(),
                );
            final spillsOver =
                t.startMinutes.isNotNull() &
                startAndDur.isBiggerThanValue(1440);

            return isToday | (isYesterday & spillsOver);
          })
          ..orderBy([(t) => OrderingTerm.asc(t.startMinutes)]))
        .watch();
  }

  /// Get a single task by id.
  Future<TasksTableData?> getTaskById(String id) {
    return (select(tasksTable)
      ..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get all tasks (used by sync push to cloud).
  Future<List<TasksTableData>> getAllTasks() {
    return select(tasksTable).get();
  }

  /// Insert a new task.
  Future<void> insertTask(TasksTableCompanion task) async {
    await clearDeletedTaskMarks(_extractPresentIds([task]));
    await into(tasksTable).insert(task);
  }

  /// Upsert a task — replaces any existing row with same id (used by sync pull).
  Future<void> upsertTask(TasksTableCompanion task) async {
    await clearDeletedTaskMarks(_extractPresentIds([task]));
    await into(tasksTable).insert(task, mode: InsertMode.replace);
  }

  /// Insert multiple tasks in a batch.
  Future<void> insertTasks(List<TasksTableCompanion> tasks) async {
    await clearDeletedTaskMarks(_extractPresentIds(tasks));
    await batch((batch) {
      batch.insertAll(tasksTable, tasks);
    });
  }

  /// Update an existing task.
  Future<bool> updateTask(TasksTableCompanion task) async {
    await clearDeletedTaskMarks(_extractPresentIds([task]));
    return update(tasksTable).replace(task);
  }

  /// Delete a task by id.
  Future<int> deleteTaskById(String id) {
    return (delete(tasksTable)..where((t) => t.id.equals(id))).go();
  }

  /// Delete all instances of a recurring task (by parentTaskId OR id).
  Future<int> deleteRecurringFamily(String parentId) {
    return (delete(tasksTable)..where(
      (t) => t.parentTaskId.equals(parentId) | t.id.equals(parentId),
    )).go();
  }

  /// Delete all instances of a recurring task from a specific date.
  Future<int> deleteRecurringTasksFromDate(
    String parentId,
    String date, {
    bool inclusive = true,
  }) {
    return (delete(tasksTable)..where(
      (t) =>
          (t.parentTaskId.equals(parentId) | t.id.equals(parentId)) &
          (inclusive
              ? t.taskDate.isBiggerOrEqualValue(date)
              : t.taskDate.isBiggerThanValue(date)),
    )).go();
  }

  Future<List<String>> getRecurringFamilyTaskIds(String parentId) async {
    final rows =
        await (select(tasksTable)..where(
          (t) => t.parentTaskId.equals(parentId) | t.id.equals(parentId),
        )).get();
    return rows.map((row) => row.id).toList();
  }

  Future<List<String>> getRecurringTaskIdsFromDate(
    String parentId,
    String date, {
    bool inclusive = true,
  }) async {
    final rows =
        await (select(tasksTable)..where(
          (t) =>
              (t.parentTaskId.equals(parentId) | t.id.equals(parentId)) &
              (inclusive
                  ? t.taskDate.isBiggerOrEqualValue(date)
                  : t.taskDate.isBiggerThanValue(date)),
        )).get();
    return rows.map((row) => row.id).toList();
  }

  Future<void> recordTaskDeletions(
    Iterable<String> ids, {
    DateTime? deletedAt,
  }) async {
    final uniqueIds = ids.where((id) => id.isNotEmpty).toSet().toList();
    if (uniqueIds.isEmpty) return;

    final deletedAtMillis =
        (deletedAt ?? DateTime.now()).toUtc().millisecondsSinceEpoch;
    await batch((batch) {
      for (final id in uniqueIds) {
        batch.customStatement(
          'INSERT OR REPLACE INTO deleted_tasks (id, deleted_at) VALUES (?, ?)',
          [id, deletedAtMillis],
        );
      }
    });
  }

  Future<List<DeletedTaskTombstone>> getDeletedTaskTombstones() async {
    final rows =
        await customSelect(
          'SELECT id, deleted_at FROM deleted_tasks ORDER BY deleted_at ASC',
        ).get();
    return rows.map((row) {
      return DeletedTaskTombstone(
        id: row.read<String>('id'),
        deletedAt: DateTime.fromMillisecondsSinceEpoch(
          row.read<int>('deleted_at'),
          isUtc: true,
        ),
      );
    }).toList();
  }

  Future<void> clearDeletedTaskMarks(Iterable<String> ids) async {
    final uniqueIds = ids.where((id) => id.isNotEmpty).toSet().toList();
    if (uniqueIds.isEmpty) return;

    await batch((batch) {
      for (final id in uniqueIds) {
        batch.customStatement('DELETE FROM deleted_tasks WHERE id = ?', [id]);
      }
    });
  }

  /// Get all tasks for a date range (for analytics).
  Future<List<TasksTableData>> getTasksInRange(String from, String to) {
    return (select(tasksTable)
      ..where((t) => t.taskDate.isBetweenValues(from, to))).get();
  }

  /// Update status + completedAt.
  Future<void> updateStatus(
    String id, {
    required String status,
    DateTime? completedAt,
  }) {
    return (update(tasksTable)..where((t) => t.id.equals(id))).write(
      TasksTableCompanion(
        status: Value(status),
        completedAt: Value(completedAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  List<String> _extractPresentIds(List<TasksTableCompanion> tasks) {
    return tasks
        .where((task) => task.id.present && task.id.value.isNotEmpty)
        .map((task) => task.id.value)
        .toList();
  }
}
