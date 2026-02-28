import 'package:taskstack/features/task_stack/domain/entities/task.dart';

abstract class TaskRepository {
  Stream<List<Task>> watchTasksForDate(DateTime date);
  Future<Task?> getTaskById(String id);
  Future<void> insertTask(Task task);
  Future<void> insertTasks(List<Task> tasks);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String id);
  Future<void> deleteRecurringFamily(String parentId);
  Future<List<Task>> getTasksInRange(DateTime from, DateTime to);
  Future<void> updateStatus(
    String id, {
    required String status,
    DateTime? completedAt,
  });
}
