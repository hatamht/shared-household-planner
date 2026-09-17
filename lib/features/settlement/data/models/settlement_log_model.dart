import '../../domain/entities/settlement_log.dart';

/// Data model representing a [SettlementLog] with JSON and SQLite serialization.
class SettlementLogModel extends SettlementLog {
  const SettlementLogModel({
    required super.id,
    super.projectId,
    required super.payer,
    required super.payee,
    required super.amount,
    required super.date,
    super.status = SettlementStatus.pending,
    super.note,
    required super.createdAt,
  });

  factory SettlementLogModel.fromEntity(SettlementLog entity) {
    return SettlementLogModel(
      id: entity.id,
      projectId: entity.projectId,
      payer: entity.payer,
      payee: entity.payee,
      amount: entity.amount,
      date: entity.date,
      status: entity.status,
      note: entity.note,
      createdAt: entity.createdAt,
    );
  }

  factory SettlementLogModel.fromJson(Map<String, dynamic> json) {
    return SettlementLogModel(
      id: json['id'] as String,
      projectId: json['projectId'] as String?,
      payer: json['payer'] as String,
      payee: json['payee'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      status: SettlementStatus.fromString(json['status'] as String?),
      note: json['note'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'payer': payer,
      'payee': payee,
      'amount': amount,
      'date': date.toIso8601String(),
      'status': status.value,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SettlementLogModel.fromMap(Map<String, dynamic> map) =>
      SettlementLogModel.fromJson(map);

  Map<String, dynamic> toMap() => toJson();
}
