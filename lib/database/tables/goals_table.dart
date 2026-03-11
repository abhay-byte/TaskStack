import 'package:drift/drift.dart';

/// Drift table for goals/projects.
class GoalsTable extends Table {
  @override
  String get tableName => 'goals';

  TextColumn get id => text()();
  TextColumn get title => text().withLength(max: 80)();
  TextColumn get type => text().withDefault(const Constant('project'))();
  /// Duration of the goal in hours. Null means no set time.
  IntColumn get durationHours => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
