import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/bills_bloc.dart';
import '../widgets/bill_card.dart';
import '../widgets/stats_card.dart';
import '../../domain/entities/bill.dart';
import '../../domain/entities/bill_participant.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/bill_filter.dart';
import '../../domain/services/bill_filter_persistence_service.dart';
import '../widgets/bill_search_filter_bar.dart';
import 'add_bill_screen.dart';


import '../../../projects/domain/entities/project.dart';
import '../../../projects/presentation/bloc/project_bloc.dart';

enum BillGroupingMode { project, date }

class BillsListScreen extends StatefulWidget {
  final BillFilter? initialFilter;
  final BillFilterPersistenceService? persistenceService;
  final BillGroupingMode initialGroupingMode;

  const BillsListScreen({
    Key? key,
    this.initialFilter,
    this.persistenceService,
    this.initialGroupingMode = BillGroupingMode.project,
  }) : super(key: key);

  @override
  State<BillsListScreen> createState() => _BillsListScreenState();
}

class _BillsListScreenState extends State<BillsListScreen> {
  late BillFilter _filter;
  late final BillFilterPersistenceService _persistenceService;
  late BillGroupingMode _groupingMode;
  final Set<String> _collapsedProjectIds = <String>{};

  @override
  void initState() {
    super.initState();
    _persistenceService = widget.persistenceService ?? const BillFilterPersistenceService();
    _filter = widget.initialFilter ?? BillFilterPersistenceService.currentFilter;
    _groupingMode = widget.initialGroupingMode;
    _loadSavedFilter();
    context.read<BillsBloc>().add(const GetBillsEvent());
  }

  Future<void> _loadSavedFilter() async {
    if (widget.initialFilter == null) {
      final saved = await _persistenceService.loadFilter();
      if (mounted) {
        setState(() {
          _filter = saved;
        });
      }
    }
  }

  void _onFilterChanged(BillFilter newFilter) {
    setState(() {
      _filter = newFilter;
    });
    _persistenceService.saveFilter(newFilter);
  }

  void _onClearAllFilters() {
    setState(() {
      _filter = const BillFilter.initial();
    });
    _persistenceService.clearFilter();
  }

  bool _isProjectExpanded(String id) => !_collapsedProjectIds.contains(id);

  void _toggleProjectExpand(String id) {
    setState(() {
      if (_collapsedProjectIds.contains(id)) {
        _collapsedProjectIds.remove(id);
      } else {
        _collapsedProjectIds.add(id);
      }
    });
  }

  void _toggleExpandCollapseAll(List<_ProjectSectionData> sections) {
    setState(() {
      if (_collapsedProjectIds.isEmpty) {
        _collapsedProjectIds.addAll(sections.map((s) => s.id));
      } else {
        _collapsedProjectIds.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('bills')),
        elevation: 0,
      ),
      body: BlocBuilder<BillsBloc, BillsState>(
        builder: (context, state) {
          if (state is BillsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BillsLoaded) {
            return _buildBillsList(context, state.bills);
          } else if (state is BillsError) {
            return Center(child: Text(loc.translate('error')));
          }
          return Center(child: Text(loc.translate('no_bills')));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBillDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBillsList(BuildContext context, List<Bill> allBills) {
    ProjectBloc? projectBloc;
    try {
      projectBloc = BlocProvider.of<ProjectBloc>(context);
    } catch (_) {
      projectBloc = null;
    }

    if (projectBloc != null) {
      return BlocBuilder<ProjectBloc, ProjectState>(
        bloc: projectBloc,
        builder: (context, projectState) {
          final projects = projectState is ProjectLoaded ? projectState.projects : <Project>[];
          return _buildBillsContent(context, allBills, projects);
        },
      );
    }

    return _buildBillsContent(context, allBills, const <Project>[]);
  }

  List<_ProjectSectionData> _buildSections(
    List<Bill> filteredBills,
    List<Project> displayProjects,
    AppLocalizations loc,
  ) {
    final List<_ProjectSectionData> sections = [];

    for (final project in displayProjects) {
      final pBills = filteredBills.where((b) => b.projectId == project.id).toList();
      if (pBills.isNotEmpty) {
        final total = pBills.fold<double>(0.0, (sum, b) => sum + b.amount);
        sections.add(_ProjectSectionData(
          id: project.id,
          title: project.name,
          icon: project.iconData,
          color: project.color,
          currencySymbol: project.currencySymbol,
          bills: pBills,
          totalAmount: total,
          isGeneral: false,
        ));
      }
    }

    final generalBills = filteredBills
        .where((b) =>
            b.projectId == null ||
            b.projectId!.isEmpty ||
            b.projectId == 'none' ||
            b.projectId == 'general')
        .toList();
    if (generalBills.isNotEmpty) {
      final total = generalBills.fold<double>(0.0, (sum, b) => sum + b.amount);
      sections.add(_ProjectSectionData(
        id: 'general',
        title: loc.translate('general_expenses'),
        icon: Icons.receipt_long_outlined,
        color: Colors.blueGrey,
        currencySymbol: '₫',
        bills: generalBills,
        totalAmount: total,
        isGeneral: true,
      ));
    }

    return sections;
  }

  Widget _buildBillsContent(BuildContext context, List<Bill> allBills, List<Project> projects) {
    final loc = AppLocalizations.of(context);

    if (allBills.isEmpty) {
      return Center(
        child: Text(loc.translate('no_bills')),
      );
    }

    final availablePersons = allBills
        .expand((b) => [b.paidBy, ...b.participants.map((p) => p.name)])
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final availableCategories = allBills
        .map((b) => b.category)
        .where((cat) => cat.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final maxBillAmount = allBills.isEmpty
        ? 1000.0
        : allBills.map((b) => b.amount).reduce((a, b) => a > b ? a : b);

    final filteredBills = _filter.apply(allBills);

    final projectMap = {for (final p in projects) p.id: p};
    final extraProjectIds = allBills
        .map((b) => b.projectId)
        .where((id) => id != null && id.isNotEmpty && !projectMap.containsKey(id))
        .cast<String>()
        .toSet();

    final displayProjects = [
      ...projects,
      ...extraProjectIds.map((id) => Project(
            id: id,
            name: id,
            members: const [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )),
    ];

    final hasUnassignedBills = allBills.any(
      (b) =>
          b.projectId == null ||
          b.projectId!.isEmpty ||
          b.projectId == 'none' ||
          b.projectId == 'general',
    );

    final sections = _buildSections(filteredBills, displayProjects, loc);

    return Column(
      children: [
        BillSearchFilterBar(
          filter: _filter,
          resultCount: filteredBills.length,
          availablePersons: availablePersons,
          availableCategories: availableCategories,
          maxBillAmount: maxBillAmount,
          onFilterChanged: _onFilterChanged,
          onClearAllFilters: _onClearAllFilters,
        ),
        _buildProjectFilterChips(context, displayProjects, hasUnassignedBills),
        _buildGroupingToggleBar(context, sections),
        Expanded(
          child: filteredBills.isEmpty
              ? _buildEmptyState(context, loc)
              : _groupingMode == BillGroupingMode.project
                  ? _buildProjectGroupedList(context, sections, loc)
                  : _buildDateGroupedList(context, filteredBills),
        ),
      ],
    );
  }

  Widget _buildProjectFilterChips(
    BuildContext context,
    List<Project> displayProjects,
    bool hasUnassignedBills,
  ) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isAllSelected = _filter.selectedProjectId == null ||
        _filter.selectedProjectId == 'all';
    final isNoneSelected = _filter.selectedProjectId == 'none' ||
        _filter.selectedProjectId == 'general';

    return SingleChildScrollView(
      key: const Key('projectFilterChipsBar'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // "All Projects" chip
          FilterChip(
            key: const Key('projectFilterChip_all'),
            selected: isAllSelected,
            showCheckmark: false,
            avatar: Icon(
              Icons.apps,
              size: 16,
              color: isAllSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            label: Text(loc.translate('all_projects')),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isAllSelected ? FontWeight.bold : FontWeight.normal,
              color: isAllSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
            selectedColor: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (_) {
              if (!isAllSelected) {
                _onFilterChanged(
                  _filter.copyWith(selectedProjectId: null, clearProject: true),
                );
              }
            },
          ),
          const SizedBox(width: 8),

          // Chips for each project
          ...displayProjects.map((project) {
            final isSelected = _filter.selectedProjectId == project.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                key: Key('projectFilterChip_${project.id}'),
                selected: isSelected,
                showCheckmark: false,
                avatar: Icon(
                  project.iconData,
                  size: 16,
                  color: isSelected ? Colors.white : project.color,
                ),
                label: Text(project.name),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                ),
                selectedColor: project.color,
                backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (selected) {
                  _onFilterChanged(
                    _filter.copyWith(
                      selectedProjectId: selected ? project.id : null,
                      clearProject: !selected,
                    ),
                  );
                },
              ),
            );
          }),

          // "General Expenses" chip
          if (hasUnassignedBills || displayProjects.isNotEmpty) ...[
            FilterChip(
              key: const Key('projectFilterChip_none'),
              selected: isNoneSelected,
              showCheckmark: false,
              avatar: Icon(
                Icons.receipt_long_outlined,
                size: 16,
                color: isNoneSelected ? Colors.white : Colors.blueGrey,
              ),
              label: Text(loc.translate('general_expenses')),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isNoneSelected ? FontWeight.bold : FontWeight.normal,
                color: isNoneSelected ? Colors.white : theme.colorScheme.onSurface,
              ),
              selectedColor: Colors.blueGrey,
              backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (selected) {
                _onFilterChanged(
                  _filter.copyWith(
                    selectedProjectId: selected ? 'none' : null,
                    clearProject: !selected,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupingToggleBar(BuildContext context, List<_ProjectSectionData> sections) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isProject = _groupingMode == BillGroupingMode.project;
    final allExpanded = _collapsedProjectIds.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      key: const Key('groupByProjectToggle'),
                      onTap: () {
                        if (!isProject) {
                          setState(() => _groupingMode = BillGroupingMode.project);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isProject ? theme.colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 14,
                              color: isProject
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                loc.translate('group_by_project'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isProject
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      key: const Key('groupByDateToggle'),
                      onTap: () {
                        if (isProject) {
                          setState(() => _groupingMode = BillGroupingMode.date);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: !isProject ? theme.colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              size: 14,
                              color: !isProject
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                loc.translate('group_by_date'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: !isProject
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isProject && sections.isNotEmpty) ...[
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('expandCollapseAllButton'),
                onTap: () => _toggleExpandCollapseAll(sections),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  key: Key(allExpanded ? 'collapseAllButton' : 'expandAllButton'),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        allExpanded ? Icons.unfold_less : Icons.unfold_more,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        allExpanded ? loc.translate('collapse_all') : loc.translate('expand_all'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectGroupedList(
    BuildContext context,
    List<_ProjectSectionData> sections,
    AppLocalizations loc,
  ) {
    if (sections.isEmpty) {
      return _buildEmptyState(context, loc);
    }

    return ListView.builder(
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        final isExpanded = _isProjectExpanded(section.id);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProjectSectionHeader(
              context,
              projectId: section.id,
              title: section.title,
              icon: section.icon,
              color: section.color,
              currencySymbol: section.currencySymbol,
              totalAmount: section.totalAmount,
              billCount: section.bills.length,
              isGeneral: section.isGeneral,
              isExpanded: isExpanded,
              onTap: () => _toggleProjectExpand(section.id),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Column(
                      children: section.bills.map(
                        (bill) => BillCard(
                          bill: bill,
                          projectName: section.title,
                          projectColor: section.color,
                          projectIcon: section.icon,
                        ),
                      ).toList(),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateGroupedList(BuildContext context, List<Bill> filteredBills) {
    Map<String, List<Bill>> groupedBills = {};
    for (var bill in filteredBills) {
      final monthYear = DateFormat('MMM yyyy', Localizations.localeOf(context).languageCode).format(bill.date);
      if (!groupedBills.containsKey(monthYear)) {
        groupedBills[monthYear] = [];
      }
      groupedBills[monthYear]!.add(bill);
    }

    return ListView.builder(
      itemCount: groupedBills.keys.length,
      itemBuilder: (context, index) {
        final monthYear = groupedBills.keys.elementAt(index);
        final monthBills = groupedBills[monthYear]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                monthYear,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            StatsCard(bills: monthBills),
            ...monthBills.map((bill) => BillCard(bill: bill)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations loc) {
    return Center(
      key: const Key('noMatchingBillsEmptyState'),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              loc.translate('no_matching_bills'),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              key: const Key('clearFiltersEmptyStateButton'),
              onPressed: _onClearAllFilters,
              icon: const Icon(Icons.clear_all),
              label: Text(loc.translate('clear_all_filters')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectSectionHeader(
    BuildContext context, {
    required String projectId,
    required String title,
    required IconData icon,
    required Color color,
    required String currencySymbol,
    required double totalAmount,
    required int billCount,
    required bool isGeneral,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyDisplay = currencySymbol == 'VND' ? ' đ' : ' $currencySymbol';
    final formattedTotal = '${NumberFormat('#,##0.##').format(totalAmount)}$currencyDisplay';
    final billCountText = billCount == 1
        ? loc.translate('bill_count_singular')
        : '$billCount ${loc.translate('bill_count_plural')}';

    return KeyedSubtree(
      key: Key('projectSectionHeader_$projectId'),
      child: Container(
        key: isGeneral ? const Key('projectSectionHeader_none') : null,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surface
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(isDark ? 0.4 : 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            key: Key('projectSectionHeaderInk_$projectId'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          billCountText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        loc.translate('project_expense_total'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedTotal,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.0 : -0.25,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      key: Key('projectChevron_$projectId'),
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddBillDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddBillScreen(),
      ),
    );
  }
}

class _ProjectSectionData {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String currencySymbol;
  final List<Bill> bills;
  final double totalAmount;
  final bool isGeneral;

  const _ProjectSectionData({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.currencySymbol,
    required this.bills,
    required this.totalAmount,
    required this.isGeneral,
  });
}

class AddBillDialog extends StatefulWidget {
  const AddBillDialog({Key? key}) : super(key: key);

  @override
  State<AddBillDialog> createState() => _AddBillDialogState();
}

class _AddBillDialogState extends State<AddBillDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _paidByController = TextEditingController();
  final _participantsController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _paidByController.dispose();
    _participantsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(loc.translate('add_bill')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: loc.translate('bill_name'),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.translate('name_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: loc.translate('amount'),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.translate('amount_required');
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return loc.translate('amount_positive');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: loc.translate('category'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _paidByController,
                decoration: InputDecoration(
                  labelText: loc.translate('payer'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _participantsController,
                decoration: InputDecoration(
                  labelText: loc.translate('participants'),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.translate('participants_required');
                  }
                  final count = value.split(',').length;
                  if (count < 2) {
                    return loc.translate('participants_min');
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.translate('cancel')),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final participantNames = _participantsController.text.split(',').map((e) => e.trim()).toList();
              final participants = participantNames
                  .asMap()
                  .entries
                  .map((e) => BillParticipant(
                    participantId: 'p${e.key}',
                    name: e.value,
                    amount: double.parse(_amountController.text) / participantNames.length,
                  ))
                  .toList();

              final bill = Bill(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: _titleController.text,
                amount: double.parse(_amountController.text),
                category: _categoryController.text,
                date: DateTime.now(),
                paidBy: _paidByController.text,
                participants: participants,
              );

              context.read<BillsBloc>().add(AddBillEvent(bill: bill));
              Navigator.pop(context);
            }
          },
          child: Text(loc.translate('add')),
        ),
      ],
    );
  }
}
