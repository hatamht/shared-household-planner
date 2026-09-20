import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../../domain/services/calculator_evaluator.dart';
import '../widgets/calculator_keyboard.dart';

// ─── Category keyword maps for silent auto-detection ───
const Map<String, List<String>> autoCategoryKeywords = {
  'restaurant': ['food', 'lunch', 'dinner', 'breakfast', 'meal', 'eat', 'restaurant',
      'ăn trưa', 'ăn tối', 'ăn sáng', 'cơm', 'phở', 'bún', 'trưa', 'tối', 'sáng', 'quán', 'cafe', 'coffee', 'cà phê'],
  'transport': ['taxi', 'uber', 'grab', 'bus', 'car', 'gas', 'fuel', 'parking',
      'xe máy', 'xe ôm', 'xe bus', 'xe buýt', 'gửi xe', 'xăng', 'đổ xăng', 'đậu xe', 'đi lại'],
  'shopping': ['shop', 'buy', 'store', 'market', 'mall', 'grocery', 'mua', 'siêu thị', 'chợ'],
  'entertainment': ['movie', 'film', 'game', 'netflix', 'concert', 'show', 'phim', 'trò chơi'],
  'health': ['doctor', 'medicine', 'pharmacy', 'hospital', 'thuốc', 'bệnh viện', 'khám'],
  'travel': ['hotel', 'flight', 'trip', 'travel', 'vacation', 'tour', 'khách sạn', 'vé máy bay', 'du lịch'],
  'utilities': ['electric', 'water', 'internet', 'rent', 'điện', 'nước', 'thuê nhà', 'wifi'],
  'party': ['party', 'birthday', 'event', 'tiệc', 'sinh nhật'],
  'sport': ['gym', 'sport', 'fitness', 'swimming', 'thể thao', 'bơi', 'gym'],
};

String detectCategoryFromText(String text) {
  if (text.trim().isEmpty) return 'restaurant';
  final lower = text.toLowerCase();
  for (final entry in autoCategoryKeywords.entries) {
    for (final keyword in entry.value) {
      if (lower.contains(keyword)) return entry.key;
    }
  }
  return 'restaurant';
}

class AddBillScreen extends StatefulWidget {
  final ProjectSettings projectSettings;
  final Future<String?> Function(ImageSource source)? onPickImage;
  final Future<List<String>> Function()? onPickMultipleImages;
  final String? initialImagePath;
  final List<String>? initialImagePaths;
  final Bill? billToEdit;
  final BillTemplate? template;
  final String? projectId;
  final String? projectName;
  final bool requireProject;
  final bool? initialCompactMode;

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
    this.projectName,
    this.requireProject = false,
    this.initialCompactMode,
  }) : super(key: key);

  @override
  State<AddBillScreen> createState() => AddBillScreenState();
}

class AddBillScreenState extends State<AddBillScreen>
    with TickerProviderStateMixin {
  late bool _isCompactMode;
  bool get isCompactMode => _isCompactMode;
  FocusNode get descriptionFocusNode => titleFocusNode;

  // ── Animation controllers for Compact ↔ Full mode transition ──
  late AnimationController _modeAnimController;
  late Animation<double> _compactFade;     // 1.0 in compact → 0.0 in full
  late Animation<double> _fullFade;        // 0.0 in compact → 1.0 in full
  late Animation<double> _expandIconTurn; // 0.0 → 0.5 (180° rotate)

  late TextEditingController titleController;
  late TextEditingController amountController;
  late TextEditingController paidByController;
  late TextEditingController participantController;

  bool _showCalculator = false;
  void _toggleCalculator() {
    setState(() {
      _showCalculator = !_showCalculator;
    });
  }

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
  bool _hasUserExplicitlySelectedProject = false;

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

    _isCompactMode = widget.initialCompactMode ?? (widget.billToEdit == null && widget.template == null);

    // ── Set up Compact ↔ Full mode animation (300ms easeInOut) ──
    _modeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: _isCompactMode ? 0.0 : 1.0, // 0=compact, 1=full
    );
    final curvedAnim = CurvedAnimation(
      parent: _modeAnimController,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut,
    );
    _compactFade = Tween<double>(begin: 1.0, end: 0.0).animate(curvedAnim);
    _fullFade    = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnim);
    _expandIconTurn = Tween<double>(begin: 0.0, end: 0.5).animate(curvedAnim);

    if (_isCompactMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          titleFocusNode.requestFocus();
        }
      });
    }

    titleController.addListener(() {
      setState(() {});
    });

    amountController.addListener(() {
      setState(() {});
    });

    // Load all projects for the dropdown & project selector
    try {
      final projectBloc = context.read<ProjectBloc>();
      projectBloc.add(const GetAllProjects());
      if (projectBloc.state is ProjectLoaded) {
        final state = projectBloc.state as ProjectLoaded;
        final targetId = widget.billToEdit?.projectId ?? widget.projectId;
        if (targetId != null) {
          final found = state.projects.where((p) => p.id == targetId);
          if (found.isNotEmpty) {
            selectedProject = found.first;
            projectMembers = List.from(selectedProject!.members);
            if (widget.billToEdit == null && selectedParticipants.isEmpty) {
              selectedParticipants = Set.from(selectedProject!.members);
              if (selectedProject!.members.isNotEmpty && paidByController.text.isEmpty) {
                paidByController.text = selectedProject!.members.first;
              }
            }
          }
        } else if (widget.billToEdit == null) {
          _resolveDefaultProject(state.projects);
        }
      }
    } catch (_) {}

    if (widget.projectId != null) {
      if (selectedProject == null && widget.projectName != null) {
        selectedProject = Project(
          id: widget.projectId!,
          name: widget.projectName!,
          members: widget.projectSettings.members,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      if (projectMembers.isEmpty && widget.projectSettings.members.isNotEmpty) {
        projectMembers = List.from(widget.projectSettings.members);
      }
      if (widget.billToEdit == null && selectedParticipants.isEmpty && widget.projectSettings.members.isNotEmpty) {
        selectedParticipants = Set.from(widget.projectSettings.members);
        if (projectMembers.isNotEmpty && paidByController.text.isEmpty) {
          paidByController.text = projectMembers.first;
        }
        _syncParticipantControllers();
      }
    }

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

    final amount = _currentAmount;
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
      projectId: _hasUserExplicitlySelectedProject
          ? selectedProject?.id
          : (selectedProject?.id ?? widget.billToEdit?.projectId ?? widget.projectId),
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
    _modeAnimController.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────
  // Two-Mode Layout Helpers (Compact Mode)
  // ────────────────────────────────────────

  /// Animated expand: Compact → Full (300ms easeInOut)
  Future<void> _switchToFullMode() async {
    setState(() => _isCompactMode = false);
    await _modeAnimController.forward();
  }

  /// Animated collapse: Full → Compact (300ms easeInOut)
  Future<void> _switchToCompactMode() async {
    setState(() => _isCompactMode = true);
    await _modeAnimController.reverse();
  }

  bool get _canSave {
    final hasProject = _hasUserExplicitlySelectedProject
        ? selectedProject != null
        : (selectedProject != null ||
            (widget.projectId != null && widget.projectId!.isNotEmpty));
    return hasProject && _currentAmount > 0;
  }

  bool get _isToday {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  String _formatCompactDate(AppLocalizations loc) {
    if (_isToday) return loc.translate('today');
    return DateFormat('MMM d').format(selectedDate);
  }

  String _compactMembersLabel(AppLocalizations loc) {
    if (selectedProject == null) {
      return loc.translate('members');
    }
    final members = selectedProject!.members;
    final validParticipants =
        selectedParticipants.where((m) => members.contains(m)).toList();
    if (validParticipants.isEmpty) {
      return '${members.length} ${loc.translate('members')}';
    } else if (validParticipants.length == 1) {
      return validParticipants.first;
    } else {
      return '${validParticipants.length} ${loc.translate('members')}';
    }
  }

  void _onCompactDescriptionChanged(String text) {
    if (text.trim().isEmpty) {
      isTitleManuallyEdited = false;
    } else {
      isTitleManuallyEdited = true;
      final detected = detectCategoryFromText(text);
      final match = categoriesList.where((c) => c.id == detected);
      if (match.isNotEmpty && match.first.id != selectedCategoryItem.id) {
        setState(() {
          selectedCategoryItem = match.first;
        });
      }
    }
  }

  void _openCompactMembersSheet() {
    FocusScope.of(context).unfocus();
    final loc = AppLocalizations.of(context);
    if (selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('selectProjectFirstSnackBar'),
          content: Text(loc.translate('select_project_first')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final members = selectedProject!.members;
    final tempSelected = Set<String>.from(
      selectedParticipants.where((m) => members.contains(m)),
    );
    if (tempSelected.isEmpty) {
      tempSelected.addAll(members);
    }
    String tempPayer = paidByController.text.trim().isNotEmpty &&
            members.contains(paidByController.text.trim())
        ? paidByController.text.trim()
        : (members.isNotEmpty ? members.first : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.translate('members'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          key: const Key('compactMembersSelectAllButton'),
                          onPressed: () {
                            setModalState(() {
                              if (tempSelected.length == members.length) {
                                tempSelected.clear();
                              } else {
                                tempSelected.addAll(members);
                              }
                            });
                          },
                          child: Text(
                            tempSelected.length == members.length
                                ? loc.translate('deselect_all')
                                : loc.translate('select_all'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: members.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final m = members[i];
                          final isChecked = tempSelected.contains(m);
                          final isPayer = (tempPayer == m);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Color(int.parse(
                                selectedCategoryItem.colorHex.replaceFirst('#', '0xFF'),
                              )).withOpacity(0.15),
                              child: Text(
                                m.isNotEmpty ? m[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(int.parse(
                                    selectedCategoryItem.colorHex.replaceFirst('#', '0xFF'),
                                  )),
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(m, style: const TextStyle(fontWeight: FontWeight.w500)),
                                if (isPayer) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      loc.translate('paid_by'),
                                      style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  key: Key('compact_set_payer_$m'),
                                  icon: Icon(
                                    isPayer ? Icons.star : Icons.star_border,
                                    color: isPayer ? Colors.amber : Colors.grey,
                                    size: 20,
                                  ),
                                  tooltip: loc.translate('paid_by'),
                                  onPressed: () {
                                    setModalState(() {
                                      tempPayer = m;
                                      tempSelected.add(m);
                                    });
                                  },
                                ),
                                Checkbox(
                                  key: Key('compact_member_checkbox_$m'),
                                  value: isChecked,
                                  onChanged: (val) {
                                    setModalState(() {
                                      if (val == true) {
                                        tempSelected.add(m);
                                      } else {
                                        tempSelected.remove(m);
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              setModalState(() {
                                if (isChecked) {
                                  tempSelected.remove(m);
                                } else {
                                  tempSelected.add(m);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        key: const Key('compactMembersDoneButton'),
                        onPressed: () {
                          setState(() {
                            selectedParticipants = Set.from(tempSelected);
                            if (tempPayer.isNotEmpty) {
                              paidByController.text = tempPayer;
                            }
                            _syncParticipantControllers();
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(int.parse(
                            selectedCategoryItem.colorHex.replaceFirst('#', '0xFF'),
                          )),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(loc.translate('done'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openCompactSplitSheet() {
    FocusScope.of(context).unfocus();
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final members = selectedProject?.members ??
        (selectedParticipants.isNotEmpty ? selectedParticipants.toList() : ['You']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String currentMode = _splitMode;
        String currentPayer = paidByController.text.trim().isNotEmpty
            ? paidByController.text.trim()
            : (members.isNotEmpty ? members.first : 'You');

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      loc.translate('split_bills'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loc.translate('paid_by'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: members.map((m) {
                        final isSelected = currentPayer == m;
                        return ChoiceChip(
                          key: Key('compact_payer_chip_$m'),
                          label: Text(m),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => currentPayer = m);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      loc.translate('split_mode'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    _buildCompactSplitModeItem('equal', loc.translate('split_mode_equal'), currentMode, (m) {
                      setModalState(() => currentMode = m);
                    }),
                    _buildCompactSplitModeItem('percentage', loc.translate('split_mode_percentage'), currentMode, (m) {
                      setModalState(() => currentMode = m);
                    }),
                    _buildCompactSplitModeItem('shares', loc.translate('split_mode_shares'), currentMode, (m) {
                      setModalState(() => currentMode = m);
                    }),
                    _buildCompactSplitModeItem('custom', loc.translate('split_mode_custom'), currentMode, (m) {
                      setModalState(() => currentMode = m);
                    }),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        key: const Key('compactSplitDoneButton'),
                        onPressed: () {
                          setState(() {
                            _splitMode = currentMode;
                            paidByController.text = currentPayer;
                            _syncParticipantControllers();
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(int.parse(
                            selectedCategoryItem.colorHex.replaceFirst('#', '0xFF'),
                          )),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(loc.translate('done'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompactSplitModeItem(
    String mode,
    String label,
    String selectedMode,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = selectedMode == mode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        key: Key('compact_split_mode_$mode'),
        borderRadius: BorderRadius.circular(10),
        onTap: () => onSelected(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Color(int.parse(selectedCategoryItem.colorHex.replaceFirst('#', '0xFF'))).withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? Color(int.parse(selectedCategoryItem.colorHex.replaceFirst('#', '0xFF')))
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 20,
                color: isSelected
                    ? Color(int.parse(selectedCategoryItem.colorHex.replaceFirst('#', '0xFF')))
                    : Colors.grey,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _splitChipLabel(AppLocalizations loc) {
    final payer = paidByController.text.trim().isNotEmpty
        ? paidByController.text.trim()
        : (selectedProject?.members.isNotEmpty == true
            ? selectedProject!.members.first
            : loc.translate('you'));
    switch (_splitMode) {
      case 'equal':
        return '${loc.translate('paid_by')} $payer · ${loc.translate('split_mode_equal')}';
      case 'percentage':
        return '${loc.translate('paid_by')} $payer · ${loc.translate('split_mode_percentage')}';
      case 'shares':
        return '${loc.translate('paid_by')} $payer · ${loc.translate('split_mode_shares')}';
      case 'custom':
        return '${loc.translate('paid_by')} $payer · ${loc.translate('split_mode_custom')}';
      default:
        return '${loc.translate('paid_by')} $payer · ${loc.translate('split_mode_equal')}';
    }
  }

  Widget _buildCompactChip({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
    Key? key,
    bool isActive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Color(int.parse(selectedCategoryItem.colorHex.replaceFirst('#', '0xFF'))).withOpacity(0.15)
              : (isDark ? const Color(0xFF262626) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Color(int.parse(selectedCategoryItem.colorHex.replaceFirst('#', '0xFF')))
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactDescriptionField(AppLocalizations loc, Color categoryColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              selectedCategoryItem.icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: const Key('compactDescriptionField'),
              focusNode: titleFocusNode,
              controller: titleController,
              onChanged: _onCompactDescriptionChanged,
              decoration: InputDecoration(
                hintText: loc.translate('bill_name_hint'),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textInputAction: TextInputAction.next,
            ),
          ),
          if (titleController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              splashRadius: 18,
              onPressed: () {
                setState(() {
                  titleController.clear();
                  isTitleManuallyEdited = false;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCompactAmountField(AppLocalizations loc, Color categoryColor, bool isDark) {
    final text = amountController.text.trim();
    final hasOp = CalculatorEvaluator.hasOperator(text);
    final evalResult = CalculatorEvaluator.evaluate(text);
    final canEval = evalResult != null && !evalResult.isNaN && !evalResult.isInfinite;
    final hasError = hasOp && !canEval && text.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasError
                  ? Colors.redAccent
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                selectedCurrency,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      key: const Key('compactAmountField'),
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (val) {
                        final evaluated = CalculatorEvaluator.evaluate(val);
                        if (evaluated != null) {
                          amountController.text = CalculatorEvaluator.formatResult(evaluated);
                        }
                      },
                    ),
                    if (hasOp && canEval)
                      Text(
                        '= ${CalculatorEvaluator.formatResult(evalResult)}',
                        key: const Key('compactAmountCalcPreview'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: categoryColor,
                        ),
                      )
                    else if (hasError)
                      Text(
                        loc.translate('invalid_expression'),
                        key: const Key('compactAmountCalcError'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.redAccent,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('toggleCalculatorButton'),
                icon: Icon(
                  _showCalculator ? Icons.keyboard_hide : Icons.calculate_outlined,
                  color: categoryColor,
                ),
                tooltip: loc.translate('calculator'),
                onPressed: _toggleCalculator,
              ),
            ],
          ),
        ),
        if (_showCalculator) ...[
          const SizedBox(height: 8),
          CalculatorKeyboard(
            controller: amountController,
            accentColor: categoryColor,
          ),
        ],
      ],
    );
  }

  Widget _buildCompactSecondaryBar(AppLocalizations loc, Color categoryColor, bool isDark) {
    return SingleChildScrollView(
      key: const Key('compactSecondaryBar'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Date Chip
          _buildCompactChip(
            key: const Key('compactDateChip'),
            icon: Icon(Icons.calendar_today, size: 16, color: categoryColor),
            label: _formatCompactDate(loc),
            onTap: _selectDate,
          ),
          const SizedBox(width: 8),
          // Members Chip
          _buildCompactChip(
            key: const Key('compactMembersChip'),
            icon: Icon(Icons.group, size: 16, color: categoryColor),
            label: _compactMembersLabel(loc),
            onTap: _openCompactMembersSheet,
          ),
          const SizedBox(width: 8),
          // Camera Chip
          _buildCompactChip(
            key: const Key('compactCameraChip'),
            icon: Icon(
              imagePaths.isNotEmpty ? Icons.check_circle : Icons.camera_alt,
              size: 16,
              color: imagePaths.isNotEmpty ? Colors.green : categoryColor,
            ),
            label: imagePaths.isNotEmpty ? '${imagePaths.length} ảnh' : loc.translate('receipt'),
            isActive: imagePaths.isNotEmpty,
            onTap: () => _pickImage(ImageSource.camera),
          ),
          const SizedBox(width: 8),
          // Expand Button (animated rotating icon)
          _buildCompactChip(
            key: const Key('expandToFullModeButton'),
            icon: RotationTransition(
              turns: _expandIconTurn,
              child: Icon(Icons.tune, size: 16, color: categoryColor),
            ),
            label: loc.translate('expand'),
            onTap: _switchToFullMode,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSplitChip(AppLocalizations loc, Color categoryColor, bool isDark) {
    return InkWell(
      key: const Key('compactSplitChip'),
      onTap: _openCompactSplitSheet,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.call_split, size: 18, color: categoryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _splitChipLabel(loc),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapseBar(AppLocalizations loc, Color categoryColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            key: const Key('collapseToCompactModeButton'),
            icon: const Icon(Icons.unfold_less, size: 18),
            label: Text(loc.translate('collapse')),
            style: TextButton.styleFrom(
              foregroundColor: categoryColor,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: _switchToCompactMode,
          ),
        ],
      ),
    );
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
  // Project selection handler & persistence
  // ────────────────────────────────────────
  static const String _lastSelectedProjectPrefKey = 'last_selected_project_id';

  void _saveLastSelectedProjectId(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSelectedProjectPrefKey, id);
    } catch (_) {}
  }

  Future<void> _resolveDefaultProject(List<Project> projects) async {
    if (!mounted || projects.isEmpty || selectedProject != null || widget.billToEdit != null) {
      return;
    }

    if (widget.projectId != null) {
      final match = projects.where((p) => p.id == widget.projectId).firstOrNull;
      if (match != null) {
        _applyProject(match);
        return;
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_lastSelectedProjectPrefKey);
      if (savedId != null) {
        final match = projects.where((p) => p.id == savedId).firstOrNull;
        if (match != null) {
          _applyProject(match);
          return;
        }
      }
    } catch (_) {}

    if (projects.isNotEmpty) {
      _applyProject(projects.first);
    }
  }

  void _applyProject(Project project) {
    if (!mounted) return;
    setState(() {
      selectedProject = project;
      projectMembers = List.from(project.members);
      if (widget.billToEdit == null && (selectedParticipants.isEmpty || !_hasUserExplicitlySelectedProject)) {
        selectedParticipants = Set.from(project.members);
        if (project.members.isNotEmpty && paidByController.text.isEmpty) {
          paidByController.text = project.members.first;
        }
      }
      _syncParticipantControllers();
    });
  }

  void _onProjectSelected(Project? project) {
    _hasUserExplicitlySelectedProject = true;
    if (project != null) {
      _saveLastSelectedProjectId(project.id);
    }
    setState(() {
      selectedProject = project;
      if (project == null) {
        if (manualParticipants.isEmpty && selectedParticipants.isNotEmpty) {
          manualParticipants.addAll(selectedParticipants);
        }
        projectMembers = [];
        selectedParticipants = {};
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
      _syncParticipantControllers();
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
    if (manualParticipants.isNotEmpty) {
      return manualParticipants;
    }
    return selectedParticipants.toList();
  }

  // ────────────────────────────────────────
  // Real-time Split Calculation
  double get _currentAmount {
    final text = amountController.text.trim();
    final direct = double.tryParse(text);
    if (direct != null) return direct;
    return CalculatorEvaluator.evaluate(text) ?? 0.0;
  }

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

    // AC 7: Cannot add bill without selecting project
    bool hasAvailableProjects = false;
    try {
      final projectBloc = context.read<ProjectBloc>();
      if (projectBloc.state is ProjectLoaded) {
        hasAvailableProjects = (projectBloc.state as ProjectLoaded).projects.isNotEmpty;
      }
    } catch (_) {}

    if (widget.requireProject || (hasAvailableProjects && widget.billToEdit == null)) {
      if (selectedProject == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: const Key('projectRequiredSnackBar'),
            content: Text(loc.translate('project_required')),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      }
    }

    if (_isCompactMode) {
      if (titleController.text.trim().isEmpty) {
        titleController.text = _getCategoryDisplayName(selectedCategoryItem, loc);
      }
      if (paidByController.text.trim().isEmpty) {
        paidByController.text = (selectedProject?.members.isNotEmpty == true)
            ? selectedProject!.members.first
            : 'You';
      }
      if (selectedParticipants.length < 2 && selectedProject != null && selectedProject!.members.length >= 2) {
        selectedParticipants = Set.from(selectedProject!.members);
        _syncParticipantControllers();
      }
    }

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

    final evalResult = CalculatorEvaluator.evaluate(amountController.text.trim());
    if (evalResult != null) {
      amountController.text = CalculatorEvaluator.formatResult(evalResult);
    }

    final amount = double.tryParse(amountController.text) ?? _currentAmount;
    if (amount <= 0) {
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

    final amount = double.tryParse(amountController.text) ?? _currentAmount;
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
      projectId: _hasUserExplicitlySelectedProject
          ? selectedProject?.id
          : (selectedProject?.id ?? widget.billToEdit?.projectId ?? widget.projectId),
      categoryIcon: selectedCategoryItem.icon,
      currency: selectedCurrency,
      imagePath: imagePaths.isNotEmpty ? imagePaths.first : null,
      imagePaths: List.from(imagePaths),
      categoryColor: selectedCategoryItem.colorHex,
      splitMode: _splitMode,
    );

    final billsBloc = context.read<BillsBloc>();
    BillTemplatesBloc? templatesBloc;
    try {
      templatesBloc = context.read<BillTemplatesBloc>();
    } catch (_) {}
    BillRepository? billRepo;
    try {
      billRepo = context.read<BillRepository>();
    } catch (_) {}

    if (_saveSplitModeAsDefault) {
      try {
        await DefaultSplitModeService.instance.setDefaultSplitModeForCategory(
          selectedCategoryItem.id,
          _splitMode,
        );
      } catch (_) {}
    }

    if (widget.billToEdit != null) {
      if (billRepo != null) {
        await billRepo.update(bill);
        billsBloc.add(const GetBillsEvent());
      } else {
        billsBloc.add(AddBillEvent(bill: bill));
      }
    } else {
      billsBloc.add(AddBillEvent(bill: bill));
    }
    if (_usedTemplateId != null && templatesBloc != null) {
      templatesBloc.add(RecordTemplateUsageEvent(_usedTemplateId!));
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
          TextButton(
            key: const Key('saveBillButton'),
            onPressed: _canSave ? _submitForm : null,
            child: Text(
              loc.translate('save'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _canSave
                    ? categoryColor
                    : (isDark ? Colors.white38 : Colors.black26),
              ),
            ),
          ),
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
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopProjectSelector(context, loc, isDark),
            // ── Animated mode sections ──────────────────────────
            // Compact content slides/fades out while Full content slides/fades in
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _isCompactMode
                  ? FadeTransition(
                      opacity: _compactFade,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          _buildCompactDescriptionField(loc, categoryColor, isDark),
                          const SizedBox(height: 12),
                          _buildCompactAmountField(loc, categoryColor, isDark),
                          const SizedBox(height: 12),
                          _buildCompactSecondaryBar(loc, categoryColor, isDark),
                          const SizedBox(height: 12),
                          _buildCompactSplitChip(loc, categoryColor, isDark),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              key: const Key('saveProjectButton'),
                              onPressed: _canSave ? _submitForm : null,
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
                          const SizedBox(height: 8),
                        ],
                      ),
                    )
                  : FadeTransition(
                      opacity: _fullFade,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          _buildCollapseBar(loc, categoryColor, isDark),
                          _buildQuickTemplatesSection(loc, isDark),
                          const SizedBox(height: 6),
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
            const SizedBox(height: 6),

            // ── 1. Title Section (CEO Clarification) ─────────────
            // LEFT: Circular badge with category icon + brand color
            // CENTER: Title input field (auto-filled)
            // RIGHT: Camera icon button + Clear (X) button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            const SizedBox(height: 6),

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
            const SizedBox(height: 4),
            SizedBox(
              height: 62,
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
                          width: 66,
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
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
                              Text(cat.icon, style: const TextStyle(fontSize: 18)),
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
            const SizedBox(height: 6),

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
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        key: const Key('receiptGalleryList'),
                        scrollDirection: Axis.horizontal,
                        itemCount: imagePaths.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                                  width: 76,
                                  height: 76,
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
                                                const Icon(Icons.image, size: 28, color: Colors.grey),
                                                const SizedBox(height: 2),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                                  child: Text(
                                                    path.split('/').last,
                                                    style: const TextStyle(fontSize: 8),
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
            const SizedBox(height: 6),

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
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
                          onSubmitted: (val) {
                            final evaluated = CalculatorEvaluator.evaluate(val);
                            if (evaluated != null) {
                              amountController.text = CalculatorEvaluator.formatResult(evaluated);
                            }
                          },
                        ),
                        if (CalculatorEvaluator.hasOperator(amountController.text.trim()) &&
                            CalculatorEvaluator.canEvaluate(amountController.text.trim()))
                          Text(
                            '= ${CalculatorEvaluator.formatResult(CalculatorEvaluator.evaluate(amountController.text.trim())!)}',
                            key: const Key('fullAmountCalcPreview'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        else if (CalculatorEvaluator.hasOperator(amountController.text.trim()) &&
                            !CalculatorEvaluator.canEvaluate(amountController.text.trim()) &&
                            amountController.text.trim().isNotEmpty)
                          Text(
                            loc.translate('invalid_expression'),
                            key: const Key('fullAmountCalcError'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.redAccent,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('fullToggleCalculatorButton'),
                    icon: Icon(
                      _showCalculator ? Icons.keyboard_hide : Icons.calculate_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: loc.translate('calculator'),
                    onPressed: _toggleCalculator,
                  ),
                ],
              ),
            ),
            if (_showCalculator) ...[
              const SizedBox(height: 8),
              CalculatorKeyboard(
                controller: amountController,
                accentColor: categoryColor,
              ),
            ],
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
                         ],     // full FT Column children
                       ),       // full FT Column
                     ),         // full FadeTransition
            ),                  // AnimatedSize
          ],     // outer Column children
        ),       // outer Column
      ),         // SingleChildScrollView
    );                          // return Scaffold
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
  // Top Project Selector & Picker (AC 1, AC 2, AC 3)
  // ────────────────────────────────────────
  void _openProjectPickerBottomSheet(
    BuildContext context,
    AppLocalizations loc,
    List<Project> projects,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              key: const Key('projectPickerBottomSheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    key: const Key('projectPickerDragHandle'),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      loc.translate('select_project_modal_title'),
                      key: const Key('projectPickerTitle'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      key: const Key('projectPickerCloseButton'),
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(bottomSheetContext).pop(),
                    ),
                  ],
                ),
                const Divider(),
                if (projects.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        loc.translate('project_no_members'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        ListTile(
                          key: const Key('projectPickerItem_none'),
                          leading: CircleAvatar(
                            backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            child: const Icon(Icons.clear, size: 18),
                          ),
                          title: Text(loc.translate('no_project')),
                          selected: selectedProject == null,
                          trailing: selectedProject == null
                              ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                              : null,
                          onTap: () {
                            _onProjectSelected(null);
                            Navigator.of(bottomSheetContext).pop();
                          },
                        ),
                        ...projects.map((p) {
                          final isSelected = selectedProject?.id == p.id;
                          final isBright = p.color.computeLuminance() > 0.5;
                          final iconColor = isBright ? Colors.black87 : Colors.white;
                          return ListTile(
                            key: Key('projectPickerItem_${p.id}'),
                            leading: CircleAvatar(
                              backgroundColor: p.color,
                              child: Icon(
                                p.iconData,
                                color: iconColor,
                                size: 18,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p.name,
                                    key: Key('projectItem_${p.id}'),
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                Container(
                                  key: Key('projectPickerColorChip_${p.id}'),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: p.color.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: p.color.withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: p.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(p.iconData, size: 12, color: p.color),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text('${p.members.length} members'),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: Theme.of(context).colorScheme.primary,
                                  )
                                : null,
                            onTap: () {
                              _onProjectSelected(p);
                              Navigator.of(bottomSheetContext).pop();
                            },
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopProjectSelector(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
  ) {
    return BlocConsumer<ProjectBloc, ProjectState>(
      listener: (context, state) {
        if (state is ProjectLoaded && !_hasUserExplicitlySelectedProject) {
          final targetId = widget.billToEdit?.projectId ?? widget.projectId;
          if (targetId != null) {
            final matching = state.projects.where((p) => p.id == targetId).firstOrNull;
            if (matching != null && (selectedProject?.id != matching.id || projectMembers.isEmpty)) {
              setState(() {
                selectedProject = matching;
                projectMembers = List.from(matching.members);
                if (widget.billToEdit == null && selectedParticipants.isEmpty) {
                  selectedParticipants = Set.from(matching.members);
                  if (matching.members.isNotEmpty && paidByController.text.isEmpty) {
                    paidByController.text = matching.members.first;
                  }
                  _syncParticipantControllers();
                }
              });
            }
          } else if (selectedProject == null && widget.billToEdit == null) {
            _resolveDefaultProject(state.projects);
          }
        }
      },
      builder: (context, state) {
        List<Project> projects = [];
        if (state is ProjectLoaded) {
          projects = state.projects;
        }

        Project? dropdownVal = selectedProject;
        if (dropdownVal != null) {
          dropdownVal = projects.where((p) => p.id == dropdownVal!.id).firstOrNull ?? dropdownVal;
        } else if (!_hasUserExplicitlySelectedProject) {
          final targetId = widget.billToEdit?.projectId ?? widget.projectId;
          if (targetId != null) {
            dropdownVal = projects.where((p) => p.id == targetId).firstOrNull;
          }
        }

        if (dropdownVal != null && !projects.any((p) => p == dropdownVal)) {
          dropdownVal = null;
        }

        final cardBg = isDark ? const Color(0xFF242424) : Colors.white;
        final cardBorder = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

        return Container(
          key: const Key('projectSelector'),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: selectedProject != null
                          ? selectedProject!.color.withOpacity(0.15)
                          : Theme.of(context).colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.folder_outlined,
                      color: selectedProject != null
                          ? selectedProject!.color
                          : Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.translate('select_project'),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                selectedProject?.name ??
                                    widget.projectName ??
                                    loc.translate('no_project_selected'),
                                key: const Key('selectedProjectName'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (selectedProject != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                key: const Key('projectSelectorColorChip'),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: selectedProject!.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selectedProject!.color.withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: selectedProject!.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      selectedProject!.iconData,
                                      size: 12,
                                      color: selectedProject!.color,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const Key('projectSelectorButton'),
                    onPressed: () => _openProjectPickerBottomSheet(context, loc, projects),
                    icon: const Icon(Icons.swap_horiz, size: 14),
                    label: Text(loc.translate('choose_project'), style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Dropdown field for direct dropdown picking and test backward-compatibility
              DropdownButtonFormField<Project?>(
                key: const Key('projectDropdown'),
                value: dropdownVal,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                  hintText: loc.translate('select_project'),
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
              ),
            ],
          ),
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
