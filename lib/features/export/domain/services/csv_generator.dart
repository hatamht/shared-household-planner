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
    dynamic settlementLogs,
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

    // ── 4. Payment History & Settlement Logs ──────────────────────────────────
    if (settlementLogs != null && settlementLogs is Iterable && settlementLogs.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('# Payment History & Settlement Log');
      buffer.writeln('Date,Payer,Payee,Amount,Status,Note');
      for (final log in settlementLogs) {
        final dateStr = dateFormat.format(log.date as DateTime);
        final payer = _escape(log.payer as String);
        final payee = _escape(log.payee as String);
        final amountStr = (log.amount as num).toStringAsFixed(2);
        final statusStr = _escape(log.status.toString().split('.').last);
        final noteStr = _escape((log.note as String?) ?? '');
        buffer.writeln('$dateStr,$payer,$payee,$amountStr,$statusStr,$noteStr');
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
