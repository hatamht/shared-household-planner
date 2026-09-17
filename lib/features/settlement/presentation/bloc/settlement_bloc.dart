import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/balance_evolution.dart';
import '../../domain/entities/settlement_filter.dart';
import '../../domain/entities/settlement_log.dart';
import '../../domain/usecases/settlement_usecases.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class SettlementEvent extends Equatable {
  const SettlementEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettlementsEvent extends SettlementEvent {
  final String? projectId;
  final SettlementFilter? filter;

  const LoadSettlementsEvent({this.projectId, this.filter});

  @override
  List<Object?> get props => [projectId, filter];
}

class CreateSettlementEvent extends SettlementEvent {
  final SettlementLog log;

  const CreateSettlementEvent(this.log);

  @override
  List<Object?> get props => [log];
}

class UpdateSettlementEvent extends SettlementEvent {
  final SettlementLog log;

  const UpdateSettlementEvent(this.log);

  @override
  List<Object?> get props => [log];
}

class DeleteSettlementEvent extends SettlementEvent {
  final String id;

  const DeleteSettlementEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class MarkSettlementAsPaidEvent extends SettlementEvent {
  final String id;

  const MarkSettlementAsPaidEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class UndoMarkSettlementAsPaidEvent extends SettlementEvent {
  final String id;

  const UndoMarkSettlementAsPaidEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class UpdateSettlementFilterEvent extends SettlementEvent {
  final SettlementFilter filter;

  const UpdateSettlementFilterEvent(this.filter);

  @override
  List<Object?> get props => [filter];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class SettlementState extends Equatable {
  const SettlementState();

  @override
  List<Object?> get props => [];
}

class SettlementInitial extends SettlementState {}

class SettlementLoading extends SettlementState {}

class SettlementLoaded extends SettlementState {
  final List<SettlementLog> allLogs;
  final SettlementFilter filter;
  final List<SettlementLog> filteredLogs;
  final List<BalanceEvolutionItem> evolutionItems;

  const SettlementLoaded({
    required this.allLogs,
    required this.filter,
    required this.filteredLogs,
    required this.evolutionItems,
  });

  double get totalPaid => allLogs
      .where((l) => l.isPaid)
      .fold(0.0, (sum, l) => sum + l.amount);

  double get totalPending => allLogs
      .where((l) => l.isPending)
      .fold(0.0, (sum, l) => sum + l.amount);

  double get filteredPaid => filteredLogs
      .where((l) => l.isPaid)
      .fold(0.0, (sum, l) => sum + l.amount);

  double get filteredPending => filteredLogs
      .where((l) => l.isPending)
      .fold(0.0, (sum, l) => sum + l.amount);

  @override
  List<Object?> get props => [
        allLogs,
        filter,
        filteredLogs,
        evolutionItems,
      ];
}

class SettlementError extends SettlementState {
  final String message;

  const SettlementError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class SettlementBloc extends Bloc<SettlementEvent, SettlementState> {
  final GetSettlementLogsUseCase getSettlementLogsUseCase;
  final CreateSettlementLogUseCase createSettlementLogUseCase;
  final UpdateSettlementLogUseCase updateSettlementLogUseCase;
  final DeleteSettlementLogUseCase deleteSettlementLogUseCase;
  final MarkAsPaidUseCase markAsPaidUseCase;
  final UndoMarkAsPaidUseCase undoMarkAsPaidUseCase;

  String? _currentProjectId;
  SettlementFilter _currentFilter = const SettlementFilter(oldestFirst: true);

  SettlementBloc({
    required this.getSettlementLogsUseCase,
    required this.createSettlementLogUseCase,
    required this.updateSettlementLogUseCase,
    required this.deleteSettlementLogUseCase,
    required this.markAsPaidUseCase,
    required this.undoMarkAsPaidUseCase,
  }) : super(SettlementInitial()) {
    on<LoadSettlementsEvent>(_onLoadSettlements);
    on<CreateSettlementEvent>(_onCreateSettlement);
    on<UpdateSettlementEvent>(_onUpdateSettlement);
    on<DeleteSettlementEvent>(_onDeleteSettlement);
    on<MarkSettlementAsPaidEvent>(_onMarkAsPaid);
    on<UndoMarkSettlementAsPaidEvent>(_onUndoMarkAsPaid);
    on<UpdateSettlementFilterEvent>(_onUpdateFilter);
  }

  SettlementLoaded _buildLoadedState(List<SettlementLog> logs, SettlementFilter filter) {
    final filtered = filter.filterLogs(logs);
    final evolution = BalanceEvolutionCalculator.calculate(filtered);
    return SettlementLoaded(
      allLogs: List.unmodifiable(logs),
      filter: filter,
      filteredLogs: filtered,
      evolutionItems: evolution,
    );
  }

  Future<void> _onLoadSettlements(
    LoadSettlementsEvent event,
    Emitter<SettlementState> emit,
  ) async {
    emit(SettlementLoading());
    _currentProjectId = event.projectId;
    if (event.filter != null) {
      _currentFilter = event.filter!;
    } else {
      _currentFilter = _currentFilter.copyWith(projectId: event.projectId);
    }

    final result = await getSettlementLogsUseCase(projectId: _currentProjectId);
    result.fold(
      (failure) => emit(SettlementError(failure.message)),
      (logs) => emit(_buildLoadedState(logs, _currentFilter)),
    );
  }

  Future<void> _onCreateSettlement(
    CreateSettlementEvent event,
    Emitter<SettlementState> emit,
  ) async {
    final result = await createSettlementLogUseCase(event.log);
    await result.fold(
      (failure) async => emit(SettlementError(failure.message)),
      (_) async {
        final reloadResult = await getSettlementLogsUseCase(projectId: _currentProjectId);
        reloadResult.fold(
          (failure) => emit(SettlementError(failure.message)),
          (logs) => emit(_buildLoadedState(logs, _currentFilter)),
        );
      },
    );
  }

  Future<void> _onUpdateSettlement(
    UpdateSettlementEvent event,
    Emitter<SettlementState> emit,
  ) async {
    final result = await updateSettlementLogUseCase(event.log);
    await result.fold(
      (failure) async => emit(SettlementError(failure.message)),
      (_) async {
        final reloadResult = await getSettlementLogsUseCase(projectId: _currentProjectId);
        reloadResult.fold(
          (failure) => emit(SettlementError(failure.message)),
          (logs) => emit(_buildLoadedState(logs, _currentFilter)),
        );
      },
    );
  }

  Future<void> _onDeleteSettlement(
    DeleteSettlementEvent event,
    Emitter<SettlementState> emit,
  ) async {
    final result = await deleteSettlementLogUseCase(event.id);
    await result.fold(
      (failure) async => emit(SettlementError(failure.message)),
      (_) async {
        final reloadResult = await getSettlementLogsUseCase(projectId: _currentProjectId);
        reloadResult.fold(
          (failure) => emit(SettlementError(failure.message)),
          (logs) => emit(_buildLoadedState(logs, _currentFilter)),
        );
      },
    );
  }

  Future<void> _onMarkAsPaid(
    MarkSettlementAsPaidEvent event,
    Emitter<SettlementState> emit,
  ) async {
    final result = await markAsPaidUseCase(event.id);
    await result.fold(
      (failure) async => emit(SettlementError(failure.message)),
      (_) async {
        final reloadResult = await getSettlementLogsUseCase(projectId: _currentProjectId);
        reloadResult.fold(
          (failure) => emit(SettlementError(failure.message)),
          (logs) => emit(_buildLoadedState(logs, _currentFilter)),
        );
      },
    );
  }

  Future<void> _onUndoMarkAsPaid(
    UndoMarkSettlementAsPaidEvent event,
    Emitter<SettlementState> emit,
  ) async {
    final result = await undoMarkAsPaidUseCase(event.id);
    await result.fold(
      (failure) async => emit(SettlementError(failure.message)),
      (_) async {
        final reloadResult = await getSettlementLogsUseCase(projectId: _currentProjectId);
        reloadResult.fold(
          (failure) => emit(SettlementError(failure.message)),
          (logs) => emit(_buildLoadedState(logs, _currentFilter)),
        );
      },
    );
  }

  void _onUpdateFilter(
    UpdateSettlementFilterEvent event,
    Emitter<SettlementState> emit,
  ) {
    _currentFilter = event.filter;
    if (state is SettlementLoaded) {
      final currentLogs = (state as SettlementLoaded).allLogs;
      emit(_buildLoadedState(currentLogs, _currentFilter));
    }
  }
}
