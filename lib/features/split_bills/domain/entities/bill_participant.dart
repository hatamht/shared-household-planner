import 'package:equatable/equatable.dart';

class BillParticipant extends Equatable {
  final String memberId;
  final double amount;

  const BillParticipant({
    required this.memberId,
    required this.amount,
  });

  @override
  List<Object?> get props => [memberId, amount];
}
