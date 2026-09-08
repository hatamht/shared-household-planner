import 'package:equatable/equatable.dart';
import 'bill_participant.dart';
import 'category_icon.dart';

class Bill extends Equatable {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String paidBy;
  final List<BillParticipant> participants;
  final String? projectId;
  final String? categoryIcon;
  final String? currency;
  final String? imagePath;
  final String? categoryColor;

  const Bill({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.paidBy,
    required this.participants,
    this.projectId,
    this.categoryIcon,
    this.currency,
    this.imagePath,
    this.categoryColor,
  });

  /// Effective color: returns categoryColor if present, or fallback from defaultCategoryIcons, or default gray
  String get effectiveCategoryColor {
    if (categoryColor != null && categoryColor!.isNotEmpty) {
      return categoryColor!;
    }
    final match = defaultCategoryIcons.where((c) => c.id == category);
    if (match.isNotEmpty) {
      return match.first.colorHex;
    }
    return '#9E9E9E';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        amount,
        category,
        date,
        paidBy,
        participants,
        projectId,
        categoryIcon,
        currency,
        imagePath,
        categoryColor,
      ];
}
