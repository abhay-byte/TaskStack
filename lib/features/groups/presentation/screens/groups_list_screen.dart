import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:taskstack/features/auth/presentation/providers/auth_provider.dart';
import 'package:taskstack/features/groups/presentation/providers/group_provider.dart';
import 'package:taskstack/core/widgets/animated_graphic.dart';

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
        appBar: AppBar(
          title: const Text('Social'),
          titleTextStyle: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 240,
                  child: AnimatedGraphic(
                    assetPath: 'assets/images/dashboard_illustration.svg',
                  ),
                ),
                const Gap(32),
                Text(
                  'Connect & Collaborate',
                  style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const Gap(12),
                Text(
                  'Join groups to share tasks, track group habits, and achieve goals together.',
                  style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const Gap(40),
                FilledButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In to Start'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(220, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const Gap(12),
                TextButton(
                  onPressed: () => context.go('/signup'),
                  child: Text(
                    'Create a new account',
                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final groupsAsync = ref.watch(groupNotifierProvider);
    final pendingCount = ref.watch(inviteNotifierProvider.notifier).pendingCount;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('My Groups'),
        titleTextStyle: tt.titleLarge?.copyWith(color: cs.onSurface),
        centerTitle: false,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Badge.count(
              count: pendingCount,
              isLabelVisible: pendingCount > 0,
              backgroundColor: cs.error,
              child: const Icon(Icons.mail_outline),
            ),
            tooltip: 'Invites',
            onPressed: () => _showInvitesSheet(context, ref),
          ),
          const Gap(8),
        ],
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: cs.errorContainer),
                const Gap(16),
                Text('Couldn\'t load groups', style: tt.titleLarge),
                const Gap(8),
                Text(
                  e.toString(),
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const Gap(24),
                FilledButton.tonalIcon(
                  onPressed: () => ref.read(groupNotifierProvider.notifier).load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.group_outlined, size: 80, color: cs.primary),
                    ),
                    const Gap(24),
                    Text('No Groups Yet', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const Gap(12),
                    Text(
                      'Groups help you stay accountable with friends. Create one or join with a code!',
                      style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(32),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push('/groups/join'),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Join with Code'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(200, 48),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(groupNotifierProvider.notifier).load(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const Gap(12),
              itemBuilder: (context, i) {
                final g = groups[i];
                final isOwner = g.role == 'owner';
                
                return Card(
                  elevation: 0,
                  color: cs.surfaceContainerLow,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: cs.outlineVariant.withOpacity(0.5), width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push('/groups/${g.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [cs.primaryContainer, cs.secondaryContainer],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                g.name.substring(0, 1).toUpperCase(),
                                style: tt.headlineSmall?.copyWith(
                                  color: cs.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const Gap(16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  g.name,
                                  style: tt.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                if (g.description != null) ...[
                                  const Gap(4),
                                  Text(
                                    g.description!,
                                    style: tt.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const Gap(8),
                                Row(
                                  children: [
                                    Icon(Icons.people_outline, size: 16, color: cs.onSurfaceVariant),
                                    const Gap(4),
                                    Text(
                                      '${g.members.length} members',
                                      style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Gap(8),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isOwner ? cs.primary : cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isOwner ? 'OWNER' : 'MEMBER',
                                  style: tt.labelSmall?.copyWith(
                                    color: isOwner ? cs.onPrimary : cs.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              if (isOwner)
                                PopupMenuButton<String>(
                                  icon: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.more_vert, color: cs.onSurfaceVariant, size: 20),
                                  ),
                                  padding: EdgeInsets.zero,
                                  offset: const Offset(0, 32),
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, color: Colors.red),
                                          Gap(12),
                                          Text('Delete group'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      _confirmDeleteGroup(context, ref, g);
                                    }
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'join',
            tooltip: 'Join via QR or Code',
            backgroundColor: cs.secondaryContainer,
            foregroundColor: cs.onSecondaryContainer,
            onPressed: () => context.push('/groups/join'),
            child: const Icon(Icons.qr_code_scanner),
          ),
          const Gap(16),
          FloatingActionButton.extended(
            heroTag: 'create',
            onPressed: () => context.push('/groups/new'),
            icon: const Icon(Icons.add),
            label: const Text('New Group'),
            elevation: 4,
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context, WidgetRef ref, dynamic group) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_forever_outlined, color: cs.error, size: 32),
        title: const Text('Delete Group?'),
        content: Text(
          'This will permanently delete "${group.name}" and remove all members. This action cannot be undone.',
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(groupNotifierProvider.notifier).delete(group.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Group deleted'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: cs.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showInvitesSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
    final tt = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, ctrl) => Column(
        children: [
          const Gap(12),
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text('Pending Invites', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (invitesAsync.hasValue && invitesAsync.value!.isNotEmpty)
                  Badge(
                    label: Text('${invitesAsync.value!.length}'),
                    largeSize: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
              ],
            ),
          ),
          const Gap(16),
          Expanded(
            child: invitesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (invites) {
                if (invites.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mail_outline, size: 64, color: cs.outlineVariant),
                        const Gap(16),
                        Text(
                          'No pending invites',
                          style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  controller: ctrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: invites.length,
                  separatorBuilder: (_, __) => const Gap(12),
                  itemBuilder: (_, i) {
                    final inv = invites[i];
                    return Card(
                      elevation: 0,
                      color: cs.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(inv.groupName, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          subtitle: Text('Invited by @${inv.inviterUsername}', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton.filledTonal(
                                icon: Icon(Icons.close, color: cs.error, size: 20),
                                onPressed: () => notifier.reject(inv.id),
                                tooltip: 'Reject',
                              ),
                              const Gap(8),
                              IconButton.filled(
                                icon: const Icon(Icons.check, size: 20),
                                onPressed: () => notifier.accept(inv.id),
                                tooltip: 'Accept',
                              ),
                            ],
                          ),
                        ),
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
