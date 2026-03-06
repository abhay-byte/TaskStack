import 'package:drift/drift.dart';
import 'package:taskstack/database/app_database.dart';
import 'package:taskstack/database/tables/tasks_table.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [TasksTable])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  /// Watch all tasks for a given date (yyyy-MM-dd), including overnight spillovers.
  /// Note: Parent recurring tasks (recurringType != none AND parentTaskId == null)
  /// do NOT spill over - only their generated instances should show on each date.
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

            // Parent recurring tasks (has recurrence type but no parentTaskId)
            // should NOT spill over - only their generated instances show on each date.
            // This prevents tasks like "Sleep" created on Friday from appearing on Saturday
            // just because they span midnight.
            final isParentRecurring = t.parentTaskId.isNull() &
                (t.recurrenceType.equals('daily') |
                t.recurrenceType.equals('weekly') |
                t.recurrenceType.equals('custom') |
                t.recurrenceType.equals('repeatToday'));
            
            // Only allow spill-over for non-parent tasks (i.e., generated instances)
            final canSpillOver = ~isParentRecurring & spillsOver;

            return isToday | (isYesterday & canSpillOver);
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
  Future<void> insertTask(TasksTableCompanion task) {
    return into(tasksTable).insert(task);
  }

  /// Upsert a task — replaces any existing row with same id (used by sync pull).
  Future<void> upsertTask(TasksTableCompanion task) {
    return into(tasksTable).insert(task, mode: InsertMode.replace);
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
