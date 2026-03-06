import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SyncStatus { idle, syncing, error }

abstract class SyncRepository {
  Future<void> pushLocalToCloud();
  Future<void> pullCloudToLocal();
}

final syncStatusProvider = StateProvider<SyncStatus>((_) => SyncStatus.idle);

/// Stores the last sync error message for UI display
final syncErrorMessageProvider = StateProvider<String?>((_) => null);
