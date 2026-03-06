import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/features/groups/data/repositories/group_repository_impl.dart';
import 'package:taskstack/features/groups/domain/entities/group.dart';
import 'package:taskstack/features/groups/domain/entities/invite.dart';
import 'package:taskstack/features/groups/domain/repositories/group_repository.dart';

// ── Group Notifier ─────────────────────────────────────────────────────────────

class GroupNotifier extends Notifier<AsyncValue<List<Group>>> {
  @override
  AsyncValue<List<Group>> build() {
    load();
    return const AsyncValue.loading();
  }

  GroupRepository get _repo => ref.read(groupRepositoryProvider);

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final groups = await _repo.fetchMyGroups();
      state = AsyncValue.data(groups);
    } on DioException catch (e) {
      state = AsyncValue.error(
        e.response?.data['error'] ?? e.message ?? 'Network error',
        StackTrace.current,
      );
    }
  }

  Future<bool> create(String name, String? description) async {
    try {
      final group = await _repo.createGroup(
        name: name,
        description: description,
      );
      state = AsyncValue.data([group, ...state.value ?? []]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> joinByCode(String code) async {
    try {
      await _repo.joinByCode(code);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> inviteByUsername(String groupId, String username) async {
    try {
      await _repo.inviteByUsername(groupId, username);
      return true;
    } on DioException catch (e) {
      return Future.error(
        e.response?.data['error'] ?? e.message ?? 'Network error',
      );
    }
  }
}

final groupNotifierProvider =
    NotifierProvider<GroupNotifier, AsyncValue<List<Group>>>(GroupNotifier.new);

// ── Group Detail Provider ──────────────────────────────────────────────────────

final groupDetailProvider = FutureProvider.autoDispose.family<Group, String>((
  ref,
  groupId,
) {
  return ref.watch(groupRepositoryProvider).fetchGroup(groupId);
});

final groupQrProvider = FutureProvider.autoDispose.family<String?, String>((
  ref,
  groupId,
) {
  return ref.watch(groupRepositoryProvider).fetchGroupQr(groupId);
});

// ── Invite Notifier ────────────────────────────────────────────────────────────

class InviteNotifier extends Notifier<AsyncValue<List<Invite>>> {
  @override
  AsyncValue<List<Invite>> build() {
    load();
    return const AsyncValue.loading();
  }

  GroupRepository get _repo => ref.read(groupRepositoryProvider);

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final invites = await _repo.fetchInvites();
      state = AsyncValue.data(invites);
    } on DioException catch (e) {
      state = AsyncValue.error(
        e.response?.data['error'] ?? e.message ?? 'Network error',
        StackTrace.current,
      );
    }
  }

  int get pendingCount => state.value?.length ?? 0;

  Future<void> accept(String inviteId) async {
    try {
      await _repo.acceptInvite(inviteId);
      await load();
    } catch (_) {}
  }

  Future<void> reject(String inviteId) async {
    try {
      await _repo.rejectInvite(inviteId);
      await load();
    } catch (_) {}
  }
}

final inviteNotifierProvider =
    NotifierProvider<InviteNotifier, AsyncValue<List<Invite>>>(
      InviteNotifier.new,
    );
