import 'package:equatable/equatable.dart';
import 'settlement_log.dart';

/// Available date range presets for filtering settlements.
enum SettlementDateRange {
  allTime,
  thisMonth,
  lastMonth,
  custom,
}

/// Filter criteria for querying and displaying settlement logs.
class SettlementFilter extends Equatable {
  final String? person;
  final SettlementDateRange dateRange;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final SettlementStatus? status;
  final String? projectId;
  final DateTime? referenceDate;
  final bool oldestFirst;

  const SettlementFilter({
    this.person,
    this.dateRange = SettlementDateRange.allTime,
    this.customStartDate,
    this.customEndDate,
    this.status,
    this.projectId,
    this.referenceDate,
    this.oldestFirst = true,
  });

  SettlementFilter copyWith({
    String? person,
    SettlementDateRange? dateRange,
    DateTime? customStartDate,
    DateTime? customEndDate,
    SettlementStatus? status,
    String? projectId,
    DateTime? referenceDate,
    bool? oldestFirst,
    bool clearPerson = false,
    bool clearStatus = false,
    bool clearProject = false,
  }) {
    return SettlementFilter(
      person: clearPerson ? null : (person ?? this.person),
      dateRange: dateRange ?? this.dateRange,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      status: clearStatus ? null : (status ?? this.status),
      projectId: clearProject ? null : (projectId ?? this.projectId),
      referenceDate: referenceDate ?? this.referenceDate,
      oldestFirst: oldestFirst ?? this.oldestFirst,
    );
  }

  /// Filters and orders [logs] according to the configured criteria.
  List<SettlementLog> filterLogs(List<SettlementLog> logs) {
    final now = referenceDate ?? DateTime.now();

    final filtered = logs.where((log) {
      // 1. Project filtering
      if (projectId != null && projectId!.isNotEmpty && log.projectId != projectId) {
        return false;
      }

      // 2. Person filtering (matches payer OR payee)
      if (person != null && person!.trim().isNotEmpty) {
        final target = person!.trim().toLowerCase();
        final payerMatches = log.payer.trim().toLowerCase() == target;
        final payeeMatches = log.payee.trim().toLowerCase() == target;
        if (!payerMatches && !payeeMatches) {
          return false;
        }
      }

      // 3. Status filtering
      if (status != null && log.status != status) {
        return false;
      }

      // 4. Date range filtering
      switch (dateRange) {
        case SettlementDateRange.allTime:
          return true;

        case SettlementDateRange.thisMonth:
          return log.date.year == now.year && log.date.month == now.month;

        case SettlementDateRange.lastMonth:
          final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
          final lastMonth = now.month == 1 ? 12 : now.month - 1;
          return log.date.year == lastMonthYear && log.date.month == lastMonth;

        case SettlementDateRange.custom:
          final logDay = DateTime(log.date.year, log.date.month, log.date.day);
          if (customStartDate != null) {
            final startDay = DateTime(
              customStartDate!.year,
              customStartDate!.month,
              customStartDate!.day,
            );
            if (logDay.isBefore(startDay)) return false;
          }
          if (customEndDate != null) {
            final endDay = DateTime(
              customEndDate!.year,
              customEndDate!.month,
              customEndDate!.day,
            );
            if (logDay.isAfter(endDay)) return false;
          }
          return true;
      }
    }).toList();

    // 5. Timeline ordering: oldest settlement first (or newest first if configured)
    filtered.sort((a, b) {
      final cmp = a.date.compareTo(b.date);
      if (cmp != 0) {
        return oldestFirst ? cmp : -cmp;
      }
      // Secondary sort by createdAt
      return oldestFirst
          ? a.createdAt.compareTo(b.createdAt)
          : b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  @override
  List<Object?> get props => [
        person,
        dateRange,
        customStartDate,
        customEndDate,
        status,
        projectId,
        referenceDate,
        oldestFirst,
      ];
}
