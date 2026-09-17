import 'package:equatable/equatable.dart';
import '../../domain/entities/request_item.dart';

abstract class RequestEvent extends Equatable {
  const RequestEvent();

  @override
  List<Object?> get props => [];
}

class LoadRequestsEvent extends RequestEvent {
  final String? projectId;

  const LoadRequestsEvent({this.projectId});

  @override
  List<Object?> get props => [projectId];
}

class CreateRequestEvent extends RequestEvent {
  final RequestItem request;

  const CreateRequestEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class UpdateRequestEvent extends RequestEvent {
  final RequestItem request;

  const UpdateRequestEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class ChangeRequestStatusEvent extends RequestEvent {
  final String requestId;
  final RequestStatus newStatus;

  const ChangeRequestStatusEvent({
    required this.requestId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [requestId, newStatus];
}

class DeleteRequestEvent extends RequestEvent {
  final String requestId;

  const DeleteRequestEvent(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class FilterRequestsEvent extends RequestEvent {
  final String? projectId;
  final RequestStatus? statusFilter;

  const FilterRequestsEvent({
    this.projectId,
    this.statusFilter,
  });

  @override
  List<Object?> get props => [projectId, statusFilter];
}
