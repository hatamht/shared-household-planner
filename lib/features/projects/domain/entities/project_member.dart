import 'package:equatable/equatable.dart';

/// Role of a user in a shared project
enum ProjectRole {
  owner,
  member;

  bool get isOwner => this == ProjectRole.owner;
  bool get isMember => this == ProjectRole.member;
}

/// Represents a member participating in a shared project
class ProjectMember extends Equatable {
  final String id;
  final String name;
  final ProjectRole role;
  final String? photoUrl;
  final DateTime? joinedAt;

  const ProjectMember({
    required this.id,
    required this.name,
    this.role = ProjectRole.member,
    this.photoUrl,
    this.joinedAt,
  });

  bool get isOwner => role.isOwner;
  bool get isMember => role.isMember;

  ProjectMember copyWith({
    String? id,
    String? name,
    ProjectRole? role,
    String? photoUrl,
    DateTime? joinedAt,
  }) {
    return ProjectMember(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'role': role.name,
        'photoUrl': photoUrl,
        'joinedAt': joinedAt?.toIso8601String(),
      };

  factory ProjectMember.fromMap(Map<String, dynamic> map) => ProjectMember(
        id: (map['id'] as String?) ?? '',
        name: (map['name'] as String?) ?? '',
        role: ProjectRole.values.firstWhere(
          (e) => e.name == map['role'],
          orElse: () => ProjectRole.member,
        ),
        photoUrl: map['photoUrl'] as String?,
        joinedAt: map['joinedAt'] != null
            ? DateTime.tryParse(map['joinedAt'] as String)
            : null,
      );

  @override
  List<Object?> get props => [id, name, role, photoUrl, joinedAt];
}
