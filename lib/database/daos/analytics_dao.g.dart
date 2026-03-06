// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_dao.dart';

// ignore_for_file: type=lint
mixin _$AnalyticsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DailySummariesTableTable get dailySummariesTable =>
      attachedDatabase.dailySummariesTable;
  AnalyticsDaoManager get managers => AnalyticsDaoManager(this);
}

class AnalyticsDaoManager {
  final _$AnalyticsDaoMixin _db;
  AnalyticsDaoManager(this._db);
  $$DailySummariesTableTableTableManager get dailySummariesTable =>
      $$DailySummariesTableTableTableManager(
        _db.attachedDatabase,
        _db.dailySummariesTable,
      );
}
