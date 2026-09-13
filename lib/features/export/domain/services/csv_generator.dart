import 'package:intl/intl.dart';
import '../../../split_bills/domain/entities/bill.dart';
import 'export_settlement_helper.dart';

/// Service for generating RFC 4180 compliant CSV representations of bills and settlements.
class CsvGenerator {
  const CsvGenerator();

  /// Generates a CSV string containing bills and an appended settlement summary.
  String generate({
    required List<Bill> bills,
    bool includeSettlement = true,
  }) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd');

    // ── 1. Bills Header ──────────────────────────────────────────────────────
    buffer.writeln('Date,Person,Amount,Category,Description');

    // ── 2. Bills Rows ────────────────────────────────────────────────────────
    for (final bill in bills) {
      final dateStr = dateFormat.format(bill.date);
      final person = _escape(bill.paidBy);
      final amountStr = bill.amount.toStringAsFixed(2);
      final category = _escape(bill.category);
      final description = _escape(bill.title);

      buffer.writeln('$dateStr,$person,$amountStr,$category,$description');
    }

    // ── 3. Settlement Summary ────────────────────────────────────────────────
    if (includeSettlement) {
      buffer.writeln();
      buffer.writeln('# Settlement Summary');

      final settlementSummary = ExportSettlementHelper.calculate(bills);

      if (settlementSummary.settlements.isEmpty) {
        buffer.writeln('Status');
        buffer.writeln(_escape('All balances are settled!'));
      } else {
        buffer.writeln('From,To,Amount');
        for (final item in settlementSummary.settlements) {
          final from = _escape(item.from);
          final to = _escape(item.to);
          final amount = item.amount.toStringAsFixed(2);
          buffer.writeln('$from,$to,$amount');
        }
      }
    }

    return buffer.toString();
  }

  /// Escapes a field according to standard RFC 4180 rules.
  static String _escape(String field) {
    // If the field contains commas, double quotes, carriage returns, or newlines:
    if (field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r')) {
      final escaped = field.replaceAll('"', '""');
      return '"$escaped"';
    }
    return field;
  }
}
