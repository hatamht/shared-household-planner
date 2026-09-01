import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';

class BillModel extends Bill {
  const BillModel({
    required String id,
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    required String paidBy,
    required List<BillParticipant> participants,
  }) : super(
    id: id,
    title: title,
    amount: amount,
    category: category,
    date: date,
    paidBy: paidBy,
    participants: participants,
  );

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      paidBy: json['paidBy'] as String,
      participants: (json['participants'] as List<dynamic>)
          .map((p) => BillParticipant(
            participantId: p['participantId'] as String,
            name: p['name'] as String,
            amount: (p['amount'] as num).toDouble(),
          ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
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
          })
          .toList(),
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
    );
  }
}
