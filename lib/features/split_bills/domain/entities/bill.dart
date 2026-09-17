import 'package:equatable/equatable.dart';
import 'bill_participant.dart';
import 'category_icon.dart';
import 'split_mode.dart';

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
  final List<String> imagePaths;
  final String? categoryColor;
  final String splitMode;

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
    this.imagePaths = const [],
    this.categoryColor,
    this.splitMode = 'equal',
  });

  /// SplitMode enum representation
  SplitMode get splitModeEnum => SplitMode.fromString(splitMode);

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

  /// All image paths attached to this bill, ensuring backward compatibility with [imagePath]
  List<String> get effectiveImagePaths {
    if (imagePaths.isNotEmpty) return imagePaths;
    if (imagePath != null && imagePath!.isNotEmpty) return [imagePath!];
    return const [];
  }

  /// Single primary image path for backward compatibility
  String? get effectiveImagePath {
    if (imagePath != null && imagePath!.isNotEmpty) return imagePath;
    if (imagePaths.isNotEmpty) return imagePaths.first;
    return null;
  }

  /// True if at least one receipt image is attached
  bool get hasReceipt => effectiveImagePaths.isNotEmpty;

  /// Count of attached receipt images
  int get receiptCount => effectiveImagePaths.length;

  Bill copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? paidBy,
    List<BillParticipant>? participants,
    String? projectId,
    String? categoryIcon,
    String? currency,
    String? imagePath,
    List<String>? imagePaths,
    String? categoryColor,
    String? splitMode,
  }) {
    return Bill(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      paidBy: paidBy ?? this.paidBy,
      participants: participants ?? this.participants,
      projectId: projectId ?? this.projectId,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      currency: currency ?? this.currency,
      imagePath: imagePath ?? this.imagePath,
      imagePaths: imagePaths ?? this.imagePaths,
      categoryColor: categoryColor ?? this.categoryColor,
      splitMode: splitMode ?? this.splitMode,
    );
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
        imagePaths,
        categoryColor,
        splitMode,
      ];
}
