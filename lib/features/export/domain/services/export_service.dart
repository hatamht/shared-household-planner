import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../split_bills/domain/entities/bill.dart';
import '../entities/export_options.dart';
import 'csv_generator.dart';
import 'export_filename_builder.dart';
import 'pdf_generator.dart';
import 'share_service.dart';

/// Represents the outcome of an export operation.
class ExportResult {
  final bool success;
  final String? filePath;
  final String? fileName;
  final ExportFormat format;
  final int billCount;
  final String? error;

  const ExportResult({
    required this.success,
    this.filePath,
    this.fileName,
    required this.format,
    required this.billCount,
    this.error,
  });

  factory ExportResult.failure({
    required ExportFormat format,
    required int billCount,
    required String error,
  }) {
    return ExportResult(
      success: false,
      format: format,
      billCount: billCount,
      error: error,
    );
  }
}

/// Orchestrates generating files, writing them to disk, and sharing via sheet.
class ExportService {
  final CsvGenerator csvGenerator;
  final PdfGenerator pdfGenerator;
  final ExportFilenameBuilder filenameBuilder;
  final ShareService shareService;
  final Future<Directory> Function()? getOutputDirectory;

  const ExportService({
    this.csvGenerator = const CsvGenerator(),
    this.pdfGenerator = const PdfGenerator(),
    this.filenameBuilder = const ExportFilenameBuilder(),
    this.shareService = const SharePlusService(),
    this.getOutputDirectory,
  });

  /// Generates the export file (CSV or PDF) and saves it to local disk storage.
  Future<ExportResult> exportToFile({
    required List<Bill> bills,
    required ExportFilter filter,
    String currencySymbol = '€',
    dynamic settlementLogs,
  }) async {
    try {
      final filteredBills = filter.filterBills(bills);
      final fileName = filenameBuilder.build(
        projectName: filter.projectName,
        format: filter.format,
      );

      final dir = getOutputDirectory != null
          ? await getOutputDirectory!()
          : await getTemporaryDirectory();

      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      if (filter.format == ExportFormat.csv) {
        final csvString = csvGenerator.generate(
          bills: filteredBills,
          includeSettlement: true,
          settlementLogs: settlementLogs,
        );
        await file.writeAsString(csvString);
      } else {
        final pdfBytes = await pdfGenerator.generate(
          bills: filteredBills,
          projectName: filter.projectName,
          dateRangeLabel: filter.dateRange.name,
          currencySymbol: currencySymbol,
          includeSettlement: true,
          settlementLogs: settlementLogs,
        );
        await file.writeAsBytes(pdfBytes);
      }

      return ExportResult(
        success: true,
        filePath: filePath,
        fileName: fileName,
        format: filter.format,
        billCount: filteredBills.length,
      );
    } catch (e) {
      return ExportResult.failure(
        format: filter.format,
        billCount: bills.length,
        error: e.toString(),
      );
    }
  }

  /// Exports the file and immediately invokes the system share sheet.
  Future<ExportResult> exportAndShare({
    required List<Bill> bills,
    required ExportFilter filter,
    String currencySymbol = '€',
    dynamic settlementLogs,
  }) async {
    final exportRes = await exportToFile(
      bills: bills,
      filter: filter,
      currencySymbol: currencySymbol,
      settlementLogs: settlementLogs,
    );

    if (!exportRes.success || exportRes.filePath == null) {
      return exportRes;
    }

    final shareSuccess = await shareService.shareFile(
      filePath: exportRes.filePath!,
      subject: 'Household Expenses Export - ${exportRes.fileName}',
      text: 'Exported ${exportRes.billCount} bills.',
    );

    if (!shareSuccess) {
      return ExportResult(
        success: false,
        filePath: exportRes.filePath,
        fileName: exportRes.fileName,
        format: exportRes.format,
        billCount: exportRes.billCount,
        error: 'Sharing cancelled or unavailable',
      );
    }

    return exportRes;
  }
}
