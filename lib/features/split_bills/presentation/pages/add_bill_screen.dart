import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/bill.dart';
import '../../domain/entities/bill_participant.dart';
import '../../domain/entities/category_icon.dart';
import '../bloc/bills_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/domain/entities/project_settings.dart';
import '../../../projects/presentation/bloc/project_bloc.dart';

class AddBillScreen extends StatefulWidget {
  final ProjectSettings projectSettings;
  final Future<String?> Function(ImageSource source)? onPickImage;
  final String? initialImagePath;

  const AddBillScreen({
    Key? key,
    this.projectSettings = const ProjectSettings(),
    this.onPickImage,
    this.initialImagePath,
  }) : super(key: key);

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  late TextEditingController titleController;
  late TextEditingController amountController;
  late TextEditingController paidByController;
  late TextEditingController participantController;

  // Selected Category & Icon
  late CategoryIconItem selectedCategoryItem;

  // Image path
  String? imagePath;

  // Currency
  late String selectedCurrency;

  // When / Date
  DateTime selectedDate = DateTime.now();

  // Project-aware state
  Project? selectedProject;
  List<String> projectMembers = [];
  Set<String> selectedParticipants = {};

  // Legacy free-text for non-project flow
  List<String> manualParticipants = [];

  final ImagePicker _defaultPicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    amountController = TextEditingController();
    paidByController = TextEditingController();
    participantController = TextEditingController();

    selectedCategoryItem = defaultCategoryIcons.first;
    selectedCurrency = widget.projectSettings.defaultCurrency;
    imagePath = widget.initialImagePath;

    amountController.addListener(() {
      setState(() {});
    });

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
  // Image Pick & Remove
  // ────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      if (widget.onPickImage != null) {
        final path = await widget.onPickImage!(source);
        if (path != null) {
          setState(() => imagePath = path);
        }
        return;
      }

      final XFile? file = await _defaultPicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() => imagePath = file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() => imagePath = null);
  }

  // ────────────────────────────────────────
  // Date Picker
  // ────────────────────────────────────────
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
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
        selectedParticipants = Set.from(project.members);
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
  // Manual participant handler
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

  List<String> get _effectiveParticipants {
    if (selectedProject != null) {
      return selectedParticipants.toList();
    }
    return manualParticipants;
  }

  // ────────────────────────────────────────
  // Real-time Split Calculation
  // ────────────────────────────────────────
  double get _currentAmount => double.tryParse(amountController.text) ?? 0.0;

  double get _perPersonAmount {
    final count = _effectiveParticipants.length;
    if (count == 0 || _currentAmount <= 0) return 0.0;
    return _currentAmount / count;
  }

  // ────────────────────────────────────────
  // Validation
  // ────────────────────────────────────────
  bool _validateForm() {
    final loc = AppLocalizations.of(context);

    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('bill_name_required'))),
      );
      return false;
    }

    if (amountController.text.trim().isEmpty) {
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

    if (paidByController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('payer_required'))),
      );
      return false;
    }

    final parts = _effectiveParticipants;
    if (parts.length < 2) {
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
      title: titleController.text.trim(),
      amount: amount,
      category: selectedCategoryItem.id,
      date: selectedDate,
      paidBy: paidByController.text.trim(),
      participants: billParticipants,
      projectId: selectedProject?.id,
      categoryIcon: selectedCategoryItem.icon,
      currency: selectedCurrency,
      imagePath: imagePath,
    );

    context.read<BillsBloc>().add(AddBillEvent(bill: bill));
    Navigator.pop(context);
  }

  // ────────────────────────────────────────
  // Build UI
  // ────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currencySymbol = currencySymbols[selectedCurrency] ?? selectedCurrency;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('add_bill')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Title + Icon preview ─────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  key: const Key('selectedCategoryIconBadge'),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    selectedCategoryItem.icon,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: loc.translate('bill_name'),
                      hintText: loc.translate('bill_name_example'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── 2. Icon Category Selector (12+ icons) ───────────
            Text(
              loc.translate('category'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: defaultCategoryIcons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = defaultCategoryIcons[index];
                  final isSelected = cat.id == selectedCategoryItem.id;
                  return InkWell(
                    key: Key('category_icon_${cat.id}'),
                    onTap: () {
                      setState(() {
                        selectedCategoryItem = cat;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 64,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).cardColor,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cat.icon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 2),
                          Text(
                            loc.translate(cat.nameKey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── 3. Image Upload & Preview ────────────────────────
            Text(
              loc.translate('image'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  key: const Key('pickGalleryButton'),
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: Text(loc.translate('gallery')),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  key: const Key('takeCameraButton'),
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: Text(loc.translate('camera')),
                ),
              ],
            ),
            if (imagePath != null) ...[
              const SizedBox(height: 10),
              Container(
                key: const Key('imagePreview'),
                height: 100,
                width: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.grey.shade100,
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: File(imagePath!).existsSync()
                          ? Image.file(
                              File(imagePath!),
                              fit: BoxFit.cover,
                              width: 140,
                              height: 100,
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.image, size: 36, color: Colors.grey),
                                  Text(
                                    imagePath!.split('/').last,
                                    style: const TextStyle(fontSize: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          key: const Key('removeImageButton'),
                          padding: EdgeInsets.zero,
                          iconSize: 14,
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: _removeImage,
                          tooltip: loc.translate('remove_image'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // ── 4. Amount + Currency ────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: loc.translate('amount'),
                      hintText: '100000',
                      border: const OutlineInputBorder(),
                      suffixText: currencySymbol,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    key: const Key('currencyDropdown'),
                    value: selectedCurrency,
                    decoration: InputDecoration(
                      labelText: loc.translate('currency'),
                      border: const OutlineInputBorder(),
                    ),
                    items: widget.projectSettings.availableCurrencies
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text('$c (${currencySymbols[c] ?? c})'),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => selectedCurrency = val);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── 5. Paid By ──────────────────────────────────────
            TextField(
              key: const Key('payerField'),
              controller: paidByController,
              decoration: InputDecoration(
                labelText: loc.translate('payer'),
                hintText: loc.translate('payer_hint'),
                border: const OutlineInputBorder(),
                helperText: selectedProject != null &&
                        selectedProject!.members.isNotEmpty
                    ? selectedProject!.members.join(', ')
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // ── 6. When (Date Picker) ───────────────────────────
            InkWell(
              key: const Key('datePickerButton'),
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: loc.translate('when'),
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
              ),
            ),
            const SizedBox(height: 20),

            // ── 7. Split Section ────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.translate('split'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_perPersonAmount > 0)
                  Text(
                    '${loc.translate('each_pays')}: ${_perPersonAmount.toStringAsFixed(0)} $currencySymbol',
                    key: const Key('realtimeSplitText'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Project Dropdown
            _buildProjectDropdown(loc),
            const SizedBox(height: 12),

            // Member list / Manual participants
            Text(
              loc.translate('participants'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            if (selectedProject != null)
              _buildProjectMemberChips(loc)
            else
              _buildManualParticipants(loc),

            const SizedBox(height: 24),

            // ── 8. Save Button ──────────────────────────────────
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
