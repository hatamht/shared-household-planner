import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../features/split_bills/domain/entities/bill.dart';
import '../entities/project.dart';
import '../entities/project_statistics.dart';
import '../entities/settlement_item.dart';

/// Input parameters for settlement calculation.
class CalculateSettlementParams extends Equatable {
  final Project project;
  final List<Bill> bills;

  const CalculateSettlementParams({
    required this.project,
    required this.bills,
  });

  @override
  List<Object?> get props => [project, bills];
}

/// Calculates who owes whom for a given project and its bills.
///
/// ## Settlement Formula
///
/// For each member m in project.members:
///   totalPaid[m]  = sum of bill.amount for all bills where bill.paidBy == m
///   share[m]      = sum of participant.amount for all bills where participant.name == m
///   net[m]        = totalPaid[m] - share[m]
///
/// net > 0 → creditor (others owe them)
/// net < 0 → debtor   (they owe others)
///
/// Simplified settlements use a greedy algorithm:
///   Sort creditors descending, debtors ascending.
///   For each debtor, pay down the largest creditor first.
///   This minimises the total number of transactions.
class CalculateSettlementUseCase
    implements UseCase<ProjectStatistics, CalculateSettlementParams> {
  const CalculateSettlementUseCase();

  @override
  Future<Either<Failure, ProjectStatistics>> call(
    CalculateSettlementParams params,
  ) async {
    try {
      final stats = _calculate(params.project, params.bills);
      return Right(stats);
    } catch (e) {
      return Left(LocalFailure('Settlement calculation failed: $e'));
    }
  }

  ProjectStatistics _calculate(Project project, List<Bill> bills) {
    final members = project.members;

    // Filter bills that belong to this project
    final projectBills = bills
        .where((b) => b.projectId == project.id)
        .toList();

    // ── Step 1: Compute totalPaid and share per member ──────────────
    final totalPaid = <String, double>{};
    final share = <String, double>{};

    for (final m in members) {
      totalPaid[m] = 0.0;
      share[m] = 0.0;
    }

    for (final bill in projectBills) {
      // Credit the payer
      if (totalPaid.containsKey(bill.paidBy)) {
        totalPaid[bill.paidBy] = totalPaid[bill.paidBy]! + bill.amount;
      }
      // Each participant owes their share
      for (final p in bill.participants) {
        if (share.containsKey(p.name)) {
          share[p.name] = share[p.name]! + p.amount;
        }
      }
    }

    // ── Step 2: Net balance ─────────────────────────────────────────
    final netBalance = <String, double>{};
    for (final m in members) {
      netBalance[m] = (totalPaid[m] ?? 0.0) - (share[m] ?? 0.0);
    }

    // ── Step 3: Total expense ───────────────────────────────────────
    final totalExpense =
        projectBills.fold<double>(0.0, (sum, b) => sum + b.amount);

    // ── Step 4: Simplified settlement (greedy debt minimization) ────
    final settlements = _minimizeDebts(netBalance);

    // ── Step 5: Top stats ───────────────────────────────────────────
    String? topPayer;
    String? topDebtor;

    if (totalPaid.isNotEmpty) {
      final maxPaid = totalPaid.values
          .fold<double>(0, (max, v) => v > max ? v : max);
      if (maxPaid > 0) {
        topPayer = totalPaid.entries
            .firstWhere((e) => e.value == maxPaid)
            .key;
      }
    }

    if (netBalance.isNotEmpty) {
      final minNet = netBalance.values
          .fold<double>(0, (min, v) => v < min ? v : min);
      if (minNet < -0.01) {
        topDebtor = netBalance.entries
            .firstWhere((e) => e.value == minNet)
            .key;
      }
    }

    return ProjectStatistics(
      totalPaidPerPerson: Map.unmodifiable(totalPaid),
      netBalancePerPerson: Map.unmodifiable(netBalance),
      settlements: settlements,
      topPayer: topPayer,
      topDebtor: topDebtor,
      totalExpense: totalExpense,
    );
  }

  /// Greedy debt minimization algorithm.
  ///
  /// Reduces the settlement list to the minimum number of transactions.
  List<SettlementItem> _minimizeDebts(Map<String, double> netBalance) {
    const epsilon = 0.01; // ignore rounding noise below 1 cent

    // Separate into creditors (net > 0) and debtors (net < 0)
    final creditors = netBalance.entries
        .where((e) => e.value > epsilon)
        .map((e) => _Participant(e.key, e.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount)); // descending

    final debtors = netBalance.entries
        .where((e) => e.value < -epsilon)
        .map((e) => _Participant(e.key, -e.value)) // store as positive
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount)); // descending (most debt first)

    final result = <SettlementItem>[];

    int ci = 0, di = 0;
    while (ci < creditors.length && di < debtors.length) {
      final creditor = creditors[ci];
      final debtor = debtors[di];

      final payment = creditor.amount < debtor.amount
          ? creditor.amount
          : debtor.amount;

      if (payment > epsilon) {
        result.add(SettlementItem(
          from: debtor.name,
          to: creditor.name,
          amount: double.parse(payment.toStringAsFixed(0)),
        ));
      }

      creditor.amount -= payment;
      debtor.amount -= payment;

      if (creditor.amount <= epsilon) ci++;
      if (debtor.amount <= epsilon) di++;
    }

    return result;
  }
}

/// Internal mutable helper for the greedy algorithm.
class _Participant {
  final String name;
  double amount;

  _Participant(this.name, this.amount);
}
