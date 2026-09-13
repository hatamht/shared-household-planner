import 'package:shared_household_planner/features/settings/presentation/pages/settings_screen.dart';
import 'package:shared_household_planner/features/statistics/presentation/pages/statistics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/core/theme/app_theme.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/create_project_screen.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/project_detail_screen.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/project_screen.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/bills_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  void _refreshData() {
    try {
      context.read<ProjectBloc>().add(const GetAllProjects());
    } catch (_) {}
    try {
      context.read<BillsBloc>().add(const GetBillsEvent());
    } catch (_) {}
  }

  Future<void> _handlePullToRefresh() async {
    _refreshData();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void _confirmDeleteProject(BuildContext context, Project project) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(loc.translate('delete_project')),
        content: Text(loc.translate('delete_project_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(loc.translate('cancel')),
          ),
          TextButton(
            key: const Key('confirmDeleteProjectButton'),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              try {
                context.read<ProjectBloc>().add(DeleteProject(project.id));
              } catch (_) {}
            },
            child: Text(
              loc.translate('delete'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showProjectContextMenu(BuildContext context, Project project) {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetCtx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(loc.translate('edit_project')),
                onTap: () {
                  Navigator.of(bottomSheetCtx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateProjectScreen(project: project),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: Text(loc.translate('leave_project')),
                onTap: () {
                  Navigator.of(bottomSheetCtx).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                title: Text(
                  loc.translate('delete_project'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.of(bottomSheetCtx).pop();
                  _confirmDeleteProject(context, project);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getAvatarColor(int index) {
    const colors = [
      Color(0xFF6366F1), // Indigo
      Color(0xFF10B981), // Emerald
      Color(0xFFF59E0B), // Amber
      Color(0xFFEC4899), // Pink
      Color(0xFF8B5CF6), // Purple
      Color(0xFF3B82F6), // Blue
      Color(0xFF14B8A6), // Teal
      Color(0xFFEF4444), // Red
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    LanguageProvider? languageProvider;
    try {
      languageProvider = Provider.of<LanguageProvider>(context, listen: true);
    } catch (_) {
      languageProvider = null;
    }

    ThemeProvider? themeProvider;
    try {
      themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    } catch (_) {
      themeProvider = null;
    }

    final isDark = themeProvider?.isDarkMode ??
        (Theme.of(context).brightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.translate('app_name'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0.5,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            tooltip: loc.translate('language'),
            onSelected: (String code) {
              languageProvider?.setLanguage(code);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'en',
                child: Text('🇬🇧 ${loc.translate("english")}'),
              ),
              PopupMenuItem(
                value: 'vi',
                child: Text('🇻🇳 ${loc.translate("vietnamese")}'),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: IconButton(
              key: const Key('themeToggleButton'),
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
              ),
              tooltip: isDark ? loc.translate('light_mode') : loc.translate('dark_mode'),
              onPressed: () => themeProvider?.toggleTheme(),
            ),
          ),
        ],
      ),
      body: _buildCurrentTab(context, loc, isDark),
      bottomNavigationBar: _buildBottomNavigationBar(context, loc, isDark),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton(
              key: const Key('addProjectButton'),
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              tooltip: loc.translate('add_project'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildCurrentTab(BuildContext context, AppLocalizations loc, bool isDark) {
    switch (_currentTabIndex) {
      case 0:
        return _buildProjectsTab(context, loc, isDark);
      case 1:
        return _buildBillsTab(context, loc);
      case 2:
        return const StatisticsScreen();
      case 3:
        return const SettingsScreen();
      default:
        return _buildProjectsTab(context, loc, isDark);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 0: Projects Dashboard
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProjectsTab(BuildContext context, AppLocalizations loc, bool isDark) {
    ProjectState projectState = const ProjectInitial();
    try {
      projectState = context.watch<ProjectBloc>().state;
    } catch (_) {}

    BillsState billsState = const BillsInitial();
    try {
      billsState = context.watch<BillsBloc>().state;
    } catch (_) {}

    List<Project> projects = [];
    if (projectState is ProjectLoaded) {
      projects = projectState.projects;
    }

    List<Bill> allBills = [];
    if (billsState is BillsLoaded) {
      allBills = billsState.bills;
    }

    return RefreshIndicator(
      key: const Key('pullToRefresh'),
      onRefresh: _handlePullToRefresh,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Overview Stats Card
          _buildSummaryStatsCard(context, loc, projects, allBills, isDark),
          const SizedBox(height: 12),

          // Quick Action Buttons Row (preserves compatibility with projectsButton and splitBillsButton)
          _buildQuickActionRow(context, loc),
          const SizedBox(height: 16),

          // Section Title: Projects
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.translate('all_projects'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${projects.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Project List or Empty State
          if (projectState is ProjectLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text(loc.translate('loading'))),
            )
          else if (projects.isEmpty)
            _buildEmptyState(context, loc)
          else
            ...projects.asMap().entries.map((entry) {
              final index = entry.key;
              final project = entry.value;
              final projectBills = allBills.where((b) => b.projectId == project.id).toList();
              final double projectTotal = projectBills.fold(0.0, (sum, b) => sum + b.amount);
              return _buildProjectCard(
                context,
                loc,
                project,
                index,
                projectBills.length,
                projectTotal,
                isDark,
              );
            }).toList(),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stats Card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSummaryStatsCard(
    BuildContext context,
    AppLocalizations loc,
    List<Project> projects,
    List<Bill> allBills,
    bool isDark,
  ) {
    final Set<String> uniqueMembers = {};
    for (final p in projects) {
      uniqueMembers.addAll(p.members);
    }
    final double grandTotal = allBills.fold(0.0, (sum, b) => sum + b.amount);
    final currencyFormatter = NumberFormat.currency(symbol: '€', decimalDigits: 2);

    return Card(
      key: const Key('statsSummaryCard'),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  loc.translate('overview'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  '${projects.length}',
                  loc.translate('projects'),
                  const Color(0xFF3B82F6),
                ),
                _buildStatDivider(isDark),
                _buildStatColumn(
                  '${uniqueMembers.length}',
                  loc.translate('total_members'),
                  const Color(0xFF10B981),
                ),
                _buildStatDivider(isDark),
                _buildStatColumn(
                  '${allBills.length}',
                  loc.translate('total_bills_count'),
                  const Color(0xFFF59E0B),
                ),
                _buildStatDivider(isDark),
                _buildStatColumn(
                  currencyFormatter.format(grandTotal),
                  loc.translate('total_spent'),
                  const Color(0xFFEC4899),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      height: 28,
      width: 1,
      color: isDark ? Colors.white24 : Colors.black12,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Quick Action Buttons Row
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildQuickActionRow(BuildContext context, AppLocalizations loc) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            key: const Key('projectsButton'),
            onPressed: () => Navigator.of(context).pushNamed('/projects'),
            icon: const Icon(Icons.folder_shared, size: 18),
            label: Text(loc.translate('projects')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            key: const Key('splitBillsButton'),
            onPressed: () => Navigator.of(context).pushNamed('/bills'),
            icon: const Icon(Icons.receipt, size: 18),
            label: Text(loc.translate('split_bills')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Empty State
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context, AppLocalizations loc) {
    return Container(
      key: const Key('emptyProjectsState'),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            loc.translate('no_projects'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            loc.translate('create_first_project_prompt'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            key: const Key('emptyStateAddProjectButton'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: Text(loc.translate('add_project')),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Project Card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProjectCard(
    BuildContext context,
    AppLocalizations loc,
    Project project,
    int index,
    int billsCount,
    double totalSpent,
    bool isDark,
  ) {
    final currencyFormatter = NumberFormat.currency(symbol: '€', decimalDigits: 2);
    final avatarColor = _getAvatarColor(index);
    final initial = project.name.isNotEmpty ? project.name[0].toUpperCase() : 'P';
    final statsText = '${project.members.length} members, $billsCount bills, ${currencyFormatter.format(totalSpent)} total';

    return Dismissible(
      key: Key('dismissible_${project.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        _confirmDeleteProject(context, project);
        return false; // Let confirm dialog trigger delete via bloc
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        key: Key('projectCard_${project.id}'),
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProjectDetailScreen(project: project),
              ),
            );
          },
          onLongPress: () => _showProjectContextMenu(context, project),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Project Icon / Circle Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: avatarColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Title and Stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statsText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                            ),
                      ),
                      if (project.description != null && project.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          project.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Chevron icon
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).disabledColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 1: Requests / Bills
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBillsTab(BuildContext context, AppLocalizations loc) {
    return const BillsListScreen();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 2: Settings
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSettingsTab(BuildContext context, AppLocalizations loc, bool isDark) {
    return const SettingsScreen();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom Navigation Bar
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBottomNavigationBar(BuildContext context, AppLocalizations loc, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        key: const Key('bottomNavigationBar'),
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: isDark ? Colors.white54 : Colors.black45,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.folder_shared),
            label: loc.translate('projects'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long),
            label: loc.translate('requests'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.insights),
            label: loc.translate('statistics'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: loc.translate('settings'),
          ),
        ],
      ),
    );
  }
}
