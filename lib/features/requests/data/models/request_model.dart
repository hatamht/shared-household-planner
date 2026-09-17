import '../../domain/entities/request_item.dart';

class RequestModel extends RequestItem {
  const RequestModel({
    required super.id,
    required super.projectId,
    required super.title,
    super.description,
    super.status = RequestStatus.pending,
    required super.createdAt,
    super.updatedAt,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: RequestStatus.fromString(json['status'] as String? ?? 'pending'),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'description': description,
      'status': status.toDbValue(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory RequestModel.fromEntity(RequestItem item) {
    return RequestModel(
      id: item.id,
      projectId: item.projectId,
      title: item.title,
      description: item.description,
      status: item.status,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    );
  }

  RequestItem toEntity() {
    return RequestItem(
      id: id,
      projectId: projectId,
      title: title,
      description: description,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  RequestModel copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    bool clearDescription = false,
    RequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RequestModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
