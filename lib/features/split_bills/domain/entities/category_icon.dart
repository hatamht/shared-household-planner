import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'category_entity.dart';

class CategoryIconItem extends Equatable {
  final String id;
  final String icon;
  final String nameKey;
  final String colorHex;

  const CategoryIconItem({
    required this.id,
    required this.icon,
    required this.nameKey,
    this.colorHex = '#9E9E9E',
  });

  Color get color => colorFromHex(colorHex);

  @override
  List<Object?> get props => [id, icon, nameKey, colorHex];
}

const List<CategoryIconItem> defaultCategoryIcons = [
  CategoryIconItem(id: 'restaurant', icon: '🍽️', nameKey: 'category_restaurant', colorHex: '#F44336'),
  CategoryIconItem(id: 'transport', icon: '🚕', nameKey: 'category_transport', colorHex: '#2196F3'),
  CategoryIconItem(id: 'shopping', icon: '🛍️', nameKey: 'category_shopping', colorHex: '#4CAF50'),
  CategoryIconItem(id: 'health', icon: '💊', nameKey: 'category_health', colorHex: '#E91E63'),
  CategoryIconItem(id: 'entertainment', icon: '🎬', nameKey: 'category_entertainment', colorHex: '#9C27B0'),
  CategoryIconItem(id: 'travel', icon: '✈️', nameKey: 'category_travel', colorHex: '#FF9800'),
  CategoryIconItem(id: 'utilities', icon: '🏠', nameKey: 'category_utilities', colorHex: '#9E9E9E'),
  CategoryIconItem(id: 'education', icon: '📚', nameKey: 'category_education', colorHex: '#3F51B5'),
  CategoryIconItem(id: 'party', icon: '🎉', nameKey: 'category_party', colorHex: '#E040FB'),
  CategoryIconItem(id: 'office', icon: '💼', nameKey: 'category_office', colorHex: '#FFC107'),
  CategoryIconItem(id: 'pet', icon: '🐕', nameKey: 'category_pet', colorHex: '#795548'),
  CategoryIconItem(id: 'sport', icon: '⚽', nameKey: 'category_sport', colorHex: '#00BCD4'),
];

const Map<String, String> currencySymbols = {
  'VND': '₫',
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'JPY': '¥',
  'SGD': 'S\$',
  'THB': '฿',
};
