import 'package:drift/drift.dart';
import 'package:taskstack/database/app_database.dart';
import 'package:taskstack/database/tables/goals_table.dart';
import 'package:taskstack/database/tables/tasks_table.dart';

part 'goal_dao.g.dart';

@DriftAccessor(tables: [GoalsTable, TasksTable])
class GoalDao extends DatabaseAccessor<AppDatabase> with _$GoalDaoMixin {
  GoalDao(super.db);

  Stream<List<GoalsTableData>> watchAllGoals() {
    return select(goalsTable).watch();
  }

  Future<List<GoalsTableData>> getAllGoals() {
    return select(goalsTable).get();
  }

  Future<GoalsTableData?> getGoalById(String id) {
    return (select(goalsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertGoal(GoalsTableCompanion goal) {
    return into(goalsTable).insert(goal, mode: InsertMode.replace);
  }

  Future<void> updateGoal(GoalsTableCompanion goal) {
    return update(goalsTable).replace(goal);
  }

  Future<void> deleteGoalById(String id) {
    return (delete(goalsTable)..where((t) => t.id.equals(id))).go();
  }

  /// Watch all tasks linked to a specific goal.
  Stream<List<TasksTableData>> watchTasksForGoal(String goalId) {
    return (select(tasksTable)
          ..where((t) => t.goalId.equals(goalId)))
        .watch();
  }

  /// Get all tasks linked to a specific goal.
  Future<List<TasksTableData>> getTasksForGoal(String goalId) {
    return (select(tasksTable)
          ..where((t) => t.goalId.equals(goalId)))
        .get();
  }

  /// Get tasks linked to a goal within a date range (yyyy-MM-dd).
  Future<List<TasksTableData>> getTasksForGoalInRange(
    String goalId,
    String from,
    String to,
  ) {
    return (select(tasksTable)
          ..where(
            (t) =>
                t.goalId.equals(goalId) &
                t.taskDate.isBetweenValues(from, to),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.taskDate)]))
        .get();
  }

  /// Sum of durationMinutes for completed tasks linked to a goal.
  Future<int?> getCommittedMinutesForGoal(String goalId) async {
    final query = customSelect(
      'SELECT SUM(duration_minutes) as total '
      'FROM tasks '
      'WHERE goal_id = ? AND status = ?',
      variables: [Variable<String>(goalId), Variable<String>('completed')],
    );
    final row = await query.getSingleOrNull();
    return row?.read<int?>('total');
  }
}
