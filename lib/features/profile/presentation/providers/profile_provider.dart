import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/features/auth/domain/entities/auth_user.dart';
import 'package:taskstack/features/profile/domain/entities/user_profile.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';

// ── Profile Repository ─────────────────────────────────────────────────────────

class ProfileRepository {
  ProfileRepository(this._firestore, this._auth);
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid => _auth.currentUser!.uid;

  Future<UserProfile> fetchMe() async {
    final doc = await _firestore.collection('users').doc(_uid).get();
    if (!doc.exists) throw Exception('Profile not found.');
    return UserProfile.fromFirestore(doc.id, doc.data()!);
  }

  Future<AuthUser> updateMe({
    String? displayName,
    String? bio,
    String? avatarUrl,
    bool? isPublic,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (bio != null) updates['bio'] = bio;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
    if (isPublic != null) updates['isPublic'] = isPublic;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(_uid).update(updates);
    }

    final doc = await _firestore.collection('users').doc(_uid).get();
    final data = doc.data()!;
    return AuthUser(
      id: _uid,
      username: data['username'] as String? ?? '',
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      bio: data['bio'] as String?,
      isPublic: data['isPublic'] as bool? ?? false,
    );
  }

  Future<UserProfile> fetchUser(String userId) async {
    final doc = await _visibleUserDoc(userId);
    return UserProfile.fromFirestore(userId, doc.data()!);
  }

  Future<List<Task>> fetchUserTasks(String userId) async {
    await _visibleUserDoc(userId);

    if (userId == _uid) {
      return _fetchPrivateTasks(userId);
    }

    final sharedGroupIds = await _sharedGroupIdsFor(userId);
    if (sharedGroupIds.isEmpty) {
      throw Exception('Profile is private.');
    }

    final tasksById = <String, Task>{};
    for (final groupId in sharedGroupIds) {
      final snap =
          await _firestore
              .collection('groups')
              .doc(groupId)
              .collection('member_tasks')
              .where('userId', isEqualTo: userId)
              .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['deletedAt'] != null) continue;
        final task = _taskFromFirestore(doc.id, data);
        final existing = tasksById[task.id];
        if (existing == null || task.updatedAt.isAfter(existing.updatedAt)) {
          tasksById[task.id] = task;
        }
      }
    }

    final tasks = tasksById.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return tasks;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _visibleUserDoc(
    String userId,
  ) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) throw Exception('User not found.');
    final data = doc.data()!;

    final isPublic = data['isPublic'] as bool? ?? false;
    if (!isPublic && userId != _uid) {
      final myGroupIds = await _groupIdsFor(_uid);
      final theirGroupIds = await _groupIdsFor(userId);
      if (myGroupIds.intersection(theirGroupIds).isEmpty) {
        throw Exception('Profile is private.');
      }
    }
    return doc;
  }

  Future<Set<String>> _groupIdsFor(String userId) async {
    final groups =
        await _firestore
            .collection('group_members')
            .where('userId', isEqualTo: userId)
            .get();
    return groups.docs.map((d) => d.data()['groupId'] as String).toSet();
  }

  Future<List<Task>> _fetchPrivateTasks(String userId) async {
    final snap =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('tasks')
            .get();
    final tasks = <Task>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['deletedAt'] != null) continue;
      tasks.add(_taskFromFirestore(doc.id, data));
    }
    tasks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return tasks;
  }

  Future<Set<String>> _sharedGroupIdsFor(String userId) async {
    final myGroupIds = await _groupIdsFor(_uid);
    final theirGroupIds = await _groupIdsFor(userId);
    return myGroupIds.intersection(theirGroupIds);
  }

  Task _taskFromFirestore(String id, Map<String, dynamic> data) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) {
        return DateTime.tryParse(value);
      }
      final text = value.toString();
      return DateTime.tryParse(text);
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    bool parseBool(dynamic value, {bool fallback = false}) {
      if (value == null) return fallback;
      if (value is bool) return value;
      final text = value.toString().toLowerCase();
      return text == 'true' || text == '1';
    }

    List<String> parseTags(dynamic value) {
      if (value == null) return const [];
      if (value is List) {
        return value
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      final raw = value.toString();
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (_) {}
      return const [];
    }

    RecurrenceType parseRecurrenceType(dynamic value) {
      final text = value?.toString() ?? 'none';
      return RecurrenceType.values.firstWhere(
        (e) => e.name == text,
        orElse: () => RecurrenceType.none,
      );
    }

    TaskStatus parseStatus(dynamic value) {
      final text = value?.toString() ?? 'pending';
      return TaskStatus.values.firstWhere(
        (e) => e.name == text,
        orElse: () => TaskStatus.pending,
      );
    }

    final taskDate = parseDateTime(data['taskDate']) ?? DateTime.now();
    return Task(
      id: data['id']?.toString() ?? id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString(),
      purpose: data['purpose']?.toString(),
      iconId: data['iconId']?.toString(),
      graphicImage: data['graphicImage']?.toString(),
      colorArgb: parseInt(data['colorArgb']),
      tags: parseTags(data['tagsJson'] ?? data['tags']),
      startMinutes: parseInt(data['startMinutes']),
      durationMinutes: parseInt(data['durationMinutes']),
      recurrenceType: parseRecurrenceType(data['recurrenceType']),
      recurrenceRule: data['recurrenceRule']?.toString(),
      repeatIntervalMinutes: parseInt(data['repeatIntervalMinutes']),
      notificationEnabled: parseBool(
        data['notificationEnabled'],
        fallback: true,
      ),
      notificationOffsetMinutes:
          parseInt(data['notificationOffsetMinutes']) ?? 5,
      status: parseStatus(data['status']),
      completedAt: parseDateTime(data['completedAt']),
      createdAt: parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(data['updatedAt']) ?? DateTime.now(),
      parentTaskId: data['parentTaskId']?.toString(),
      goalId: data['goalId']?.toString(),
      taskDate: DateTime(taskDate.year, taskDate.month, taskDate.day),
    );
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

// ── Profile Providers ─────────────────────────────────────────────────────────

final myProfileProvider = FutureProvider.autoDispose<UserProfile>((ref) {
  return ref.watch(profileRepositoryProvider).fetchMe();
});

final userProfileProvider = FutureProvider.autoDispose
    .family<UserProfile, String>((ref, userId) {
      return ref.watch(profileRepositoryProvider).fetchUser(userId);
    });

final memberTasksProvider = FutureProvider.autoDispose
    .family<List<Task>, String>((ref, userId) {
      return ref.watch(profileRepositoryProvider).fetchUserTasks(userId);
    });

class MemberProfileStats {
  const MemberProfileStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.scheduledTasks,
    required this.inProgressTasks,
    required this.completionRate,
    required this.topTag,
    required this.mostActiveHour,
    required this.createdThisWeek,
  });

  final int totalTasks;
  final int completedTasks;
  final int scheduledTasks;
  final int inProgressTasks;
  final double completionRate;
  final String? topTag;
  final int? mostActiveHour;
  final int createdThisWeek;

  factory MemberProfileStats.fromTasks(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final totalTasks = tasks.length;
    final completedTasks = tasks.where((t) => t.isDone).length;
    final scheduledTasks = tasks.where((t) => t.startMinutes != null).length;
    final inProgressTasks =
        tasks
            .where(
              (t) =>
                  t.taskDate.year == today.year &&
                  t.taskDate.month == today.month &&
                  t.taskDate.day == today.day &&
                  t.isInProgress(now),
            )
            .length;
    final completionRate = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

    final tagCounts = <String, int>{};
    for (final task in tasks) {
      for (final tag in task.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    final sortedTags =
        tagCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final activeHours = List<int>.filled(24, 0);
    for (final task in tasks) {
      if (task.startMinutes != null) {
        activeHours[task.startMinutes! ~/ 60]++;
      }
    }
    final mostActiveHour =
        activeHours.every((count) => count == 0)
            ? null
            : activeHours.indexOf(activeHours.reduce((a, b) => a > b ? a : b));
    final createdThisWeek =
        tasks.where((task) => !task.createdAt.isBefore(weekStart)).length;

    return MemberProfileStats(
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      scheduledTasks: scheduledTasks,
      inProgressTasks: inProgressTasks,
      completionRate: completionRate,
      topTag: sortedTags.isEmpty ? null : sortedTags.first.key,
      mostActiveHour: mostActiveHour,
      createdThisWeek: createdThisWeek,
    );
  }
}

final memberProfileStatsProvider = FutureProvider.autoDispose
    .family<MemberProfileStats, String>((ref, userId) {
      return ref
          .watch(memberTasksProvider(userId).future)
          .then(MemberProfileStats.fromTasks);
    });
