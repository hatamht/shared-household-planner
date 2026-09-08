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
  final String? projectId;
  final String? categoryIcon;
  final String? currency;
  final String? imagePath;

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
        projectId,
        categoryIcon,
        currency,
        imagePath,
      ];
}
