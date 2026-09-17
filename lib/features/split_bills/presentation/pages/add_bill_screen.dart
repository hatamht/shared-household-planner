import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/bill.dart';
import '../../domain/entities/bill_participant.dart';
import '../../domain/entities/category_icon.dart';
import '../../domain/repositories/bill_repository.dart';
import '../bloc/bills_bloc.dart';
import '../widgets/add_category_bottom_sheet.dart';
import '../widgets/edit_category_bottom_sheet.dart';
import '../widgets/receipt_viewer_modal.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/receipt_image_service.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/domain/entities/project_settings.dart';
import '../../../projects/presentation/bloc/project_bloc.dart';
import '../../../templates/domain/entities/bill_template.dart';
import '../../../templates/presentation/bloc/bill_templates_bloc.dart';
import '../../../templates/presentation/pages/bill_templates_screen.dart';
import '../../domain/entities/split_mode.dart';
import '../../domain/services/smart_split_calculator.dart';
import '../../domain/services/default_split_mode_service.dart';

class AddBillScreen extends StatefulWidget {
  final ProjectSettings projectSettings;
  final Future<String?> Function(ImageSource source)? onPickImage;
  final Future<List<String>> Function()? onPickMultipleImages;
  final String? initialImagePath;
  final List<String>? initialImagePaths;
  final Bill? billToEdit;
  final BillTemplate? template;
  final String? projectId;

  const AddBillScreen({
    Key? key,
    this.projectSettings = const ProjectSettings(),
    this.onPickImage,
    this.onPickMultipleImages,
    this.initialImagePath,
    this.initialImagePaths,
    this.billToEdit,
    this.template,
    this.projectId,
  }) : super(key: key);

  @override
  State<AddBillScreen> createState() => AddBillScreenState();
}

class AddBillScreenState extends State<AddBillScreen> {
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

  // Image paths
  List<String> imagePaths = [];
  String? get imagePath => imagePaths.isNotEmpty ? imagePaths.first : null;
  set imagePath(String? value) {
    setState(() {
      if (value == null) {
        imagePaths.clear();
      } else {
        if (!imagePaths.contains(value)) {
          imagePaths.add(value);
        }
      }
    });
  }

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
  String? _usedTemplateId;

  // Split Mode state
  String _splitMode = 'equal';
  final Map<String, TextEditingController> _percentageControllers = {};
  final Map<String, TextEditingController> _sharesControllers = {};
  final Map<String, TextEditingController> _customAmountControllers = {};
  bool _saveSplitModeAsDefault = false;

  final ImagePicker _defaultPicker = ImagePicker();

  void _syncParticipantControllers() {
    final participants = _effectiveParticipants;
    final count = participants.length;
    final evenPercentages = SmartSplitCalculator.distributePercentagesEvenly(count);

    for (int i = 0; i < participants.length; i++) {
      final name = participants[i];
      if (!_percentageControllers.containsKey(name)) {
        final pct = i < evenPercentages.length ? evenPercentages[i] : 0.0;
        _percentageControllers[name] = TextEditingController(
          text: pct % 1 == 0 ? pct.toInt().toString() : pct.toString(),
        );
      }
      if (!_sharesControllers.containsKey(name)) {
        _sharesControllers[name] = TextEditingController(text: '1');
      }
      if (!_customAmountControllers.containsKey(name)) {
        final perPerson = count > 0 ? _currentAmount / count : 0.0;
        _customAmountControllers[name] = TextEditingController(
          text: perPerson % 1 == 0 ? perPerson.toInt().toString() : perPerson.toStringAsFixed(1),
        );
      }
    }
  }

  void _checkDefaultSplitMode() async {
    final defaultMode = await DefaultSplitModeService.instance.getDefaultSplitModeForCategory(selectedCategoryItem.id);
    if (defaultMode != null && mounted) {
      setState(() {
        _splitMode = defaultMode;
        _syncParticipantControllers();
      });
    }
  }

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

    if (widget.initialImagePaths != null && widget.initialImagePaths!.isNotEmpty) {
      imagePaths = List.from(widget.initialImagePaths!);
    } else if (widget.initialImagePath != null) {
      imagePaths = [widget.initialImagePath!];
    } else if (widget.billToEdit != null) {
      imagePaths = List.from(widget.billToEdit!.effectiveImagePaths);
    }

    if (widget.billToEdit != null) {
      final b = widget.billToEdit!;
      titleController.text = b.title;
      amountController.text = b.amount.toStringAsFixed(0);
      paidByController.text = b.paidBy;
      selectedDate = b.date;
      selectedCurrency = b.currency ?? widget.projectSettings.defaultCurrency;
      final match = categoriesList.where((c) => c.id == b.category);
      if (match.isNotEmpty) {
        selectedCategoryItem = match.first;
      }
      manualParticipants = b.participants.map((p) => p.name).toList();
      selectedParticipants = b.participants.map((p) => p.name).toSet();
      _splitMode = b.splitMode;
      for (final p in b.participants) {
        if (p.percentage != null) {
          final pct = p.percentage!;
          _percentageControllers[p.name] = TextEditingController(
            text: pct % 1 == 0 ? pct.toInt().toString() : pct.toString(),
          );
        }
        if (p.shares != null) {
          final sh = p.shares!;
          _sharesControllers[p.name] = TextEditingController(
            text: sh % 1 == 0 ? sh.toInt().toString() : sh.toString(),
          );
        }
        final amt = p.amount;
        _customAmountControllers[p.name] = TextEditingController(
          text: amt % 1 == 0 ? amt.toInt().toString() : amt.toStringAsFixed(1),
        );
      }
      _syncParticipantControllers();
    } else if (widget.template != null) {
      _applyTemplate(widget.template!, recordUsage: false);
    } else {
      _syncParticipantControllers();
      _checkDefaultSplitMode();
    }

    titleController.addListener(() {
      setState(() {});
    });

    amountController.addListener(() {
      setState(() {});
    });

    // Load all projects for the dropdown
    try {
      context.read<ProjectBloc>().add(const GetAllProjects());
    } catch (_) {}

    // Load templates
    try {
      context.read<BillTemplatesBloc>().add(const LoadTemplatesEvent());
    } catch (_) {}
  }

  void _applyTemplate(BillTemplate t, {bool recordUsage = false}) {
    titleController.text = t.title;
    if (t.amount > 0) {
      amountController.text = t.amount.toStringAsFixed(0);
    }
    paidByController.text = t.paidBy ?? '';
    selectedCurrency = t.currency;
    final match = categoriesList.where((c) => c.id == t.category);
    if (match.isNotEmpty) {
      selectedCategoryItem = match.first;
    } else if (t.categoryIcon != null) {
      selectedCategoryItem = CategoryIconItem(
        id: t.category,
        nameKey: t.category,
        icon: t.categoryIcon!,
        colorHex: t.categoryColor ?? '#4CAF50',
      );
    }
    manualParticipants = List.from(t.participants);
    selectedParticipants = t.participants.toSet();
    _splitMode = t.splitMode;
    _syncParticipantControllers();
    isTitleManuallyEdited = true;
    _usedTemplateId = t.id;

    if (recordUsage) {
      try {
        context.read<BillTemplatesBloc>().add(RecordTemplateUsageEvent(t.id));
      } catch (_) {}
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _saveAsTemplate() {
    final loc = AppLocalizations.of(context);
    final title = titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('bill_name_required'))),
      );
      return;
    }

    final amount = double.tryParse(amountController.text) ?? 0.0;
    final participants = _effectiveParticipants;
    final template = BillTemplate(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      category: selectedCategoryItem.id,
      categoryIcon: selectedCategoryItem.icon,
      categoryColor: selectedCategoryItem.colorHex,
      currency: selectedCurrency,
      splitMode: _splitMode,
      paidBy: paidByController.text.trim(),
      participants: participants,
      projectId: selectedProject?.id ?? widget.projectId,
      createdAt: DateTime.now(),
    );

    try {
      context.read<BillTemplatesBloc>().add(CreateTemplateEvent(template));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('templateSavedSnackBar'),
          content: Text(loc.translate('template_saved_success')),
        ),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    titleController.dispose();
    titleFocusNode.dispose();
    amountController.dispose();
    paidByController.dispose();
    participantController.dispose();
    for (final c in _percentageControllers.values) {
      c.dispose();
    }
    for (final c in _sharesControllers.values) {
      c.dispose();
    }
    for (final c in _customAmountControllers.values) {
      c.dispose();
    }
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
    if (widget.billToEdit == null) {
      _checkDefaultSplitMode();
    }
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
          final savedPath = await ReceiptImageService.saveReceiptFromPath(path);
          setState(() {
            if (!imagePaths.contains(savedPath)) {
              imagePaths.add(savedPath);
            }
          });
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
        final savedPath = await ReceiptImageService.saveReceiptFromPath(file.path);
        setState(() {
          if (!imagePaths.contains(savedPath)) {
            imagePaths.add(savedPath);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> pickMultipleImages() => _pickMultipleImages();

  Future<void> _pickMultipleImages() async {
    try {
      if (widget.onPickMultipleImages != null) {
        final paths = await widget.onPickMultipleImages!();
        for (final p in paths) {
          final saved = await ReceiptImageService.saveReceiptFromPath(p);
          if (!imagePaths.contains(saved)) {
            imagePaths.add(saved);
          }
        }
        setState(() {});
        return;
      }

      if (widget.onPickImage != null) {
        final path = await widget.onPickImage!(ImageSource.gallery);
        if (path != null) {
          final saved = await ReceiptImageService.saveReceiptFromPath(path);
          if (!imagePaths.contains(saved)) {
            imagePaths.add(saved);
          }
        }
        setState(() {});
        return;
      }

      final List<XFile> files = await _defaultPicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (files.isNotEmpty) {
        for (final file in files) {
          final saved = await ReceiptImageService.saveReceiptFromPath(file.path);
          if (!imagePaths.contains(saved)) {
            imagePaths.add(saved);
          }
        }
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  void _removeImage([int? index]) {
    setState(() {
      if (index != null && index >= 0 && index < imagePaths.length) {
        imagePaths.removeAt(index);
      } else if (imagePaths.isNotEmpty) {
        imagePaths.removeLast();
      }
    });
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
        _syncParticipantControllers();
      });
    }
  }

  void _removeManualParticipant(int index) {
    setState(() {
      manualParticipants.removeAt(index);
      _syncParticipantControllers();
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

    final mode = SplitMode.fromString(_splitMode);
    if (mode == SplitMode.percentage) {
      final pMap = <String, double>{};
      for (final name in parts) {
        pMap[name] = double.tryParse(_percentageControllers[name]?.text.trim() ?? '') ?? 0.0;
      }
      final res = SmartSplitCalculator.validatePercentage(pMap);
      if (!res.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.translate(res.errorMessageKey!))),
        );
        return false;
      }
    } else if (mode == SplitMode.shares) {
      final sMap = <String, double>{};
      for (final name in parts) {
        sMap[name] = double.tryParse(_sharesControllers[name]?.text.trim() ?? '') ?? 0.0;
      }
      final res = SmartSplitCalculator.validateShares(sMap);
      if (!res.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.translate(res.errorMessageKey!))),
        );
        return false;
      }
    } else if (mode == SplitMode.custom) {
      final cMap = <String, double>{};
      for (final name in parts) {
        cMap[name] = double.tryParse(_customAmountControllers[name]?.text.trim() ?? '') ?? 0.0;
      }
      final res = SmartSplitCalculator.validateCustom(amount, cMap);
      if (!res.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.translate(res.errorMessageKey!))),
        );
        return false;
      }
    }

    return true;
  }

  // ────────────────────────────────────────
  // Submit
  // ────────────────────────────────────────
  void _submitForm() async {
    if (!_validateForm()) return;

    final amount = double.parse(amountController.text);
    final parts = _effectiveParticipants;
    final mode = SplitMode.fromString(_splitMode);

    List<BillParticipant> billParticipants;
    switch (mode) {
      case SplitMode.percentage:
        final pMap = <String, double>{};
        for (final name in parts) {
          pMap[name] = double.tryParse(_percentageControllers[name]?.text.trim() ?? '') ?? 0.0;
        }
        billParticipants = SmartSplitCalculator.calculatePercentage(
          totalAmount: amount,
          percentages: pMap,
        );
        break;
      case SplitMode.shares:
        final sMap = <String, double>{};
        for (final name in parts) {
          sMap[name] = double.tryParse(_sharesControllers[name]?.text.trim() ?? '') ?? 0.0;
        }
        billParticipants = SmartSplitCalculator.calculateShares(
          totalAmount: amount,
          shares: sMap,
        );
        break;
      case SplitMode.custom:
        final cMap = <String, double>{};
        for (final name in parts) {
          cMap[name] = double.tryParse(_customAmountControllers[name]?.text.trim() ?? '') ?? 0.0;
        }
        billParticipants = SmartSplitCalculator.calculateCustom(
          totalAmount: amount,
          customAmounts: cMap,
        );
        break;
      case SplitMode.equal:
      default:
        billParticipants = SmartSplitCalculator.calculateEqual(
          totalAmount: amount,
          participantNames: parts,
        );
        break;
    }

    final bill = Bill(
      id: widget.billToEdit?.id ?? const Uuid().v4(),
      title: titleController.text.trim(),
      amount: amount,
      category: selectedCategoryItem.id,
      date: selectedDate,
      paidBy: paidByController.text.trim(),
      participants: billParticipants,
      projectId: selectedProject?.id ?? widget.billToEdit?.projectId,
      categoryIcon: selectedCategoryItem.icon,
      currency: selectedCurrency,
      imagePath: imagePaths.isNotEmpty ? imagePaths.first : null,
      imagePaths: List.from(imagePaths),
      categoryColor: selectedCategoryItem.colorHex,
      splitMode: _splitMode,
    );

    if (_saveSplitModeAsDefault) {
      try {
        await DefaultSplitModeService.instance.setDefaultSplitModeForCategory(
          selectedCategoryItem.id,
          _splitMode,
        );
      } catch (_) {}
    }

    if (widget.billToEdit != null) {
      try {
        final repo = context.read<BillRepository>();
        await repo.update(bill);
        if (mounted) {
          context.read<BillsBloc>().add(const GetBillsEvent());
        }
      } catch (_) {
        context.read<BillsBloc>().add(AddBillEvent(bill: bill));
      }
    } else {
      context.read<BillsBloc>().add(AddBillEvent(bill: bill));
    }
    if (_usedTemplateId != null) {
      try {
        context.read<BillTemplatesBloc>().add(RecordTemplateUsageEvent(_usedTemplateId!));
      } catch (_) {}
    }
    if (mounted) {
      Navigator.pop(context);
    }
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
        actions: [
          IconButton(
            key: const Key('saveAsTemplateAppBarButton'),
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: loc.translate('save_as_template'),
            onPressed: _saveAsTemplate,
          ),
        ],
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
            _buildQuickTemplatesSection(loc, isDark),
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
                Expanded(
                  child: Text(
                    loc.translate('category'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
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

            // ── 3. Image Upload & Preview (Receipt Images & Multi-Image Gallery) ──
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  loc.translate('receipt_images'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('pickGalleryButton'),
                      onPressed: () => _pickMultipleImages(),
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
            if (imagePaths.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                key: const Key('imagePreview'),
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${loc.translate('receipts')} (${imagePaths.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        TextButton.icon(
                          key: const Key('clearAllReceiptsButton'),
                          onPressed: () => setState(() => imagePaths.clear()),
                          icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.red),
                          label: Text(
                            loc.translate('delete_receipt'),
                            style: const TextStyle(fontSize: 11, color: Colors.red),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        key: const Key('receiptGalleryList'),
                        scrollDirection: Axis.horizontal,
                        itemCount: imagePaths.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final path = imagePaths[index];
                          final file = File(path);
                          final exists = file.existsSync();

                          return GestureDetector(
                            key: Key('receiptThumbnail_$index'),
                            onTap: () {
                              ReceiptViewerModal.show(
                                context,
                                imagePaths: imagePaths,
                                initialIndex: index,
                                onDelete: (idx) => _removeImage(idx),
                              );
                            },
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: cardBorder),
                                    color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: exists
                                        ? Image.file(file, fit: BoxFit.cover)
                                        : Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.image, size: 32, color: Colors.grey),
                                                const SizedBox(height: 2),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                                  child: Text(
                                                    path.split('/').last,
                                                    style: const TextStyle(fontSize: 9),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.black.withOpacity(0.65),
                                    child: IconButton(
                                      key: index == 0
                                          ? const Key('removeImageButton')
                                          : Key('removeImageButton_$index'),
                                      padding: EdgeInsets.zero,
                                      iconSize: 14,
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      onPressed: () => _removeImage(index),
                                      tooltip: loc.translate('remove_image'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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
                      key: const Key('amountField'),
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

            // ── 6. Split Section (Split Mode selection & Member lists) ─
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.translate('split'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_splitMode == 'equal' && _perPersonAmount > 0)
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

            // Split Mode Radio Group
            _buildSplitModeRadioGroup(loc, isDark),
            const SizedBox(height: 12),

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

            const SizedBox(height: 12),

            // Dynamic Split Breakdown Inputs for Percentage, Shares, and Custom modes
            if (_effectiveParticipants.isNotEmpty && _splitMode != 'equal')
              _buildSplitModeInputs(loc, isDark, currencySymbol),

            // Save default split mode checkbox
            CheckboxListTile(
              key: const Key('saveDefaultSplitModeCheckbox'),
              value: _saveSplitModeAsDefault,
              onChanged: (val) {
                setState(() {
                  _saveSplitModeAsDefault = val ?? false;
                });
              },
              title: Text(
                loc.translate('save_split_mode_as_default'),
                style: const TextStyle(fontSize: 13),
              ),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),

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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                key: const Key('saveAsTemplateButton'),
                onPressed: _saveAsTemplate,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: Text(loc.translate('save_as_template')),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTemplatesSection(AppLocalizations loc, bool isDark) {
    try {
      BlocProvider.of<BillTemplatesBloc>(context);
    } catch (_) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<BillTemplatesBloc, BillTemplatesState>(
      builder: (context, state) {
        if (state is BillTemplatesLoaded && state.templates.isNotEmpty) {
          final list = state.favorites.isNotEmpty ? state.favorites : state.templates;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bookmark_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          loc.translate('quick_templates'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      key: const Key('openTemplatesScreenButton'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BillTemplatesScreen(
                              onSelectTemplate: (tpl) {
                                _applyTemplate(tpl);
                              },
                            ),
                          ),
                        );
                      },
                      child: Text(
                        loc.translate('manage_templates'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  key: const Key('quickTemplatesRow'),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: list.take(6).map((t) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ActionChip(
                          key: Key('quickTemplateChip_${t.id}'),
                          avatar: Text(
                            t.categoryIcon ?? '💰',
                            style: const TextStyle(fontSize: 14),
                          ),
                          label: Text(t.title),
                          onPressed: () => _applyTemplate(t),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
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
                key: const Key('participantNameField'),
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

  // ────────────────────────────────────────
  // Split Mode Radio Group
  // ────────────────────────────────────────
  Widget _buildSplitModeRadioGroup(AppLocalizations loc, bool isDark) {
    return Container(
      key: const Key('splitModeRadioGroup'),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: SplitMode.values.map((mode) {
          final isSelected = _splitMode == mode.value;
          return RadioListTile<String>(
            key: Key('splitModeRadio_${mode.value}'),
            value: mode.value,
            groupValue: _splitMode,
            dense: true,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
            title: Row(
              children: [
                Icon(
                  mode.icon,
                  size: 18,
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mode.getLocalizedName(loc),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _splitMode = val;
                  _syncParticipantControllers();
                });
              }
            },
          );
        }).toList(),
      ),
    );
  }

  // ────────────────────────────────────────
  // Dynamic Split Mode Inputs
  // ────────────────────────────────────────
  Widget _buildSplitModeInputs(AppLocalizations loc, bool isDark, String currencySymbol) {
    _syncParticipantControllers();
    final parts = _effectiveParticipants;
    final mode = SplitMode.fromString(_splitMode);

    switch (mode) {
      case SplitMode.percentage:
        double currentSum = 0;
        for (final name in parts) {
          currentSum += double.tryParse(_percentageControllers[name]?.text.trim() ?? '') ?? 0.0;
        }
        final is100 = (currentSum - 100.0).abs() <= 0.01;

        return Card(
          key: const Key('percentageInputsSection'),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${loc.translate('total_percentage')}: ${currentSum.toStringAsFixed(1)}% / 100%',
                      key: const Key('totalPercentageText'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: is100 ? Colors.green : Colors.deepOrange,
                      ),
                    ),
                    TextButton.icon(
                      key: const Key('distributePercentagesEvenlyButton'),
                      onPressed: () {
                        final even = SmartSplitCalculator.distributePercentagesEvenly(parts.length);
                        setState(() {
                          for (int i = 0; i < parts.length; i++) {
                            final name = parts[i];
                            final val = i < even.length ? even[i] : 0.0;
                            _percentageControllers[name]?.text =
                                val % 1 == 0 ? val.toInt().toString() : val.toString();
                          }
                        });
                      },
                      icon: const Icon(Icons.auto_fix_high, size: 16),
                      label: Text(loc.translate('distribute_evenly'), style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const Divider(),
                ...parts.map((name) {
                  final pct = double.tryParse(_percentageControllers[name]?.text.trim() ?? '') ?? 0.0;
                  final calculated = _currentAmount > 0 ? (_currentAmount * (pct / 100.0)) : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 40,
                            child: TextField(
                              key: Key('percentageInput_$name'),
                              controller: _percentageControllers[name],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                suffixText: '%',
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '${_formatAmount(calculated)} $currencySymbol',
                            key: Key('calculatedAmount_$name'),
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );

      case SplitMode.shares:
        double totalShares = 0;
        for (final name in parts) {
          totalShares += double.tryParse(_sharesControllers[name]?.text.trim() ?? '') ?? 0.0;
        }

        return Card(
          key: const Key('sharesInputsSection'),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${loc.translate('total_shares')}: ${totalShares % 1 == 0 ? totalShares.toInt() : totalShares.toStringAsFixed(1)}',
                      key: const Key('totalSharesText'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: totalShares > 0 ? Theme.of(context).colorScheme.primary : Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                ...parts.map((name) {
                  final sh = double.tryParse(_sharesControllers[name]?.text.trim() ?? '') ?? 0.0;
                  final fraction = totalShares > 0 ? (sh / totalShares) : 0.0;
                  final calculated = _currentAmount * fraction;
                  final pct = fraction * 100.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        IconButton(
                          key: Key('sharesMinus_$name'),
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            final cur = double.tryParse(_sharesControllers[name]?.text.trim() ?? '') ?? 1.0;
                            if (cur > 0) {
                              final next = cur - 1;
                              _sharesControllers[name]?.text =
                                  next % 1 == 0 ? next.toInt().toString() : next.toString();
                              setState(() {});
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 45,
                          height: 38,
                          child: TextField(
                            key: Key('sharesInput_$name'),
                            controller: _sharesControllers[name],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          key: Key('sharesPlus_$name'),
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            final cur = double.tryParse(_sharesControllers[name]?.text.trim() ?? '') ?? 0.0;
                            final next = cur + 1;
                            _sharesControllers[name]?.text =
                                next % 1 == 0 ? next.toInt().toString() : next.toString();
                            setState(() {});
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '${_formatAmount(calculated)} $currencySymbol\n(${pct.toStringAsFixed(1)}%)',
                            key: Key('calculatedAmount_$name'),
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );

      case SplitMode.custom:
        double totalCustom = 0;
        for (final name in parts) {
          totalCustom += double.tryParse(_customAmountControllers[name]?.text.trim() ?? '') ?? 0.0;
        }
        final remaining = _currentAmount - totalCustom;
        final isBalanced = remaining.abs() <= 0.01;

        return Card(
          key: const Key('customInputsSection'),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${loc.translate('remaining_amount')}: ${_formatAmount(remaining)} $currencySymbol',
                      key: const Key('remainingAmountText'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isBalanced ? Colors.green : Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                ...parts.map((name) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 40,
                            child: TextField(
                              key: Key('customAmountInput_$name'),
                              controller: _customAmountControllers[name],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                suffixText: currencySymbol,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          key: Key('fillRemainingButton_$name'),
                          icon: const Icon(Icons.all_inclusive, size: 20),
                          tooltip: loc.translate('fill_remaining'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            final cur = double.tryParse(_customAmountControllers[name]?.text.trim() ?? '') ?? 0.0;
                            final newVal = cur + remaining;
                            if (newVal >= 0) {
                              _customAmountControllers[name]?.text =
                                  newVal % 1 == 0 ? newVal.toInt().toString() : newVal.toStringAsFixed(1);
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );

      case SplitMode.equal:
      default:
        return const SizedBox.shrink();
    }
  }
}
