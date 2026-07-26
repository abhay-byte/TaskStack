import 'package:taskstack/features/task_stack/domain/entities/task.dart';

abstract class TaskRepository {
  Stream<List<Task>> watchTasksForDate(DateTime date);
  Stream<Map<String, List<Task>>> watchTasksInRange(DateTime from, DateTime to);
  Future<Task?> getTaskById(String id);
  Future<void> insertTask(Task task);
  Future<void> insertTasks(List<Task> tasks);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String id);
  Future<void> deleteRecurringFamily(String parentId);
  Future<void> deleteRecurringTasksFromDate(
    String parentId,
    DateTime date, {
    bool inclusive = true,
  });
  Future<List<Task>> getTasksInRange(DateTime from, DateTime to);
  Future<void> updateStatus(
    String id, {
    required String status,
    DateTime? completedAt,
  });

  // ── Rolling window maintenance ──────────────────────────────────────────
  Future<List<Task>> getRecurringParents();
  Future<List<String>> getInstanceDatesInRange(
    String parentId,
    DateTime from,
    DateTime to,
  );
  Future<void> deleteOldPendingInstances(String parentId, DateTime before);
}
