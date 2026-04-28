import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/database/app_database.dart';
import 'package:taskstack/database/daos/goal_dao.dart';
import 'package:taskstack/features/task_stack/domain/entities/goal.dart';
import 'package:taskstack/features/task_stack/domain/repositories/goal_repository.dart';

class GoalRepositoryImpl implements GoalRepository {
  GoalRepositoryImpl(this._dao);
  final GoalDao _dao;

  @override
  Stream<List<Goal>> watchAllGoals() {
    return _dao.watchAllGoals().map((rows) => rows.map(_rowToGoal).toList());
  }

  @override
  Future<List<Goal>> getAllGoals() async {
    final rows = await _dao.getAllGoals();
    return rows.map(_rowToGoal).toList();
  }

  @override
  Future<Goal?> getGoalById(String id) async {
    final row = await _dao.getGoalById(id);
    return row == null ? null : _rowToGoal(row);
  }

  @override
  Future<void> insertGoal(Goal goal) => _dao.insertGoal(_goalToCompanion(goal));

  @override
  Future<void> updateGoal(Goal goal) => _dao.updateGoal(_goalToCompanion(goal));

  @override
  Future<void> deleteGoalById(String id) => _dao.deleteGoalById(id);

  @override
  Stream<List<GoalTaskInfo>> watchTasksForGoal(String goalId) {
    return _dao.watchTasksForGoal(goalId).map(
          (rows) => rows
              .map(
                (r) => GoalTaskInfo(
                  id: r.id,
                  title: r.title,
                  taskDate: r.taskDate,
                  durationMinutes: r.durationMinutes,
                  status: r.status,
                  completedAt: r.completedAt,
                ),
              )
              .toList(),
        );
  }

  @override
  Future<int?> getCommittedMinutesForGoal(String goalId) {
    return _dao.getCommittedMinutesForGoal(goalId);
  }

  // ── Mappers ──────────────────────────────────────────────────────────────

  Goal _rowToGoal(GoalsTableData row) {
    return Goal(
      id: row.id,
      title: row.title,
      type: GoalType.values.firstWhere(
        (e) => e.name == row.type,
        orElse: () => GoalType.project,
      ),
      durationHours: row.durationHours,
      iconId: row.iconId,
      graphicImage: row.graphicImage,
      colorArgb: row.colorArgb,
      isGoal: row.isGoal,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  GoalsTableCompanion _goalToCompanion(Goal goal) {
    return GoalsTableCompanion(
      id: Value(goal.id),
      title: Value(goal.title),
      type: Value(goal.type.name),
      durationHours: Value(goal.durationHours),
      iconId: Value(goal.iconId),
      graphicImage: Value(goal.graphicImage),
      colorArgb: Value(goal.colorArgb),
      isGoal: Value(goal.isGoal),
      createdAt: Value(goal.createdAt),
      updatedAt: Value(goal.updatedAt),
    );
  }
}

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepositoryImpl(ref.watch(goalDaoProvider));
});
