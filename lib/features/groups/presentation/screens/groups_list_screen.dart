import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskstack/features/auth/presentation/providers/auth_provider.dart';
import 'package:taskstack/features/groups/presentation/providers/group_provider.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // ── Guest gate ──────────────────────────────────────────────────────────
    if (isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('Social')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded,
                    size: 72, color: cs.onSurfaceVariant),
                const SizedBox(height: 24),
                Text(
                  'Sign in to use Social',
                  style: tt.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Groups, invites, and profiles are only available when you have an account.',
                  style: tt.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/signup'),
                  child: const Text('Create an account'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final groupsAsync = ref.watch(groupNotifierProvider);
    final pendingCount =
        ref.watch(inviteNotifierProvider.notifier).pendingCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.mail_outline),
                tooltip: 'Invites',
                onPressed: () => _showInvitesSheet(context, ref),
              ),
              if (pendingCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: cs.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$pendingCount',
                      style: TextStyle(
                          color: cs.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: groupsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: cs.error),
              const SizedBox(height: 12),
              Text('$e'),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () =>
                    ref.read(groupNotifierProvider.notifier).load(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group_outlined,
                      size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 16),
                  Text('No groups yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Create one or join via invite code',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  FilledButton.tonal(
                    onPressed: () => context.push('/groups/join'),
                    child: const Text('Join with Code'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(groupNotifierProvider.notifier).load(),
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: groups.length,
              itemBuilder: (context, i) {
                final g = groups[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      child: Text(
                        g.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(color: cs.onPrimaryContainer),
                      ),
                    ),
                    title: Text(g.name),
                    subtitle: g.description != null
                        ? Text(g.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)
                        : null,
                    trailing: Chip(label: Text(g.role ?? 'member')),
                    onTap: () => context.push('/groups/${g.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'join',
            tooltip: 'Scan QR / Enter Code',
            onPressed: () => context.push('/groups/join'),
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'create',
            onPressed: () => context.push('/groups/new'),
            icon: const Icon(Icons.add),
            label: const Text('New Group'),
          ),
        ],
      ),
    );
  }

  void _showInvitesSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _InvitesSheet(ref: ref),
    );
  }
}

// ── Inline Invites Sheet ───────────────────────────────────────────────────────

class _InvitesSheet extends ConsumerWidget {
  const _InvitesSheet({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final invitesAsync = ref.watch(inviteNotifierProvider);
    final notifier = ref.read(inviteNotifierProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (ctx, ctrl) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Pending Invites',
                style: Theme.of(context).textTheme.titleLarge),
          ),
          Expanded(
            child: invitesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (invites) {
                if (invites.isEmpty) {
                  return Center(
                    child: Text('No pending invites',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  );
                }
                return ListView.builder(
                  controller: ctrl,
                  itemCount: invites.length,
                  itemBuilder: (_, i) {
                    final inv = invites[i];
                    return ListTile(
                      title: Text(inv.groupName),
                      subtitle: Text('From @${inv.inviterUsername}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.close,
                                color: cs.error),
                            tooltip: 'Reject',
                            onPressed: () =>
                                notifier.reject(inv.id),
                          ),
                          IconButton(
                            icon: Icon(Icons.check,
                                color: cs.primary),
                            tooltip: 'Accept',
                            onPressed: () =>
                                notifier.accept(inv.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
