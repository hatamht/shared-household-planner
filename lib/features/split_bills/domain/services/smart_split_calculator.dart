import 'package:uuid/uuid.dart';
import '../entities/bill_participant.dart';
import '../entities/split_mode.dart';

class SplitValidationResult {
  final bool isValid;
  final String? errorMessageKey;
  final Map<String, dynamic> metadata;

  const SplitValidationResult({
    required this.isValid,
    this.errorMessageKey,
    this.metadata = const {},
  });

  static const valid = SplitValidationResult(isValid: true);
}

class SmartSplitCalculator {
  static const double tolerance = 0.01;

  /// Calculate equal split where each participant pays totalAmount / N
  static List<BillParticipant> calculateEqual({
    required double totalAmount,
    required List<String> participantNames,
    Map<String, String>? participantIds,
  }) {
    if (participantNames.isEmpty) return const [];
    final count = participantNames.length;
    final perPerson = totalAmount > 0 ? totalAmount / count : 0.0;
    final percent = 100.0 / count;

    return participantNames.map((name) {
      final id = participantIds?[name] ?? const Uuid().v4();
      return BillParticipant(
        participantId: id,
        name: name,
        amount: perPerson,
        percentage: percent,
        shares: 1.0,
      );
    }).toList();
  }

  /// Calculate percentage split where each participant pays totalAmount * (percent / 100)
  static List<BillParticipant> calculatePercentage({
    required double totalAmount,
    required Map<String, double> percentages,
    Map<String, String>? participantIds,
  }) {
    return percentages.entries.map((entry) {
      final name = entry.key;
      final percent = entry.value;
      final amount = totalAmount > 0 ? (totalAmount * (percent / 100.0)) : 0.0;
      final id = participantIds?[name] ?? const Uuid().v4();

      return BillParticipant(
        participantId: id,
        name: name,
        amount: amount,
        percentage: percent,
      );
    }).toList();
  }

  /// Calculate shares split where each participant pays totalAmount * (shares / totalShares)
  static List<BillParticipant> calculateShares({
    required double totalAmount,
    required Map<String, double> shares,
    Map<String, String>? participantIds,
  }) {
    final totalShares = shares.values.fold<double>(0.0, (sum, s) => sum + s);

    return shares.entries.map((entry) {
      final name = entry.key;
      final share = entry.value;
      final fraction = totalShares > 0 ? (share / totalShares) : 0.0;
      final amount = totalAmount * fraction;
      final percent = fraction * 100.0;
      final id = participantIds?[name] ?? const Uuid().v4();

      return BillParticipant(
        participantId: id,
        name: name,
        amount: amount,
        percentage: percent,
        shares: share,
      );
    }).toList();
  }

  /// Calculate custom amount split
  static List<BillParticipant> calculateCustom({
    required double totalAmount,
    required Map<String, double> customAmounts,
    Map<String, String>? participantIds,
  }) {
    return customAmounts.entries.map((entry) {
      final name = entry.key;
      final amount = entry.value;
      final percent = totalAmount > 0 ? (amount / totalAmount) * 100.0 : 0.0;
      final id = participantIds?[name] ?? const Uuid().v4();

      return BillParticipant(
        participantId: id,
        name: name,
        amount: amount,
        percentage: percent,
      );
    }).toList();
  }

  /// Validation: percentages sum to 100% and none are negative
  static SplitValidationResult validatePercentage(Map<String, double> percentages) {
    if (percentages.isEmpty) {
      return const SplitValidationResult(
        isValid: false,
        errorMessageKey: 'min_2_participants',
      );
    }

    for (final p in percentages.values) {
      if (p < 0) {
        return const SplitValidationResult(
          isValid: false,
          errorMessageKey: 'percentage_cannot_be_negative',
        );
      }
    }

    final sum = percentages.values.fold<double>(0.0, (acc, val) => acc + val);
    if ((sum - 100.0).abs() > tolerance) {
      return SplitValidationResult(
        isValid: false,
        errorMessageKey: 'percentage_must_equal_100',
        metadata: {'sum': sum, 'diff': 100.0 - sum},
      );
    }

    return const SplitValidationResult(isValid: true);
  }

  /// Validation: total shares > 0 and no shares are negative
  static SplitValidationResult validateShares(Map<String, double> shares) {
    if (shares.isEmpty) {
      return const SplitValidationResult(
        isValid: false,
        errorMessageKey: 'min_2_participants',
      );
    }

    for (final s in shares.values) {
      if (s < 0) {
        return const SplitValidationResult(
          isValid: false,
          errorMessageKey: 'shares_cannot_be_negative',
        );
      }
    }

    final totalShares = shares.values.fold<double>(0.0, (acc, val) => acc + val);
    if (totalShares <= 0) {
      return const SplitValidationResult(
        isValid: false,
        errorMessageKey: 'total_shares_must_be_positive',
      );
    }

    return const SplitValidationResult(isValid: true);
  }

  /// Validation: custom amounts sum to totalAmount (within tolerance)
  static SplitValidationResult validateCustom(double totalAmount, Map<String, double> customAmounts) {
    if (customAmounts.isEmpty) {
      return const SplitValidationResult(
        isValid: false,
        errorMessageKey: 'min_2_participants',
      );
    }

    for (final amt in customAmounts.values) {
      if (amt < 0) {
        return const SplitValidationResult(
          isValid: false,
          errorMessageKey: 'amount_cannot_be_negative',
        );
      }
    }

    final sum = customAmounts.values.fold<double>(0.0, (acc, val) => acc + val);
    if ((sum - totalAmount).abs() > tolerance) {
      return SplitValidationResult(
        isValid: false,
        errorMessageKey: 'custom_amounts_must_equal_total',
        metadata: {
          'sum': sum,
          'total': totalAmount,
          'diff': totalAmount - sum,
        },
      );
    }

    return const SplitValidationResult(isValid: true);
  }

  /// General validation dispatcher for any SplitMode
  static SplitValidationResult validate({
    required SplitMode mode,
    required double totalAmount,
    required List<String> participants,
    Map<String, double>? percentages,
    Map<String, double>? shares,
    Map<String, double>? customAmounts,
  }) {
    if (participants.length < 2) {
      return const SplitValidationResult(
        isValid: false,
        errorMessageKey: 'min_2_participants',
      );
    }

    if (totalAmount <= 0) {
      return const SplitValidationResult(
        isValid: false,
        errorMessageKey: 'amount_must_be_positive',
      );
    }

    switch (mode) {
      case SplitMode.equal:
        return const SplitValidationResult(isValid: true);
      case SplitMode.percentage:
        return validatePercentage(percentages ?? {});
      case SplitMode.shares:
        return validateShares(shares ?? {});
      case SplitMode.custom:
        return validateCustom(totalAmount, customAmounts ?? {});
    }
  }

  /// Helper to distribute 100% evenly across count participants
  static List<double> distributePercentagesEvenly(int count) {
    if (count <= 0) return const [];
    final base = (100.0 / count);
    final rounded = double.parse(base.toStringAsFixed(2));
    final list = List<double>.filled(count, rounded);
    final total = rounded * count;
    final diff = double.parse((100.0 - total).toStringAsFixed(2));
    if (diff != 0) {
      list[0] = double.parse((list[0] + diff).toStringAsFixed(2));
    }
    return list;
  }
}
