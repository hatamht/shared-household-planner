import 'package:equatable/equatable.dart';

/// Defines how a data conflict was resolved
enum ConflictResolution {
  /// Remote (cloud) version wins — newer timestamp
  remoteWins,

  /// Local version wins — newer local timestamp
  localWins,

  /// Remote deleted, local edited — local changes preserved safely
  deleteVsEditPreserveLocal,

  /// Remote deleted, local deleted — no-op
  bothDeleted,

  /// Rollback: local state preserved as-is, will be re-synced later
  rollback,
}

/// Represents a detected conflict between local and remote versions of an entity
class ConflictItem extends Equatable {
  /// Unique identifier for this conflict record
  final String id;

  /// Type of entity ('bill', 'project', 'settlement')
  final String entityType;

  /// ID of the conflicted entity
  final String entityId;

  /// The local entity payload (may be null if local was deleted)
  final Map<String, dynamic>? localData;

  /// The remote entity payload (may be null if remote was deleted)
  final Map<String, dynamic>? remoteData;

  /// Timestamp of the local version
  final DateTime? localUpdatedAt;

  /// Timestamp of the remote version
  final DateTime? remoteUpdatedAt;

  /// When this conflict was detected
  final DateTime detectedAt;

  const ConflictItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    this.localData,
    this.remoteData,
    this.localUpdatedAt,
    this.remoteUpdatedAt,
    required this.detectedAt,
  });

  /// True if the remote entity was deleted
  bool get isRemoteDeleted => remoteData == null;

  /// True if the local entity was deleted
  bool get isLocalDeleted => localData == null;

  /// True if both sides have data (concurrent edits)
  bool get isConcurrentEdit => localData != null && remoteData != null;

  ConflictItem copyWith({
    String? id,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? localData,
    Map<String, dynamic>? remoteData,
    DateTime? localUpdatedAt,
    DateTime? remoteUpdatedAt,
    DateTime? detectedAt,
  }) {
    return ConflictItem(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      localData: localData ?? this.localData,
      remoteData: remoteData ?? this.remoteData,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
      detectedAt: detectedAt ?? this.detectedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'entityType': entityType,
        'entityId': entityId,
        'localData': localData,
        'remoteData': remoteData,
        'localUpdatedAt': localUpdatedAt?.toIso8601String(),
        'remoteUpdatedAt': remoteUpdatedAt?.toIso8601String(),
        'detectedAt': detectedAt.toIso8601String(),
      };

  factory ConflictItem.fromMap(Map<String, dynamic> map) => ConflictItem(
        id: map['id'] as String,
        entityType: map['entityType'] as String,
        entityId: map['entityId'] as String,
        localData: map['localData'] != null
            ? Map<String, dynamic>.from(map['localData'] as Map)
            : null,
        remoteData: map['remoteData'] != null
            ? Map<String, dynamic>.from(map['remoteData'] as Map)
            : null,
        localUpdatedAt: map['localUpdatedAt'] != null
            ? DateTime.tryParse(map['localUpdatedAt'] as String)
            : null,
        remoteUpdatedAt: map['remoteUpdatedAt'] != null
            ? DateTime.tryParse(map['remoteUpdatedAt'] as String)
            : null,
        detectedAt: map['detectedAt'] != null
            ? DateTime.tryParse(map['detectedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  @override
  List<Object?> get props => [
        id,
        entityType,
        entityId,
        localData,
        remoteData,
        localUpdatedAt,
        remoteUpdatedAt,
        detectedAt,
      ];
}

/// Result of a conflict resolution operation
class ConflictResult extends Equatable {
  /// The conflict item that was resolved
  final ConflictItem conflict;

  /// How the conflict was resolved
  final ConflictResolution resolution;

  /// The winning payload to persist (may be null if both were deleted)
  final Map<String, dynamic>? resolvedData;

  /// Human-readable message describing what happened
  final String message;

  /// Whether local SQLite data needs to be updated
  final bool requiresLocalUpdate;

  /// Whether remote Firestore data needs to be updated
  final bool requiresRemoteUpdate;

  const ConflictResult({
    required this.conflict,
    required this.resolution,
    this.resolvedData,
    required this.message,
    this.requiresLocalUpdate = false,
    this.requiresRemoteUpdate = false,
  });

  bool get isRemoteWins => resolution == ConflictResolution.remoteWins;
  bool get isLocalWins => resolution == ConflictResolution.localWins;
  bool get isDeleteVsEdit =>
      resolution == ConflictResolution.deleteVsEditPreserveLocal;
  bool get isRollback => resolution == ConflictResolution.rollback;
  bool get isBothDeleted => resolution == ConflictResolution.bothDeleted;

  @override
  List<Object?> get props =>
      [conflict, resolution, resolvedData, message, requiresLocalUpdate, requiresRemoteUpdate];
}
