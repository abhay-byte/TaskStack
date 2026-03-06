import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:taskstack/database/tables/tasks_table.dart';
import 'package:taskstack/database/tables/tags_table.dart';
import 'package:taskstack/database/tables/daily_summaries_table.dart';
import 'package:taskstack/database/tables/goals_table.dart';
import 'package:taskstack/database/daos/task_dao.dart';
import 'package:taskstack/database/daos/tag_dao.dart';
import 'package:taskstack/database/daos/analytics_dao.dart';
import 'package:taskstack/database/daos/goal_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [TasksTable, TagsTable, DailySummariesTable, GoalsTable],
  daos: [TaskDao, TagDao, AnalyticsDao, GoalDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(tasksTable, tasksTable.graphicImage);
      }
      if (from < 3) {
        await m.createTable(goalsTable);
        await m.addColumn(tasksTable, tasksTable.goalId);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'taskstack.db'));
    return NativeDatabase.createInBackground(file);
  });
}

/// Riverpod provider for the singleton database instance.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// DAO providers
final taskDaoProvider = Provider<TaskDao>((ref) {
  return ref.watch(appDatabaseProvider).taskDao;
});

final tagDaoProvider = Provider<TagDao>((ref) {
  return ref.watch(appDatabaseProvider).tagDao;
});

final analyticsDaoProvider = Provider<AnalyticsDao>((ref) {
  return ref.watch(appDatabaseProvider).analyticsDao;
});

final goalDaoProvider = Provider<GoalDao>((ref) {
  return ref.watch(appDatabaseProvider).goalDao;
});
