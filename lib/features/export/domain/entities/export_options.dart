import 'package:equatable/equatable.dart';
import '../../../split_bills/domain/entities/bill.dart';

/// Available export file formats.
enum ExportFormat {
  csv,
  pdf,
}

/// Available predefined or custom date range filters.
enum ExportDateRange {
  allTime,
  thisMonth,
  lastMonth,
  custom,
}

/// Options and filtering criteria for exporting bills and settlement summaries.
class ExportFilter extends Equatable {
  final ExportFormat format;
  final ExportDateRange dateRange;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final String? projectId;
  final String? projectName;
  final DateTime? referenceDate;

  const ExportFilter({
    this.format = ExportFormat.csv,
    this.dateRange = ExportDateRange.allTime,
    this.customStartDate,
    this.customEndDate,
    this.projectId,
    this.projectName,
    this.referenceDate,
  });

  ExportFilter copyWith({
    ExportFormat? format,
    ExportDateRange? dateRange,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? projectId,
    String? projectName,
    DateTime? referenceDate,
    bool clearProject = false,
  }) {
    return ExportFilter(
      format: format ?? this.format,
      dateRange: dateRange ?? this.dateRange,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      projectId: clearProject ? null : (projectId ?? this.projectId),
      projectName: clearProject ? null : (projectName ?? this.projectName),
      referenceDate: referenceDate ?? this.referenceDate,
    );
  }

  /// Filters a list of bills according to the current project and date range settings.
  List<Bill> filterBills(List<Bill> bills) {
    final now = referenceDate ?? DateTime.now();

    return bills.where((b) {
      // 1. Project filtering
      if (projectId != null && projectId!.isNotEmpty && b.projectId != projectId) {
        return false;
      }

      // 2. Date filtering
      switch (dateRange) {
        case ExportDateRange.allTime:
          return true;

        case ExportDateRange.thisMonth:
          return b.date.year == now.year && b.date.month == now.month;

        case ExportDateRange.lastMonth:
          final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
          final lastMonth = now.month == 1 ? 12 : now.month - 1;
          return b.date.year == lastMonthYear && b.date.month == lastMonth;

        case ExportDateRange.custom:
          final billDay = DateTime(b.date.year, b.date.month, b.date.day);
          if (customStartDate != null) {
            final startDay = DateTime(
              customStartDate!.year,
              customStartDate!.month,
              customStartDate!.day,
            );
            if (billDay.isBefore(startDay)) return false;
          }
          if (customEndDate != null) {
            final endDay = DateTime(
              customEndDate!.year,
              customEndDate!.month,
              customEndDate!.day,
            );
            if (billDay.isAfter(endDay)) return false;
          }
          return true;
      }
    }).toList();
  }

  @override
  List<Object?> get props => [
        format,
        dateRange,
        customStartDate,
        customEndDate,
        projectId,
        projectName,
        referenceDate,
      ];
}
