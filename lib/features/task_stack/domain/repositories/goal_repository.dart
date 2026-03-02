import 'package:taskstack/features/task_stack/domain/entities/goal.dart';

abstract class GoalRepository {
  Stream<List<Goal>> watchAllGoals();
  Future<List<Goal>> getAllGoals();
  Future<Goal?> getGoalById(String id);
  Future<void> insertGoal(Goal goal);
  Future<void> updateGoal(Goal goal);
  Future<void> deleteGoalById(String id);
}
