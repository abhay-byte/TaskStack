import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/features/task_stack/data/repositories/goal_repository_impl.dart';
import 'package:taskstack/features/task_stack/domain/entities/goal.dart';
import 'package:taskstack/features/task_stack/domain/repositories/goal_repository.dart';

final goalsProvider = StreamProvider<List<Goal>>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return repository.watchAllGoals();
});

final goalTasksProvider =
    StreamProvider.family<List<GoalTaskInfo>, String>((ref, goalId) {
  final repository = ref.watch(goalRepositoryProvider);
  return repository.watchTasksForGoal(goalId);
});

final committedMinutesProvider =
    FutureProvider.family<int?, String>((ref, goalId) {
  final repository = ref.watch(goalRepositoryProvider);
  return repository.getCommittedMinutesForGoal(goalId);
});
