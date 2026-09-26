import 'package:equatable/equatable.dart';
import '../../domain/entities/sync_status.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

/// Trigger sync immediately (e.g. from manual sync button)
class TriggerSyncEvent extends SyncEvent {
  final String? projectId;

  const TriggerSyncEvent({this.projectId});

  @override
  List<Object?> get props => [projectId];
}

/// Event dispatched when sync status changes in SyncService
class SyncStatusUpdatedEvent extends SyncEvent {
  final SyncStatus status;

  const SyncStatusUpdatedEvent(this.status);

  @override
  List<Object?> get props => [status];
}

/// Enqueue a change to the sync queue
class EnqueueSyncItemEvent extends SyncEvent {
  final SyncQueueItem item;

  const EnqueueSyncItemEvent(this.item);

  @override
  List<Object?> get props => [item];
}

/// Clear pending queue
class ClearSyncQueueEvent extends SyncEvent {
  const ClearSyncQueueEvent();
}
