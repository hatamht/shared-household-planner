import '../entities/conflict_item.dart';

/// Abstract contract for a conflict resolution strategy.
/// Inject different implementations (LWW, CRDT, etc.) as needed.
abstract class ConflictResolverStrategy {
  /// Resolves a conflict between local and remote versions.
  ConflictResult resolve(ConflictItem conflict);
}

/// Last-Write-Wins (LWW) strategy using [updatedAt] timestamps.
///
/// Rules:
/// 1. Both deleted → [ConflictResolution.bothDeleted] — no-op.
/// 2. Remote deleted, local edited → [ConflictResolution.deleteVsEditPreserveLocal]
///    — keep local, re-enqueue for upload.
/// 3. Local deleted, remote edited → [ConflictResolution.remoteWins]
///    — apply remote (resurrection).
/// 4. Both exist → compare [remoteUpdatedAt] vs [localUpdatedAt]:
///    - Remote newer → [ConflictResolution.remoteWins]
///    - Local newer (or tie) → [ConflictResolution.localWins]
class LastWriteWinsResolver implements ConflictResolverStrategy {
  const LastWriteWinsResolver();

  @override
  ConflictResult resolve(ConflictItem conflict) {
    // Case 1: Both deleted — no-op
    if (conflict.isRemoteDeleted && conflict.isLocalDeleted) {
      return ConflictResult(
        conflict: conflict,
        resolution: ConflictResolution.bothDeleted,
        resolvedData: null,
        message: 'Both local and remote versions are deleted. No action needed.',
        requiresLocalUpdate: false,
        requiresRemoteUpdate: false,
      );
    }

    // Case 2: Remote deleted, local has edits — preserve local (safe rollback)
    if (conflict.isRemoteDeleted && !conflict.isLocalDeleted) {
      return ConflictResult(
        conflict: conflict,
        resolution: ConflictResolution.deleteVsEditPreserveLocal,
        resolvedData: conflict.localData,
        message:
            'Remote deleted while local was edited. Local changes preserved and will be re-uploaded.',
        requiresLocalUpdate: false,
        requiresRemoteUpdate: true,
      );
    }

    // Case 3: Local deleted, remote has edits — remote wins (resurrection)
    if (conflict.isLocalDeleted && !conflict.isRemoteDeleted) {
      return ConflictResult(
        conflict: conflict,
        resolution: ConflictResolution.remoteWins,
        resolvedData: conflict.remoteData,
        message:
            'Local was deleted but remote has a newer version. Remote version restored.',
        requiresLocalUpdate: true,
        requiresRemoteUpdate: false,
      );
    }

    // Case 4: Both have data — compare timestamps
    final localTs = conflict.localUpdatedAt;
    final remoteTs = conflict.remoteUpdatedAt;

    // If no timestamps available, local wins (safe default)
    if (localTs == null && remoteTs == null) {
      return ConflictResult(
        conflict: conflict,
        resolution: ConflictResolution.localWins,
        resolvedData: conflict.localData,
        message: 'No timestamps available. Local version kept as safe default.',
        requiresLocalUpdate: false,
        requiresRemoteUpdate: true,
      );
    }

    // Remote timestamp is strictly newer
    if (remoteTs != null && (localTs == null || remoteTs.isAfter(localTs))) {
      return ConflictResult(
        conflict: conflict,
        resolution: ConflictResolution.remoteWins,
        resolvedData: conflict.remoteData,
        message:
            'Remote version (${remoteTs.toIso8601String()}) is newer than local (${localTs?.toIso8601String() ?? 'unknown'}). Remote applied.',
        requiresLocalUpdate: true,
        requiresRemoteUpdate: false,
      );
    }

    // Local timestamp is newer or equal — local wins
    return ConflictResult(
      conflict: conflict,
      resolution: ConflictResolution.localWins,
      resolvedData: conflict.localData,
      message:
          'Local version (${localTs?.toIso8601String() ?? 'unknown'}) is newer or equal to remote. Local kept.',
      requiresLocalUpdate: false,
      requiresRemoteUpdate: true,
    );
  }
}

/// Safe rollback strategy — always preserves local data without touching remote.
///
/// Used when a network error or unexpected cloud error prevents safe merging.
/// Guarantees: no local SQLite data is ever lost.
class SafeRollbackResolver implements ConflictResolverStrategy {
  const SafeRollbackResolver();

  @override
  ConflictResult resolve(ConflictItem conflict) {
    return ConflictResult(
      conflict: conflict,
      resolution: ConflictResolution.rollback,
      resolvedData: conflict.localData,
      message:
          'Rollback: Local data safely preserved. Will retry sync when conditions are met.',
      requiresLocalUpdate: false,
      requiresRemoteUpdate: false,
    );
  }
}

/// High-level conflict resolution service that orchestrates strategy selection
/// and tracks resolution history.
class ConflictResolver {
  final ConflictResolverStrategy _defaultStrategy;
  final List<ConflictResult> _history = [];

  ConflictResolver({
    ConflictResolverStrategy? strategy,
  }) : _defaultStrategy = strategy ?? const LastWriteWinsResolver();

  /// Resolve a single conflict item using the configured strategy.
  ConflictResult resolve(ConflictItem conflict) {
    final result = _defaultStrategy.resolve(conflict);
    _history.add(result);
    return result;
  }

  /// Resolve a batch of conflicts and return all results.
  List<ConflictResult> resolveAll(List<ConflictItem> conflicts) {
    return conflicts.map(resolve).toList();
  }

  /// Rollback a specific entity — always preserves local data.
  ConflictResult rollback(ConflictItem conflict) {
    const rollbackStrategy = SafeRollbackResolver();
    final result = rollbackStrategy.resolve(conflict);
    _history.add(result);
    return result;
  }

  /// Returns an unmodifiable view of all resolved conflicts.
  List<ConflictResult> get resolutionHistory => List.unmodifiable(_history);

  /// Clears the resolution history.
  void clearHistory() => _history.clear();

  /// Number of conflicts resolved in this session.
  int get totalResolved => _history.length;

  /// Number of resolutions where remote won.
  int get remoteWinsCount => _history
      .where((r) => r.resolution == ConflictResolution.remoteWins)
      .length;

  /// Number of resolutions where local won.
  int get localWinsCount => _history
      .where((r) => r.resolution == ConflictResolution.localWins)
      .length;

  /// Number of delete-vs-edit conflicts (local preserved).
  int get deleteVsEditCount => _history
      .where((r) => r.resolution == ConflictResolution.deleteVsEditPreserveLocal)
      .length;

  /// Number of rollbacks performed.
  int get rollbackCount =>
      _history.where((r) => r.resolution == ConflictResolution.rollback).length;
}
