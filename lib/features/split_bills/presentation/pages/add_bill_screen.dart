import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/bill.dart';
import '../../domain/entities/bill_participant.dart';
import '../bloc/bills_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/presentation/bloc/project_bloc.dart';
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

  // Project-aware state
  Project? selectedProject;
  List<String> projectMembers = [];
  Set<String> selectedParticipants = {};

  // Legacy free-text for non-project flow
  List<String> manualParticipants = [];
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
    // Load all projects for the dropdown
    context.read<ProjectBloc>().add(const GetAllProjects());
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    paidByController.dispose();
    participantController.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────
  // Project selection handler
  // ────────────────────────────────────────
  void _onProjectSelected(Project? project) {
    setState(() {
      selectedProject = project;
      if (project == null) {
        projectMembers = [];
        selectedParticipants = {};
        paidByController.clear();
      } else {
        projectMembers = List.from(project.members);
        // Pre-select ALL members
        selectedParticipants = Set.from(project.members);
        // Smart payer: pre-fill with first member as suggestion
        if (project.members.isNotEmpty && paidByController.text.isEmpty) {
          paidByController.text = project.members.first;
        }
        if (project.members.isEmpty) {
          final loc = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.translate('project_no_members'))),
          );
        }
      }
    });
  }

  // ────────────────────────────────────────
  // Manual participant (non-project flow)
  // ────────────────────────────────────────
  void _addManualParticipant() {
    if (participantController.text.isNotEmpty) {
      setState(() {
        manualParticipants.add(participantController.text.trim());
        participantController.clear();
      });
    }
  }

  void _removeManualParticipant(int index) {
    setState(() {
      manualParticipants.removeAt(index);
    });
  }

  // ────────────────────────────────────────
  // Computed participant list
  // ────────────────────────────────────────
  List<String> get _effectiveParticipants {
    if (selectedProject != null) {
      return selectedParticipants.toList();
    }
    return manualParticipants;
  }

  // ────────────────────────────────────────
  // Validation
  // ────────────────────────────────────────
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

    final parts = _effectiveParticipants;
    if (parts.isEmpty || parts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('min_2_participants'))),
      );
      return false;
    }

    return true;
  }

  // ────────────────────────────────────────
  // Submit
  // ────────────────────────────────────────
  void _submitForm() {
    if (!_validateForm()) return;

    final amount = double.parse(amountController.text);
    final parts = _effectiveParticipants;
    final perPerson = amount / parts.length;

    final billParticipants = parts
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
      projectId: selectedProject?.id,
    );

    context.read<BillsBloc>().add(AddBillEvent(bill: bill));
    Navigator.pop(context);
  }

  // ────────────────────────────────────────
  // Build
  // ────────────────────────────────────────
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
            // ── Project Dropdown ──────────────────────────────
            _buildProjectDropdown(loc),
            const SizedBox(height: 16),

            // ── Bill Title ────────────────────────────────────
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: loc.translate('bill_name'),
                hintText: loc.translate('bill_name_example'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Amount ───────────────────────────────────────
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: loc.translate('amount'),
                hintText: '100000',
                border: const OutlineInputBorder(),
                suffixText: 'đ',
              ),
            ),
            const SizedBox(height: 16),

            // ── Category ─────────────────────────────────────
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

            // ── Payer ─────────────────────────────────────────
            TextField(
              key: const Key('payerField'),
              controller: paidByController,
              decoration: InputDecoration(
                labelText: loc.translate('payer'),
                hintText: loc.translate('payer_hint'),
                border: const OutlineInputBorder(),
                // If project selected, show helper with member list
                helperText: selectedProject != null &&
                        selectedProject!.members.isNotEmpty
                    ? selectedProject!.members.join(', ')
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            // ── Participants section ──────────────────────────
            Text(
              loc.translate('participants'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            if (selectedProject != null)
              _buildProjectMemberChips(loc)
            else
              _buildManualParticipants(loc),

            const SizedBox(height: 24),

            // ── Save Button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('saveProjectButton'),
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

  // ────────────────────────────────────────
  // Project Dropdown widget
  // ────────────────────────────────────────
  Widget _buildProjectDropdown(AppLocalizations loc) {
    return BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, state) {
        List<Project> projects = [];
        if (state is ProjectLoaded) {
          projects = state.projects;
        }

        return DropdownButtonFormField<Project?>(
          key: const Key('projectDropdown'),
          value: selectedProject,
          decoration: InputDecoration(
            labelText: loc.translate('select_project'),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.folder_open),
          ),
          items: [
            DropdownMenuItem<Project?>(
              value: null,
              child: Text(loc.translate('no_project')),
            ),
            ...projects.map(
              (p) => DropdownMenuItem<Project?>(
                value: p,
                child: Text(p.name),
              ),
            ),
          ],
          onChanged: _onProjectSelected,
        );
      },
    );
  }

  // ────────────────────────────────────────
  // Project member toggle chips
  // ────────────────────────────────────────
  Widget _buildProjectMemberChips(AppLocalizations loc) {
    if (projectMembers.isEmpty) {
      return Text(
        loc.translate('project_no_members'),
        style: const TextStyle(color: Colors.orange),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.translate('tap_to_toggle'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: projectMembers.map((member) {
            final isSelected = selectedParticipants.contains(member);
            return FilterChip(
              key: Key('member_chip_$member'),
              label: Text(member),
              selected: isSelected,
              avatar: CircleAvatar(
                backgroundColor: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                child: Text(
                  member.isNotEmpty ? member[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : Colors.black54,
                  ),
                ),
              ),
              checkmarkColor: Colors.white,
              selectedColor:
                  Theme.of(context).colorScheme.primaryContainer,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedParticipants.add(member);
                  } else {
                    selectedParticipants.remove(member);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ────────────────────────────────────────
  // Manual participants (no project selected)
  // ────────────────────────────────────────
  Widget _buildManualParticipants(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              onPressed: _addManualParticipant,
              icon: const Icon(Icons.add),
              label: Text(loc.translate('add')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (manualParticipants.isNotEmpty)
          Wrap(
            spacing: 8,
            children: List.generate(
              manualParticipants.length,
              (index) => Chip(
                label: Text(manualParticipants[index]),
                onDeleted: () => _removeManualParticipant(index),
              ),
            ),
          ),
      ],
    );
  }
}
