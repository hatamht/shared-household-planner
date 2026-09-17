import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/bill.dart';
import '../../domain/entities/split_mode.dart';
import '../widgets/receipt_viewer_modal.dart';
import '../../../templates/domain/entities/bill_template.dart';
import '../../../templates/presentation/bloc/bill_templates_bloc.dart';
import 'add_bill_screen.dart';

class BillDetailScreen extends StatelessWidget {
  final Bill bill;

  const BillDetailScreen({
    Key? key,
    required this.bill,
  }) : super(key: key);

  String _formatAmount(double amount, String currency) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    final formatted = formatter.format(amount);
    return currency == 'VND' ? '$formatted đ' : '$formatted $currency';
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

  void _saveAsTemplate(BuildContext context) {
    final loc = AppLocalizations.of(context);
    try {
      final template = BillTemplate(
        id: const Uuid().v4(),
        title: bill.title,
        amount: bill.amount,
        category: bill.category,
        categoryIcon: bill.categoryIcon,
        categoryColor: bill.categoryColor,
        currency: bill.currency ?? 'VND',
        splitMode: bill.splitMode,
        paidBy: bill.paidBy,
        participants: bill.participants.map((p) => p.name).toList(),
        projectId: bill.projectId,
        createdAt: DateTime.now(),
      );
      BlocProvider.of<BillTemplatesBloc>(context).add(CreateTemplateEvent(template));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: Key('templateSaved_${bill.id}'),
          content: Text(loc.translate('template_saved_success')),
        ),
      );
    } catch (_) {}
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddBillScreen(billToEdit: bill),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = bill.currency ?? 'VND';
    final locale = Localizations.localeOf(context).languageCode;
    final dateFormat = DateFormat('dd MMMM yyyy', locale);
    final splitMode = bill.splitModeEnum;

    Color catColor;
    try {
      final hex = bill.effectiveCategoryColor.replaceAll('#', '');
      catColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      catColor = Theme.of(context).colorScheme.primary;
    }

    return Scaffold(
      key: const Key('billDetailScreen'),
      appBar: AppBar(
        key: const Key('billDetailAppBar'),
        title: Text(loc.translate('bill_detail')),
        actions: [
          IconButton(
            key: const Key('billDetailEditButton'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: loc.translate('edit_bill'),
            onPressed: () => _navigateToEdit(context),
          ),
          IconButton(
            key: const Key('billDetailSaveTemplateButton'),
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: loc.translate('save_as_template'),
            onPressed: () => _saveAsTemplate(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              bill.categoryIcon ?? '💰',
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bill.title,
                                key: const Key('billDetailTitle'),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: catColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      loc.translate('category_${bill.category}'),
                                      key: const Key('billDetailCategory'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white70 : catColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    dateFormat.format(bill.date),
                                    key: const Key('billDetailDate'),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    // Amount and Payer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.translate('total_amount'),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatAmount(bill.amount, currency),
                                key: const Key('billDetailAmount'),
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.payment, size: 16),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '${loc.translate('paid_by')}: ${bill.paidBy}',
                                    key: const Key('billDetailPayer'),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Split Mode Badge
                    Container(
                      key: const Key('billDetailSplitMode'),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(splitMode.icon, size: 16, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${loc.translate('split_mode')}: ${splitMode.getLocalizedName(loc)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Split Breakdown Card
            Card(
              key: const Key('billDetailBreakdown'),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            loc.translate('split_breakdown'),
                            key: const Key('splitBreakdownTitle'),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${bill.participants.length} ${loc.translate('participants')}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...bill.participants.map((p) {
                      String subtitle = '';
                      switch (splitMode) {
                        case SplitMode.percentage:
                          final pct = p.percentage ?? (bill.amount > 0 ? (p.amount / bill.amount * 100) : 0);
                          subtitle = '${pct.toStringAsFixed(1)}%';
                          break;
                        case SplitMode.shares:
                          final sh = p.shares ?? 1.0;
                          final shStr = sh % 1 == 0 ? sh.toInt().toString() : sh.toString();
                          final pct = p.percentage ?? (bill.amount > 0 ? (p.amount / bill.amount * 100) : 0);
                          subtitle = '$shStr ${loc.translate(sh == 1 ? 'share' : 'shares')} (${pct.toStringAsFixed(1)}%)';
                          break;
                        case SplitMode.custom:
                          subtitle = loc.translate('split_mode_custom');
                          break;
                        case SplitMode.equal:
                        default:
                          subtitle = loc.translate('split_mode_equal');
                          break;
                      }

                      return Container(
                        key: Key('breakdownParticipantRow_${p.name}'),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              child: Text(
                                p.name.isNotEmpty ? p.name.substring(0, 1).toUpperCase() : '?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    key: Key('breakdownParticipantName_${p.name}'),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  Text(
                                    subtitle,
                                    key: Key('breakdownParticipantDetail_${p.name}'),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatAmount(p.amount, currency),
                              key: Key('breakdownParticipantAmount_${p.name}'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Receipts section if available
            if (bill.hasReceipt) ...[
              Card(
                key: const Key('billDetailReceipts'),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.receipt_long, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                loc.translate('receipt_images'),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          Text(
                            '${bill.receiptCount}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: bill.effectiveImagePaths.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, idx) {
                            final path = bill.effectiveImagePaths[idx];
                            return GestureDetector(
                              key: Key('billDetailReceiptThumbnail_$idx'),
                              onTap: () => _openReceiptModal(context),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: File(path).existsSync()
                                    ? Image.file(
                                        File(path),
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 90,
                                        height: 90,
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.broken_image),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                key: const Key('billDetailBottomEditButton'),
                onPressed: () => _navigateToEdit(context),
                icon: const Icon(Icons.edit),
                label: Text(loc.translate('edit_bill')),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                key: const Key('billDetailBottomTemplateButton'),
                onPressed: () => _saveAsTemplate(context),
                icon: const Icon(Icons.bookmark_add_outlined),
                label: Text(loc.translate('save_as_template')),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
