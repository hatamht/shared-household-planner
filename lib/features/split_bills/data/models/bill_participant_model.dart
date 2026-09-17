import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';

class BillParticipantModel extends BillParticipant {
  const BillParticipantModel({
    required String participantId,
    required String name,
    required double amount,
    double? percentage,
    double? shares,
  }) : super(
    participantId: participantId,
    name: name,
    amount: amount,
    percentage: percentage,
    shares: shares,
  );

  factory BillParticipantModel.fromJson(Map<String, dynamic> json) {
    return BillParticipantModel(
      participantId: json['participantId'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      percentage: json['percentage'] != null ? (json['percentage'] as num).toDouble() : null,
      shares: json['shares'] != null ? (json['shares'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participantId': participantId,
      'name': name,
      'amount': amount,
      if (percentage != null) 'percentage': percentage,
      if (shares != null) 'shares': shares,
    };
  }

  factory BillParticipantModel.fromEntity(BillParticipant participant) {
    return BillParticipantModel(
      participantId: participant.participantId,
      name: participant.name,
      amount: participant.amount,
      percentage: participant.percentage,
      shares: participant.shares,
    );
  }

  @override
  BillParticipantModel copyWith({
    String? participantId,
    String? name,
    double? amount,
    double? percentage,
    double? shares,
  }) {
    return BillParticipantModel(
      participantId: participantId ?? this.participantId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
      shares: shares ?? this.shares,
    );
  }
}
