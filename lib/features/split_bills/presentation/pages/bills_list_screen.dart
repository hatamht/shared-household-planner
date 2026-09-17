import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/bills_bloc.dart';
import '../widgets/bill_card.dart';
import '../widgets/stats_card.dart';
import '../../domain/entities/bill.dart';
import '../../domain/entities/bill_participant.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/bill_filter.dart';
import '../../domain/services/bill_filter_persistence_service.dart';
import '../widgets/bill_search_filter_bar.dart';
import 'add_bill_screen.dart';
import 'fast_add_bill_screen.dart';


class BillsListScreen extends StatefulWidget {
  final BillFilter? initialFilter;
  final BillFilterPersistenceService? persistenceService;

  const BillsListScreen({
    Key? key,
    this.initialFilter,
    this.persistenceService,
  }) : super(key: key);

  @override
  State<BillsListScreen> createState() => _BillsListScreenState();
}

class _BillsListScreenState extends State<BillsListScreen> {
  late BillFilter _filter;
  late final BillFilterPersistenceService _persistenceService;

  @override
  void initState() {
    super.initState();
    _persistenceService = widget.persistenceService ?? const BillFilterPersistenceService();
    _filter = widget.initialFilter ?? BillFilterPersistenceService.currentFilter;
    _loadSavedFilter();
    context.read<BillsBloc>().add(const GetBillsEvent());
  }

  Future<void> _loadSavedFilter() async {
    if (widget.initialFilter == null) {
      final saved = await _persistenceService.loadFilter();
      if (mounted) {
        setState(() {
          _filter = saved;
        });
      }
    }
  }

  void _onFilterChanged(BillFilter newFilter) {
    setState(() {
      _filter = newFilter;
    });
    _persistenceService.saveFilter(newFilter);
  }

  void _onClearAllFilters() {
    setState(() {
      _filter = const BillFilter.initial();
    });
    _persistenceService.clearFilter();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('bills')),
        elevation: 0,
      ),
      body: BlocBuilder<BillsBloc, BillsState>(
        builder: (context, state) {
          if (state is BillsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BillsLoaded) {
            return _buildBillsList(context, state.bills);
          } else if (state is BillsError) {
            return Center(child: Text(loc.translate('error')));
          }
          return Center(child: Text(loc.translate('no_bills')));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBillDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBillsList(BuildContext context, List<Bill> allBills) {
    final loc = AppLocalizations.of(context);

    if (allBills.isEmpty) {
      return Center(
        child: Text(loc.translate('no_bills')),
      );
    }

    final availablePersons = allBills
        .expand((b) => [b.paidBy, ...b.participants.map((p) => p.name)])
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final availableCategories = allBills
        .map((b) => b.category)
        .where((cat) => cat.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final maxBillAmount = allBills.isEmpty
        ? 1000.0
        : allBills.map((b) => b.amount).reduce((a, b) => a > b ? a : b);

    final filteredBills = _filter.apply(allBills);

    Map<String, List<Bill>> groupedBills = {};
    for (var bill in filteredBills) {
      final monthYear = DateFormat('MMM yyyy', Localizations.localeOf(context).languageCode).format(bill.date);
      if (!groupedBills.containsKey(monthYear)) {
        groupedBills[monthYear] = [];
      }
      groupedBills[monthYear]!.add(bill);
    }

    return Column(
      children: [
        BillSearchFilterBar(
          filter: _filter,
          resultCount: filteredBills.length,
          availablePersons: availablePersons,
          availableCategories: availableCategories,
          maxBillAmount: maxBillAmount,
          onFilterChanged: _onFilterChanged,
          onClearAllFilters: _onClearAllFilters,
        ),
        Expanded(
          child: filteredBills.isEmpty
              ? Center(
                  key: const Key('noMatchingBillsEmptyState'),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc.translate('no_matching_bills'),
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          key: const Key('clearFiltersEmptyStateButton'),
                          onPressed: _onClearAllFilters,
                          icon: const Icon(Icons.clear_all),
                          label: Text(loc.translate('clear_all_filters')),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: groupedBills.keys.length,
                  itemBuilder: (context, index) {
                    final monthYear = groupedBills.keys.elementAt(index);
                    final monthBills = groupedBills[monthYear]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            monthYear,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        StatsCard(bills: monthBills),
                        ...monthBills.map((bill) => BillCard(bill: bill)).toList(),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddBillDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider<BillsBloc>.value(
          value: context.read<BillsBloc>(),
          child: const FastAddBillScreen(),
        ),
      ),
    );
  }
}

class AddBillDialog extends StatefulWidget {
  const AddBillDialog({Key? key}) : super(key: key);

  @override
  State<AddBillDialog> createState() => _AddBillDialogState();
}

class _AddBillDialogState extends State<AddBillDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _paidByController = TextEditingController();
  final _participantsController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _paidByController.dispose();
    _participantsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(loc.translate('add_bill')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: loc.translate('bill_name'),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.translate('name_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: loc.translate('amount'),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.translate('amount_required');
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return loc.translate('amount_positive');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: loc.translate('category'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _paidByController,
                decoration: InputDecoration(
                  labelText: loc.translate('payer'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _participantsController,
                decoration: InputDecoration(
                  labelText: loc.translate('participants'),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.translate('participants_required');
                  }
                  final count = value.split(',').length;
                  if (count < 2) {
                    return loc.translate('participants_min');
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.translate('cancel')),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final participantNames = _participantsController.text.split(',').map((e) => e.trim()).toList();
              final participants = participantNames
                  .asMap()
                  .entries
                  .map((e) => BillParticipant(
                    participantId: 'p${e.key}',
                    name: e.value,
                    amount: double.parse(_amountController.text) / participantNames.length,
                  ))
                  .toList();

              final bill = Bill(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: _titleController.text,
                amount: double.parse(_amountController.text),
                category: _categoryController.text,
                date: DateTime.now(),
                paidBy: _paidByController.text,
                participants: participants,
              );

              context.read<BillsBloc>().add(AddBillEvent(bill: bill));
              Navigator.pop(context);
            }
          },
          child: Text(loc.translate('add')),
        ),
      ],
    );
  }
}
