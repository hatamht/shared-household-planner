import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/services/realtime_sync_service.dart';
import 'realtime_event.dart';
import 'realtime_state.dart';

class RealtimeBloc extends Bloc<RealtimeEvent, RealtimeBlocState> {
  final RealtimeSyncService _syncService;
  StreamSubscription? _serviceSubscription;

  RealtimeBloc({required RealtimeSyncService syncService})
      : _syncService = syncService,
        super(const RealtimeBlocState()) {
    on<StartProjectRealtimeEvent>(_onStartProject);
    on<StopProjectRealtimeEvent>(_onStopProject);
    on<StopAllRealtimeEvent>(_onStopAll);
    on<RemoteChangeReceivedEvent>(_onRemoteChangeReceived);
    on<DismissRemoteNotificationEvent>(_onDismissNotification);
    on<ClearRemoteChangeHistoryEvent>(_onClearHistory);
    on<RealtimeAppLifecycleChangedEvent>(_onLifecycleChanged);

    // Subscribe to service's change stream
    _serviceSubscription = _syncService.changeStream.listen(
      (change) {
        if (!isClosed) {
          add(RemoteChangeReceivedEvent(change));
        }
      },
    );
  }

  void _onStartProject(
    StartProjectRealtimeEvent event,
    Emitter<RealtimeBlocState> emit,
  ) {
    if (isClosed) return;
    _syncService.attachProjectListener(event.projectId);
    final updated = Set<String>.from(state.activeProjects)..add(event.projectId);
    emit(state.copyWith(activeProjects: updated));
  }

  void _onStopProject(
    StopProjectRealtimeEvent event,
    Emitter<RealtimeBlocState> emit,
  ) {
    if (isClosed) return;
    _syncService.detachProjectListener(event.projectId);
    final updated = Set<String>.from(state.activeProjects)..remove(event.projectId);
    emit(state.copyWith(activeProjects: updated));
  }

  void _onStopAll(
    StopAllRealtimeEvent event,
    Emitter<RealtimeBlocState> emit,
  ) {
    if (isClosed) return;
    _syncService.detachAll();
    emit(state.copyWith(activeProjects: const {}));
  }

  void _onRemoteChangeReceived(
    RemoteChangeReceivedEvent event,
    Emitter<RealtimeBlocState> emit,
  ) {
    if (isClosed) return;
    final updatedHistory = List.of(state.changeHistory)..add(event.change);
    emit(state.copyWith(
      latestChange: event.change,
      changeHistory: updatedHistory,
      showNotification: true,
    ));
  }

  void _onDismissNotification(
    DismissRemoteNotificationEvent event,
    Emitter<RealtimeBlocState> emit,
  ) {
    if (isClosed) return;
    emit(state.copyWith(
      showNotification: false,
      clearLatestChange: true,
    ));
  }

  void _onClearHistory(
    ClearRemoteChangeHistoryEvent event,
    Emitter<RealtimeBlocState> emit,
  ) {
    if (isClosed) return;
    emit(state.copyWith(
      changeHistory: const [],
      clearLatestChange: true,
      showNotification: false,
    ));
  }

  void _onLifecycleChanged(
    RealtimeAppLifecycleChangedEvent event,
    Emitter<RealtimeBlocState> emit,
  ) {
    if (isClosed) return;
    final isBg = event.state == AppLifecycleState.paused ||
        event.state == AppLifecycleState.detached;
    if (isBg) {
      _syncService.pauseListeners();
      emit(state.copyWith(isPaused: true));
    } else if (event.state == AppLifecycleState.resumed) {
      _syncService.resumeListeners();
      emit(state.copyWith(isPaused: false));
    }
  }

  @override
  Future<void> close() {
    _serviceSubscription?.cancel();
    return super.close();
  }
}
