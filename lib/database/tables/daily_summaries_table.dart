import 'package:drift/drift.dart';

/// Materialised daily summary — cached analytics per calendar day.
class DailySummariesTable extends Table {
  @override
  String get tableName => 'daily_summaries';

  TextColumn get taskDate => text()(); // yyyy-MM-dd — PK
  IntColumn get totalScheduled =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalCompleted =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalDurationPlanned =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalDurationCompleted =>
      integer().withDefault(const Constant(0))();
  RealColumn get productivityScore => real().nullable()();
  TextColumn get tagBreakdownJson =>
      text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {taskDate};
}
