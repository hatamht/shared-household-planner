import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/bill.dart';
import '../../domain/entities/bill_participant.dart';
import '../../domain/entities/category_icon.dart';
import '../../domain/services/smart_split_calculator.dart';
import '../bloc/bills_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../projects/domain/entities/project_settings.dart';

// ─── Category keyword maps for silent auto-detection ───
const Map<String, List<String>> _categoryKeywords = {
  'restaurant': ['food', 'lunch', 'dinner', 'breakfast', 'meal', 'eat', 'restaurant',
      'ăn trưa', 'ăn tối', 'ăn sáng', 'cơm', 'phở', 'bún', 'trưa', 'tối', 'sáng', 'quán', 'cafe', 'coffee', 'cà phê'],
  'transport': ['taxi', 'uber', 'grab', 'bus', 'car', 'gas', 'fuel', 'parking',
      'xe', 'xăng', 'đổ xăng', 'đậu xe', 'đi lại'],
  'shopping': ['shop', 'buy', 'store', 'market', 'mall', 'grocery', 'mua', 'siêu thị', 'chợ'],
  'entertainment': ['movie', 'film', 'game', 'netflix', 'concert', 'show', 'phim', 'trò chơi'],
  'health': ['doctor', 'medicine', 'pharmacy', 'hospital', 'thuốc', 'bệnh viện', 'khám'],
  'travel': ['hotel', 'flight', 'trip', 'travel', 'vacation', 'tour', 'khách sạn', 'vé máy bay', 'du lịch'],
  'utilities': ['electric', 'water', 'internet', 'rent', 'điện', 'nước', 'thuê nhà', 'wifi'],
  'party': ['party', 'birthday', 'event', 'tiệc', 'sinh nhật'],
  'sport': ['gym', 'sport', 'fitness', 'swimming', 'thể thao', 'bơi', 'gym'],
};

/// Silently detect category from description text.
/// Public for testing purposes.
String detectCategoryFromText(String text) {
  if (text.trim().isEmpty) return 'restaurant';
  final lower = text.toLowerCase();
  for (final entry in _categoryKeywords.entries) {
    for (final keyword in entry.value) {
      if (lower.contains(keyword)) return entry.key;
    }
  }
  return 'restaurant';
}

// Keep backward compat alias
String _detectCategory(String text) => detectCategoryFromText(text);


/// A streamlined bill entry screen with fast UX.
/// Shows only 2 primary inputs (Description + Amount) and compact secondary chips.
class FastAddBillScreen extends StatefulWidget {
  final ProjectSettings projectSettings;
  final List<String> projectMembers;
  final String? projectId;
  final String? currentUser; // "you" by default

  const FastAddBillScreen({
    Key? key,
    this.projectSettings = const ProjectSettings(),
    this.projectMembers = const [],
    this.projectId,
    this.currentUser,
  }) : super(key: key);

  @override
  State<FastAddBillScreen> createState() => FastAddBillScreenState();
}

class FastAddBillScreenState extends State<FastAddBillScreen> {
  late final TextEditingController _descController;
  late final TextEditingController _amountController;
  late final FocusNode _descFocusNode;
  late final FocusNode _amountFocusNode;

  DateTime _selectedDate = DateTime.now();
  Set<String> _selectedMembers = {};
  CategoryIconItem _detectedCategory = defaultCategoryIcons.first;
  String _splitMode = 'equal';
  String _paidBy = '';

  // Track if members were manually changed (reserved for future use)
  // ignore: unused_field
  bool _membersManuallyChanged = false;

  /// Exposed for testing purposes.
  FocusNode get descriptionFocusNode => _descFocusNode;


  @override
  void initState() {
    super.initState();
    _descController = TextEditingController();
    _amountController = TextEditingController();
    _descFocusNode = FocusNode();
    _amountFocusNode = FocusNode();

    // Pre-populate paid-by from currentUser or first project member
    _paidBy = widget.currentUser ?? (widget.projectMembers.isNotEmpty ? widget.projectMembers.first : '');

    // Pre-select all project members
    if (widget.projectMembers.isNotEmpty) {
      _selectedMembers = Set.from(widget.projectMembers);
    }

    _descController.addListener(_onDescChanged);
    _amountController.addListener(() => setState(() {}));

    // Auto-focus description on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _descFocusNode.requestFocus();
    });
  }

  void _onDescChanged() {
    final detected = _detectCategory(_descController.text);
    final matchedCat = defaultCategoryIcons.firstWhere(
      (c) => c.id == detected,
      orElse: () => defaultCategoryIcons.first,
    );
    if (matchedCat.id != _detectedCategory.id) {
      setState(() => _detectedCategory = matchedCat);
    } else {
      setState(() {}); // rebuild for save button state
    }
  }

  @override
  void dispose() {
    _descController.removeListener(_onDescChanged);
    _descController.dispose();
    _amountController.dispose();
    _descFocusNode.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  bool get _canSave {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    return amount > 0;
  }

  double get _currentAmount => double.tryParse(_amountController.text.trim()) ?? 0.0;

  // ─── Date helpers ────────────────────────────────────
  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String _formatDate(AppLocalizations loc) {
    if (_isToday) return loc.translate('today');
    return DateFormat('MMM d').format(_selectedDate);
  }

  // ─── Actions ─────────────────────────────────────────
  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _openMembersSheet() {
    FocusScope.of(context).unfocus();
    _showMembersBottomSheet();
  }

  void _showMembersBottomSheet() {
    final loc = AppLocalizations.of(context);
    // Temp selection state inside sheet
    Set<String> tempSelected = Set.from(_selectedMembers);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final allNames = widget.projectMembers.isNotEmpty
                ? widget.projectMembers
                : tempSelected.toList();
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.translate('select_participants'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (allNames.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        loc.translate('project_no_members'),
                        style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                      ),
                    )
                  else
                    ...allNames.map((name) {
                      final isSelected = tempSelected.contains(name);
                      return CheckboxListTile(
                        key: Key('fast_member_checkbox_$name'),
                        title: Text(name),
                        value: isSelected,
                        onChanged: (val) {
                          setSheetState(() {
                            if (val == true) {
                              tempSelected.add(name);
                            } else {
                              tempSelected.remove(name);
                            }
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                  // Add freetext member if no project
                  if (widget.projectMembers.isEmpty)
                    _AddMemberInline(
                      onAdd: (name) {
                        setSheetState(() => tempSelected.add(name));
                      },
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      key: const Key('fastMembersConfirmButton'),
                      onPressed: () {
                        setState(() {
                          _selectedMembers = Set.from(tempSelected);
                          _membersManuallyChanged = true;
                        });
                        Navigator.pop(sheetCtx);
                      },
                      child: Text(loc.translate('ok')),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openSplitSheet() {
    FocusScope.of(context).unfocus();
    _showSplitBottomSheet();
  }

  void _showSplitBottomSheet() {
    final loc = AppLocalizations.of(context);
    String tempSplitMode = _splitMode;
    String tempPaidBy = _paidBy;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allMembers = _selectedMembers.isNotEmpty
        ? _selectedMembers.toList()
        : (widget.projectMembers.isNotEmpty ? widget.projectMembers : [loc.translate('you')]);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.translate('split'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  // Paid By
                  Text(
                    loc.translate('paid_by'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allMembers.map((name) {
                      final selected = tempPaidBy == name;
                      return FilterChip(
                        key: Key('fast_paidby_chip_$name'),
                        label: Text(name),
                        selected: selected,
                        onSelected: (_) => setSheetState(() => tempPaidBy = name),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Split mode
                  Text(
                    loc.translate('split_mode'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SplitModeChip(
                        key: const Key('fast_split_equal_chip'),
                        label: loc.translate('split_mode_equal'),
                        icon: Icons.people_outline,
                        value: 'equal',
                        selected: tempSplitMode == 'equal',
                        onTap: () => setSheetState(() => tempSplitMode = 'equal'),
                      ),
                      _SplitModeChip(
                        key: const Key('fast_split_percentage_chip'),
                        label: loc.translate('split_mode_percentage'),
                        icon: Icons.percent,
                        value: 'percentage',
                        selected: tempSplitMode == 'percentage',
                        onTap: () => setSheetState(() => tempSplitMode = 'percentage'),
                      ),
                      _SplitModeChip(
                        key: const Key('fast_split_shares_chip'),
                        label: loc.translate('split_mode_shares'),
                        icon: Icons.pie_chart_outline,
                        value: 'shares',
                        selected: tempSplitMode == 'shares',
                        onTap: () => setSheetState(() => tempSplitMode = 'shares'),
                      ),
                      _SplitModeChip(
                        key: const Key('fast_split_custom_chip'),
                        label: loc.translate('split_mode_custom'),
                        icon: Icons.tune,
                        value: 'custom',
                        selected: tempSplitMode == 'custom',
                        onTap: () => setSheetState(() => tempSplitMode = 'custom'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      key: const Key('fastSplitConfirmButton'),
                      onPressed: () {
                        setState(() {
                          _splitMode = tempSplitMode;
                          _paidBy = tempPaidBy;
                        });
                        Navigator.pop(sheetCtx);
                      },
                      child: Text(loc.translate('ok')),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _submitBill() {
    final amount = _currentAmount;
    if (amount <= 0) return;

    final description = _descController.text.trim();
    final title = description.isEmpty
        ? _detectedCategory.nameKey
        : description;

    final paidBy = _paidBy.isNotEmpty ? _paidBy : 'You';

    // Build participants
    final participants = _selectedMembers.isNotEmpty
        ? _selectedMembers.toList()
        : [paidBy];

    final List<BillParticipant> billParticipants =
        SmartSplitCalculator.calculateEqual(
      totalAmount: amount,
      participantNames: participants.length >= 2 ? participants : [paidBy, paidBy],
    );

    final bill = Bill(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      category: _detectedCategory.id,
      date: _selectedDate,
      paidBy: paidBy,
      participants: billParticipants,
      projectId: widget.projectId,
      categoryIcon: _detectedCategory.icon,
      currency: widget.projectSettings.defaultCurrency,
      splitMode: _splitMode,
    );

    try {
      context.read<BillsBloc>().add(AddBillEvent(bill: bill));
    } catch (_) {}

    if (mounted) Navigator.pop(context);
  }

  // ─── Split chip label ────────────────────────────────
  String _splitChipLabel(AppLocalizations loc) {
    final paidLabel = _paidBy.isNotEmpty ? _paidBy : loc.translate('you');
    switch (_splitMode) {
      case 'equal':
        return loc.translate('fast_split_equal_label')
            .replaceAll('{payer}', paidLabel);
      case 'percentage':
        return '${loc.translate('paid_by')} $paidLabel · ${loc.translate('split_mode_percentage')}';
      case 'shares':
        return '${loc.translate('paid_by')} $paidLabel · ${loc.translate('split_mode_shares')}';
      case 'custom':
        return '${loc.translate('paid_by')} $paidLabel · ${loc.translate('split_mode_custom')}';
      default:
        return '${loc.translate('paid_by')} $paidLabel · ${loc.translate('split_mode_equal')}';
    }
  }

  // ─── Build ───────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final catColor = _detectedCategory.color;

    final membersLabel = _selectedMembers.isEmpty
        ? loc.translate('members')
        : (_selectedMembers.length == 1
            ? _selectedMembers.first
            : '${_selectedMembers.length} ${loc.translate('members')}');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        key: const Key('fastAddBillAppBar'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          key: const Key('fastAddBillCloseButton'),
          icon: const Icon(Icons.close),
          tooltip: loc.translate('cancel'),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _detectedCategory.icon,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 6),
            Text(
              loc.translate('add_bill'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              key: const Key('fastSaveButton'),
              onPressed: _canSave ? _submitBill : null,
              style: TextButton.styleFrom(
                foregroundColor: _canSave ? colorScheme.primary : Colors.grey,
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              child: Text(loc.translate('save')),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Primary input 1: Description ─────────────────────
                  _buildDescriptionField(loc, isDark, catColor),
                  const SizedBox(height: 20),

                  // ── Primary input 2: Amount ──────────────────────────
                  _buildAmountField(loc, isDark, colorScheme),
                  const SizedBox(height: 28),

                  // ── Secondary bar: chips row ─────────────────────────
                  _buildSecondaryBar(loc, isDark, colorScheme, membersLabel),
                  const SizedBox(height: 20),

                  // ── Split chip ───────────────────────────────────────
                  _buildSplitChip(loc, isDark, colorScheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField(AppLocalizations loc, bool isDark, Color catColor) {
    return Container(
      key: const Key('fastDescriptionContainer'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _descFocusNode.hasFocus
              ? catColor
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          width: _descFocusNode.hasFocus ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.translate('description'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              // Category emoji from auto-detect
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _detectedCategory.icon,
                    key: ValueKey(_detectedCategory.id),
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  key: const Key('fastDescriptionField'),
                  controller: _descController,
                  focusNode: _descFocusNode,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: loc.translate('fast_description_hint'),
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white30 : Colors.black26,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) {}, // handled by listener
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField(AppLocalizations loc, bool isDark, ColorScheme colorScheme) {
    return Container(
      key: const Key('fastAmountContainer'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _amountFocusNode.hasFocus
              ? colorScheme.primary
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          width: _amountFocusNode.hasFocus ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.translate('amount'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _currencySymbol,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: isDark ? Colors.white54 : Colors.black38,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const Key('fastAmountField'),
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: _currentAmount > 0
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? Colors.white38 : Colors.black26),
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.09),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              // Currency label
              Text(
                widget.projectSettings.defaultCurrency,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryBar(
    AppLocalizations loc,
    bool isDark,
    ColorScheme colorScheme,
    String membersLabel,
  ) {
    final chipBg = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
    final chipBorder = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return SingleChildScrollView(
      key: const Key('fastSecondaryBar'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Date chip
          _SecondaryChip(
            key: const Key('fastDateChip'),
            icon: Icons.calendar_today_outlined,
            label: _formatDate(loc),
            bgColor: chipBg,
            borderColor: chipBorder,
            onTap: _pickDate,
          ),
          const SizedBox(width: 8),

          // Members chip
          _SecondaryChip(
            key: const Key('fastMembersChip'),
            icon: Icons.people_outline,
            label: membersLabel,
            bgColor: chipBg,
            borderColor: chipBorder,
            onTap: _openMembersSheet,
          ),
          const SizedBox(width: 8),

          // Camera chip
          _SecondaryChip(
            key: const Key('fastCameraChip'),
            icon: Icons.camera_alt_outlined,
            label: loc.translate('camera'),
            bgColor: chipBg,
            borderColor: chipBorder,
            onTap: () {
              // Camera: open AddBillScreen for full flow
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.translate('fast_camera_hint'))),
              );
            },
          ),
          const SizedBox(width: 8),

          // More chip → navigate to full AddBillScreen
          _SecondaryChip(
            key: const Key('fastMoreChip'),
            icon: Icons.tune,
            label: loc.translate('more'),
            bgColor: chipBg,
            borderColor: chipBorder,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.translate('fast_more_hint'))),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSplitChip(AppLocalizations loc, bool isDark, ColorScheme colorScheme) {
    return GestureDetector(
      key: const Key('fastSplitChip'),
      onTap: _openSplitSheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(isDark ? 0.15 : 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: colorScheme.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _splitChipLabel(loc),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  String get _currencySymbol {
    return currencySymbols[widget.projectSettings.defaultCurrency] ??
        widget.projectSettings.defaultCurrency;
  }
}

// ─── Helper widgets ──────────────────────────────────────────────────────────

class _SecondaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _SecondaryChip({
    Key? key,
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isDark ? Colors.white70 : Colors.black54),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _SplitModeChip({
    Key? key,
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colorScheme.primary : Colors.grey.shade400,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? colorScheme.primary : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? colorScheme.primary : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline add member widget for the members sheet (no-project flow).
class _AddMemberInline extends StatefulWidget {
  final void Function(String name) onAdd;

  const _AddMemberInline({required this.onAdd});

  @override
  State<_AddMemberInline> createState() => _AddMemberInlineState();
}

class _AddMemberInlineState extends State<_AddMemberInline> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('fastAddMemberField'),
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: loc.translate('enter_name'),
                isDense: true,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              textCapitalization: TextCapitalization.words,
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  widget.onAdd(val.trim());
                  _ctrl.clear();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            key: const Key('fastAddMemberButton'),
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              if (_ctrl.text.trim().isNotEmpty) {
                widget.onAdd(_ctrl.text.trim());
                _ctrl.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
