// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_dao.dart';

// ignore_for_file: type=lint
mixin _$GoalDaoMixin on DatabaseAccessor<AppDatabase> {
  $GoalsTableTable get goalsTable => attachedDatabase.goalsTable;
  $TasksTableTable get tasksTable => attachedDatabase.tasksTable;
  GoalDaoManager get managers => GoalDaoManager(this);
}

class GoalDaoManager {
  final _$GoalDaoMixin _db;
  GoalDaoManager(this._db);
  $$GoalsTableTableTableManager get goalsTable =>
      $$GoalsTableTableTableManager(_db.attachedDatabase, _db.goalsTable);
  $$TasksTableTableTableManager get tasksTable =>
      $$TasksTableTableTableManager(_db.attachedDatabase, _db.tasksTable);
}
