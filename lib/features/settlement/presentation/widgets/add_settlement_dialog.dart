import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/settlement_log.dart';

/// Interactive modal sheet/dialog for recording or editing a settlement transaction.
class AddSettlementDialog extends StatefulWidget {
  final String? projectId;
  final List<String> availableMembers;
  final String? initialPayer;
  final String? initialPayee;
  final double? initialAmount;
  final SettlementLog? editingLog;
  final void Function(SettlementLog log) onSave;

  const AddSettlementDialog({
    super.key,
    this.projectId,
    this.availableMembers = const [],
    this.initialPayer,
    this.initialPayee,
    this.initialAmount,
    this.editingLog,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    String? projectId,
    List<String> availableMembers = const [],
    String? initialPayer,
    String? initialPayee,
    double? initialAmount,
    SettlementLog? editingLog,
    required void Function(SettlementLog log) onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddSettlementDialog(
        projectId: projectId,
        availableMembers: availableMembers,
        initialPayer: initialPayer,
        initialPayee: initialPayee,
        initialAmount: initialAmount,
        editingLog: editingLog,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AddSettlementDialog> createState() => _AddSettlementDialogState();
}

class _AddSettlementDialogState extends State<AddSettlementDialog> {
  late TextEditingController _payerController;
  late TextEditingController _payeeController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  late DateTime _selectedDate;
  late SettlementStatus _status;

  String? _payerError;
  String? _payeeError;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    final log = widget.editingLog;
    _payerController = TextEditingController(
      text: log?.payer ?? widget.initialPayer ?? '',
    );
    _payeeController = TextEditingController(
      text: log?.payee ?? widget.initialPayee ?? '',
    );
    _amountController = TextEditingController(
      text: log != null
          ? log.amount.toString()
          : (widget.initialAmount != null && widget.initialAmount! > 0
              ? widget.initialAmount!.toStringAsFixed(2)
              : ''),
    );
    _noteController = TextEditingController(text: log?.note ?? '');

    _selectedDate = log?.date ?? DateTime.now();
    _status = log?.status ?? SettlementStatus.paid; // Default to paid when recording settlement
  }

  @override
  void dispose() {
    _payerController.dispose();
    _payeeController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool _validate(AppLocalizations loc) {
    setState(() {
      _payerError = null;
      _payeeError = null;
      _amountError = null;
    });

    final payer = _payerController.text.trim();
    final payee = _payeeController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    bool isValid = true;

    if (payer.isEmpty) {
      setState(() => _payerError = loc.translate('payer_required'));
      isValid = false;
    }

    if (payee.isEmpty) {
      setState(() => _payeeError = loc.translate('payee_required'));
      isValid = false;
    }

    if (payer.isNotEmpty && payee.isNotEmpty && payer.toLowerCase() == payee.toLowerCase()) {
      setState(() => _payeeError = loc.translate('payer_payee_same_error'));
      isValid = false;
    }

    if (amount == null || amount <= 0) {
      setState(() => _amountError = loc.translate('amount_must_be_positive'));
      isValid = false;
    }

    return isValid;
  }

  void _submit() {
    final loc = AppLocalizations.of(context);
    if (!_validate(loc)) return;

    final payer = _payerController.text.trim();
    final payee = _payeeController.text.trim();
    final amount = double.parse(_amountController.text.trim());
    final note = _noteController.text.trim();

    final now = DateTime.now();
    final id = widget.editingLog?.id ?? 'settlement_${now.millisecondsSinceEpoch}';

    final result = SettlementLog(
      id: id,
      projectId: widget.projectId ?? widget.editingLog?.projectId,
      payer: payer,
      payee: payee,
      amount: amount,
      date: _selectedDate,
      status: _status,
      note: note.isNotEmpty ? note : null,
      createdAt: widget.editingLog?.createdAt ?? now,
    );

    widget.onSave(result);
    Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.editingLog != null
                        ? loc.translate('settlement_details')
                        : loc.translate('record_payment'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Payer input
              if (widget.availableMembers.isNotEmpty)
                DropdownButtonFormField<String>(
                  key: const Key('payerDropdownField'),
                  value: widget.availableMembers.contains(_payerController.text)
                      ? _payerController.text
                      : null,
                  decoration: InputDecoration(
                    labelText: loc.translate('payer'),
                    errorText: _payerError,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: widget.availableMembers
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _payerController.text = val);
                    }
                  },
                )
              else
                TextFormField(
                  key: const Key('payerInputField'),
                  controller: _payerController,
                  decoration: InputDecoration(
                    labelText: loc.translate('payer'),
                    errorText: _payerError,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              const SizedBox(height: 12),

              // Payee input
              if (widget.availableMembers.isNotEmpty)
                DropdownButtonFormField<String>(
                  key: const Key('payeeDropdownField'),
                  value: widget.availableMembers.contains(_payeeController.text)
                      ? _payeeController.text
                      : null,
                  decoration: InputDecoration(
                    labelText: loc.translate('payee'),
                    errorText: _payeeError,
                    prefixIcon: const Icon(Icons.arrow_downward),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: widget.availableMembers
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _payeeController.text = val);
                    }
                  },
                )
              else
                TextFormField(
                  key: const Key('payeeInputField'),
                  controller: _payeeController,
                  decoration: InputDecoration(
                    labelText: loc.translate('payee'),
                    errorText: _payeeError,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              const SizedBox(height: 12),

              // Amount input
              TextFormField(
                key: const Key('settlementAmountField'),
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: loc.translate('amount'),
                  errorText: _amountError,
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              // Date picker tile
              InkWell(
                key: const Key('settlementDateTile'),
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${loc.translate('payment_date')}: ${dateFormat.format(_selectedDate)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Status Selector
              Row(
                children: [
                  Text(
                    '${loc.translate('status')}: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    key: const Key('settlementStatusPaidChip'),
                    label: Text(loc.translate('status_paid')),
                    selected: _status == SettlementStatus.paid,
                    selectedColor: Colors.green.shade100,
                    onSelected: (selected) {
                      if (selected) setState(() => _status = SettlementStatus.paid);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    key: const Key('settlementStatusPendingChip'),
                    label: Text(loc.translate('status_pending')),
                    selected: _status == SettlementStatus.pending,
                    selectedColor: Colors.orange.shade100,
                    onSelected: (selected) {
                      if (selected) setState(() => _status = SettlementStatus.pending);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Payment Note input
              TextFormField(
                key: const Key('settlementNoteField'),
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: loc.translate('payment_note'),
                  hintText: loc.translate('payment_note_hint'),
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // Save button
              ElevatedButton(
                key: const Key('saveSettlementButton'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _submit,
                child: Text(
                  loc.translate('save'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
