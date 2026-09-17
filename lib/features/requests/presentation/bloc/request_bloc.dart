import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/request_usecases.dart';
import 'request_event.dart';
import 'request_state.dart';

class RequestBloc extends Bloc<RequestEvent, RequestState> {
  final GetAllRequestsUseCase getAllRequestsUseCase;
  final GetRequestsByProjectIdUseCase getRequestsByProjectIdUseCase;
  final CreateRequestUseCase createRequestUseCase;
  final UpdateRequestUseCase updateRequestUseCase;
  final DeleteRequestUseCase deleteRequestUseCase;

  RequestBloc({
    required this.getAllRequestsUseCase,
    required this.getRequestsByProjectIdUseCase,
    required this.createRequestUseCase,
    required this.updateRequestUseCase,
    required this.deleteRequestUseCase,
  }) : super(const RequestInitial()) {
    on<LoadRequestsEvent>(_onLoadRequests);
    on<CreateRequestEvent>(_onCreateRequest);
    on<UpdateRequestEvent>(_onUpdateRequest);
    on<ChangeRequestStatusEvent>(_onChangeRequestStatus);
    on<DeleteRequestEvent>(_onDeleteRequest);
    on<FilterRequestsEvent>(_onFilterRequests);
  }

  Future<void> _onLoadRequests(
    LoadRequestsEvent event,
    Emitter<RequestState> emit,
  ) async {
    final currentProjectId = event.projectId ??
        (state is RequestLoaded ? (state as RequestLoaded).selectedProjectId : null);
    final currentFilter =
        state is RequestLoaded ? (state as RequestLoaded).statusFilter : null;

    final result = await getAllRequestsUseCase();
    result.fold(
      (failure) => emit(RequestError(failure.message)),
      (requests) {
        emit(RequestLoaded(
          allRequests: requests,
          selectedProjectId: currentProjectId,
          statusFilter: currentFilter,
        ));
      },
    );
  }

  Future<void> _onCreateRequest(
    CreateRequestEvent event,
    Emitter<RequestState> emit,
  ) async {
    final result = await createRequestUseCase(event.request);
    result.fold(
      (failure) => emit(RequestError(failure.message)),
      (created) {
        if (state is RequestLoaded) {
          final current = state as RequestLoaded;
          final updatedList = [created, ...current.allRequests];
          emit(current.copyWith(allRequests: updatedList));
        } else {
          emit(RequestLoaded(allRequests: [created]));
        }
      },
    );
  }

  Future<void> _onUpdateRequest(
    UpdateRequestEvent event,
    Emitter<RequestState> emit,
  ) async {
    final result = await updateRequestUseCase(event.request);
    result.fold(
      (failure) => emit(RequestError(failure.message)),
      (updated) {
        if (state is RequestLoaded) {
          final current = state as RequestLoaded;
          final updatedList = current.allRequests
              .map((r) => r.id == updated.id ? updated : r)
              .toList();
          emit(current.copyWith(allRequests: updatedList));
        }
      },
    );
  }

  Future<void> _onChangeRequestStatus(
    ChangeRequestStatusEvent event,
    Emitter<RequestState> emit,
  ) async {
    if (state is! RequestLoaded) return;
    final current = state as RequestLoaded;
    final existing = current.allRequests.where((r) => r.id == event.requestId).firstOrNull;
    if (existing == null) return;

    final updated = existing.copyWith(
      status: event.newStatus,
      updatedAt: DateTime.now(),
    );

    final result = await updateRequestUseCase(updated);
    result.fold(
      (failure) => emit(RequestError(failure.message)),
      (saved) {
        final updatedList = current.allRequests
            .map((r) => r.id == saved.id ? saved : r)
            .toList();
        emit(current.copyWith(allRequests: updatedList));
      },
    );
  }

  Future<void> _onDeleteRequest(
    DeleteRequestEvent event,
    Emitter<RequestState> emit,
  ) async {
    final result = await deleteRequestUseCase(event.requestId);
    result.fold(
      (failure) => emit(RequestError(failure.message)),
      (_) {
        if (state is RequestLoaded) {
          final current = state as RequestLoaded;
          final updatedList = current.allRequests
              .where((r) => r.id != event.requestId)
              .toList();
          emit(current.copyWith(allRequests: updatedList));
        }
      },
    );
  }

  void _onFilterRequests(
    FilterRequestsEvent event,
    Emitter<RequestState> emit,
  ) {
    if (state is RequestLoaded) {
      final current = state as RequestLoaded;
      emit(current.copyWith(
        selectedProjectId: event.projectId,
        clearSelectedProjectId: event.projectId == null,
        statusFilter: event.statusFilter,
        clearStatusFilter: event.statusFilter == null,
      ));
    }
  }
}
