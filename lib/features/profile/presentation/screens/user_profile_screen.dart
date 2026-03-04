import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/features/profile/presentation/providers/profile_provider.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          final isPrivate = e.toString().contains('private');
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPrivate ? Icons.lock_outline : Icons.error_outline,
                  size: 64,
                  color: cs.outlineVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  isPrivate ? 'Profile is private' : 'Failed to load profile',
                  style: tt.titleMedium,
                ),
                if (isPrivate)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 32, right: 32),
                    child: Text(
                      'You need to be in the same group to view this profile.',
                      style: tt.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          );
        },
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: cs.primaryContainer,
                backgroundImage: profile.avatarUrl != null
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null
                    ? Text(
                        profile.username[0].toUpperCase(),
                        style: TextStyle(
                            fontSize: 40,
                            color: cs.onPrimaryContainer),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(profile.displayName, style: tt.headlineSmall),
              Text('@${profile.username}',
                  style: tt.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              if (profile.isPublic)
                Chip(
                  label: const Text('Public'),
                  avatar: const Icon(Icons.public, size: 16),
                  backgroundColor: cs.secondaryContainer,
                )
              else
                Chip(
                  label: const Text('Private'),
                  avatar: const Icon(Icons.lock, size: 16),
                ),
              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bio', style: tt.labelLarge),
                          const SizedBox(height: 4),
                          Text(profile.bio!),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Member since ${profile.createdAt.year}',
                style: tt.bodySmall?.copyWith(color: cs.outlineVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
