import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../features/split_bills/domain/entities/bill.dart';
import '../../../../features/split_bills/domain/repositories/bill_repository.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/project_statistics.dart';
import '../../domain/entities/settlement_item.dart';
import '../../domain/usecases/calculate_settlement_usecase.dart';
import '../bloc/project_bloc.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<_ProjectDetailData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _dataFuture = _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<_ProjectDetailData> _loadData() async {
    final repo = context.read<BillRepository>();
    final billsResult =
        await repo.getBillsByProjectId(widget.project.id);

    final bills = billsResult.fold<List<Bill>>((_) => [], (b) => b);

    const calculator = CalculateSettlementUseCase();
    final statsResult = await calculator(
      CalculateSettlementParams(
        project: widget.project,
        bills: bills,
      ),
    );
    final stats = statsResult.fold<ProjectStatistics?>((_) => null, (s) => s);

    return _ProjectDetailData(bills: bills, stats: stats);
  }

  // ─────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final project = widget.project;

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(key: const Key('billsTab'), text: loc.translate('bills_tab')),
            Tab(key: const Key('settlementTab'), text: loc.translate('settlement_tab')),
            Tab(key: const Key('statisticsTab'), text: loc.translate('statistics_tab')),
          ],
        ),
      ),
      body: FutureBuilder<_ProjectDetailData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text(loc.translate('error')));
          }
          final data = snapshot.data!;
          return TabBarView(
            controller: _tabController,
            children: [
              _BillsTab(project: project, bills: data.bills),
              _SettlementTab(
                  project: project, stats: data.stats),
              _StatisticsTab(
                  project: project, stats: data.stats),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Data holder
// ─────────────────────────────────────────────────────
class _ProjectDetailData {
  final List<Bill> bills;
  final ProjectStatistics? stats;
  _ProjectDetailData({required this.bills, required this.stats});
}

// ─────────────────────────────────────────────────────
// Tab 1 — Bills
// ─────────────────────────────────────────────────────
class _BillsTab extends StatelessWidget {
  final Project project;
  final List<Bill> bills;

  const _BillsTab({required this.project, required this.bills});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    if (bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long,
                size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(
              loc.translate('no_bills_in_project'),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        final participantNames =
            bill.participants.map((p) => p.name).join(', ');
        return Card(
          key: Key('billItem_${bill.id}'),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.receipt)),
            title: Text(bill.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                '${loc.translate('paid_by_label')}: ${bill.paidBy}\n$participantNames'),
            trailing: Text(
              '${_formatAmount(bill.amount)}đ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────
// Tab 2 — Settlement
// ─────────────────────────────────────────────────────
class _SettlementTab extends StatelessWidget {
  final Project project;
  final ProjectStatistics? stats;

  const _SettlementTab({required this.project, required this.stats});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    if (stats == null) {
      return Center(child: Text(loc.translate('error')));
    }

    if (stats!.isAllSettled) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              loc.translate('no_settlement_needed'),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          loc.translate('settlement'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...stats!.settlements.map((item) => _SettlementCard(item: item)),
        const SizedBox(height: 24),
        // Net balance section
        Text(
          loc.translate('net_balance'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...stats!.netBalancePerPerson.entries.map((e) {
          final isPositive = e.value >= 0;
          return Card(
            key: Key('netBalance_${e.key}'),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isPositive
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                child: Text(
                  e.key.isNotEmpty ? e.key[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(e.key),
              trailing: Text(
                '${isPositive ? '+' : ''}${_formatAmount(e.value)}đ',
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SettlementCard extends StatelessWidget {
  final SettlementItem item;

  const _SettlementCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Card(
      key: Key('settlement_${item.from}_${item.to}'),
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              child: Text(item.from.isNotEmpty ? item.from[0].toUpperCase() : '?'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyLarge,
                  children: [
                    TextSpan(
                        text: item.from,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' ${loc.translate('owes')} '),
                    TextSpan(
                        text: item.to,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            Text(
              '${_formatAmount(item.amount)}đ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.red),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 16),
            const SizedBox(width: 4),
            CircleAvatar(
              child: Text(item.to.isNotEmpty ? item.to[0].toUpperCase() : '?'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Tab 3 — Statistics
// ─────────────────────────────────────────────────────
class _StatisticsTab extends StatelessWidget {
  final Project project;
  final ProjectStatistics? stats;

  const _StatisticsTab({required this.project, required this.stats});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    if (stats == null) {
      return Center(child: Text(loc.translate('error')));
    }

    final numMembers = project.members.length;
    final perPerson = numMembers > 0 ? stats!.totalExpense / numMembers : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        Card(
          key: const Key('summaryCard'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.translate('total_expense'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '${_formatAmount(stats!.totalExpense)}đ',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                if (numMembers > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '≈ ${_formatAmount(perPerson)}đ ${loc.translate('per_person')}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Top stats
        if (stats!.topPayer != null)
          _StatRow(
            key: const Key('topPayerRow'),
            icon: Icons.emoji_events,
            color: Colors.amber,
            label: loc.translate('top_payer'),
            value: stats!.topPayer!,
            amount: stats!.totalPaidPerPerson[stats!.topPayer] ?? 0,
          ),
        if (stats!.topDebtor != null)
          _StatRow(
            key: const Key('topDebtorRow'),
            icon: Icons.trending_down,
            color: Colors.red,
            label: loc.translate('top_debtor'),
            value: stats!.topDebtor!,
            amount: (stats!.netBalancePerPerson[stats!.topDebtor] ?? 0).abs(),
          ),
        const SizedBox(height: 16),

        // Per-person breakdown
        Text(
          loc.translate('total_spent'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...stats!.totalPaidPerPerson.entries.map((e) {
          return Card(
            key: Key('statsPerson_${e.key}'),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                    e.key.isNotEmpty ? e.key[0].toUpperCase() : '?'),
              ),
              title: Text(e.key),
              trailing: Text(
                '${_formatAmount(e.value)}đ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final double amount;

  const _StatRow({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        subtitle: Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          '${_formatAmount(amount)}đ',
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────────────
String _formatAmount(double amount) {
  // Format without decimals for VND display
  final abs = amount.abs();
  if (abs >= 1000000) {
    return '${(abs / 1000000).toStringAsFixed(1)}M';
  } else if (abs >= 1000) {
    return '${(abs / 1000).toStringAsFixed(0)}k';
  }
  return abs.toStringAsFixed(0);
}
