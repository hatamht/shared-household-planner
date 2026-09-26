import 'package:equatable/equatable.dart';
import '../../domain/entities/sync_status.dart';

/// State of the SyncBloc
class SyncBlocState extends Equatable {
  final SyncStatus status;
  final String? lastSyncMessage;
  final bool isTriggering;

  const SyncBlocState({
    this.status = const SyncStatus(),
    this.lastSyncMessage,
    this.isTriggering = false,
  });

  bool get isSyncing => status.isSyncing || isTriggering;
  bool get isOffline => status.isOffline;
  bool get isSynced => status.isSynced && !isTriggering;
  bool get hasPending => status.hasPending;
  bool get hasError => status.hasError;
  int get pendingCount => status.pendingCount;
  DateTime? get lastSyncedAt => status.lastSyncedAt;

  SyncBlocState copyWith({
    SyncStatus? status,
    String? lastSyncMessage,
    bool? isTriggering,
  }) {
    return SyncBlocState(
      status: status ?? this.status,
      lastSyncMessage: lastSyncMessage ?? this.lastSyncMessage,
      isTriggering: isTriggering ?? this.isTriggering,
    );
  }

  @override
  List<Object?> get props => [status, lastSyncMessage, isTriggering];
}
