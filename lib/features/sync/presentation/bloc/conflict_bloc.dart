import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/conflict_item.dart';
import '../../domain/services/conflict_resolver.dart';
import 'conflict_event.dart';
import 'conflict_state.dart';

/// BLoC managing conflict detection, resolution, and notification display.
class ConflictBloc extends Bloc<ConflictEvent, ConflictBlocState> {
  final ConflictResolver _resolver;

  ConflictBloc({ConflictResolver? resolver})
      : _resolver = resolver ?? ConflictResolver(),
        super(const ConflictBlocState()) {
    on<ConflictDetectedEvent>(_onConflictDetected);
    on<ResolveConflictEvent>(_onResolveConflict);
    on<RollbackConflictEvent>(_onRollbackConflict);
    on<ResolveAllConflictsEvent>(_onResolveAllConflicts);
    on<DismissConflictNotificationEvent>(_onDismissNotification);
    on<ClearConflictHistoryEvent>(_onClearHistory);
  }

  void _onConflictDetected(
      ConflictDetectedEvent event, Emitter<ConflictBlocState> emit) {
    if (isClosed) return;
    final updated = List<ConflictItem>.from(state.pendingConflicts)
      ..add(event.conflict);
    emit(state.copyWith(pendingConflicts: updated));
  }

  void _onResolveConflict(
      ResolveConflictEvent event, Emitter<ConflictBlocState> emit) {
    if (isClosed) return;
    emit(state.copyWith(isProcessing: true));

    final result = _resolver.resolve(event.conflict);

    final pending = List<ConflictItem>.from(state.pendingConflicts)
      ..removeWhere((c) => c.id == event.conflict.id);

    final history = List<ConflictResult>.from(state.resolutionHistory)
      ..add(result);

    if (!isClosed) {
      emit(state.copyWith(
        lastResolved: result,
        pendingConflicts: pending,
        resolutionHistory: history,
        showNotification: true,
        isProcessing: false,
      ));
    }
  }

  void _onRollbackConflict(
      RollbackConflictEvent event, Emitter<ConflictBlocState> emit) {
    if (isClosed) return;
    emit(state.copyWith(isProcessing: true));

    final result = _resolver.rollback(event.conflict);

    final pending = List<ConflictItem>.from(state.pendingConflicts)
      ..removeWhere((c) => c.id == event.conflict.id);

    final history = List<ConflictResult>.from(state.resolutionHistory)
      ..add(result);

    if (!isClosed) {
      emit(state.copyWith(
        lastResolved: result,
        pendingConflicts: pending,
        resolutionHistory: history,
        showNotification: true,
        isProcessing: false,
      ));
    }
  }

  void _onResolveAllConflicts(
      ResolveAllConflictsEvent event, Emitter<ConflictBlocState> emit) {
    if (isClosed) return;
    emit(state.copyWith(isProcessing: true));

    final results = _resolver.resolveAll(event.conflicts);
    final lastResult = results.isNotEmpty ? results.last : null;

    final history = List<ConflictResult>.from(state.resolutionHistory)
      ..addAll(results);

    if (!isClosed) {
      emit(state.copyWith(
        lastResolved: lastResult,
        pendingConflicts: const [],
        resolutionHistory: history,
        showNotification: results.isNotEmpty,
        isProcessing: false,
      ));
    }
  }

  void _onDismissNotification(
      DismissConflictNotificationEvent event, Emitter<ConflictBlocState> emit) {
    if (isClosed) return;
    emit(state.copyWith(showNotification: false, clearLastResolved: true));
  }

  void _onClearHistory(
      ClearConflictHistoryEvent event, Emitter<ConflictBlocState> emit) {
    if (isClosed) return;
    _resolver.clearHistory();
    emit(state.copyWith(
      resolutionHistory: const [],
      clearLastResolved: true,
      showNotification: false,
    ));
  }
}
