import 'package:drift/drift.dart';
import 'package:taskstack/database/app_database.dart';
import 'package:taskstack/database/tables/daily_summaries_table.dart';

part 'analytics_dao.g.dart';

@DriftAccessor(tables: [DailySummariesTable])
class AnalyticsDao extends DatabaseAccessor<AppDatabase>
    with _$AnalyticsDaoMixin {
  AnalyticsDao(super.db);

  Future<DailySummariesTableData?> getSummaryForDate(String date) {
    return (select(dailySummariesTable)
          ..where((s) => s.taskDate.equals(date)))
        .getSingleOrNull();
  }

  Future<List<DailySummariesTableData>> getSummariesInRange(
    String from,
    String to,
  ) {
    return (select(dailySummariesTable)
          ..where((s) => s.taskDate.isBetweenValues(from, to))
          ..orderBy([(s) => OrderingTerm.asc(s.taskDate)]))
        .get();
  }

  Future<void> upsertSummary(DailySummariesTableCompanion summary) {
    return into(dailySummariesTable).insertOnConflictUpdate(summary);
  }
}
