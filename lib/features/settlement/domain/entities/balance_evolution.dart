import 'package:equatable/equatable.dart';
import 'settlement_log.dart';

/// Represents a single point in the timeline showing settlement details and the running balance evolution.
class BalanceEvolutionItem extends Equatable {
  final SettlementLog log;
  /// Running total of paid settlements accumulated up to and including this transaction.
  final double runningTotal;
  /// Total volume of all recorded settlements (paid + pending) up to this point.
  final double cumulativeTotal;

  const BalanceEvolutionItem({
    required this.log,
    required this.runningTotal,
    required this.cumulativeTotal,
  });

  @override
  List<Object?> get props => [log, runningTotal, cumulativeTotal];
}

/// Helper service for calculating running balance evolution over a sequence of settlements.
class BalanceEvolutionCalculator {
  const BalanceEvolutionCalculator();

  /// Calculates the running balance evolution for a chronological list of [logs].
  /// Note: [logs] should be ordered chronologically (oldest first).
  static List<BalanceEvolutionItem> calculate(List<SettlementLog> logs) {
    double runningPaid = 0.0;
    double runningTotalVolume = 0.0;

    final items = <BalanceEvolutionItem>[];

    for (final log in logs) {
      runningTotalVolume += log.amount;
      if (log.isPaid) {
        runningPaid += log.amount;
      }

      items.add(
        BalanceEvolutionItem(
          log: log,
          runningTotal: runningPaid,
          cumulativeTotal: runningTotalVolume,
        ),
      );
    }

    return List.unmodifiable(items);
  }
}
