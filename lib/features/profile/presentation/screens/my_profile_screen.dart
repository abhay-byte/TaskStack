import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/features/auth/presentation/providers/auth_provider.dart';
import 'package:taskstack/features/profile/presentation/providers/profile_provider.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  final _displayNameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _avatarCtrl = TextEditingController();
  bool _isPublic = false;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  void _loadFromProfile() {
    final profile = ref.read(myProfileProvider).valueOrNull;
    if (profile == null || _loaded) return;
    _displayNameCtrl.text = profile.displayName;
    _bioCtrl.text = profile.bio ?? '';
    _avatarCtrl.text = profile.avatarUrl ?? '';
    _isPublic = profile.isPublic;
    _loaded = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updatedUser = await ref
          .read(profileRepositoryProvider)
          .updateMe(
            displayName: _displayNameCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
            avatarUrl: _avatarCtrl.text.trim().isEmpty
                ? null
                : _avatarCtrl.text.trim(),
            isPublic: _isPublic,
          );
      ref.read(authNotifierProvider.notifier).updateUser(updatedUser);
      ref.invalidate(myProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(authNotifierProvider.notifier).logout();
    // GoRouter redirect will push to /login
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
    final cs = Theme.of(context).colorScheme;

    profileAsync.whenData((_) => _loadFromProfile());

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Avatar ──────────────────────────────────────────────────
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: cs.primaryContainer,
                  backgroundImage: profile.avatarUrl != null
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: profile.avatarUrl == null
                      ? Text(
                          profile.username[0].toUpperCase(),
                          style: TextStyle(
                              fontSize: 36,
                              color: cs.onPrimaryContainer),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('@${profile.username}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ),
              const SizedBox(height: 28),

              TextFormField(
                controller: _displayNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                maxLength: 60,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _bioCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLength: 280,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _avatarCtrl,
                decoration: const InputDecoration(
                  labelText: 'Avatar URL (optional)',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                title: const Text('Public Profile'),
                subtitle: const Text(
                    'Others can find you without being in the same group'),
                value: _isPublic,
                onChanged: (v) => setState(() => _isPublic = v),
              ),
              const SizedBox(height: 28),

              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
