import 'package:drift/drift.dart';
import 'package:taskstack/database/app_database.dart';
import 'package:taskstack/database/tables/tasks_table.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [TasksTable])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  /// Watch all tasks for a given date (yyyy-MM-dd).
  Stream<List<TasksTableData>> watchTasksForDate(String date) {
    return (select(tasksTable)
          ..where((t) => t.taskDate.equals(date))
          ..orderBy([
            (t) => OrderingTerm.asc(t.startMinutes),
          ]))
        .watch();
  }

  /// Get a single task by id.
  Future<TasksTableData?> getTaskById(String id) {
    return (select(tasksTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Insert a new task.
  Future<void> insertTask(TasksTableCompanion task) {
    return into(tasksTable).insert(task);
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
    return (delete(tasksTable)
          ..where(
            (t) => t.parentTaskId.equals(parentId) | t.id.equals(parentId),
          ))
        .go();
  }

  /// Get all tasks for a date range (for analytics).
  Future<List<TasksTableData>> getTasksInRange(String from, String to) {
    return (select(tasksTable)
          ..where((t) => t.taskDate.isBetweenValues(from, to)))
        .get();
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
