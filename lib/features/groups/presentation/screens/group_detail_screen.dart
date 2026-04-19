import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:taskstack/features/groups/presentation/providers/group_provider.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({super.key, required this.groupId});
  final String groupId;

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  final _inviteCtrl = TextEditingController();

  @override
  void dispose() {
    _inviteCtrl.dispose();
    super.dispose();
  }

  Future<void> _showInviteDialog() async {
    _inviteCtrl.clear();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.person_add_outlined),
        title: const Text('Invite Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the username of the person you want to invite to this group.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const Gap(16),
            TextField(
              controller: _inviteCtrl,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: const Icon(Icons.alternate_email),
                hintText: 'e.g. johndoe',
                filled: true,
                fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final username = _inviteCtrl.text.trim();
              if (username.isEmpty) return;
              try {
                await ref
                    .read(groupNotifierProvider.notifier)
                    .inviteByUsername(widget.groupId, username);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invite sent to @$username'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
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
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: groupAsync.when(
          data: (g) => Text(g.name),
          loading: () => const Text('Group Details'),
          error: (_, __) => const Text('Error'),
        ),
        titleTextStyle: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_outlined),
            tooltip: 'Group QR Code',
            onPressed: () => context.push('/groups/${widget.groupId}/qr'),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Invite Member',
            onPressed: _showInviteDialog,
          ),
          const Gap(8),
        ],
      ),
      body: groupAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: cs.error),
              const Gap(16),
              Text('Failed to load group', style: tt.titleLarge),
              const Gap(8),
              Text(e.toString(), style: tt.bodyMedium),
              const Gap(24),
              FilledButton.tonal(
                onPressed: () => ref.refresh(groupDetailProvider(widget.groupId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (group) => RefreshIndicator(
          onRefresh: () => ref.refresh(groupDetailProvider(widget.groupId).future),
          child: CustomScrollView(
            slivers: [
              if (group.description != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 0,
                      color: cs.primaryContainer.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: cs.primaryContainer.withOpacity(0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: cs.primary, size: 20),
                            const Gap(12),
                            Expanded(
                              child: Text(
                                group.description!,
                                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                  child: Row(
                    children: [
                      Text(
                        'Members',
                        style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Gap(12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${group.members.length}',
                          style: tt.labelLarge?.copyWith(
                            color: cs.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final m = group.members[i];
                      final isOwner = m.role == 'owner';
                      
                      return Card(
                        elevation: 0,
                        color: cs.surfaceContainerLow,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: cs.outlineVariant.withOpacity(0.3)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: cs.outlineVariant.withOpacity(0.5), width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: cs.primaryContainer,
                              backgroundImage: m.avatarUrl != null
                                  ? NetworkImage(m.avatarUrl!)
                                  : null,
                              child: m.avatarUrl == null
                                  ? Text(
                                      m.username[0].toUpperCase(),
                                      style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                          ),
                          title: Text(
                            m.displayName ?? m.username,
                            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '@${m.username}',
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOwner ? cs.primaryContainer : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              m.role,
                              style: tt.labelSmall?.copyWith(
                                color: isOwner ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () => context.push('/profile/${m.id}'),
                        ),
                      );
                    },
                    childCount: group.members.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: Gap(100)),
            ],
          ),
        ),
      ),
      floatingActionButton: groupAsync.hasValue ? FloatingActionButton.extended(
        onPressed: _showInviteDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Invite Member'),
      ) : null,
    );
  }
}
