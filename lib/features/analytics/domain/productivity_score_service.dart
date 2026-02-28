import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/database/app_database.dart';
import 'package:taskstack/database/tables/daily_summaries_table.dart';
import 'package:taskstack/features/task_stack/domain/repositories/task_repository.dart';
import 'package:taskstack/features/task_stack/data/repositories/task_repository_impl.dart';

/// Calculates and persists the [DailySummary] for a given date.
/// Call this after any task CRUD or completion event for that date.
class ProductivityScoreService {
  ProductivityScoreService(this._repo, this._db);

  final TaskRepository _repo;
  final AppDatabase _db;

  Future<void> updateSummaryFor(DateTime date) async {
    final tasks = await _repo.getTasksInRange(date, date);

    final totalScheduled = tasks.length;
    final totalCompleted = tasks.where((t) => t.isDone).length;

    final totalDurationPlanned = tasks
        .map((t) => t.durationMinutes ?? 0)
        .fold(0, (a, b) => a + b);

    final totalDurationCompleted = tasks
        .where((t) => t.isDone)
        .map((t) => t.durationMinutes ?? 0)
        .fold(0, (a, b) => a + b);

    // Productivity score: weighted by completion rate + duration ratio
    double score = 0.0;
    if (totalScheduled > 0) {
      final completionRate = totalCompleted / totalScheduled;
      final durationRatio = totalDurationPlanned == 0
          ? 0.0
          : totalDurationCompleted / totalDurationPlanned;
      // 70% weight on completion, 30% on duration
      score = (completionRate * 0.7 + durationRatio * 0.3) * 100;
    }

    // Tag breakdown
    final tagCounts = <String, int>{};
    for (final t in tasks) {
      for (final tag in t.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    await _db.analyticsDao.upsertSummary(
      DailySummariesTableCompanion(
        taskDate: Value(dateStr),
        totalScheduled: Value(totalScheduled),
        totalCompleted: Value(totalCompleted),
        totalDurationPlanned: Value(totalDurationPlanned),
        totalDurationCompleted: Value(totalDurationCompleted),
        productivityScore: Value(score),
        tagBreakdownJson: Value(jsonEncode(tagCounts)),
      ),
    );
  }
}

final productivityScoreServiceProvider =
    Provider<ProductivityScoreService>((ref) {
  return ProductivityScoreService(
    ref.watch(taskRepositoryProvider),
    ref.watch(appDatabaseProvider),
  );
});
