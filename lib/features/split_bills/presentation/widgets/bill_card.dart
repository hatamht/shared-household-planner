import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/bill.dart';
import '../../../../core/localization/app_localizations.dart';
import 'receipt_viewer_modal.dart';

class BillCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback? onTap;

  const BillCard({Key? key, required this.bill, this.onTap}) : super(key: key);

  String _getCategoryEmoji(String? category) {
    final categoryMap = {
      'food': '🍕',
      'restaurant': '🍽️',
      'transport': '🚕',
      'entertainment': '🎬',
      'utilities': '⚡',
      'shopping': '🛍️',
      'health': '🏥',
      'other': '💰',
    };
    return categoryMap[category?.toLowerCase()] ?? '💰';
  }

  void _openReceiptModal(BuildContext context) {
    if (bill.hasReceipt) {
      ReceiptViewerModal.show(
        context,
        imagePaths: bill.effectiveImagePaths,
        title: bill.title,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final dateFormat = DateFormat('dd MMM yyyy', locale);
    final loc = AppLocalizations.of(context);
    final currency = bill.currency ?? 'VND';
    final hasReceipt = bill.hasReceipt;

    return Card(
      key: Key('billCard_${bill.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else if (hasReceipt) {
            _openReceiptModal(context);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Category emoji
              Text(
                bill.categoryIcon ?? _getCategoryEmoji(bill.category),
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),

              // Title and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dateFormat.format(bill.date)} • ${loc.translate('category_${bill.category}')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${bill.participants.length} ${loc.translate('participants')}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                        if (hasReceipt) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.attach_file,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          Text(
                            '${bill.effectiveImagePaths.length}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Receipt Thumbnail if exists
              if (hasReceipt) ...[
                GestureDetector(
                  key: Key('billReceiptThumbnail_${bill.id}'),
                  onTap: () => _openReceiptModal(context),
                  child: Container(
                    key: const Key('billReceiptThumbnail'),
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: File(bill.effectiveImagePaths.first).existsSync()
                              ? Image.file(
                                  File(bill.effectiveImagePaths.first),
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.blueGrey.withOpacity(0.15),
                                  width: 44,
                                  height: 44,
                                  child: const Icon(
                                    Icons.receipt_long,
                                    size: 24,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                        ),
                        if (bill.effectiveImagePaths.length > 1)
                          Positioned(
                            bottom: 1,
                            right: 1,
                            child: Container(
                              key: const Key('receiptCountBadge'),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '+${bill.effectiveImagePaths.length - 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${bill.amount.toStringAsFixed(0)}${currency == 'VND' ? 'đ' : ' $currency'}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      ),
    );
  }
}
