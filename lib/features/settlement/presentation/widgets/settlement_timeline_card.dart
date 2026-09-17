import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/balance_evolution.dart';
import '../../domain/entities/settlement_log.dart';

/// Card rendering a single settlement transaction in the chronological timeline.
class SettlementTimelineCard extends StatelessWidget {
  final BalanceEvolutionItem item;
  final String currencySymbol;
  final void Function(SettlementLog log)? onMarkAsPaid;
  final void Function(SettlementLog log)? onUndoMarkAsPaid;
  final void Function(SettlementLog log)? onDelete;
  final void Function(SettlementLog log)? onEdit;

  const SettlementTimelineCard({
    super.key,
    required this.item,
    this.currencySymbol = 'đ',
    this.onMarkAsPaid,
    this.onUndoMarkAsPaid,
    this.onDelete,
    this.onEdit,
  });

  String _formatAmount(double value) {
    final formatter = NumberFormat('#,##0.##');
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final log = item.log;
    final dateFormat = DateFormat('yyyy-MM-dd');

    final isPaid = log.isPaid;
    final statusColor = isPaid ? Colors.green : Colors.orange;

    return Card(
      key: Key('settlementCard_${log.id}'),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1.2,
        ),
      ),
      color: isDark ? const Color(0xFF242424) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Status badge & Running Total badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPaid ? Icons.check_circle : Icons.pending_outlined,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPaid
                            ? loc.translate('status_paid')
                            : loc.translate('status_pending'),
                        key: Key('settlementStatusText_${log.id}'),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Running total badge (Balance evolution)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${loc.translate('running_total')}: ${_formatAmount(item.runningTotal)}$currencySymbol',
                    key: Key('runningTotalText_${log.id}'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Middle Row: Avatars, who paid whom, and amount
            Row(
              children: [
                // Payer Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  child: Text(
                    log.payer.isNotEmpty ? log.payer[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Payer -> Payee text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              log.payer,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                          ),
                          Flexible(
                            child: Text(
                              log.payee,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateFormat.format(log.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount
                Text(
                  '${_formatAmount(log.amount)}$currencySymbol',
                  key: Key('settlementAmountText_${log.id}'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isPaid ? Colors.green : Colors.redAccent,
                  ),
                ),
              ],
            ),

            // Note (if present)
            if (log.note != null && log.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note_alt_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        log.note!,
                        key: Key('settlementNoteText_${log.id}'),
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 20),

            // Bottom Actions: Mark as paid / Undo button & Options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isPaid)
                  TextButton.icon(
                    key: Key('markPaidButton_${log.id}'),
                    icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                    label: Text(
                      loc.translate('mark_as_paid'),
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => onMarkAsPaid?.call(log),
                  )
                else
                  TextButton.icon(
                    key: Key('undoPaidButton_${log.id}'),
                    icon: const Icon(Icons.undo, size: 18, color: Colors.orange),
                    label: Text(
                      loc.translate('undo_mark_as_paid'),
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => onUndoMarkAsPaid?.call(log),
                  ),

                // Delete button
                IconButton(
                  key: Key('deleteSettlement_${log.id}'),
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                  tooltip: loc.translate('delete'),
                  onPressed: () => onDelete?.call(log),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
