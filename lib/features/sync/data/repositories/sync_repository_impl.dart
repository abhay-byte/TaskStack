import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/core/providers/guest_mode_provider.dart';
import 'package:taskstack/database/app_database.dart';
import 'package:taskstack/database/daos/goal_dao.dart';
import 'package:taskstack/database/daos/task_dao.dart';
import 'package:taskstack/features/sync/domain/repositories/sync_repository.dart';

class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl({
    required this.firestore,
    required this.auth,
    required this.taskDao,
    required this.goalDao,
    required this.ref,
  });

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final TaskDao taskDao;
  final GoalDao goalDao;
  final Ref ref;

  String? get _uid => auth.currentUser?.uid;

  // ── PUSH: local → cloud ────────────────────────────────────────────────────

  @override
  Future<void> pushLocalToCloud() async {
    final isGuest = ref.read(isGuestModeProvider);
    debugPrint('[Sync] pushLocalToCloud: isGuest=$isGuest');
    ref.read(syncErrorMessageProvider.notifier).state = null;
    if (isGuest || _uid == null) {
      ref.read(syncErrorMessageProvider.notifier).state =
          'Cannot sync in guest mode. Please sign in.';
      return;
    }
    ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
    debugPrint('[Sync] Starting push to cloud...');
    try {
      await _pushGoals();
      await _pushTasks();
      ref.read(syncStatusProvider.notifier).state = SyncStatus.idle;
      debugPrint('[Sync] Push completed successfully');
    } on FirebaseException catch (e) {
      final msg = e.message ?? 'Firebase error';
      debugPrint('[Sync] Push failed: $msg');
      ref.read(syncErrorMessageProvider.notifier).state = 'Sync failed: $msg';
      ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
    } catch (e) {
      debugPrint('[Sync] Push failed: $e');
      ref.read(syncErrorMessageProvider.notifier).state = 'Sync failed: $e';
      ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
    }
  }

  Future<void> _pushGoals() async {
    final goals = await goalDao.getAllGoals();
    if (goals.isEmpty) return;
    final uid = _uid!;
    // Firestore max batch size = 500
    final chunks = _chunk(goals, 400);
    for (final chunk in chunks) {
      final batch = firestore.batch();
      for (final g in chunk) {
        final ref = firestore
            .collection('users')
            .doc(uid)
            .collection('goals')
            .doc(g.id);
        // Last-write-wins: only overwrite if our updatedAt is newer
        batch.set(ref, {
          'id': g.id,
          'title': g.title,
          'type': g.type,
          'durationHours': g.durationHours,
          'createdAt': g.createdAt.toUtc().toIso8601String(),
          'updatedAt': g.updatedAt.toUtc().toIso8601String(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
    }
    debugPrint('[Sync] Pushed ${goals.length} goals');
  }

  Future<void> _pushTasks() async {
    final tasks = await taskDao.getAllTasks();
    if (tasks.isEmpty) return;
    final uid = _uid!;
    final chunks = _chunk(tasks, 400);
    for (final chunk in chunks) {
      final batch = firestore.batch();
      for (final t in chunk) {
        final ref = firestore
            .collection('users')
            .doc(uid)
            .collection('tasks')
            .doc(t.id);
        batch.set(ref, {
          'id': t.id,
          'title': t.title,
          'description': t.description,
          'purpose': t.purpose,
          'iconId': t.iconId,
          'colorArgb': t.colorArgb != null ? t.colorArgb! & 0xFFFFFFFF : null,
          'tagsJson': t.tagsJson,
          'startMinutes': t.startMinutes,
          'durationMinutes': t.durationMinutes,
          'recurrenceType': t.recurrenceType,
          'recurrenceRule': t.recurrenceRule,
          'repeatIntervalMinutes': t.repeatIntervalMinutes,
          'notificationEnabled': t.notificationEnabled,
          'notificationOffsetMinutes': t.notificationOffsetMinutes,
          'status': t.status,
          'completedAt': t.completedAt?.toUtc().toIso8601String(),
          'taskDate': t.taskDate,
          'graphicImage': t.graphicImage,
          'parentTaskId': t.parentTaskId,
          'goalId': t.goalId,
          'createdAt': t.createdAt.toUtc().toIso8601String(),
          'updatedAt': t.updatedAt.toUtc().toIso8601String(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
    }
    debugPrint('[Sync] Pushed ${tasks.length} tasks');
  }

  // ── PULL: cloud → local ────────────────────────────────────────────────────

  @override
  Future<void> pullCloudToLocal() async {
    final isGuest = ref.read(isGuestModeProvider);
    debugPrint('[Sync] pullCloudToLocal: isGuest=$isGuest');
    ref.read(syncErrorMessageProvider.notifier).state = null;
    if (isGuest || _uid == null) {
      ref.read(syncErrorMessageProvider.notifier).state =
          'Cannot sync in guest mode. Please sign in.';
      return;
    }
    ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
    debugPrint('[Sync] Starting pull from cloud...');
    try {
      await _pullGoals();
      await _pullTasks();
      ref.read(syncStatusProvider.notifier).state = SyncStatus.idle;
      debugPrint('[Sync] Pull completed successfully');
    } on FirebaseException catch (e) {
      final msg = e.message ?? 'Firebase error';
      debugPrint('[Sync] Pull failed: $msg');
      ref.read(syncErrorMessageProvider.notifier).state = 'Sync failed: $msg';
      ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
    } catch (e) {
      debugPrint('[Sync] Pull failed: $e');
      ref.read(syncErrorMessageProvider.notifier).state = 'Sync failed: $e';
      ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
    }
  }

  Future<void> _pullGoals() async {
    final uid = _uid!;
    final snap = await firestore
        .collection('users')
        .doc(uid)
        .collection('goals')
        .get();
    for (final doc in snap.docs) {
      final m = doc.data();
      await goalDao.insertGoal(
        GoalsTableCompanion(
          id: Value(m['id'] as String),
          title: Value(m['title'] as String),
          type: Value(m['type'] as String? ?? 'project'),
          durationHours: Value(m['durationHours'] as int?),
          createdAt: Value(DateTime.parse(m['createdAt'] as String)),
          updatedAt: Value(DateTime.parse(m['updatedAt'] as String)),
        ),
      );
    }
    debugPrint('[Sync] Pulled ${snap.docs.length} goals');
  }

  Future<void> _pullTasks() async {
    final uid = _uid!;
    final snap = await firestore
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .get();

    for (final doc in snap.docs) {
      final m = doc.data();
      DateTime? parseDt(dynamic v) =>
          v == null ? null : DateTime.parse(v as String);

      await taskDao.upsertTask(
        TasksTableCompanion(
          id: Value(m['id'] as String),
          title: Value(m['title'] as String),
          description: Value(m['description'] as String?),
          purpose: Value(m['purpose'] as String?),
          iconId: Value(m['iconId'] as String?),
          colorArgb: Value(
            m['colorArgb'] == null
                ? null
                : int.parse(m['colorArgb'].toString()),
          ),
          graphicImage: Value(m['graphicImage'] as String?),
          tagsJson: Value(m['tagsJson'] as String? ?? '[]'),
          startMinutes: Value(m['startMinutes'] as int?),
          durationMinutes: Value(m['durationMinutes'] as int?),
          recurrenceType: Value(m['recurrenceType'] as String? ?? 'none'),
          recurrenceRule: Value(m['recurrenceRule'] as String?),
          repeatIntervalMinutes: Value(m['repeatIntervalMinutes'] as int?),
          notificationEnabled:
              Value(m['notificationEnabled'] as bool? ?? true),
          notificationOffsetMinutes:
              Value(m['notificationOffsetMinutes'] as int? ?? 5),
          status: Value(m['status'] as String? ?? 'pending'),
          completedAt: Value(parseDt(m['completedAt'])),
          taskDate: Value(
            (m['taskDate'] as String).substring(0, 10),
          ),
          parentTaskId: Value(m['parentTaskId'] as String?),
          goalId: Value(m['goalId'] as String?),
          createdAt: Value(DateTime.parse(m['createdAt'] as String)),
          updatedAt: Value(DateTime.parse(m['updatedAt'] as String)),
        ),
      );
    }
    debugPrint('[Sync] Pulled ${snap.docs.length} tasks');
  }

  List<List<T>> _chunk<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, i + size < list.length ? i + size : list.length));
    }
    return chunks;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepositoryImpl(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    taskDao: ref.watch(taskDaoProvider),
    goalDao: ref.watch(goalDaoProvider),
    ref: ref,
  );
});
