import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/bill_filter.dart';
import '../../../../core/localization/app_localizations.dart';

class BillFilterBottomSheet extends StatefulWidget {
  final BillFilter initialFilter;
  final List<String> availablePersons;
  final List<String> availableCategories;
  final double maxBillAmount;
  final ValueChanged<BillFilter> onApply;
  final VoidCallback? onReset;

  const BillFilterBottomSheet({
    Key? key,
    required this.initialFilter,
    required this.availablePersons,
    required this.availableCategories,
    required this.maxBillAmount,
    required this.onApply,
    this.onReset,
  }) : super(key: key);

  static Future<BillFilter?> show({
    required BuildContext context,
    required BillFilter currentFilter,
    required List<String> availablePersons,
    required List<String> availableCategories,
    required double maxBillAmount,
  }) {
    return showModalBottomSheet<BillFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BillFilterBottomSheet(
        initialFilter: currentFilter,
        availablePersons: availablePersons,
        availableCategories: availableCategories,
        maxBillAmount: maxBillAmount,
        onApply: (filter) => Navigator.of(ctx).pop(filter),
        onReset: () {},
      ),
    );
  }

  @override
  State<BillFilterBottomSheet> createState() => _BillFilterBottomSheetState();
}

class _BillFilterBottomSheetState extends State<BillFilterBottomSheet> {
  late Set<String> _selectedPersons;
  late Set<String> _selectedCategories;
  DateTime? _fromDate;
  DateTime? _toDate;
  double? _minAmount;
  double? _maxAmount;
  late double _sliderMax;

  @override
  void initState() {
    super.initState();
    _selectedPersons = Set.from(widget.initialFilter.selectedPersons);
    _selectedCategories = Set.from(widget.initialFilter.selectedCategories);
    _fromDate = widget.initialFilter.fromDate;
    _toDate = widget.initialFilter.toDate;
    _minAmount = widget.initialFilter.minAmount;
    _maxAmount = widget.initialFilter.maxAmount;

    final upper = widget.maxBillAmount > 0 ? widget.maxBillAmount : 1000.0;
    _sliderMax = upper < 100 ? 100 : upper;
  }

  void _resetAll() {
    setState(() {
      _selectedPersons.clear();
      _selectedCategories.clear();
      _fromDate = null;
      _toDate = null;
      _minAmount = null;
      _maxAmount = null;
    });
    widget.onReset?.call();
  }

  BillFilter _buildFilter() {
    return widget.initialFilter.copyWith(
      selectedPersons: _selectedPersons,
      selectedCategories: _selectedCategories,
      fromDate: _fromDate,
      toDate: _toDate,
      minAmount: _minAmount,
      maxAmount: _maxAmount,
      clearDates: _fromDate == null && _toDate == null,
      clearAmounts: _minAmount == null && _maxAmount == null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentMin = _minAmount ?? 0.0;
    final currentMax = _maxAmount ?? _sliderMax;
    final clampedMin = currentMin.clamp(0.0, _sliderMax);
    final clampedMax = currentMax.clamp(clampedMin, _sliderMax);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header with Title and Reset
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.translate('filters'),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                key: const Key('resetFiltersButton'),
                onPressed: _resetAll,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(loc.translate('reset_filters')),
              ),
            ],
          ),
          const Divider(),

          // Scrollable Filter Sections
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. PERSON FILTER (Multi-select)
                  _buildSectionHeader(
                    context: context,
                    icon: Icons.person_outline,
                    title: loc.translate('filter_by_person'),
                    selectedCount: _selectedPersons.length,
                    onSelectAll: () {
                      setState(() {
                        if (_selectedPersons.length == widget.availablePersons.length) {
                          _selectedPersons.clear();
                        } else {
                          _selectedPersons = Set.from(widget.availablePersons);
                        }
                      });
                    },
                    isAllSelected: widget.availablePersons.isNotEmpty &&
                        _selectedPersons.length == widget.availablePersons.length,
                  ),
                  const SizedBox(height: 8),
                  if (widget.availablePersons.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        loc.translate('all_persons'),
                        style: theme.textTheme.bodySmall,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.availablePersons.map((person) {
                        final isSelected = _selectedPersons.contains(person);
                        return FilterChip(
                          key: Key('personFilterChip_$person'),
                          label: Text(person),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedPersons.add(person);
                              } else {
                                _selectedPersons.remove(person);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 20),

                  // 2. CATEGORY FILTER (Multi-select)
                  _buildSectionHeader(
                    context: context,
                    icon: Icons.category_outlined,
                    title: loc.translate('filter_by_category'),
                    selectedCount: _selectedCategories.length,
                    onSelectAll: () {
                      setState(() {
                        if (_selectedCategories.length == widget.availableCategories.length) {
                          _selectedCategories.clear();
                        } else {
                          _selectedCategories = Set.from(widget.availableCategories);
                        }
                      });
                    },
                    isAllSelected: widget.availableCategories.isNotEmpty &&
                        _selectedCategories.length == widget.availableCategories.length,
                  ),
                  const SizedBox(height: 8),
                  if (widget.availableCategories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        loc.translate('all_categories'),
                        style: theme.textTheme.bodySmall,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.availableCategories.map((category) {
                        final isSelected = _selectedCategories.contains(category);
                        return FilterChip(
                          key: Key('categoryFilterChip_$category'),
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add(category);
                              } else {
                                _selectedCategories.remove(category);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 20),

                  // 3. DATE RANGE FILTER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.date_range, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            loc.translate('filter_by_date'),
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (_fromDate != null || _toDate != null)
                        IconButton(
                          key: const Key('clearDateRangeButton'),
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: loc.translate('clear_filters'),
                          onPressed: () {
                            setState(() {
                              _fromDate = null;
                              _toDate = null;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('fromDateButton'),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _fromDate != null
                                ? DateFormat('dd/MM/yyyy').format(_fromDate!)
                                : loc.translate('from_date'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _fromDate != null ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _fromDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setState(() {
                                _fromDate = picked;
                                if (_toDate != null && _toDate!.isBefore(picked)) {
                                  _toDate = picked;
                                }
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('toDateButton'),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _toDate != null
                                ? DateFormat('dd/MM/yyyy').format(_toDate!)
                                : loc.translate('to_date'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _toDate != null ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _toDate ?? (_fromDate ?? DateTime.now()),
                              firstDate: _fromDate ?? DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setState(() {
                                _toDate = picked;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4. AMOUNT RANGE FILTER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.attach_money, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            loc.translate('filter_by_amount'),
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (_minAmount != null || _maxAmount != null)
                        IconButton(
                          key: const Key('clearAmountRangeButton'),
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: loc.translate('clear_filters'),
                          onPressed: () {
                            setState(() {
                              _minAmount = null;
                              _maxAmount = null;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Min: ${NumberFormat.currency(symbol: '', decimalDigits: 0).format(clampedMin)}',
                        key: const Key('minAmountText'),
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Max: ${NumberFormat.currency(symbol: '', decimalDigits: 0).format(clampedMax)}',
                        key: const Key('maxAmountText'),
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  RangeSlider(
                    key: const Key('amountRangeSlider'),
                    min: 0.0,
                    max: _sliderMax,
                    divisions: _sliderMax > 20 ? 20 : null,
                    values: RangeValues(clampedMin, clampedMax),
                    labels: RangeLabels(
                      NumberFormat.compact().format(clampedMin),
                      NumberFormat.compact().format(clampedMax),
                    ),
                    onChanged: (values) {
                      setState(() {
                        _minAmount = values.start;
                        _maxAmount = values.end;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          // Footer action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('clearAllFiltersSheetButton'),
                  onPressed: _resetAll,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(loc.translate('clear_all_filters')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  key: const Key('applyFiltersButton'),
                  onPressed: () {
                    final filter = _buildFilter();
                    widget.onApply(filter);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(loc.translate('apply_filters')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int selectedCount,
    required VoidCallback onSelectAll,
    required bool isAllSelected,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (selectedCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$selectedCount',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        TextButton(
          onPressed: onSelectAll,
          child: Text(
            isAllSelected ? 'None' : 'All',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
