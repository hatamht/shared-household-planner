import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// Helper to convert hex string (#RRGGBB or 0xAARRGGBB) to Color
Color colorFromHex(String hexString, {Color defaultColor = const Color(0xFF9E9E9E)}) {
  try {
    String cleanHex = hexString.replaceAll('#', '').replaceAll('0x', '').trim();
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }
    if (cleanHex.length == 8) {
      return Color(int.parse(cleanHex, radix: 16));
    }
    return defaultColor;
  } catch (_) {
    return defaultColor;
  }
}

/// Helper to convert Color to Hex string (#RRGGBB)
String colorToHex(Color color) {
  return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}

/// Palette of 12+ preset brand colors for categories
const List<String> presetCategoryColors = [
  '#F44336', // Red (Restaurant)
  '#2196F3', // Blue (Transport)
  '#4CAF50', // Green (Shopping)
  '#E91E63', // Pink (Health)
  '#9C27B0', // Purple (Entertainment)
  '#FF9800', // Orange (Travel)
  '#9E9E9E', // Gray (Utilities)
  '#3F51B5', // Indigo (Education)
  '#E040FB', // Magenta (Party)
  '#FFC107', // Yellow / Amber (Office)
  '#795548', // Brown (Pet)
  '#00BCD4', // Cyan (Sport)
  '#009688', // Teal
  '#673AB7', // Deep Purple
];

/// Suggested Flutter icons (20+ Material IconData)
const List<IconData> suggestedCategoryIcons = [
  Icons.restaurant,
  Icons.local_taxi,
  Icons.shopping_bag,
  Icons.health_and_safety,
  Icons.local_movies,
  Icons.flight,
  Icons.home,
  Icons.school,
  Icons.cake,
  Icons.work,
  Icons.pets,
  Icons.sports_basketball,
  Icons.coffee,
  Icons.local_gas_station,
  Icons.local_grocery_store,
  Icons.fitness_center,
  Icons.fastfood,
  Icons.hotel,
  Icons.music_note,
  Icons.directions_bus,
  Icons.card_giftcard,
  Icons.beach_access,
];

/// Predefined popular category suggestions with icons + colors
class CategorySuggestion extends Equatable {
  final String id;
  final String nameEn;
  final String nameVi;
  final String emoji;
  final IconData iconData;
  final String colorHex;

  const CategorySuggestion({
    required this.id,
    required this.nameEn,
    required this.nameVi,
    required this.emoji,
    required this.iconData,
    required this.colorHex,
  });

  @override
  List<Object?> get props => [id, nameEn, nameVi, emoji, iconData, colorHex];
}

const List<CategorySuggestion> popularCategorySuggestions = [
  CategorySuggestion(
    id: 'restaurant',
    nameEn: 'Restaurant',
    nameVi: 'Nhà hàng',
    emoji: '🍽️',
    iconData: Icons.restaurant,
    colorHex: '#F44336', // Red
  ),
  CategorySuggestion(
    id: 'transport',
    nameEn: 'Transport',
    nameVi: 'Giao thông',
    emoji: '🚕',
    iconData: Icons.local_taxi,
    colorHex: '#2196F3', // Blue
  ),
  CategorySuggestion(
    id: 'shopping',
    nameEn: 'Shopping',
    nameVi: 'Mua sắm',
    emoji: '🛍️',
    iconData: Icons.shopping_bag,
    colorHex: '#4CAF50', // Green
  ),
  CategorySuggestion(
    id: 'health',
    nameEn: 'Health',
    nameVi: 'Sức khỏe',
    emoji: '💊',
    iconData: Icons.health_and_safety,
    colorHex: '#E91E63', // Pink
  ),
  CategorySuggestion(
    id: 'entertainment',
    nameEn: 'Entertainment',
    nameVi: 'Giải trí',
    emoji: '🎬',
    iconData: Icons.local_movies,
    colorHex: '#9C27B0', // Purple
  ),
  CategorySuggestion(
    id: 'travel',
    nameEn: 'Travel',
    nameVi: 'Du lịch',
    emoji: '✈️',
    iconData: Icons.flight,
    colorHex: '#FF9800', // Orange
  ),
  CategorySuggestion(
    id: 'party',
    nameEn: 'Party',
    nameVi: 'Tiệp',
    emoji: '🎉',
    iconData: Icons.cake,
    colorHex: '#E040FB', // Magenta
  ),
  CategorySuggestion(
    id: 'sport',
    nameEn: 'Sport',
    nameVi: 'Thể thao',
    emoji: '⚽',
    iconData: Icons.sports_basketball,
    colorHex: '#00BCD4', // Cyan
  ),
];

/// Category entity supporting colors, icons, and persistence
class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final String icon; // Emoji string or icon name
  final String colorHex;
  final int? iconCodePoint;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
    this.iconCodePoint,
  });

  Color get color => colorFromHex(colorHex);

  IconData? get materialIcon =>
      iconCodePoint != null ? IconData(iconCodePoint!, fontFamily: 'MaterialIcons') : null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'colorHex': colorHex,
      if (iconCodePoint != null) 'iconCodePoint': iconCodePoint,
    };
  }

  factory CategoryEntity.fromJson(Map<String, dynamic> json) {
    return CategoryEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      colorHex: json['colorHex'] as String,
      iconCodePoint: json['iconCodePoint'] as int?,
    );
  }

  @override
  List<Object?> get props => [id, name, icon, colorHex, iconCodePoint];
}

/// Default categories initialized with brand colors
const List<CategoryEntity> initialCategories = [
  CategoryEntity(id: 'restaurant', name: 'Restaurant', icon: '🍽️', colorHex: '#F44336'),
  CategoryEntity(id: 'transport', name: 'Transport', icon: '🚕', colorHex: '#2196F3'),
  CategoryEntity(id: 'shopping', name: 'Shopping', icon: '🛍️', colorHex: '#4CAF50'),
  CategoryEntity(id: 'health', name: 'Health', icon: '💊', colorHex: '#E91E63'),
  CategoryEntity(id: 'entertainment', name: 'Entertainment', icon: '🎬', colorHex: '#9C27B0'),
  CategoryEntity(id: 'travel', name: 'Travel', icon: '✈️', colorHex: '#FF9800'),
  CategoryEntity(id: 'utilities', name: 'Utilities', icon: '🏠', colorHex: '#9E9E9E'),
  CategoryEntity(id: 'education', name: 'Education', icon: '📚', colorHex: '#3F51B5'),
  CategoryEntity(id: 'party', name: 'Party', icon: '🎉', colorHex: '#E040FB'),
  CategoryEntity(id: 'office', name: 'Office', icon: '💼', colorHex: '#FFC107'),
  CategoryEntity(id: 'pet', name: 'Pet', icon: '🐕', colorHex: '#795548'),
  CategoryEntity(id: 'sport', name: 'Sport', icon: '⚽', colorHex: '#00BCD4'),
];
