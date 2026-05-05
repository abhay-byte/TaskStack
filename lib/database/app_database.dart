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
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement('''
        CREATE TABLE IF NOT EXISTS deleted_tasks (
          id TEXT NOT NULL PRIMARY KEY,
          deleted_at INTEGER NOT NULL
        )
      ''');
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(tasksTable, tasksTable.graphicImage);
      }
      if (from < 3) {
        await m.createTable(goalsTable);
        await m.addColumn(tasksTable, tasksTable.goalId);
      }
      if (from < 4) {
        await customStatement(
          'ALTER TABLE "goals" ADD COLUMN "updated_at" INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement('UPDATE "goals" SET "updated_at" = "created_at"');
      }
      if (from < 5) {
        await customStatement('''
          CREATE TABLE IF NOT EXISTS deleted_tasks (
            id TEXT NOT NULL PRIMARY KEY,
            deleted_at INTEGER NOT NULL
          )
        ''');
      }
      if (from < 6) {
        // Goals page rehaul: add icon, graphic, color, is_goal columns
        await customStatement(
          'ALTER TABLE "goals" ADD COLUMN "icon_id" TEXT',
        );
        await customStatement(
          'ALTER TABLE "goals" ADD COLUMN "graphic_image" TEXT',
        );
        await customStatement(
          'ALTER TABLE "goals" ADD COLUMN "color_argb" INTEGER',
        );
        await customStatement(
          'ALTER TABLE "goals" ADD COLUMN "is_goal" INTEGER NOT NULL DEFAULT 1',
        );
        // Rolling window: clean up old generated recurring instances
        await _cleanupOldRecurringInstances();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
    },
  );

  Future<void> _cleanupOldRecurringInstances() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 14));
    final dateStr =
        '${cutoff.year}-${cutoff.month.toString().padLeft(2, '0')}-${cutoff.day.toString().padLeft(2, '0')}';
    await customStatement('''
      DELETE FROM tasks
      WHERE parent_task_id IS NOT NULL
        AND task_date < ?
        AND status = 'pending'
        AND completed_at IS NULL
    ''', [dateStr]);
  }
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
