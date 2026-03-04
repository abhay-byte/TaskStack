import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite by Username'),
        content: TextField(
          controller: _inviteCtrl,
          decoration: const InputDecoration(
            labelText: 'Username',
            prefixIcon: Icon(Icons.alternate_email),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
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
                    SnackBar(content: Text('Invite sent to @$username')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e')),
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

    return Scaffold(
      appBar: AppBar(
        title: groupAsync.when(
          data: (g) => Text(g.name),
          loading: () => const Text('Group'),
          error: (_, __) => const Text('Group'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: 'Show QR Code',
            onPressed: () => context.push('/groups/${widget.groupId}/qr'),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Invite',
            onPressed: _showInviteDialog,
          ),
        ],
      ),
      body: groupAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Failed to load: $e')),
        data: (group) => RefreshIndicator(
          onRefresh: () => ref.refresh(groupDetailProvider(widget.groupId).future),
          child: CustomScrollView(
            slivers: [
              if (group.description != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(group.description!),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    'Members (${group.members.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final m = group.members[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: m.avatarUrl != null
                            ? NetworkImage(m.avatarUrl!)
                            : null,
                        child: m.avatarUrl == null
                            ? Text(m.username[0].toUpperCase())
                            : null,
                      ),
                      title: Text(m.displayName ?? m.username),
                      subtitle: Text('@${m.username}'),
                      trailing: Chip(
                        label: Text(m.role),
                        backgroundColor: m.role == 'owner'
                            ? cs.primaryContainer
                            : cs.surfaceContainerHighest,
                      ),
                      onTap: () => context.push('/profile/${m.id}'),
                    );
                  },
                  childCount: group.members.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }
}
