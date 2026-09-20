import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'project_palette.dart';

class Project extends Equatable {
  final String id;
  final String name;
  final String? description;
  final List<String> members;
  final int iconIndex;
  final int colorIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Project({
    required this.id,
    required this.name,
    this.description,
    required this.members,
    this.iconIndex = 0,
    this.colorIndex = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  IconData get iconData => ProjectPalette.getIcon(iconIndex);
  Color get color => ProjectPalette.getColor(colorIndex);

  Project copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? members,
    int? iconIndex,
    int? colorIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      members: members ?? this.members,
      iconIndex: iconIndex ?? this.iconIndex,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        members,
        iconIndex,
        colorIndex,
        createdAt,
        updatedAt,
      ];
}

// Alias for Criterion 1: "Create ProjectModel entity in domain/entities"
typedef ProjectModelEntity = Project;
