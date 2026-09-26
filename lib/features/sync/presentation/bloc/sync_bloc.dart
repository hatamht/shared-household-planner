import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/services/sync_service.dart';
import 'sync_event.dart';
import 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncBlocState> {
  final SyncService syncService;
  StreamSubscription? _statusSubscription;

  SyncBloc({required this.syncService})
      : super(SyncBlocState(status: syncService.status)) {
    on<TriggerSyncEvent>(_onTriggerSync);
    on<SyncStatusUpdatedEvent>(_onStatusUpdated);
    on<EnqueueSyncItemEvent>(_onEnqueueSyncItem);
    on<ClearSyncQueueEvent>(_onClearSyncQueue);

    _statusSubscription = syncService.statusStream.listen((status) {
      add(SyncStatusUpdatedEvent(status));
    });
  }

  Future<void> _onTriggerSync(
    TriggerSyncEvent event,
    Emitter<SyncBlocState> emit,
  ) async {
    if (isClosed) return;
    emit(state.copyWith(isTriggering: true));
    final result = await syncService.syncNow(projectId: event.projectId);
    if (!isClosed) {
      emit(state.copyWith(
        status: syncService.status,
        lastSyncMessage: result.message,
        isTriggering: false,
      ));
    }
  }

  void _onStatusUpdated(
    SyncStatusUpdatedEvent event,
    Emitter<SyncBlocState> emit,
  ) {
    if (!isClosed) {
      emit(state.copyWith(status: event.status));
    }
  }

  void _onEnqueueSyncItem(
    EnqueueSyncItemEvent event,
    Emitter<SyncBlocState> emit,
  ) {
    syncService.enqueue(event.item);
  }

  void _onClearSyncQueue(
    ClearSyncQueueEvent event,
    Emitter<SyncBlocState> emit,
  ) {
    syncService.clearQueue();
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    return super.close();
  }
}
