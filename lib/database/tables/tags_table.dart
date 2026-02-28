import 'package:drift/drift.dart';

/// Drift table for user-defined tags.
class TagsTable extends Table {
  @override
  String get tableName => 'tags';

  TextColumn get id => text()();
  TextColumn get name => text().withLength(max: 50).unique()();
  IntColumn get colorArgb => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
