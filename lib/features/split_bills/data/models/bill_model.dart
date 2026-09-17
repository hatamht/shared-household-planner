import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'dart:convert';

class BillModel extends Bill {
  const BillModel({
    required String id,
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    required String paidBy,
    required List<BillParticipant> participants,
    String? projectId,
    String? categoryIcon,
    String? currency,
    String? imagePath,
    List<String> imagePaths = const [],
    String? categoryColor,
    String splitMode = 'equal',
  }) : super(
    id: id,
    title: title,
    amount: amount,
    category: category,
    date: date,
    paidBy: paidBy,
    participants: participants,
    projectId: projectId,
    categoryIcon: categoryIcon,
    currency: currency,
    imagePath: imagePath,
    imagePaths: imagePaths,
    categoryColor: categoryColor,
    splitMode: splitMode,
  );

  factory BillModel.fromJson(Map<String, dynamic> json) {
    // Handle participants as either String (from SQLite) or List (from toJson/tests)
    List<dynamic> participantsList;
    final participantsData = json['participants'];
    if (participantsData is String) {
      participantsList = jsonDecode(participantsData) as List<dynamic>;
    } else {
      participantsList = participantsData as List<dynamic>;
    }

    List<String> imagePathsList = [];
    final rawImagePaths = json['imagePaths'];
    if (rawImagePaths is String && rawImagePaths.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawImagePaths);
        if (decoded is List) {
          imagePathsList = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    } else if (rawImagePaths is List) {
      imagePathsList = rawImagePaths.map((e) => e.toString()).toList();
    }

    final singleImagePath = json['imagePath'] as String?;
    if (imagePathsList.isEmpty && singleImagePath != null && singleImagePath.isNotEmpty) {
      imagePathsList = [singleImagePath];
    }
    
    return BillModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      paidBy: json['paidBy'] as String,
      participants: participantsList
          .map((p) {
            if (p is BillParticipant) return p;
            final map = p as Map<String, dynamic>;
            return BillParticipant(
              participantId: map['participantId'] as String,
              name: map['name'] as String,
              amount: (map['amount'] as num).toDouble(),
              percentage: map['percentage'] != null ? (map['percentage'] as num).toDouble() : null,
              shares: map['shares'] != null ? (map['shares'] as num).toDouble() : null,
            );
          })
          .toList(),
      projectId: json['projectId'] as String?,
      categoryIcon: json['categoryIcon'] as String?,
      currency: json['currency'] as String? ?? 'VND',
      imagePath: singleImagePath ?? (imagePathsList.isNotEmpty ? imagePathsList.first : null),
      imagePaths: imagePathsList,
      categoryColor: json['categoryColor'] as String?,
      splitMode: json['splitMode'] as String? ?? 'equal',
    );
  }

  Map<String, dynamic> toJson() {
    final paths = effectiveImagePaths;
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'paidBy': paidBy,
      'participants': participants
          .map((p) => {
            'participantId': p.participantId,
            'name': p.name,
            'amount': p.amount,
            if (p.percentage != null) 'percentage': p.percentage,
            if (p.shares != null) 'shares': p.shares,
          })
          .toList(),
      if (projectId != null) 'projectId': projectId,
      if (categoryIcon != null) 'categoryIcon': categoryIcon,
      if (currency != null) 'currency': currency,
      if (effectiveImagePath != null) 'imagePath': effectiveImagePath,
      if (paths.isNotEmpty) 'imagePaths': jsonEncode(paths),
      if (categoryColor != null) 'categoryColor': categoryColor,
      'splitMode': splitMode,
    };
  }

  factory BillModel.fromEntity(Bill bill) {
    return BillModel(
      id: bill.id,
      title: bill.title,
      amount: bill.amount,
      category: bill.category,
      date: bill.date,
      paidBy: bill.paidBy,
      participants: bill.participants,
      projectId: bill.projectId,
      categoryIcon: bill.categoryIcon,
      currency: bill.currency,
      imagePath: bill.imagePath,
      imagePaths: bill.imagePaths,
      categoryColor: bill.categoryColor,
      splitMode: bill.splitMode,
    );
  }

  @override
  BillModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? paidBy,
    List<BillParticipant>? participants,
    String? projectId,
    bool clearProjectId = false,
    String? categoryIcon,
    String? currency,
    String? imagePath,
    List<String>? imagePaths,
    String? categoryColor,
    String? splitMode,
  }) {
    return BillModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      paidBy: paidBy ?? this.paidBy,
      participants: participants ?? this.participants,
      projectId: clearProjectId ? null : (projectId ?? this.projectId),
      categoryIcon: categoryIcon ?? this.categoryIcon,
      currency: currency ?? this.currency,
      imagePath: imagePath ?? this.imagePath,
      imagePaths: imagePaths ?? this.imagePaths,
      categoryColor: categoryColor ?? this.categoryColor,
      splitMode: splitMode ?? this.splitMode,
    );
  }
}
