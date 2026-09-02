import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';

class BillParticipantModel extends BillParticipant {
  const BillParticipantModel({
    required String participantId,
    required String name,
    required double amount,
  }) : super(
    participantId: participantId,
    name: name,
    amount: amount,
  );

  factory BillParticipantModel.fromJson(Map<String, dynamic> json) {
    return BillParticipantModel(
      participantId: json['participantId'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participantId': participantId,
      'name': name,
      'amount': amount,
    };
  }

  factory BillParticipantModel.fromEntity(BillParticipant participant) {
    return BillParticipantModel(
      participantId: participant.participantId,
      name: participant.name,
      amount: participant.amount,
    );
  }
}
