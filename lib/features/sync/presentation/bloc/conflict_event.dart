import 'package:equatable/equatable.dart';
import '../../domain/entities/conflict_item.dart';

/// BLoC Events for Conflict Resolution
abstract class ConflictEvent extends Equatable {
  const ConflictEvent();

  @override
  List<Object?> get props => [];
}

/// Fired when a new conflict is detected during sync
class ConflictDetectedEvent extends ConflictEvent {
  final ConflictItem conflict;
  const ConflictDetectedEvent(this.conflict);

  @override
  List<Object?> get props => [conflict];
}

/// Fired to resolve a specific conflict
class ResolveConflictEvent extends ConflictEvent {
  final ConflictItem conflict;
  const ResolveConflictEvent(this.conflict);

  @override
  List<Object?> get props => [conflict];
}

/// Fired to rollback a specific conflict (keep local)
class RollbackConflictEvent extends ConflictEvent {
  final ConflictItem conflict;
  const RollbackConflictEvent(this.conflict);

  @override
  List<Object?> get props => [conflict];
}

/// Fired to resolve a batch of conflicts
class ResolveAllConflictsEvent extends ConflictEvent {
  final List<ConflictItem> conflicts;
  const ResolveAllConflictsEvent(this.conflicts);

  @override
  List<Object?> get props => [conflicts];
}

/// Fired to dismiss/clear the current conflict notification
class DismissConflictNotificationEvent extends ConflictEvent {
  const DismissConflictNotificationEvent();
}

/// Fired to clear the entire conflict resolution history
class ClearConflictHistoryEvent extends ConflictEvent {
  const ClearConflictHistoryEvent();
}
