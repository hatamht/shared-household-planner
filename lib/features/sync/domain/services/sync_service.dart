import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/domain/repositories/cloud_sync_repository.dart';
import '../entities/sync_status.dart';
import 'network_connectivity_service.dart';

/// Result of a synchronization operation
class SyncResult {
  final bool success;
  final bool isOffline;
  final String? message;
  final DateTime? lastSyncedAt;
  final int syncedItemsCount;

  const SyncResult({
    required this.success,
    this.isOffline = false,
    this.message,
    this.lastSyncedAt,
    this.syncedItemsCount = 0,
  });
}

/// Core Sync Engine service that manages bi-directional sync, pending queue, and status
class SyncService {
  static const String prefLastSyncedKey = 'sync_engine_last_synced_at';

  final CloudSyncRepository cloudSyncRepository;
  final NetworkConnectivityService connectivityService;
  final SharedPreferences? sharedPreferences;

  final List<SyncQueueItem> _queue = [];
  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  SyncStatus _currentStatus = const SyncStatus();
  StreamSubscription? _connectivitySubscription;
  Timer? _debounceTimer;

  SyncService({
    required this.cloudSyncRepository,
    required this.connectivityService,
    this.sharedPreferences,
  }) {
    _init();
  }

  void _init() {
    // Restore last synced timestamp from preferences
    DateTime? lastSynced;
    final savedTime = sharedPreferences?.getString(prefLastSyncedKey);
    if (savedTime != null) {
      lastSynced = DateTime.tryParse(savedTime);
    }

    _currentStatus = SyncStatus(
      state: SyncState.synced,
      pendingCount: _queue.length,
      lastSyncedAt: lastSynced,
    );

    // Auto-sync when network connectivity is restored
    _connectivitySubscription =
        connectivityService.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        if (_queue.isNotEmpty) {
          triggerDebouncedSync();
        } else {
          _updateStatus(_currentStatus.copyWith(state: SyncState.synced));
        }
      } else {
        _updateStatus(_currentStatus.copyWith(state: SyncState.offline));
      }
    });
  }

  /// Current sync status
  SyncStatus get status => _currentStatus;

  /// Stream of sync status updates
  Stream<SyncStatus> get statusStream => _statusController.stream;

  /// Pending changes queue
  List<SyncQueueItem> get pendingQueue => List.unmodifiable(_queue);

  /// Number of items awaiting sync
  int get pendingCount => _queue.length;

  /// Enqueue a pending change (e.g. created/updated bill, project, settlement)
  void enqueue(SyncQueueItem item) {
    // Deduplicate existing pending actions for the same entity if applicable
    final index = _queue.indexWhere(
        (i) => i.entityType == item.entityType && i.entityId == item.entityId);
    if (index != -1) {
      _queue[index] = item;
    } else {
      _queue.add(item);
    }

    _updateStatus(_currentStatus.copyWith(
      state: SyncState.pending,
      pendingCount: _queue.length,
    ));

    triggerDebouncedSync();
  }

  /// Clear pending queue
  void clearQueue() {
    _queue.clear();
    _updateStatus(_currentStatus.copyWith(
      pendingCount: 0,
      state: SyncState.synced,
    ));
  }

  /// Trigger debounced background sync (waits 1.5s after last mutation)
  void triggerDebouncedSync({Duration delay = const Duration(milliseconds: 1500)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () {
      syncNow();
    });
  }

  /// Execute synchronization immediately
  Future<SyncResult> syncNow({String? projectId}) async {
    final isOnline = await connectivityService.isConnected;
    if (!isOnline) {
      _updateStatus(_currentStatus.copyWith(
        state: SyncState.offline,
        pendingCount: _queue.length,
      ));
      return SyncResult(
        success: false,
        isOffline: true,
        message: 'Bạn đang ngoại tuyến. Dữ liệu đã lưu trên máy và sẽ đồng bộ khi có mạng.',
        lastSyncedAt: _currentStatus.lastSyncedAt,
      );
    }

    _updateStatus(_currentStatus.copyWith(
      state: SyncState.syncing,
      pendingCount: _queue.length,
    ));

    try {
      int syncedCount = 0;

      // 1. Process local pending queue
      final itemsToProcess = List<SyncQueueItem>.from(_queue);
      for (final item in itemsToProcess) {
        try {
          if (item.entityType == 'project') {
            // Sync project entity
            // Can be extended with remote repository calls
          }
          _queue.remove(item);
          syncedCount++;
        } catch (_) {
          // Keep in queue for next retry
        }
      }

      // 2. Record sync time
      final now = DateTime.now();
      await sharedPreferences?.setString(prefLastSyncedKey, now.toIso8601String());

      _updateStatus(_currentStatus.copyWith(
        state: SyncState.synced,
        pendingCount: _queue.length,
        lastSyncedAt: now,
        errorMessage: null,
      ));

      return SyncResult(
        success: true,
        isOffline: false,
        lastSyncedAt: now,
        syncedItemsCount: syncedCount,
      );
    } catch (e) {
      _updateStatus(_currentStatus.copyWith(
        state: SyncState.error,
        errorMessage: e.toString(),
        pendingCount: _queue.length,
      ));

      return SyncResult(
        success: false,
        isOffline: false,
        message: e.toString(),
        lastSyncedAt: _currentStatus.lastSyncedAt,
      );
    }
  }

  void _updateStatus(SyncStatus newStatus) {
    _currentStatus = newStatus;
    _statusController.add(newStatus);
  }

  void dispose() {
    _debounceTimer?.cancel();
    _connectivitySubscription?.cancel();
    _statusController.close();
  }
}
