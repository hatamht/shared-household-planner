import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/settlement_filter.dart';
import '../../domain/entities/settlement_log.dart';
import '../bloc/settlement_bloc.dart';
import '../widgets/add_settlement_dialog.dart';
import '../widgets/settlement_timeline_card.dart';

/// Screen displaying the chronological settlement log & payment history with
/// filtering, status toggling, balance evolution tracking, and export actions.
class PaymentHistoryScreen extends StatefulWidget {
  final String? projectId;
  final String? projectName;
  final List<String> projectMembers;
  final String currencySymbol;

  const PaymentHistoryScreen({
    super.key,
    this.projectId,
    this.projectName,
    this.projectMembers = const [],
    this.currencySymbol = 'đ',
  });

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  SettlementFilter _filter = const SettlementFilter(oldestFirst: true);

  @override
  void initState() {
    super.initState();
    _filter = _filter.copyWith(projectId: widget.projectId);
    context.read<SettlementBloc>().add(
          LoadSettlementsEvent(
            projectId: widget.projectId,
            filter: _filter,
          ),
        );
  }

  void _onFilterChanged(SettlementFilter newFilter) {
    setState(() => _filter = newFilter);
    context.read<SettlementBloc>().add(UpdateSettlementFilterEvent(newFilter));
  }

  void _showAddPaymentSheet(BuildContext context, {SettlementLog? editingLog}) {
    AddSettlementDialog.show(
      context,
      projectId: widget.projectId,
      availableMembers: widget.projectMembers,
      editingLog: editingLog,
      onSave: (log) {
        if (editingLog != null) {
          context.read<SettlementBloc>().add(UpdateSettlementEvent(log));
        } else {
          context.read<SettlementBloc>().add(CreateSettlementEvent(log));
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('settlement_recorded_success'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _handleMarkAsPaid(SettlementLog log) {
    context.read<SettlementBloc>().add(MarkSettlementAsPaidEvent(log.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).translate('settlement_status_updated'),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleUndoMarkAsPaid(SettlementLog log) {
    context.read<SettlementBloc>().add(UndoMarkSettlementAsPaidEvent(log.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).translate('settlement_status_updated'),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleDelete(SettlementLog log) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.translate('delete')),
        content: Text(loc.translate('delete_settlement_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.translate('cancel')),
          ),
          ElevatedButton(
            key: const Key('confirmDeleteSettlementButton'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<SettlementBloc>().add(DeleteSettlementEvent(log.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.translate('settlement_deleted')),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(loc.translate('delete')),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double val) {
    return NumberFormat('#,##0.##').format(val);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = widget.projectName != null && widget.projectName!.isNotEmpty
        ? '${widget.projectName} - ${loc.translate('payment_history')}'
        : loc.translate('payment_history');

    return Scaffold(
      key: const Key('paymentHistoryScaffold'),
      appBar: AppBar(
        title: Text(title, key: const Key('paymentHistoryAppBarTitle')),
        actions: [
          // Timeline sort order toggle (oldest first <-> newest first)
          IconButton(
            key: const Key('timelineSortOrderButton'),
            icon: Icon(
              _filter.oldestFirst ? Icons.history : Icons.update,
            ),
            tooltip: loc.translate('timeline_oldest_first'),
            onPressed: () {
              _onFilterChanged(
                _filter.copyWith(oldestFirst: !_filter.oldestFirst),
              );
            },
          ),
          IconButton(
            key: const Key('addPaymentAppBarButton'),
            icon: const Icon(Icons.add),
            tooltip: loc.translate('add_payment'),
            onPressed: () => _showAddPaymentSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('addPaymentFab'),
        onPressed: () => _showAddPaymentSheet(context),
        tooltip: loc.translate('add_payment'),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<SettlementBloc, SettlementState>(
        builder: (context, state) {
          if (state is SettlementLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SettlementError) {
            return Center(
              child: Text(state.message, style: const TextStyle(color: Colors.red)),
            );
          }

          if (state is SettlementLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<SettlementBloc>().add(
                      LoadSettlementsEvent(
                        projectId: widget.projectId,
                        filter: _filter,
                      ),
                    );
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // 1. Summary Cards (Total Paid vs Total Pending)
                  _buildMetricsRow(context, loc, state, isDark),
                  const SizedBox(height: 12),

                  // 2. Filter Bar (Person, Date Range, Status)
                  _buildFilterSection(context, loc, state, isDark),
                  const SizedBox(height: 12),

                  // 3. Timeline Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.translate('timeline_oldest_first'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${state.filteredLogs.length} ${loc.translate('items')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 4. Timeline List or Empty State
                  if (state.filteredLogs.isEmpty)
                    _buildEmptyState(context, loc, isDark)
                  else
                    ...state.evolutionItems.map((item) {
                      return SettlementTimelineCard(
                        item: item,
                        currencySymbol: widget.currencySymbol,
                        onMarkAsPaid: _handleMarkAsPaid,
                        onUndoMarkAsPaid: _handleUndoMarkAsPaid,
                        onDelete: _handleDelete,
                        onEdit: (l) => _showAddPaymentSheet(context, editingLog: l),
                      );
                    }),
                  const SizedBox(height: 80),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMetricsRow(
    BuildContext context,
    AppLocalizations loc,
    SettlementLoaded state,
    bool isDark,
  ) {
    return Row(
      children: [
        // Total Paid Metric Card
        Expanded(
          child: Card(
            key: const Key('totalPaidMetricCard'),
            elevation: 1,
            color: isDark ? const Color(0xFF1E2D24) : Colors.green.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.green.withOpacity(0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        loc.translate('status_paid'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_formatAmount(state.totalPaid)}${widget.currencySymbol}',
                    key: const Key('totalPaidAmountText'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Total Pending Metric Card
        Expanded(
          child: Card(
            key: const Key('totalPendingMetricCard'),
            elevation: 1,
            color: isDark ? const Color(0xFF33261D) : Colors.orange.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pending_outlined, size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text(
                        loc.translate('status_pending'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_formatAmount(state.totalPending)}${widget.currencySymbol}',
                    key: const Key('totalPendingAmountText'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    AppLocalizations loc,
    SettlementLoaded state,
    bool isDark,
  ) {
    // Extract unique persons across all logs + available project members
    final persons = <String>{...widget.projectMembers};
    for (final l in state.allLogs) {
      if (l.payer.isNotEmpty) persons.add(l.payer);
      if (l.payee.isNotEmpty) persons.add(l.payee);
    }
    final sortedPersons = persons.toList()..sort();

    return Card(
      key: const Key('settlementFilterCard'),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Person Selector Dropdown
            Row(
              children: [
                const Icon(Icons.filter_alt_outlined, size: 18),
                const SizedBox(width: 8),
                Text(
                  loc.translate('filter_by_person'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                DropdownButton<String?>(
                  key: const Key('filterPersonDropdown'),
                  isDense: true,
                  value: _filter.person,
                  hint: Text(loc.translate('all_persons')),
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(loc.translate('all_persons')),
                    ),
                    ...sortedPersons.map(
                      (p) => DropdownMenuItem<String?>(
                        value: p,
                        child: Text(p),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    _onFilterChanged(
                      _filter.copyWith(person: val, clearPerson: val == null),
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 16),

            // Row 2: Status Filter Chips
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  key: const Key('filterStatusAllChip'),
                  label: Text(loc.translate('all_statuses')),
                  selected: _filter.status == null,
                  onSelected: (_) {
                    _onFilterChanged(_filter.copyWith(clearStatus: true));
                  },
                ),
                ChoiceChip(
                  key: const Key('filterStatusPaidChip'),
                  label: Text(loc.translate('status_paid')),
                  selected: _filter.status == SettlementStatus.paid,
                  onSelected: (selected) {
                    _onFilterChanged(
                      selected
                          ? _filter.copyWith(status: SettlementStatus.paid)
                          : _filter.copyWith(clearStatus: true),
                    );
                  },
                ),
                ChoiceChip(
                  key: const Key('filterStatusPendingChip'),
                  label: Text(loc.translate('status_pending')),
                  selected: _filter.status == SettlementStatus.pending,
                  onSelected: (selected) {
                    _onFilterChanged(
                      selected
                          ? _filter.copyWith(status: SettlementStatus.pending)
                          : _filter.copyWith(clearStatus: true),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 3: Date Range Filter Chips
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  key: const Key('filterDateAllChip'),
                  label: Text(loc.translate('all_time')),
                  selected: _filter.dateRange == SettlementDateRange.allTime,
                  onSelected: (selected) {
                    if (selected) {
                      _onFilterChanged(
                        _filter.copyWith(dateRange: SettlementDateRange.allTime),
                      );
                    }
                  },
                ),
                ChoiceChip(
                  key: const Key('filterDateThisMonthChip'),
                  label: Text(loc.translate('this_month')),
                  selected: _filter.dateRange == SettlementDateRange.thisMonth,
                  onSelected: (selected) {
                    if (selected) {
                      _onFilterChanged(
                        _filter.copyWith(dateRange: SettlementDateRange.thisMonth),
                      );
                    }
                  },
                ),
                ChoiceChip(
                  key: const Key('filterDateLastMonthChip'),
                  label: Text(loc.translate('last_month')),
                  selected: _filter.dateRange == SettlementDateRange.lastMonth,
                  onSelected: (selected) {
                    if (selected) {
                      _onFilterChanged(
                        _filter.copyWith(dateRange: SettlementDateRange.lastMonth),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          key: const Key('emptySettlementState'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              loc.translate('no_settlement_history'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              loc.translate('no_settlement_history_desc'),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              key: const Key('emptyStateAddPaymentButton'),
              icon: const Icon(Icons.add),
              label: Text(loc.translate('record_payment')),
              onPressed: () => _showAddPaymentSheet(context),
            ),
          ],
        ),
      ),
    );
  }
}
