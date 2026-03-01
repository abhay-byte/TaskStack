import 'package:drift/drift.dart';
import 'package:taskstack/database/app_database.dart';
import 'package:taskstack/database/tables/tasks_table.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [TasksTable])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  /// Watch all tasks for a given date (yyyy-MM-dd), including overnight spillovers.
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

  /// Insert a new task.
  Future<void> insertTask(TasksTableCompanion task) {
    return into(tasksTable).insert(task);
  }

  /// Insert multiple tasks in a batch.
  Future<void> insertTasks(List<TasksTableCompanion> tasks) async {
    await batch((batch) {
      batch.insertAll(tasksTable, tasks);
    });
  }

  /// Update an existing task.
  Future<bool> updateTask(TasksTableCompanion task) {
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
}
