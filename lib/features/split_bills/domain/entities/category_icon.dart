import 'package:equatable/equatable.dart';

class CategoryIconItem extends Equatable {
  final String id;
  final String icon;
  final String nameKey;

  const CategoryIconItem({
    required this.id,
    required this.icon,
    required this.nameKey,
  });

  @override
  List<Object?> get props => [id, icon, nameKey];
}

const List<CategoryIconItem> defaultCategoryIcons = [
  CategoryIconItem(id: 'restaurant', icon: '🍽️', nameKey: 'category_restaurant'),
  CategoryIconItem(id: 'transport', icon: '🚕', nameKey: 'category_transport'),
  CategoryIconItem(id: 'shopping', icon: '🛍️', nameKey: 'category_shopping'),
  CategoryIconItem(id: 'health', icon: '💊', nameKey: 'category_health'),
  CategoryIconItem(id: 'entertainment', icon: '🎬', nameKey: 'category_entertainment'),
  CategoryIconItem(id: 'travel', icon: '✈️', nameKey: 'category_travel'),
  CategoryIconItem(id: 'utilities', icon: '🏠', nameKey: 'category_utilities'),
  CategoryIconItem(id: 'education', icon: '📚', nameKey: 'category_education'),
  CategoryIconItem(id: 'party', icon: '🎉', nameKey: 'category_party'),
  CategoryIconItem(id: 'office', icon: '💼', nameKey: 'category_office'),
  CategoryIconItem(id: 'pet', icon: '🐕', nameKey: 'category_pet'),
  CategoryIconItem(id: 'sport', icon: '⚽', nameKey: 'category_sport'),
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
