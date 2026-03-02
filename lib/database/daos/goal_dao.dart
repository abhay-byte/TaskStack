import 'package:drift/drift.dart';
import 'package:taskstack/database/app_database.dart';
import 'package:taskstack/database/tables/goals_table.dart';

part 'goal_dao.g.dart';

@DriftAccessor(tables: [GoalsTable])
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
}
