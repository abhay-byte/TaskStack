import 'package:drift/drift.dart';

/// Drift table for tasks.
class TasksTable extends Table {
  @override
  String get tableName => 'tasks';

  TextColumn get id => text()();
  TextColumn get title => text().withLength(max: 80)();
  TextColumn get description => text().nullable()();
  TextColumn get purpose => text().nullable()();
  TextColumn get iconId => text().nullable()();
  IntColumn get colorArgb => integer().nullable()();
  TextColumn get graphicImage => text().nullable()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  IntColumn get startMinutes => integer().nullable()();
  IntColumn get durationMinutes => integer().nullable()();
  TextColumn get recurrenceType => text().withDefault(const Constant('none'))();
  TextColumn get recurrenceRule => text().nullable()();
  IntColumn get repeatIntervalMinutes => integer().nullable()();
  BoolColumn get notificationEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get notificationOffsetMinutes =>
      integer().withDefault(const Constant(5))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get parentTaskId => text().nullable()();
  TextColumn get taskDate => text()(); // yyyy-MM-dd

  @override
  Set<Column> get primaryKey => {id};
}
