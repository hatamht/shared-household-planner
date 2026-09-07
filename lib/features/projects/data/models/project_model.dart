import 'dart:convert';
import '../../domain/entities/project.dart';

class ProjectModel extends Project {
  const ProjectModel({
    required super.id,
    required super.name,
    super.description,
    required super.members,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    List<String> membersList;
    final membersData = json['members'];
    if (membersData is String) {
      final decoded = jsonDecode(membersData) as List<dynamic>;
      membersList = decoded.map((e) => e.toString()).toList();
    } else if (membersData is List) {
      membersList = membersData.map((e) => e.toString()).toList();
    } else {
      membersList = [];
    }

    return ProjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      members: membersList,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'members': members,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'members': jsonEncode(members),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProjectModel.fromEntity(Project project) {
    return ProjectModel(
      id: project.id,
      name: project.name,
      description: project.description,
      members: project.members,
      createdAt: project.createdAt,
      updatedAt: project.updatedAt,
    );
  }
}
