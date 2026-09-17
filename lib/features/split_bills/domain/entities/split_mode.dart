import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';

enum SplitMode {
  equal,
  percentage,
  shares,
  custom;

  String get value {
    switch (this) {
      case SplitMode.percentage:
        return 'percentage';
      case SplitMode.shares:
        return 'shares';
      case SplitMode.custom:
        return 'custom';
      case SplitMode.equal:
        return 'equal';
    }
  }

  String get localizationKey {
    switch (this) {
      case SplitMode.percentage:
        return 'split_mode_percentage';
      case SplitMode.shares:
        return 'split_mode_shares';
      case SplitMode.custom:
        return 'split_mode_custom';
      case SplitMode.equal:
        return 'split_mode_equal';
    }
  }

  String getLocalizedName(AppLocalizations loc) {
    return loc.translate(localizationKey);
  }

  IconData get icon {
    switch (this) {
      case SplitMode.percentage:
        return Icons.percent;
      case SplitMode.shares:
        return Icons.numbers;
      case SplitMode.custom:
        return Icons.tune;
      case SplitMode.equal:
        return Icons.pie_chart_outline;
    }
  }

  static SplitMode fromString(String? value) {
    if (value == null) return SplitMode.equal;
    switch (value.toLowerCase().trim()) {
      case 'percentage':
      case 'percent':
        return SplitMode.percentage;
      case 'shares':
      case 'share':
        return SplitMode.shares;
      case 'custom':
      case 'custom_amount':
        return SplitMode.custom;
      case 'equal':
      default:
        return SplitMode.equal;
    }
  }
}
