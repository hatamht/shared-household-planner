import 'package:equatable/equatable.dart';

/// Represents the payment status of a debt settlement.
enum SettlementStatus {
  paid,
  pending;

  static SettlementStatus fromString(String? value) {
    if (value == null) return SettlementStatus.pending;
    switch (value.toLowerCase().trim()) {
      case 'paid':
        return SettlementStatus.paid;
      case 'pending':
      default:
        return SettlementStatus.pending;
    }
  }

  String get value => name;
}

/// Domain entity representing an audited payment/settlement record between two members.
class SettlementLog extends Equatable {
  final String id;
  final String? projectId;
  final String payer; // Who paid
  final String payee; // Whom was paid
  final double amount;
  final DateTime date;
  final SettlementStatus status;
  final String? note;
  final DateTime createdAt;

  const SettlementLog({
    required this.id,
    this.projectId,
    required this.payer,
    required this.payee,
    required this.amount,
    required this.date,
    this.status = SettlementStatus.pending,
    this.note,
    required this.createdAt,
  });

  bool get isPaid => status == SettlementStatus.paid;
  bool get isPending => status == SettlementStatus.pending;

  SettlementLog copyWith({
    String? id,
    String? projectId,
    String? payer,
    String? payee,
    double? amount,
    DateTime? date,
    SettlementStatus? status,
    String? note,
    DateTime? createdAt,
    bool clearNote = false,
  }) {
    return SettlementLog(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      payer: payer ?? this.payer,
      payee: payee ?? this.payee,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      status: status ?? this.status,
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        payer,
        payee,
        amount,
        date,
        status,
        note,
        createdAt,
      ];
}
