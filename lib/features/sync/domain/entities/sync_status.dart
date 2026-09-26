import 'package:equatable/equatable.dart';

/// Enum representing the synchronization state
enum SyncState {
  synced,
  syncing,
  pending,
  offline,
  error,
}

/// Entity representing the overall or project-level sync status
class SyncStatus extends Equatable {
  final SyncState state;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  const SyncStatus({
    this.state = SyncState.synced,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.errorMessage,
  });

  bool get isSyncing => state == SyncState.syncing;
  bool get isOffline => state == SyncState.offline;
  bool get isSynced => state == SyncState.synced && pendingCount == 0;
  bool get hasPending => pendingCount > 0;
  bool get hasError => state == SyncState.error;

  SyncStatus copyWith({
    SyncState? state,
    int? pendingCount,
    DateTime? lastSyncedAt,
    String? errorMessage,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Format last synced time into human readable relative string
  String formatRelativeTime({
    required String justNowText,
    required String minutesAgoTemplate,
    required String hoursAgoTemplate,
    required String neverText,
  }) {
    if (lastSyncedAt == null) return neverText;

    final diff = DateTime.now().difference(lastSyncedAt!);
    if (diff.inSeconds < 45) {
      return justNowText;
    } else if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      return minutesAgoTemplate.replaceAll('{minutes}', '$mins');
    } else if (diff.inHours < 24) {
      final hours = diff.inHours;
      return hoursAgoTemplate.replaceAll('{hours}', '$hours');
    } else {
      return '${lastSyncedAt!.day}/${lastSyncedAt!.month} ${lastSyncedAt!.hour.toString().padLeft(2, '0')}:${lastSyncedAt!.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  List<Object?> get props => [state, pendingCount, lastSyncedAt, errorMessage];
}

/// Item inside the local background sync queue
class SyncQueueItem extends Equatable {
  final String id;
  final String entityType; // 'project', 'bill', 'settlement'
  final String entityId;
  final String action; // 'create', 'update', 'delete'
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  const SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  SyncQueueItem copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? action,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? retryCount,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'entityType': entityType,
        'entityId': entityId,
        'action': action,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) => SyncQueueItem(
        id: map['id'] as String,
        entityType: map['entityType'] as String,
        entityId: map['entityId'] as String,
        action: map['action'] as String,
        payload: Map<String, dynamic>.from(map['payload'] as Map),
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [id, entityType, entityId, action, payload, createdAt, retryCount];
}
