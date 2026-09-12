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
import '../widgets/add_category_bottom_sheet.dart';
import '../widgets/edit_category_bottom_sheet.dart';
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

  // Category list & current selection
  late List<CategoryIconItem> categoriesList;
  late CategoryIconItem selectedCategoryItem;

  // Title FocusNode & Auto-fill control
  late FocusNode titleFocusNode;
  bool isTitleManuallyEdited = false;

  // Image path
  String? imagePath;

  // Currency
  late String selectedCurrency;

  // Transaction type tab
  int selectedTransactionType = 0; // 0: Expense, 1: Income, 2: Transfer

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
    titleFocusNode = FocusNode();
    amountController = TextEditingController();
    paidByController = TextEditingController();
    participantController = TextEditingController();

    categoriesList = List.from(defaultCategoryIcons);
    selectedCategoryItem = categoriesList.first;
    selectedCurrency = widget.projectSettings.defaultCurrency;
    imagePath = widget.initialImagePath;

    titleController.addListener(() {
      setState(() {});
    });

    amountController.addListener(() {
      setState(() {});
    });

    // Load all projects for the dropdown
    context.read<ProjectBloc>().add(const GetAllProjects());
  }

  @override
  void dispose() {
    titleController.dispose();
    titleFocusNode.dispose();
    amountController.dispose();
    paidByController.dispose();
    participantController.dispose();
    super.dispose();
  }

  String _getCategoryDisplayName(CategoryIconItem cat, AppLocalizations loc) {
    if (defaultCategoryIcons.any((d) => d.id == cat.id)) {
      return loc.translate(cat.nameKey);
    }
    return cat.nameKey;
  }

  // ────────────────────────────────────────
  // Category Selection & Auto-fill Title
  // ────────────────────────────────────────
  void _onCategorySelected(CategoryIconItem cat, AppLocalizations loc) {
    setState(() {
      selectedCategoryItem = cat;
      if (!isTitleManuallyEdited) {
        titleController.text = _getCategoryDisplayName(cat, loc);
        titleController.selection = TextSelection.collapsed(
          offset: titleController.text.length,
        );
      }
    });
  }

  // ────────────────────────────────────────
  // Open Add Category Bottom Sheet
  // ────────────────────────────────────────
  Future<void> _openAddCategorySheet(AppLocalizations loc) async {
    final newCategory = await AddCategoryBottomSheet.show(
      context,
      existingCategories: categoriesList,
    );

    if (newCategory != null) {
      setState(() {
        categoriesList.add(newCategory);
        selectedCategoryItem = newCategory;
        if (!isTitleManuallyEdited) {
          titleController.text = _getCategoryDisplayName(newCategory, loc);
          titleController.selection = TextSelection.collapsed(
            offset: titleController.text.length,
          );
        }
      });
    }
  }

  // ────────────────────────────────────────
  // Open Edit Category Bottom Sheet
  // ────────────────────────────────────────
  Future<void> _openEditCategorySheet(CategoryIconItem cat, AppLocalizations loc) async {
    final isDefault = defaultCategoryIcons.any((d) => d.id == cat.id);
    final result = await EditCategoryBottomSheet.show(
      context,
      category: cat,
      existingCategories: categoriesList,
      isDefaultCategory: isDefault,
    );

    if (result == null) return;

    setState(() {
      if (result.action == CategoryEditAction.updated && result.updatedCategory != null) {
        final updated = result.updatedCategory!;
        final idx = categoriesList.indexWhere((c) => c.id == cat.id);
        if (idx != -1) {
          categoriesList[idx] = updated;
        }
        if (selectedCategoryItem.id == cat.id) {
          selectedCategoryItem = updated;
          if (!isTitleManuallyEdited) {
            titleController.text = _getCategoryDisplayName(updated, loc);
            titleController.selection = TextSelection.collapsed(
              offset: titleController.text.length,
            );
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translate('category_updated')),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (result.action == CategoryEditAction.deleted) {
        categoriesList.removeWhere((c) => c.id == cat.id);
        if (selectedCategoryItem.id == cat.id) {
          selectedCategoryItem = categoriesList.isNotEmpty
              ? categoriesList.first
              : defaultCategoryIcons.first;
          if (!isTitleManuallyEdited) {
            titleController.text = _getCategoryDisplayName(selectedCategoryItem, loc);
            titleController.selection = TextSelection.collapsed(
              offset: titleController.text.length,
            );
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translate('category_deleted')),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
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
      categoryColor: selectedCategoryItem.colorHex,
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
    final categoryColor = selectedCategoryItem.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF242424) : Colors.white;
    final cardBorder = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.translate('add_bill'),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          key: const Key('closeButton'),
          icon: const Icon(Icons.close),
          splashRadius: 22,
          tooltip: loc.translate('cancel'),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(
            height: 1.0,
            thickness: 1.0,
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 0. Tab Selector Refinement ───────────────────────
            Container(
              key: const Key('transactionTypeTabs'),
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildTabItem(loc.translate('expense'), selectedTransactionType == 0, 0, categoryColor),
                  _buildTabItem(loc.translate('income'), selectedTransactionType == 1, 1, categoryColor),
                  _buildTabItem(loc.translate('transfer'), selectedTransactionType == 2, 2, categoryColor),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── 1. Title Section (CEO Clarification) ─────────────
            // LEFT: Circular badge with category icon + brand color
            // CENTER: Title input field (auto-filled)
            // RIGHT: Camera icon button + Clear (X) button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? categoryColor.withOpacity(0.4)
                      : categoryColor.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // LEFT: Circular category badge
                  Container(
                    key: const Key('selectedCategoryIconBadge'),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: categoryColor, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      selectedCategoryItem.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // CENTER: Title Input
                  Expanded(
                    child: TextField(
                      key: const Key('titleField'),
                      controller: titleController,
                      focusNode: titleFocusNode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.translate('bill_name'),
                        hintText: loc.translate('bill_name_example'),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (text) {
                        final currentCatName =
                            loc.translate(selectedCategoryItem.nameKey);
                        if (text.isEmpty) {
                          isTitleManuallyEdited = false;
                        } else if (text != currentCatName) {
                          isTitleManuallyEdited = true;
                        }
                        setState(() {});
                      },
                    ),
                  ),

                  // RIGHT: Camera button + Clear button
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: const Key('cameraTitleButton'),
                        icon: const Icon(Icons.camera_alt_outlined),
                        splashRadius: 20,
                        tooltip: loc.translate('camera'),
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                      if (titleController.text.isNotEmpty)
                        IconButton(
                          key: const Key('clearTitleButton'),
                          icon: const Icon(Icons.clear, size: 20),
                          splashRadius: 20,
                          tooltip: 'Clear',
                          onPressed: () {
                            titleController.clear();
                            isTitleManuallyEdited = false;
                            titleFocusNode.requestFocus();
                            setState(() {});
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── 2. Category Selector (Horizontal chips & + button) ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.translate('category'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  key: const Key('addCategoryButton'),
                  onPressed: () => _openAddCategorySheet(loc),
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: Text(loc.translate('add_category')),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categoriesList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = categoriesList[index];
                  final isSelected = cat.id == selectedCategoryItem.id;
                  final itemColor = cat.color;

                  return InkWell(
                    key: Key('category_icon_${cat.id}'),
                    onTap: () => _onCategorySelected(cat, loc),
                    onLongPress: () => _openEditCategorySheet(cat, loc),
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 68,
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? itemColor.withOpacity(0.2)
                                : itemColor.withOpacity(0.06),
                            border: Border.all(
                              color: isSelected ? itemColor : itemColor.withOpacity(0.3),
                              width: isSelected ? 2.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(cat.icon, style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 2),
                              Text(
                                _getCategoryDisplayName(cat, loc),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? itemColor : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Pencil edit button affordance
                        Positioned(
                          top: 2,
                          right: 2,
                          child: InkWell(
                            key: Key('edit_category_icon_${cat.id}'),
                            onTap: () => _openEditCategorySheet(cat, loc),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black54 : Colors.white70,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit,
                                size: 10,
                                color: isSelected ? itemColor : (isDark ? Colors.white60 : Colors.grey.shade600),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── 3. Image Upload & Preview ────────────────────────
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  loc.translate('image'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('pickGalleryButton'),
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, size: 16),
                      label: Text(loc.translate('gallery')),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      key: const Key('takeCameraButton'),
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, size: 16),
                      label: Text(loc.translate('camera')),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (imagePath != null) ...[
              const SizedBox(height: 10),
              Center(
                child: Container(
                  key: const Key('imagePreview'),
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: File(imagePath!).existsSync()
                            ? Image.file(
                                File(imagePath!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 140,
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.image, size: 40, color: Colors.grey),
                                    const SizedBox(height: 4),
                                    Text(
                                      imagePath!.split('/').last,
                                      style: const TextStyle(fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.black.withOpacity(0.65),
                          child: IconButton(
                            key: const Key('removeImageButton'),
                            padding: EdgeInsets.zero,
                            iconSize: 16,
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: _removeImage,
                            tooltip: loc.translate('remove_image'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // ── 4. Amount + Currency Section ─────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Currency pill dropdown
                  Container(
                    key: const Key('currencyPillContainer'),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        key: const Key('currencyDropdown'),
                        value: selectedCurrency,
                        isDense: true,
                        borderRadius: BorderRadius.circular(12),
                        items: widget.projectSettings.availableCurrencies
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    '$c (${currencySymbols[c] ?? c})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedCurrency = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Amount input right-aligned
                  Expanded(
                    child: TextField(
                      controller: amountController,
                      textAlign: TextAlign.right,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.translate('amount'),
                        hintText: '100,000',
                        border: InputBorder.none,
                        suffixText: currencySymbol,
                        suffixStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── 5. Paid By & When (Two-column layout) ─────────────
            Row(
              children: [
                // Column 1: Paid By Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cardBorder),
                    ),
                    child: TextField(
                      key: const Key('payerField'),
                      controller: paidByController,
                      decoration: InputDecoration(
                        labelText: loc.translate('payer'),
                        hintText: loc.translate('payer_hint'),
                        border: InputBorder.none,
                        isDense: true,
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        prefixIconConstraints: const BoxConstraints(minWidth: 28),
                        helperText: selectedProject != null &&
                                selectedProject!.members.isNotEmpty
                            ? selectedProject!.members.join(', ')
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Column 2: When (Date Picker Card)
                Expanded(
                  child: InkWell(
                    key: const Key('datePickerButton'),
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  loc.translate('when'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('yyyy-MM-dd').format(selectedDate),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── 6. Split Section (Cards with Avatars & Checkboxes) ─
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
                    '${loc.translate('each_pays')}: ${_formatAmount(_perPersonAmount)} $currencySymbol',
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
              _buildProjectMemberCards(loc, currencySymbol)
            else
              _buildManualParticipants(loc),

            const SizedBox(height: 24),

            // ── 7. Save Button ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                key: const Key('saveProjectButton'),
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: categoryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  loc.translate('save_bill'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────
  // Helper: Number formatter
  // ────────────────────────────────────────
  String _formatAmount(double amount) {
    if (amount % 1 == 0) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(1);
  }

  // ────────────────────────────────────────
  // Helper: Tab Item
  // ────────────────────────────────────────
  Widget _buildTabItem(String label, bool isSelected, int index, Color activeColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedTransactionType = index;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF2E2E2E) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? activeColor : (isDark ? Colors.white60 : Colors.grey.shade600),
            ),
          ),
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
  // Project member cards (Acceptance 7: Card-based display with avatars & checkboxes)
  // ────────────────────────────────────────
  Widget _buildProjectMemberCards(AppLocalizations loc, String currencySymbol) {
    if (projectMembers.isEmpty) {
      return Text(
        loc.translate('project_no_members'),
        style: const TextStyle(color: Colors.orange),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF242424) : Colors.white;
    final cardBorder = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final activeColor = selectedCategoryItem.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.translate('tap_to_toggle'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),

        // Member Cards List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: projectMembers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final member = projectMembers[index];
            final isSelected = selectedParticipants.contains(member);

            return InkWell(
              key: Key('member_card_$member'),
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedParticipants.remove(member);
                  } else {
                    selectedParticipants.add(member);
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? activeColor.withOpacity(0.12) : activeColor.withOpacity(0.06))
                      : cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? activeColor : cardBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar / Initial
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isSelected
                          ? activeColor
                          : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                      child: Text(
                        member.isNotEmpty ? member[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Member Name
                    Expanded(
                      child: Text(
                        member,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),

                    // Amount if selected
                    if (isSelected && _perPersonAmount > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          '${_formatAmount(_perPersonAmount)} $currencySymbol',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: activeColor,
                          ),
                        ),
                      ),

                    // Checkbox
                    Checkbox(
                      key: Key('member_checkbox_$member'),
                      value: isSelected,
                      activeColor: activeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            selectedParticipants.add(member);
                          } else {
                            selectedParticipants.remove(member);
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // FilterChips row for quick toggle and full backwards compatibility
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
                    ? activeColor
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
              selectedColor: activeColor.withOpacity(0.2),
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
  // Project member toggle chips (legacy support)
  // ────────────────────────────────────────
  Widget _buildProjectMemberChips(AppLocalizations loc) {
    return _buildProjectMemberCards(loc, currencySymbols[selectedCurrency] ?? selectedCurrency);
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
              key: const Key('addParticipantButton'),
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
