import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/features/task_stack/data/repositories/goal_repository_impl.dart';
import 'package:taskstack/features/task_stack/domain/entities/goal.dart';

final goalsProvider = StreamProvider<List<Goal>>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return repository.watchAllGoals();
});
