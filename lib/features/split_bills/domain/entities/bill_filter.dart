import 'package:equatable/equatable.dart';
import 'bill.dart';

/// Entity representing search and filtering criteria for Bills.
class BillFilter extends Equatable {
  final String searchQuery;
  final Set<String> selectedPersons;
  final Set<String> selectedCategories;
  final DateTime? fromDate;
  final DateTime? toDate;
  final double? minAmount;
  final double? maxAmount;

  const BillFilter({
    this.searchQuery = '',
    this.selectedPersons = const {},
    this.selectedCategories = const {},
    this.fromDate,
    this.toDate,
    this.minAmount,
    this.maxAmount,
  });

  const BillFilter.initial()
      : searchQuery = '',
        selectedPersons = const {},
        selectedCategories = const {},
        fromDate = null,
        toDate = null,
        minAmount = null,
        maxAmount = null;

  /// Whether any search query or filter condition is active.
  bool get isActive {
    return searchQuery.trim().isNotEmpty ||
        selectedPersons.isNotEmpty ||
        selectedCategories.isNotEmpty ||
        fromDate != null ||
        toDate != null ||
        minAmount != null ||
        maxAmount != null;
  }

  /// Total number of active filter categories (including search if non-empty).
  int get activeFilterCount {
    int count = 0;
    if (searchQuery.trim().isNotEmpty) count++;
    if (selectedPersons.isNotEmpty) count++;
    if (selectedCategories.isNotEmpty) count++;
    if (fromDate != null || toDate != null) count++;
    if (minAmount != null || maxAmount != null) count++;
    return count;
  }

  /// Number of non-text filters active (persons, categories, date, amount).
  int get nonTextFilterCount {
    int count = 0;
    if (selectedPersons.isNotEmpty) count++;
    if (selectedCategories.isNotEmpty) count++;
    if (fromDate != null || toDate != null) count++;
    if (minAmount != null || maxAmount != null) count++;
    return count;
  }

  /// Evaluates whether a given [bill] matches ALL active filter criteria (AND logic).
  bool matches(Bill bill) {
    // 1. Search Query filter (matches title, category, paidBy, participant names)
    final query = searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      final titleMatch = bill.title.toLowerCase().contains(query);
      final categoryMatch = bill.category.toLowerCase().contains(query);
      final payerMatch = bill.paidBy.toLowerCase().contains(query);
      final participantMatch = bill.participants.any(
        (p) => p.name.toLowerCase().contains(query),
      );

      if (!titleMatch && !categoryMatch && !payerMatch && !participantMatch) {
        return false;
      }
    }

    // 2. Person filter (matches if bill payer or any participant is in selectedPersons)
    if (selectedPersons.isNotEmpty) {
      final payerMatch = selectedPersons.contains(bill.paidBy);
      final participantMatch = bill.participants.any(
        (p) => selectedPersons.contains(p.name),
      );
      if (!payerMatch && !participantMatch) {
        return false;
      }
    }

    // 3. Category filter (matches if bill.category is in selectedCategories)
    if (selectedCategories.isNotEmpty) {
      final normalizedSelected = selectedCategories.map((c) => c.toLowerCase()).toSet();
      if (!normalizedSelected.contains(bill.category.toLowerCase())) {
        return false;
      }
    }

    // 4. Date range filter (from start of fromDate to end of toDate)
    if (fromDate != null) {
      final startOfDay = DateTime(fromDate!.year, fromDate!.month, fromDate!.day);
      if (bill.date.isBefore(startOfDay)) {
        return false;
      }
    }
    if (toDate != null) {
      final endOfDay = DateTime(toDate!.year, toDate!.month, toDate!.day, 23, 59, 59, 999);
      if (bill.date.isAfter(endOfDay)) {
        return false;
      }
    }

    // 5. Amount range filter (minAmount <= bill.amount <= maxAmount)
    if (minAmount != null && bill.amount < minAmount!) {
      return false;
    }
    if (maxAmount != null && bill.amount > maxAmount!) {
      return false;
    }

    // All active criteria matched (AND logic)
    return true;
  }

  /// Applies the filter to an arbitrary list of bills.
  List<Bill> apply(List<Bill> bills) {
    if (!isActive) return bills;
    return bills.where(matches).toList();
  }

  BillFilter copyWith({
    String? searchQuery,
    Set<String>? selectedPersons,
    Set<String>? selectedCategories,
    DateTime? fromDate,
    DateTime? toDate,
    double? minAmount,
    double? maxAmount,
    bool clearDates = false,
    bool clearAmounts = false,
  }) {
    return BillFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedPersons: selectedPersons ?? this.selectedPersons,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      fromDate: clearDates ? null : (fromDate ?? this.fromDate),
      toDate: clearDates ? null : (toDate ?? this.toDate),
      minAmount: clearAmounts ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmounts ? null : (maxAmount ?? this.maxAmount),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'searchQuery': searchQuery,
      'selectedPersons': selectedPersons.toList(),
      'selectedCategories': selectedCategories.toList(),
      'fromDate': fromDate?.toIso8601String(),
      'toDate': toDate?.toIso8601String(),
      'minAmount': minAmount,
      'maxAmount': maxAmount,
    };
  }

  factory BillFilter.fromJson(Map<String, dynamic> json) {
    return BillFilter(
      searchQuery: json['searchQuery'] as String? ?? '',
      selectedPersons: (json['selectedPersons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          const {},
      selectedCategories: (json['selectedCategories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          const {},
      fromDate: json['fromDate'] != null
          ? DateTime.tryParse(json['fromDate'] as String)
          : null,
      toDate: json['toDate'] != null
          ? DateTime.tryParse(json['toDate'] as String)
          : null,
      minAmount: (json['minAmount'] as num?)?.toDouble(),
      maxAmount: (json['maxAmount'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        selectedPersons,
        selectedCategories,
        fromDate,
        toDate,
        minAmount,
        maxAmount,
      ];
}
