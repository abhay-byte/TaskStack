
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/core/network/api_client.dart';
import 'package:taskstack/core/providers/guest_mode_provider.dart';
import 'package:taskstack/database/app_database.dart';
import 'package:taskstack/database/daos/goal_dao.dart';
import 'package:taskstack/database/daos/task_dao.dart';
import 'package:taskstack/features/sync/domain/repositories/sync_repository.dart';

class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl({
    required this.dio,
    required this.taskDao,
    required this.goalDao,
    required this.ref,
  });

  final Dio dio;
  final TaskDao taskDao;
  final GoalDao goalDao;
  final Ref ref;

  // ── PUSH: local → cloud ────────────────────────────────────────────────────

  @override
  Future<void> pushLocalToCloud() async {
    // No-op in guest mode — no account to sync to.
    final isGuest = ref.read(isGuestModeProvider);
    debugPrint('[Sync] pushLocalToCloud: isGuest=$isGuest');
    ref.read(syncErrorMessageProvider.notifier).state = null;
    if (isGuest) {
      ref.read(syncErrorMessageProvider.notifier).state = 'Cannot sync in guest mode. Please sign in.';
      return;
    }
    ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
    debugPrint('[Sync] Starting push to cloud...');
    try {
      await _pushGoals();
      await _pushTasks();
      ref.read(syncStatusProvider.notifier).state = SyncStatus.idle;
      debugPrint('[Sync] Push completed successfully');
    } on DioException catch (e) {
      String msg;
      if (e.type == DioExceptionType.connectionTimeout) {
        msg = 'Server is starting up (may take 30s). Tap to retry...';
      } else {
        msg = e.message ?? 'Network error';
      }
      debugPrint('[Sync] Push failed: $msg');
      ref.read(syncErrorMessageProvider.notifier).state = 'Sync failed: $msg';
      ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
    } catch (e) {
      debugPrint('[Sync] Push failed with error: $e');
      ref.read(syncErrorMessageProvider.notifier).state = 'Sync failed: $e';
      ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
    }
  }

  Future<void> _pushGoals() async {
    final goals = await goalDao.getAllGoals();
    if (goals.isEmpty) return;
    final payload = goals
        .map((g) => {
              'id': g.id,
              'title': g.title,
              'type': g.type,
              'duration_hours': g.durationHours,
              'created_at': g.createdAt.toUtc().toIso8601String(),
              // Goals don't have updatedAt in Drift; mirror createdAt
              'updated_at': g.createdAt.toUtc().toIso8601String(),
            })
        .toList();
    await dio.post('/tasks/goals/bulk', data: payload);
  }

  Future<void> _pushTasks() async {
    // Get all tasks across all dates
    final tasks = await taskDao.getAllTasks();
    if (tasks.isEmpty) return;
    final payload = tasks
        .map((t) => {
              'id': t.id,
              'title': t.title,
              'description': t.description,
              'purpose': t.purpose,
              'icon_id': t.iconId,
              'color_argb': t.colorArgb,
              'tags_json': t.tagsJson,
              'start_minutes': t.startMinutes,
              'duration_minutes': t.durationMinutes,
              'recurrence_type': t.recurrenceType,
              'recurrence_rule': t.recurrenceRule,
              'repeat_interval_minutes': t.repeatIntervalMinutes,
              'notification_enabled': t.notificationEnabled,
              'notification_offset_minutes': t.notificationOffsetMinutes,
              'status': t.status,
              'completed_at': t.completedAt?.toUtc().toIso8601String(),
              'task_date': t.taskDate,
              'parent_task_id': t.parentTaskId,
              'goal_id': t.goalId,
              'created_at': t.createdAt.toUtc().toIso8601String(),
              'updated_at': t.updatedAt.toUtc().toIso8601String(),
            })
        .toList();
    await dio.post('/tasks/bulk', data: payload);
  }

  // ── PULL: cloud → local ────────────────────────────────────────────────────

  @override
  Future<void> pullCloudToLocal() async {
    // No-op in guest mode — no account to sync from.
    final isGuest = ref.read(isGuestModeProvider);
    debugPrint('[Sync] pullCloudToLocal: isGuest=$isGuest');
    ref.read(syncErrorMessageProvider.notifier).state = null;
    if (isGuest) {
      ref.read(syncErrorMessageProvider.notifier).state = 'Cannot sync in guest mode. Please sign in.';
      return;
    }
    ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
    debugPrint('[Sync] Starting pull from cloud...');
    try {
      await _pullGoals();
      await _pullTasks();
      ref.read(syncStatusProvider.notifier).state = SyncStatus.idle;
      debugPrint('[Sync] Pull completed successfully');
    } on DioException catch (e) {
      String msg;
      if (e.type == DioExceptionType.connectionTimeout) {
        msg = 'Server is starting up (may take 30s). Tap to retry...';
      } else {
        msg = e.message ?? 'Network error';
      }
      debugPrint('[Sync] Pull failed: $msg');
      ref.read(syncErrorMessageProvider.notifier).state = 'Sync failed: $msg';
      ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
    } catch (e) {
      debugPrint('[Sync] Pull failed with error: $e');
      ref.read(syncErrorMessageProvider.notifier).state = 'Sync failed: $e';
      ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
    }
  }

  Future<void> _pullGoals() async {
    final res = await dio.get<List<dynamic>>('/tasks/goals');
    final rows = res.data ?? [];
    for (final raw in rows) {
      final m = raw as Map<String, dynamic>;
      await goalDao.insertGoal(
        GoalsTableCompanion(
          id: Value(m['id'] as String),
          title: Value(m['title'] as String),
          type: Value(m['type'] as String? ?? 'project'),
          durationHours: Value(m['duration_hours'] as int?),
          createdAt: Value(DateTime.parse(m['created_at'] as String)),
        ),
      );
    }
  }

  Future<void> _pullTasks() async {
    final res = await dio.get<List<dynamic>>('/tasks');
    final rows = res.data ?? [];
    final companions = rows.map((raw) {
      final m = raw as Map<String, dynamic>;

      DateTime? parseDt(dynamic v) =>
          v == null ? null : DateTime.parse(v as String);

      return TasksTableCompanion(
        id: Value(m['id'] as String),
        title: Value(m['title'] as String),
        description: Value(m['description'] as String?),
        purpose: Value(m['purpose'] as String?),
        iconId: Value(m['icon_id'] as String?),
        colorArgb: Value(m['color_argb'] as int?),
        graphicImage: const Value(null),
        tagsJson: Value(m['tags_json'] as String? ?? '[]'),
        startMinutes: Value(m['start_minutes'] as int?),
        durationMinutes: Value(m['duration_minutes'] as int?),
        recurrenceType:
            Value(m['recurrence_type'] as String? ?? 'none'),
        recurrenceRule: Value(m['recurrence_rule'] as String?),
        repeatIntervalMinutes:
            Value(m['repeat_interval_minutes'] as int?),
        notificationEnabled:
            Value(m['notification_enabled'] as bool? ?? true),
        notificationOffsetMinutes:
            Value(m['notification_offset_minutes'] as int? ?? 5),
        status: Value(m['status'] as String? ?? 'pending'),
        completedAt: Value(parseDt(m['completed_at'])),
        taskDate: Value(
          (m['task_date'] as String).substring(0, 10),
        ),
        parentTaskId: Value(m['parent_task_id'] as String?),
        goalId: Value(m['goal_id'] as String?),
        createdAt: Value(DateTime.parse(m['created_at'] as String)),
        updatedAt: Value(DateTime.parse(m['updated_at'] as String)),
      );
    }).toList();

    // Upsert each task individually using InsertMode.replace (last row wins at the
    // Drift level; cloud already chose last-write-wins before returning)
    for (final c in companions) {
      await taskDao.upsertTask(c);
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepositoryImpl(
    dio: ref.watch(apiClientProvider),
    taskDao: ref.watch(taskDaoProvider),
    goalDao: ref.watch(goalDaoProvider),
    ref: ref,
  );
});
