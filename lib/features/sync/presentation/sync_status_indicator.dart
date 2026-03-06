import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/features/sync/domain/repositories/sync_repository.dart';
import 'package:taskstack/features/sync/data/repositories/sync_repository_impl.dart';

/// Small icon in the app bar reflecting the current sync state.
/// - idle  → hidden (no clutter)
/// - syncing → spinning cloud icon
/// - error → cloud_off icon (tappable to retry)
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Debug: always show icon to see what's happening
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: switch (status) {
        SyncStatus.idle => IconButton(
            tooltip: 'Synced',
            icon: Icon(Icons.cloud_done_rounded, color: colorScheme.primary),
            onPressed: () {
              ref.read(syncRepositoryProvider).pullCloudToLocal();
            },
          ),
        SyncStatus.syncing => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colorScheme.primary,
              ),
            ),
          ),
        SyncStatus.error => IconButton(
            tooltip: 'Sync failed – tap to retry',
            icon: Icon(Icons.cloud_off_rounded, color: colorScheme.error),
            onPressed: () {
              ref.read(syncRepositoryProvider).pushLocalToCloud();
            },
          ),
      },
    );
  }
}
