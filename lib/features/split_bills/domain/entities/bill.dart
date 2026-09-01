import 'package:equatable/equatable.dart';
import 'bill_participant.dart';

class Bill extends Equatable {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String paidBy;
  final List<BillParticipant> participants;

  const Bill({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.paidBy,
    required this.participants,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        amount,
        category,
        date,
        paidBy,
        participants,
      ];
}
