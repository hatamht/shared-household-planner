import 'package:equatable/equatable.dart';

class BillParticipant extends Equatable {
  final String participantId;
  final String name;
  final double amount;

  const BillParticipant({
    required this.participantId,
    required this.name,
    required this.amount,
  });

  @override
  List<Object?> get props => [participantId, name, amount];
}
