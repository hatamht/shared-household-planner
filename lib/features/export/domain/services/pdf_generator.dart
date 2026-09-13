import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../split_bills/domain/entities/bill.dart';
import 'export_settlement_helper.dart';

/// Service for generating formatted, printable PDF documents of bills and settlements.
class PdfGenerator {
  const PdfGenerator();

  /// Generates a complete PDF document as binary bytes ([Uint8List]).
  Future<Uint8List> generate({
    required List<Bill> bills,
    String? projectName,
    String? dateRangeLabel,
    String currencySymbol = '€',
    bool includeSettlement = true,
  }) async {
    final pdf = pw.Document(
      title: projectName ?? 'Household Expense Report',
      author: 'SimSoft Studio',
    );

    final dateFormat = DateFormat('yyyy-MM-dd');
    final numberFormat = NumberFormat('#,##0.00');
    final generatedDate = dateFormat.format(DateTime.now());

    final totalExpense = bills.fold<double>(0.0, (sum, b) => sum + b.amount);
    final settlementSummary = ExportSettlementHelper.calculate(bills);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Text(
              'Shared Household Planner - Expense Report',
              style: const pw.TextStyle(
                color: PdfColors.grey600,
                fontSize: 9,
              ),
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 16),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(
                color: PdfColors.grey600,
                fontSize: 9,
              ),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // ── 1. Document Title & Subtitle ──────────────────────────────
            pw.Text(
              projectName != null && projectName.isNotEmpty
                  ? projectName
                  : 'Household Expense Report',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated on: $generatedDate',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
                if (dateRangeLabel != null && dateRangeLabel.isNotEmpty)
                  pw.Text(
                    'Period: $dateRangeLabel',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.blueGrey200, height: 20),

            // ── 2. Summary Metrics Cards ─────────────────────────────────
            pw.Row(
              children: [
                _buildMetricCard(
                  'Total Spending',
                  '$currencySymbol${numberFormat.format(totalExpense)}',
                  PdfColors.teal700,
                ),
                pw.SizedBox(width: 12),
                _buildMetricCard(
                  'Total Bills',
                  '${bills.length}',
                  PdfColors.blueGrey700,
                ),
                pw.SizedBox(width: 12),
                _buildMetricCard(
                  'Settlement Items',
                  '${settlementSummary.settlements.length}',
                  PdfColors.orange800,
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // ── 3. Bills Table ───────────────────────────────────────────
            pw.Text(
              'Expenses Breakdown',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.SizedBox(height: 8),
            if (bills.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'No expenses recorded for this selection.',
                    style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 11),
                  ),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  bottom: pw.BorderSide(color: PdfColors.blueGrey300, width: 1),
                ),
                headerStyle: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey800,
                ),
                rowDecoration: const pw.BoxDecoration(
                  color: PdfColors.white,
                ),
                oddRowDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey50,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                headers: ['Date', 'Person', 'Category', 'Description', 'Amount'],
                data: bills.map((b) {
                  return [
                    dateFormat.format(b.date),
                    b.paidBy,
                    b.category,
                    b.title,
                    '$currencySymbol${numberFormat.format(b.amount)}',
                  ];
                }).toList(),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerRight,
                },
              ),
            pw.SizedBox(height: 24),

            // ── 4. Settlement Summary Section ────────────────────────────
            if (includeSettlement) ...[
              pw.Text(
                'Settlement Summary (Who Owes Whom)',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
              ),
              pw.SizedBox(height: 8),
              if (settlementSummary.settlements.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.green200),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'All balances are settled! No payments required.',
                        style: pw.TextStyle(
                          color: PdfColors.green800,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                pw.TableHelper.fromTextArray(
                  border: const pw.TableBorder(
                    horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                    bottom: pw.BorderSide(color: PdfColors.blueGrey300, width: 1),
                  ),
                  headerStyle: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blueGrey700,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  headers: ['From (Debtor)', 'To (Creditor)', 'Amount to Pay'],
                  data: settlementSummary.settlements.map((item) {
                    return [
                      item.from,
                      item.to,
                      '$currencySymbol${numberFormat.format(item.amount)}',
                    ];
                  }).toList(),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.centerRight,
                  },
                ),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildMetricCard(String label, String value, PdfColor valueColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: PdfColors.grey200),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
