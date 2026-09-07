import 'package:equatable/equatable.dart';
import 'settlement_item.dart';

/// Aggregated statistics and settlement result for a project.
class ProjectStatistics extends Equatable {
  /// Total amount paid by each member (name → amount).
  final Map<String, double> totalPaidPerPerson;

  /// Net balance per member: positive = others owe them, negative = they owe others.
  final Map<String, double> netBalancePerPerson;

  /// Simplified list of transactions needed to settle all debts.
  final List<SettlementItem> settlements;

  /// Member who paid the most in absolute terms (null if no bills).
  final String? topPayer;

  /// Member with the highest debt (most negative net balance); null if all settled.
  final String? topDebtor;

  /// Total expense across all bills in the project.
  final double totalExpense;

  const ProjectStatistics({
    required this.totalPaidPerPerson,
    required this.netBalancePerPerson,
    required this.settlements,
    this.topPayer,
    this.topDebtor,
    required this.totalExpense,
  });

  /// True when everyone is settled (no transactions needed).
  bool get isAllSettled => settlements.isEmpty;

  @override
  List<Object?> get props => [
        totalPaidPerPerson,
        netBalancePerPerson,
        settlements,
        topPayer,
        topDebtor,
        totalExpense,
      ];
}
