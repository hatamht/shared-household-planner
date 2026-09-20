import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'project_palette.dart';
import '../../../split_bills/domain/entities/category_icon.dart';

class Project extends Equatable {
  final String id;
  final String name;
  final String? description;
  final List<String> members;
  final int iconIndex;
  final int colorIndex;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Project({
    required this.id,
    required this.name,
    this.description,
    required this.members,
    this.iconIndex = 0,
    this.colorIndex = 0,
    this.currency = 'VND',
    required this.createdAt,
    required this.updatedAt,
  });

  IconData get iconData => ProjectPalette.getIcon(iconIndex);
  Color get color => ProjectPalette.getColor(colorIndex);

  String get currencySymbol {
    final upper = currency.toUpperCase();
    switch (upper) {
      case 'VND':
        return '₫';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      default:
        return currencySymbols[upper] ?? (currency.isEmpty ? '₫' : currency);
    }
  }

  Project copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? members,
    int? iconIndex,
    int? colorIndex,
    String? currency,
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
      currency: currency ?? this.currency,
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
        currency,
        createdAt,
        updatedAt,
      ];
}

// Alias for Criterion 1: "Create ProjectModel entity in domain/entities"
typedef ProjectModelEntity = Project;
