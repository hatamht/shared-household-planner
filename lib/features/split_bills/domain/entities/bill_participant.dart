import 'package:equatable/equatable.dart';

class BillParticipant extends Equatable {
  final String participantId;
  final String name;
  final double amount;
  final double? percentage;
  final double? shares;

  const BillParticipant({
    required this.participantId,
    required this.name,
    required this.amount,
    this.percentage,
    this.shares,
  });

  BillParticipant copyWith({
    String? participantId,
    String? name,
    double? amount,
    double? percentage,
    double? shares,
  }) {
    return BillParticipant(
      participantId: participantId ?? this.participantId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
      shares: shares ?? this.shares,
    );
  }

  @override
  List<Object?> get props => [participantId, name, amount, percentage, shares];
}
