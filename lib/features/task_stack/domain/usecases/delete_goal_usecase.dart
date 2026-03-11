import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/domain/repositories/goal_repository.dart';
import 'package:taskstack/features/task_stack/domain/repositories/task_repository.dart';
import 'package:taskstack/features/task_stack/data/repositories/goal_repository_impl.dart';
import 'package:taskstack/features/task_stack/data/repositories/task_repository_impl.dart';
import 'package:taskstack/features/sync/data/repositories/sync_repository_impl.dart';

class DeleteGoalUseCase {
  const DeleteGoalUseCase(this._goalRepo, this._taskRepo, this._ref);
  final GoalRepository _goalRepo;
  final TaskRepository _taskRepo;
  final Ref _ref;

  Future<void> execute(String goalId) async {
    // 1. Fetch all tasks that might be linked to this goal
    // We fetch all tasks here since there isn't a specific getTasksByGoalId method.
    // getTasksInRange with a huge range to simulate getAllTasks if needed, or we must implement getAllTasks.
    // Looking at TaskRepository, there is no getAllTasks. 
    // We will use watchTasksForDate or similar, but since we can't easily fetch ALL tasks without a DAO, 
    // let's assume we can fetch tasks for a wide range or we need to add getAllTasks to the repo.
    // Let's add that to the repo later if needed, but for now we can read from the db via the provider directly if we had a dao.
    // Let's use getTasksInRange for a 10 year span.
    final now = DateTime.now();
    final allTasks = await _taskRepo.getTasksInRange(
      now.subtract(const Duration(days: 365 * 5)), 
      now.add(const Duration(days: 365 * 5))
    );
    
    final linkedTasks = allTasks.where((task) => task.goalId == goalId).toList();
    
    // 2. Unlink the goal from tasks
    for (final task in linkedTasks) {
      final unlinkedTask = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        purpose: task.purpose,
        iconId: task.iconId,
        graphicImage: task.graphicImage,
        colorArgb: task.colorArgb,
        tags: task.tags,
        startMinutes: task.startMinutes,
        durationMinutes: task.durationMinutes,
        recurrenceType: task.recurrenceType,
        recurrenceRule: task.recurrenceRule,
        repeatIntervalMinutes: task.repeatIntervalMinutes,
        notificationEnabled: task.notificationEnabled,
        notificationOffsetMinutes: task.notificationOffsetMinutes,
        status: task.status,
        completedAt: task.completedAt,
        createdAt: task.createdAt,
        updatedAt: DateTime.now(),
        parentTaskId: task.parentTaskId,
        taskDate: task.taskDate,
        goalId: null, // Explicitly null
      );
      
      await _taskRepo.updateTask(unlinkedTask);
    }
    
    // 3. Delete the goal
    await _goalRepo.deleteGoalById(goalId);

    // 4. Push changes to cloud immediately
    _ref.read(syncRepositoryProvider).pushLocalToCloud();
  }
}

final deleteGoalUseCaseProvider = Provider<DeleteGoalUseCase>((ref) {
  return DeleteGoalUseCase(
    ref.watch(goalRepositoryProvider),
    ref.watch(taskRepositoryProvider),
    ref,
  );
});
