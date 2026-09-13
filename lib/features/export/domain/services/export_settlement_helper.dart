import '../../../projects/domain/entities/settlement_item.dart';
import '../../../split_bills/domain/entities/bill.dart';

/// Summary of debts and net balances calculated from a collection of bills.
class ExportSettlementSummary {
  final Map<String, double> totalPaid;
  final Map<String, double> totalShare;
  final Map<String, double> netBalances;
  final List<SettlementItem> settlements;

  const ExportSettlementSummary({
    required this.totalPaid,
    required this.totalShare,
    required this.netBalances,
    required this.settlements,
  });

  bool get isAllSettled => settlements.isEmpty;
}

/// Helper for calculating settlements across any arbitrary collection of bills.
class ExportSettlementHelper {
  const ExportSettlementHelper();

  /// Computes settlements and net balances for the given [bills].
  static ExportSettlementSummary calculate(List<Bill> bills) {
    // 1. Identify all unique participants and payers
    final members = <String>{};
    for (final b in bills) {
      if (b.paidBy.trim().isNotEmpty) {
        members.add(b.paidBy.trim());
      }
      for (final p in b.participants) {
        if (p.name.trim().isNotEmpty) {
          members.add(p.name.trim());
        }
      }
    }

    final totalPaid = <String, double>{for (final m in members) m: 0.0};
    final totalShare = <String, double>{for (final m in members) m: 0.0};

    // 2. Accumulate paid and share amounts
    for (final b in bills) {
      final payer = b.paidBy.trim();
      if (payer.isNotEmpty) {
        totalPaid[payer] = (totalPaid[payer] ?? 0.0) + b.amount;
      }

      for (final p in b.participants) {
        final name = p.name.trim();
        if (name.isNotEmpty) {
          totalShare[name] = (totalShare[name] ?? 0.0) + p.amount;
        }
      }
    }

    // 3. Compute net balances
    final netBalances = <String, double>{};
    for (final m in members) {
      netBalances[m] = (totalPaid[m] ?? 0.0) - (totalShare[m] ?? 0.0);
    }

    // 4. Minimize debts using greedy algorithm
    final settlements = _minimizeDebts(netBalances);

    return ExportSettlementSummary(
      totalPaid: Map.unmodifiable(totalPaid),
      totalShare: Map.unmodifiable(totalShare),
      netBalances: Map.unmodifiable(netBalances),
      settlements: List.unmodifiable(settlements),
    );
  }

  static List<SettlementItem> _minimizeDebts(Map<String, double> netBalances) {
    const epsilon = 0.01;

    final creditors = netBalances.entries
        .where((e) => e.value > epsilon)
        .map((e) => _BalanceNode(name: e.key, balance: e.value))
        .toList()
      ..sort((a, b) => b.balance.compareTo(a.balance));

    final debtors = netBalances.entries
        .where((e) => e.value < -epsilon)
        .map((e) => _BalanceNode(name: e.key, balance: -e.value)) // positive debt
        .toList()
      ..sort((a, b) => b.balance.compareTo(a.balance));

    final settlements = <SettlementItem>[];
    int cIdx = 0;
    int dIdx = 0;

    while (cIdx < creditors.length && dIdx < debtors.length) {
      final creditor = creditors[cIdx];
      final debtor = debtors[dIdx];

      final amount = creditor.balance < debtor.balance
          ? creditor.balance
          : debtor.balance;

      final rounded = double.parse(amount.toStringAsFixed(2));
      if (rounded > 0) {
        settlements.add(SettlementItem(
          from: debtor.name,
          to: creditor.name,
          amount: rounded,
        ));
      }

      creditor.balance -= amount;
      debtor.balance -= amount;

      if (creditor.balance <= epsilon) cIdx++;
      if (debtor.balance <= epsilon) dIdx++;
    }

    return settlements;
  }
}

class _BalanceNode {
  final String name;
  double balance;
  _BalanceNode({required this.name, required this.balance});
}
