import 'package:equatable/equatable.dart';

class BillTemplate extends Equatable {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String? categoryIcon;
  final String? categoryColor;
  final String currency;
  final String? paidBy;
  final List<String> participants;
  final String splitMode;
  final String? projectId;
  final bool isFavorite;
  final int usageCount;
  final DateTime? lastUsedAt;
  final DateTime createdAt;

  const BillTemplate({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.categoryIcon,
    this.categoryColor,
    this.currency = 'VND',
    this.paidBy,
    this.participants = const [],
    this.splitMode = 'equal',
    this.projectId,
    this.isFavorite = false,
    this.usageCount = 0,
    this.lastUsedAt,
    required this.createdAt,
  });

  BillTemplate copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    String? categoryIcon,
    String? categoryColor,
    String? currency,
    String? paidBy,
    List<String>? participants,
    String? splitMode,
    String? projectId,
    bool? isFavorite,
    int? usageCount,
    DateTime? lastUsedAt,
    DateTime? createdAt,
  }) {
    return BillTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      currency: currency ?? this.currency,
      paidBy: paidBy ?? this.paidBy,
      participants: participants ?? this.participants,
      splitMode: splitMode ?? this.splitMode,
      projectId: projectId ?? this.projectId,
      isFavorite: isFavorite ?? this.isFavorite,
      usageCount: usageCount ?? this.usageCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        amount,
        category,
        categoryIcon,
        categoryColor,
        currency,
        paidBy,
        participants,
        splitMode,
        projectId,
        isFavorite,
        usageCount,
        lastUsedAt,
        createdAt,
      ];
}
