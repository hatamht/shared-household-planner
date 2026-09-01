import 'package:flutter/material.dart';
import '../../domain/entities/bill.dart';
import '../../../../core/localization/app_localizations.dart';

class StatsCard extends StatelessWidget {
  final List<Bill> bills;

  const StatsCard({Key? key, required this.bills}) : super(key: key);

  double get totalAmount {
    return bills.fold(0, (sum, bill) => sum + bill.amount);
  }

  double get userOwes {
    return totalAmount / (bills.isNotEmpty ? bills.first.participants.length : 1);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.translate('total_spent'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${totalAmount.toStringAsFixed(2)}đ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.translate('you_owe'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${userOwes.toStringAsFixed(2)}đ',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: userOwes > 0 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
