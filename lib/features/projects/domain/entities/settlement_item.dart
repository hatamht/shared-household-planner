import 'package:equatable/equatable.dart';

/// Represents a single debt: [from] owes [to] the given [amount].
class SettlementItem extends Equatable {
  final String from;
  final String to;
  final double amount;

  const SettlementItem({
    required this.from,
    required this.to,
    required this.amount,
  });

  @override
  List<Object?> get props => [from, to, amount];
}
