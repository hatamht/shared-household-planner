import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/presentation/bloc/project_bloc.dart';
import '../../../split_bills/domain/entities/bill.dart';
import '../../../split_bills/presentation/bloc/bills_bloc.dart';
import '../../domain/entities/export_options.dart';
import '../../domain/services/export_filename_builder.dart';
import '../../domain/services/export_service.dart';

/// Screen for configuring and executing data exports (CSV / PDF) with project and date filters.
class ExportDataScreen extends StatefulWidget {
  final ExportFormat initialFormat;
  final String? initialProjectId;
  final ExportService exportService;

  const ExportDataScreen({
    super.key,
    this.initialFormat = ExportFormat.csv,
    this.initialProjectId,
    this.exportService = const ExportService(),
  });

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  late ExportFormat _selectedFormat;
  ExportDateRange _selectedDateRange = ExportDateRange.allTime;
  String? _selectedProjectId;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _includeSettlement = true;
  bool _isExporting = false;

  final ExportFilenameBuilder _filenameBuilder = const ExportFilenameBuilder();

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.initialFormat;
    _selectedProjectId = widget.initialProjectId;
  }

  String _getProjectName(List<Project> projects) {
    if (_selectedProjectId == null || _selectedProjectId!.isEmpty) {
      return 'All Projects';
    }
    final match = projects.where((p) => p.id == _selectedProjectId).toList();
    return match.isNotEmpty ? match.first.name : 'Project';
  }

  ExportFilter _buildCurrentFilter(List<Project> projects) {
    return ExportFilter(
      format: _selectedFormat,
      dateRange: _selectedDateRange,
      customStartDate: _customStartDate,
      customEndDate: _customEndDate,
      projectId: _selectedProjectId,
      projectName: _getProjectName(projects),
    );
  }

  Future<void> _selectCustomDate(BuildContext context, bool isStart) async {
    final initial = isStart
        ? (_customStartDate ?? DateTime.now().subtract(const Duration(days: 30)))
        : (_customEndDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _customStartDate = picked;
          if (_customEndDate != null && _customEndDate!.isBefore(picked)) {
            _customEndDate = picked;
          }
        } else {
          _customEndDate = picked;
          if (_customStartDate != null && _customStartDate!.isAfter(picked)) {
            _customStartDate = picked;
          }
        }
      });
    }
  }

  Future<void> _handleExport({required bool andShare}) async {
    setState(() {
      _isExporting = true;
    });

    final loc = AppLocalizations.of(context);

    // Retrieve state bills and projects
    final billsBloc = context.read<BillsBloc>();
    final bills = billsBloc.state is BillsLoaded
        ? (billsBloc.state as BillsLoaded).bills
        : <Bill>[];

    final projectBloc = context.read<ProjectBloc>();
    final projects = projectBloc.state is ProjectLoaded
        ? (projectBloc.state as ProjectLoaded).projects
        : <Project>[];

    final filter = _buildCurrentFilter(projects);

    final res = andShare
        ? await widget.exportService.exportAndShare(bills: bills, filter: filter)
        : await widget.exportService.exportToFile(bills: bills, filter: filter);

    if (!mounted) return;

    setState(() {
      _isExporting = false;
    });

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            andShare
                ? '${loc.translate("export_success")}: ${res.fileName}'
                : '${loc.translate("file_saved_to")}: ${res.fileName}',
          ),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.translate("export_failed")}: ${res.error ?? "Unknown error"}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    ThemeProvider? themeProvider;
    try {
      themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    } catch (_) {}

    final isDark = themeProvider?.isDarkMode ??
        (Theme.of(context).brightness == Brightness.dark);

    final billsBlocState = context.watch<BillsBloc>().state;
    final allBills = billsBlocState is BillsLoaded ? billsBlocState.bills : <Bill>[];

    final projectBlocState = context.watch<ProjectBloc>().state;
    final projects = projectBlocState is ProjectLoaded ? projectBlocState.projects : <Project>[];

    final filter = _buildCurrentFilter(projects);
    final filteredBills = filter.filterBills(allBills);
    final totalAmount = filteredBills.fold<double>(0, (sum, b) => sum + b.amount);

    final previewFileName = _filenameBuilder.build(
      projectName: filter.projectName,
      format: _selectedFormat,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('export_data')),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── SECTION 1: Export Format ─────────────────────────────────────
          _buildSectionHeader(context, loc.translate('export_format')),
          const SizedBox(height: 8),
          _buildFormatCard(context, loc, isDark),
          const SizedBox(height: 16),

          // ── SECTION 2: Project Scope ─────────────────────────────────────
          _buildSectionHeader(context, loc.translate('scope')),
          const SizedBox(height: 8),
          _buildProjectScopeCard(context, loc, projects, isDark),
          const SizedBox(height: 16),

          // ── SECTION 3: Date Range Filter ─────────────────────────────────
          _buildSectionHeader(context, loc.translate('select_date_range')),
          const SizedBox(height: 8),
          _buildDateRangeCard(context, loc, isDark),
          const SizedBox(height: 16),

          // ── SECTION 4: Settlement Toggle ─────────────────────────────────
          _buildSettlementCard(context, loc, isDark),
          const SizedBox(height: 16),

          // ── SECTION 5: Preview & Statistics ──────────────────────────────
          _buildSectionHeader(context, loc.translate('overview')),
          const SizedBox(height: 8),
          _buildPreviewCard(
            context,
            loc,
            filteredBills.length,
            totalAmount,
            previewFileName,
            isDark,
          ),
          const SizedBox(height: 24),

          // ── SECTION 6: Action Buttons ────────────────────────────────────
          _buildActionButtons(context, loc),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Widget _buildFormatCard(BuildContext context, AppLocalizations loc, bool isDark) {
    return Card(
      key: const Key('exportFormatCard'),
      elevation: isDark ? 0 : 1,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: ChoiceChip(
                key: const Key('formatChip_csv'),
                label: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.table_chart_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('CSV (.csv)'),
                  ],
                ),
                selected: _selectedFormat == ExportFormat.csv,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedFormat = ExportFormat.csv);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                key: const Key('formatChip_pdf'),
                label: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('PDF (.pdf)'),
                  ],
                ),
                selected: _selectedFormat == ExportFormat.pdf,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedFormat = ExportFormat.pdf);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectScopeCard(
    BuildContext context,
    AppLocalizations loc,
    List<Project> projects,
    bool isDark,
  ) {
    return Card(
      key: const Key('projectScopeCard'),
      elevation: isDark ? 0 : 1,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            key: const Key('projectSelectorDropdown'),
            isExpanded: true,
            value: _selectedProjectId,
            icon: const Icon(Icons.arrow_drop_down),
            items: [
              DropdownMenuItem<String?>(
                key: const Key('projectOption_all'),
                value: null,
                child: Row(
                  children: [
                    const Icon(Icons.folder_shared_outlined, size: 20, color: Colors.teal),
                    const SizedBox(width: 12),
                    Text(loc.translate('all_projects')),
                  ],
                ),
              ),
              ...projects.map((p) {
                return DropdownMenuItem<String?>(
                  key: Key('projectOption_${p.id}'),
                  value: p.id,
                  child: Row(
                    children: [
                      const Icon(Icons.folder_outlined, size: 20, color: Colors.blueGrey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            onChanged: (val) {
              setState(() {
                _selectedProjectId = val;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeCard(BuildContext context, AppLocalizations loc, bool isDark) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Card(
      key: const Key('dateRangeCard'),
      elevation: isDark ? 0 : 1,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  key: const Key('dateRange_allTime'),
                  label: Text(loc.translate('all_time')),
                  selected: _selectedDateRange == ExportDateRange.allTime,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedDateRange = ExportDateRange.allTime);
                  },
                ),
                ChoiceChip(
                  key: const Key('dateRange_thisMonth'),
                  label: Text(loc.translate('this_month')),
                  selected: _selectedDateRange == ExportDateRange.thisMonth,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedDateRange = ExportDateRange.thisMonth);
                  },
                ),
                ChoiceChip(
                  key: const Key('dateRange_lastMonth'),
                  label: Text(loc.translate('last_month')),
                  selected: _selectedDateRange == ExportDateRange.lastMonth,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedDateRange = ExportDateRange.lastMonth);
                  },
                ),
                ChoiceChip(
                  key: const Key('dateRange_custom'),
                  label: Text(loc.translate('custom_range')),
                  selected: _selectedDateRange == ExportDateRange.custom,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedDateRange = ExportDateRange.custom;
                        _customStartDate ??= DateTime.now().subtract(const Duration(days: 30));
                        _customEndDate ??= DateTime.now();
                      });
                    }
                  },
                ),
              ],
            ),
            if (_selectedDateRange == ExportDateRange.custom) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('startDatePickerButton'),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _customStartDate != null
                            ? dateFormat.format(_customStartDate!)
                            : loc.translate('start_date'),
                      ),
                      onPressed: () => _selectCustomDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('endDatePickerButton'),
                      icon: const Icon(Icons.event, size: 16),
                      label: Text(
                        _customEndDate != null
                            ? dateFormat.format(_customEndDate!)
                            : loc.translate('end_date'),
                      ),
                      onPressed: () => _selectCustomDate(context, false),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementCard(BuildContext context, AppLocalizations loc, bool isDark) {
    return Card(
      key: const Key('settlementToggleCard'),
      elevation: isDark ? 0 : 1,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: SwitchListTile(
        key: const Key('includeSettlementSwitch'),
        title: Text(loc.translate('settlement_summary')),
        subtitle: Text(
          loc.translate('settlement_formula'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        value: _includeSettlement,
        onChanged: (val) {
          setState(() {
            _includeSettlement = val;
          });
        },
      ),
    );
  }

  Widget _buildPreviewCard(
    BuildContext context,
    AppLocalizations loc,
    int billCount,
    double totalAmount,
    String fileName,
    bool isDark,
  ) {
    final currency = NumberFormat('#,##0.00');

    return Card(
      key: const Key('exportPreviewCard'),
      elevation: isDark ? 0 : 1,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.translate('bills_count'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '$billCount',
                  key: const Key('previewBillCount'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.translate('total_amount'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  currency.format(totalAmount),
                  key: const Key('previewTotalAmount'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'File:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    key: const Key('previewFileName'),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations loc) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            key: const Key('exportAndShareButton'),
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.share),
            label: Text(loc.translate('export_and_share')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isExporting ? null : () => _handleExport(andShare: true),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            key: const Key('exportFileButton'),
            icon: const Icon(Icons.download_outlined),
            label: Text(loc.translate('export_file')),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isExporting ? null : () => _handleExport(andShare: false),
          ),
        ),
      ],
    );
  }
}
