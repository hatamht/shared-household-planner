import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/bill_filter.dart';
import '../../../../core/localization/app_localizations.dart';
import 'bill_filter_bottom_sheet.dart';

class BillSearchFilterBar extends StatefulWidget {
  final BillFilter filter;
  final int resultCount;
  final List<String> availablePersons;
  final List<String> availableCategories;
  final double maxBillAmount;
  final ValueChanged<BillFilter> onFilterChanged;
  final VoidCallback onClearAllFilters;

  const BillSearchFilterBar({
    Key? key,
    required this.filter,
    required this.resultCount,
    required this.availablePersons,
    required this.availableCategories,
    required this.maxBillAmount,
    required this.onFilterChanged,
    required this.onClearAllFilters,
  }) : super(key: key);

  @override
  State<BillSearchFilterBar> createState() => _BillSearchFilterBarState();
}

class _BillSearchFilterBarState extends State<BillSearchFilterBar> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.filter.searchQuery);
  }

  @override
  void didUpdateWidget(covariant BillSearchFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter.searchQuery != widget.filter.searchQuery &&
        _searchController.text != widget.filter.searchQuery) {
      _searchController.text = widget.filter.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet() async {
    final updated = await BillFilterBottomSheet.show(
      context: context,
      currentFilter: widget.filter,
      availablePersons: widget.availablePersons,
      availableCategories: widget.availableCategories,
      maxBillAmount: widget.maxBillAmount,
    );
    if (updated != null) {
      widget.onFilterChanged(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nonTextCount = widget.filter.nonTextFilterCount;

    final resultText = widget.resultCount == 1
        ? '1 ${loc.translate('bill_found')}'
        : '${widget.resultCount} ${loc.translate('bills_found')}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Search Bar with Filter Button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                    ),
                  ),
                  child: TextField(
                    key: const Key('searchBillsTextField'),
                    controller: _searchController,
                    onChanged: (val) {
                      widget.onFilterChanged(
                        widget.filter.copyWith(searchQuery: val),
                      );
                    },
                    decoration: InputDecoration(
                      hintText: loc.translate('search_hint'),
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 22),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              key: const Key('clearSearchQueryButton'),
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                widget.onFilterChanged(
                                  widget.filter.copyWith(searchQuery: ''),
                                );
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Filter Sheet Button
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: nonTextCount > 0
                          ? theme.colorScheme.primary.withOpacity(0.15)
                          : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: nonTextCount > 0
                            ? theme.colorScheme.primary
                            : (isDark ? Colors.white12 : Colors.grey.shade300),
                      ),
                    ),
                    child: IconButton(
                      key: const Key('openFilterSheetButton'),
                      icon: Icon(
                        Icons.tune,
                        color: nonTextCount > 0
                            ? theme.colorScheme.primary
                            : (isDark ? Colors.white70 : Colors.grey.shade700),
                      ),
                      tooltip: loc.translate('filters'),
                      onPressed: _openFilterSheet,
                    ),
                  ),
                  if (nonTextCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$nonTextCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // 2. Horizontal Quick Filter Chips
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Person Chip
              _buildQuickChip(
                key: const Key('personFilterQuickChip'),
                icon: Icons.person_outline,
                label: widget.filter.selectedPersons.isEmpty
                    ? loc.translate('filter_by_person')
                    : '${widget.filter.selectedPersons.length} ${loc.translate('filter_by_person')}',
                isSelected: widget.filter.selectedPersons.isNotEmpty,
                onTap: _openFilterSheet,
                onDeleted: widget.filter.selectedPersons.isNotEmpty
                    ? () {
                        widget.onFilterChanged(
                          widget.filter.copyWith(selectedPersons: const {}),
                        );
                      }
                    : null,
              ),
              const SizedBox(width: 8),

              // Category Chip
              _buildQuickChip(
                key: const Key('categoryFilterQuickChip'),
                icon: Icons.category_outlined,
                label: widget.filter.selectedCategories.isEmpty
                    ? loc.translate('filter_by_category')
                    : '${widget.filter.selectedCategories.length} ${loc.translate('filter_by_category')}',
                isSelected: widget.filter.selectedCategories.isNotEmpty,
                onTap: _openFilterSheet,
                onDeleted: widget.filter.selectedCategories.isNotEmpty
                    ? () {
                        widget.onFilterChanged(
                          widget.filter.copyWith(selectedCategories: const {}),
                        );
                      }
                    : null,
              ),
              const SizedBox(width: 8),

              // Date Range Chip
              _buildQuickChip(
                key: const Key('dateFilterQuickChip'),
                icon: Icons.date_range,
                label: widget.filter.fromDate != null || widget.filter.toDate != null
                    ? '${widget.filter.fromDate != null ? DateFormat('dd/MM').format(widget.filter.fromDate!) : '...'} - ${widget.filter.toDate != null ? DateFormat('dd/MM').format(widget.filter.toDate!) : '...'}'
                    : loc.translate('filter_by_date'),
                isSelected: widget.filter.fromDate != null || widget.filter.toDate != null,
                onTap: _openFilterSheet,
                onDeleted: widget.filter.fromDate != null || widget.filter.toDate != null
                    ? () {
                        widget.onFilterChanged(
                          widget.filter.copyWith(clearDates: true),
                        );
                      }
                    : null,
              ),
              const SizedBox(width: 8),

              // Amount Range Chip
              _buildQuickChip(
                key: const Key('amountFilterQuickChip'),
                icon: Icons.attach_money,
                label: widget.filter.minAmount != null || widget.filter.maxAmount != null
                    ? '${NumberFormat.compact().format(widget.filter.minAmount ?? 0)} - ${NumberFormat.compact().format(widget.filter.maxAmount ?? widget.maxBillAmount)}'
                    : loc.translate('filter_by_amount'),
                isSelected: widget.filter.minAmount != null || widget.filter.maxAmount != null,
                onTap: _openFilterSheet,
                onDeleted: widget.filter.minAmount != null || widget.filter.maxAmount != null
                    ? () {
                        widget.onFilterChanged(
                          widget.filter.copyWith(clearAmounts: true),
                        );
                      }
                    : null,
              ),

              // Clear all button chip if active
              if (widget.filter.isActive) ...[
                const SizedBox(width: 8),
                ActionChip(
                  key: const Key('clearAllFiltersButton'),
                  avatar: const Icon(Icons.close, size: 14),
                  label: Text(
                    loc.translate('clear_all_filters'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    widget.onClearAllFilters();
                  },
                ),
              ],
            ],
          ),
        ),

        // 3. Result Count & Summary Row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                resultText,
                key: const Key('resultCountText'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              if (widget.filter.isActive)
                TextButton(
                  key: const Key('clearAllFiltersHeaderButton'),
                  onPressed: () {
                    _searchController.clear();
                    widget.onClearAllFilters();
                  },
                  child: Text(
                    loc.translate('clear_all_filters'),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChip({
    required Key key,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onDeleted,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InputChip(
      key: key,
      avatar: Icon(
        icon,
        size: 14,
        color: isSelected
            ? theme.colorScheme.primary
            : (isDark ? Colors.white60 : Colors.black54),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? theme.colorScheme.primary
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      onDeleted: onDeleted,
      deleteIconColor: theme.colorScheme.primary,
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
      selectedColor: theme.colorScheme.primary.withOpacity(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : (isDark ? Colors.white12 : Colors.grey.shade300),
        ),
      ),
    );
  }
}
