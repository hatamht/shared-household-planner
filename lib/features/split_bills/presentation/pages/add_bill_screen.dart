import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/bill.dart';
import '../../domain/entities/bill_participant.dart';
import '../bloc/bills_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import 'package:uuid/uuid.dart';

class AddBillScreen extends StatefulWidget {
  const AddBillScreen({Key? key}) : super(key: key);

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  late TextEditingController titleController;
  late TextEditingController amountController;
  late TextEditingController paidByController;
  String? selectedCategory;
  List<String> participants = [];
  late TextEditingController participantController;

  final categories = [
    'food',
    'transport',
    'entertainment',
    'utilities',
    'shopping',
    'health',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    amountController = TextEditingController();
    paidByController = TextEditingController();
    participantController = TextEditingController();
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    paidByController.dispose();
    participantController.dispose();
    super.dispose();
  }

  void _addParticipant() {
    if (participantController.text.isNotEmpty) {
      setState(() {
        participants.add(participantController.text);
        participantController.clear();
      });
    }
  }

  void _removeParticipant(int index) {
    setState(() {
      participants.removeAt(index);
    });
  }

  bool _validateForm() {
    final loc = AppLocalizations.of(context);
    
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('bill_name_required'))),
      );
      return false;
    }

    if (amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('amount_required'))),
      );
      return false;
    }

    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('amount_must_be_positive'))),
      );
      return false;
    }

    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('category_required'))),
      );
      return false;
    }

    if (paidByController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('payer_required'))),
      );
      return false;
    }

    if (participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('min_2_participants'))),
      );
      return false;
    }

    if (participants.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('min_2_participants'))),
      );
      return false;
    }

    return true;
  }

  void _submitForm() {
    if (!_validateForm()) return;

    final amount = double.parse(amountController.text);
    final perPerson = amount / participants.length;

    final billParticipants = participants
        .map(
          (name) => BillParticipant(
            participantId: const Uuid().v4(),
            name: name,
            amount: perPerson,
          ),
        )
        .toList();

    final bill = Bill(
      id: const Uuid().v4(),
      title: titleController.text,
      amount: amount,
      category: selectedCategory!,
      date: DateTime.now(),
      paidBy: paidByController.text,
      participants: billParticipants,
    );

    context.read<BillsBloc>().add(AddBillEvent(bill: bill));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('add_bill')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: loc.translate('bill_name'),
                hintText: loc.translate('bill_name_example'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: loc.translate('amount'),
                hintText: '100000',
                border: const OutlineInputBorder(),
                suffixText: 'đ',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                labelText: loc.translate('category'),
                border: const OutlineInputBorder(),
              ),
              items: categories
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(loc.translate('category_$cat')),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: paidByController,
              decoration: InputDecoration(
                labelText: loc.translate('payer'),
                hintText: 'Who paid?',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loc.translate('participants'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: participantController,
                    decoration: InputDecoration(
                      labelText: loc.translate('participant_name'),
                      hintText: loc.translate('enter_name'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addParticipant,
                  icon: const Icon(Icons.add),
                  label: Text(loc.translate('add')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (participants.isNotEmpty)
              Wrap(
                spacing: 8,
                children: List.generate(
                  participants.length,
                  (index) => Chip(
                    label: Text(participants[index]),
                    onDeleted: () => _removeParticipant(index),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    loc.translate('save_bill'),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
