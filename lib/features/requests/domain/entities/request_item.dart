import 'package:equatable/equatable.dart';

enum RequestStatus {
  pending,
  completed,
  cancelled;

  static RequestStatus fromString(String value) {
    switch (value.toLowerCase().trim()) {
      case 'completed':
        return RequestStatus.completed;
      case 'cancelled':
      case 'canceled':
        return RequestStatus.cancelled;
      case 'pending':
      default:
        return RequestStatus.pending;
    }
  }

  String toDbValue() {
    switch (this) {
      case RequestStatus.completed:
        return 'completed';
      case RequestStatus.cancelled:
        return 'cancelled';
      case RequestStatus.pending:
        return 'pending';
    }
  }
}

class RequestItem extends Equatable {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const RequestItem({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    this.status = RequestStatus.pending,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status == RequestStatus.pending;
  bool get isCompleted => status == RequestStatus.completed;
  bool get isCancelled => status == RequestStatus.cancelled;

  RequestItem copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    bool clearDescription = false,
    RequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RequestItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        title,
        description,
        status,
        createdAt,
        updatedAt,
      ];
}
