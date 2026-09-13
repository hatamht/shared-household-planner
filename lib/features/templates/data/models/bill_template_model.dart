import 'dart:convert';
import '../../domain/entities/bill_template.dart';

class BillTemplateModel extends BillTemplate {
  const BillTemplateModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.category,
    super.categoryIcon,
    super.categoryColor,
    super.currency = 'VND',
    super.paidBy,
    super.participants = const [],
    super.splitMode = 'equal',
    super.projectId,
    super.isFavorite = false,
    super.usageCount = 0,
    super.lastUsedAt,
    required super.createdAt,
  });

  factory BillTemplateModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedParticipants = [];
    final pRaw = json['participants'];
    if (pRaw != null) {
      if (pRaw is String) {
        try {
          final decoded = jsonDecode(pRaw);
          if (decoded is List) {
            parsedParticipants = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {
          parsedParticipants = [];
        }
      } else if (pRaw is List) {
        parsedParticipants = pRaw.map((e) => e.toString()).toList();
      }
    }

    bool fav = false;
    final favRaw = json['isFavorite'] ?? json['is_favorite'];
    if (favRaw != null) {
      if (favRaw is bool) {
        fav = favRaw;
      } else if (favRaw is num) {
        fav = favRaw != 0;
      }
    }

    DateTime? lastUsed;
    final lastUsedRaw = json['lastUsedAt'] ?? json['last_used_at'];
    if (lastUsedRaw != null && lastUsedRaw.toString().isNotEmpty) {
      lastUsed = DateTime.tryParse(lastUsedRaw.toString());
    }

    DateTime created = DateTime.now();
    final createdRaw = json['createdAt'] ?? json['created_at'];
    if (createdRaw != null && createdRaw.toString().isNotEmpty) {
      created = DateTime.tryParse(createdRaw.toString()) ?? DateTime.now();
    }

    return BillTemplateModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category']?.toString() ?? 'other',
      categoryIcon: (json['categoryIcon'] ?? json['category_icon'])?.toString(),
      categoryColor: (json['categoryColor'] ?? json['category_color'])?.toString(),
      currency: json['currency']?.toString() ?? 'VND',
      paidBy: (json['paidBy'] ?? json['paid_by'])?.toString(),
      participants: parsedParticipants,
      splitMode: (json['splitMode'] ?? json['split_mode'])?.toString() ?? 'equal',
      projectId: (json['projectId'] ?? json['project_id'])?.toString(),
      isFavorite: fav,
      usageCount: ((json['usageCount'] ?? json['usage_count']) as num?)?.toInt() ?? 0,
      lastUsedAt: lastUsed,
      createdAt: created,
    );
  }

  factory BillTemplateModel.fromMap(Map<String, dynamic> map) =>
      BillTemplateModel.fromJson(map);

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'category_icon': categoryIcon,
        'category_color': categoryColor,
        'currency': currency,
        'paid_by': paidBy,
        'participants': jsonEncode(participants),
        'split_mode': splitMode,
        'project_id': projectId,
        'is_favorite': isFavorite ? 1 : 0,
        'usage_count': usageCount,
        'last_used_at': lastUsedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'categoryIcon': categoryIcon,
      'categoryColor': categoryColor,
      'currency': currency,
      'paidBy': paidBy,
      'participants': jsonEncode(participants),
      'splitMode': splitMode,
      'projectId': projectId,
      'isFavorite': isFavorite ? 1 : 0,
      'usageCount': usageCount,
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BillTemplateModel.fromEntity(BillTemplate entity) {
    return BillTemplateModel(
      id: entity.id,
      title: entity.title,
      amount: entity.amount,
      category: entity.category,
      categoryIcon: entity.categoryIcon,
      categoryColor: entity.categoryColor,
      currency: entity.currency,
      paidBy: entity.paidBy,
      participants: entity.participants,
      splitMode: entity.splitMode,
      projectId: entity.projectId,
      isFavorite: entity.isFavorite,
      usageCount: entity.usageCount,
      lastUsedAt: entity.lastUsedAt,
      createdAt: entity.createdAt,
    );
  }

  BillTemplate toEntity() {
    return BillTemplate(
      id: id,
      title: title,
      amount: amount,
      category: category,
      categoryIcon: categoryIcon,
      categoryColor: categoryColor,
      currency: currency,
      paidBy: paidBy,
      participants: participants,
      splitMode: splitMode,
      projectId: projectId,
      isFavorite: isFavorite,
      usageCount: usageCount,
      lastUsedAt: lastUsedAt,
      createdAt: createdAt,
    );
  }

  @override
  BillTemplateModel copyWith({
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
    return BillTemplateModel(
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
}
