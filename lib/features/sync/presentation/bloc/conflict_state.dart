import 'package:equatable/equatable.dart';
import '../../domain/entities/conflict_item.dart';

/// BLoC State for Conflict Resolution
class ConflictBlocState extends Equatable {
  /// Most recently resolved conflict result (for notification display)
  final ConflictResult? lastResolved;

  /// List of pending unresolved conflicts
  final List<ConflictItem> pendingConflicts;

  /// Full history of resolved conflicts this session
  final List<ConflictResult> resolutionHistory;

  /// Whether a conflict notification should be shown
  final bool showNotification;

  /// Whether the resolver is actively processing
  final bool isProcessing;

  const ConflictBlocState({
    this.lastResolved,
    this.pendingConflicts = const [],
    this.resolutionHistory = const [],
    this.showNotification = false,
    this.isProcessing = false,
  });

  bool get hasPendingConflicts => pendingConflicts.isNotEmpty;
  int get totalResolved => resolutionHistory.length;
  int get totalPending => pendingConflicts.length;

  ConflictBlocState copyWith({
    ConflictResult? lastResolved,
    List<ConflictItem>? pendingConflicts,
    List<ConflictResult>? resolutionHistory,
    bool? showNotification,
    bool? isProcessing,
    bool clearLastResolved = false,
  }) {
    return ConflictBlocState(
      lastResolved: clearLastResolved ? null : (lastResolved ?? this.lastResolved),
      pendingConflicts: pendingConflicts ?? this.pendingConflicts,
      resolutionHistory: resolutionHistory ?? this.resolutionHistory,
      showNotification: showNotification ?? this.showNotification,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  @override
  List<Object?> get props => [
        lastResolved,
        pendingConflicts,
        resolutionHistory,
        showNotification,
        isProcessing,
      ];
}
