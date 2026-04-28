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
  /// Material Symbols icon name (e.g. 'flag', 'fitness_center').
  TextColumn get iconId => text().nullable()();
  /// SVG graphic identifier for hero/illustration.
  TextColumn get graphicImage => text().nullable()();
  /// Accent colour for the goal card.
  IntColumn get colorArgb => integer().nullable()();
  /// Whether this is a Goal (true) or a Project (false).
  BoolColumn get isGoal => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
