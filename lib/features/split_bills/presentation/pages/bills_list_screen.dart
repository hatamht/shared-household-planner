import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/bills_bloc.dart';
import '../widgets/bill_card.dart';
import '../widgets/stats_card.dart';
import '../../domain/entities/bill.dart';
import '../../domain/entities/bill_participant.dart';
import '../../../../core/localization/app_localizations.dart';
import 'add_bill_screen.dart';

class BillsListScreen extends StatefulWidget {
  const BillsListScreen({Key? key}) : super(key: key);

  @override
  State<BillsListScreen> createState() => _BillsListScreenState();
}

class _BillsListScreenState extends State<BillsListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BillsBloc>().add(const GetBillsEvent());
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

  Widget _buildBillsList(BuildContext context, List<Bill> bills) {
    if (bills.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context).translate('no_bills')),
      );
    }

    Map<String, List<Bill>> groupedBills = {};
    for (var bill in bills) {
      final monthYear = DateFormat('MMM yyyy', Localizations.localeOf(context).languageCode).format(bill.date);
      if (!groupedBills.containsKey(monthYear)) {
        groupedBills[monthYear] = [];
      }
      groupedBills[monthYear]!.add(bill);
    }

    return ListView.builder(
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
    );
  }

  void _showAddBillDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider<BillsBloc>.value(
          value: context.read<BillsBloc>(),
          child: const AddBillScreen(),
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
