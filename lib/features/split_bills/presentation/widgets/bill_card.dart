import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/bill.dart';
import '../../../../core/localization/app_localizations.dart';

class BillCard extends StatelessWidget {
  final Bill bill;

  const BillCard({Key? key, required this.bill}) : super(key: key);

  String _getCategoryEmoji(String? category) {
    final categoryMap = {
      'food': '🍕',
      'transport': '🚕',
      'entertainment': '🎬',
      'utilities': '⚡',
      'shopping': '🛍️',
      'health': '🏥',
      'other': '💰',
    };
    return categoryMap[category?.toLowerCase()] ?? '💰';
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final dateFormat = DateFormat('dd MMM yyyy', locale);
    final loc = AppLocalizations.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(
              _getCategoryEmoji(bill.category),
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dateFormat.format(bill.date)} • ${loc.translate('category_${bill.category}')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${bill.participants.length} ${loc.translate('participants')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${bill.amount.toStringAsFixed(0)}đ',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '−',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
