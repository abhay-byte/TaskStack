import 'package:taskstack/features/task_stack/domain/entities/goal.dart';

abstract class GoalRepository {
  Stream<List<Goal>> watchAllGoals();
  Future<List<Goal>> getAllGoals();
  Future<Goal?> getGoalById(String id);
  Future<void> insertGoal(Goal goal);
  Future<void> updateGoal(Goal goal);
  Future<void> deleteGoalById(String id);

  /// Watch all tasks linked to a specific goal.
  Stream<List<GoalTaskInfo>> watchTasksForGoal(String goalId);

  /// Get committed (completed) time in minutes for a goal.
  Future<int?> getCommittedMinutesForGoal(String goalId);
}

/// Lightweight task info for goal timeline display.
class GoalTaskInfo {
  const GoalTaskInfo({
    required this.id,
    required this.title,
    required this.taskDate,
    required this.durationMinutes,
    required this.status,
    required this.completedAt,
  });

  final String id;
  final String title;
  final String taskDate;
  final int? durationMinutes;
  final String status;
  final DateTime? completedAt;
}
