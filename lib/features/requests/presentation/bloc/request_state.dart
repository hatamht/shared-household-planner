import 'package:equatable/equatable.dart';
import '../../domain/entities/request_item.dart';

abstract class RequestState extends Equatable {
  const RequestState();

  @override
  List<Object?> get props => [];
}

class RequestInitial extends RequestState {
  const RequestInitial();
}

class RequestLoading extends RequestState {
  const RequestLoading();
}

class RequestLoaded extends RequestState {
  final List<RequestItem> allRequests;
  final String? selectedProjectId;
  final RequestStatus? statusFilter;

  const RequestLoaded({
    required this.allRequests,
    this.selectedProjectId,
    this.statusFilter,
  });

  List<RequestItem> get filteredRequests {
    return allRequests.where((req) {
      if (selectedProjectId != null && req.projectId != selectedProjectId) {
        return false;
      }
      if (statusFilter != null && req.status != statusFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  int countForProject(String projectId) {
    return allRequests.where((r) => r.projectId == projectId).length;
  }

  int countByStatus(RequestStatus status, {String? projectId}) {
    return allRequests.where((r) {
      if (projectId != null && r.projectId != projectId) return false;
      return r.status == status;
    }).length;
  }

  int get pendingCount => countByStatus(RequestStatus.pending, projectId: selectedProjectId);
  int get completedCount => countByStatus(RequestStatus.completed, projectId: selectedProjectId);
  int get cancelledCount => countByStatus(RequestStatus.cancelled, projectId: selectedProjectId);

  RequestLoaded copyWith({
    List<RequestItem>? allRequests,
    String? selectedProjectId,
    bool clearSelectedProjectId = false,
    RequestStatus? statusFilter,
    bool clearStatusFilter = false,
  }) {
    return RequestLoaded(
      allRequests: allRequests ?? this.allRequests,
      selectedProjectId: clearSelectedProjectId
          ? null
          : (selectedProjectId ?? this.selectedProjectId),
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }

  @override
  List<Object?> get props => [
        allRequests,
        selectedProjectId,
        statusFilter,
      ];
}

class RequestError extends RequestState {
  final String message;

  const RequestError(this.message);

  @override
  List<Object?> get props => [message];
}
