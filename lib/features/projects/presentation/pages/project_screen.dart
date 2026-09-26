import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/project_palette.dart';
import '../bloc/project_bloc.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/cloud_sync_repository.dart';
import '../../../auth/data/repositories/firestore_cloud_sync_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/widgets/auth_prompt_bottom_sheet.dart';
import '../../../auth/presentation/widgets/invite_code_dialog.dart';

/// Category filter definition tied to icon indices in [ProjectPalette]
class _CategoryFilter {
  final String labelKey; // i18n key
  final List<int> iconIndices; // empty means "All"
  const _CategoryFilter(this.labelKey, this.iconIndices);
}

const _categoryFilters = [
  _CategoryFilter('filter_all', []),
  _CategoryFilter('filter_family_home', [0, 1]), // apartment, home
  _CategoryFilter('filter_travel', [2]), // flight_takeoff
  _CategoryFilter('filter_food_dining', [3]), // restaurant
  _CategoryFilter('filter_event', [4]), // celebration
  _CategoryFilter('filter_school', [5]), // school
  _CategoryFilter('filter_work', [6]), // work
  _CategoryFilter('filter_shopping', [7]), // shopping_bag
];

enum _SortOption { newest, oldest, nameAZ, nameZA, members }

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedCategoryIndex = 0; // index into _categoryFilters
  String _selectedCurrency = 'all'; // 'all' or currency code
  _SortOption _sortOption = _SortOption.newest;

  @override
  void initState() {
    super.initState();
    context.read<ProjectBloc>().add(const GetAllProjects());
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCategoryIndex != 0 ||
      _selectedCurrency != 'all';

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategoryIndex = 0;
      _selectedCurrency = 'all';
    });
  }

  List<Project> _applyFiltersAndSort(List<Project> projects) {
    var result = projects.where((p) {
      // Text search: name, description, members
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery;
        final inName = p.name.toLowerCase().contains(q);
        final inDesc = p.description?.toLowerCase().contains(q) ?? false;
        final inMembers = p.members.any((m) => m.toLowerCase().contains(q));
        if (!inName && !inDesc && !inMembers) return false;
      }
      // Category filter
      final cat = _categoryFilters[_selectedCategoryIndex];
      if (cat.iconIndices.isNotEmpty && !cat.iconIndices.contains(p.iconIndex)) {
        return false;
      }
      // Currency filter
      if (_selectedCurrency != 'all' &&
          p.currency.toUpperCase() != _selectedCurrency) {
        return false;
      }
      return true;
    }).toList();

    // Sort
    switch (_sortOption) {
      case _SortOption.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _SortOption.oldest:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case _SortOption.nameAZ:
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _SortOption.nameZA:
        result.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case _SortOption.members:
        result.sort((a, b) => b.members.length.compareTo(a.members.length));
        break;
    }
    return result;
  }

  Set<String> _getAvailableCurrencies(List<Project> projects) {
    final currencies = projects.map((p) => p.currency.toUpperCase()).toSet();
    return currencies;
  }

  void _confirmDelete(BuildContext context, Project project) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.translate('delete_project')),
        content: Text(loc.translate('delete_project_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(loc.translate('cancel')),
          ),
          TextButton(
            key: const Key('confirmDeleteProjectButton'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ProjectBloc>().add(DeleteProject(project.id));
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

  void _showSortBottomSheet(BuildContext context, AppLocalizations loc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final sortOptions = [
          (_SortOption.newest, loc.translate('sort_newest'), Icons.schedule_rounded),
          (_SortOption.oldest, loc.translate('sort_oldest'), Icons.history_rounded),
          (_SortOption.nameAZ, loc.translate('sort_name_az'), Icons.sort_by_alpha_rounded),
          (_SortOption.nameZA, loc.translate('sort_name_za'), Icons.sort_by_alpha_rounded),
          (_SortOption.members, loc.translate('sort_members'), Icons.people_rounded),
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  loc.translate('sort_projects'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...sortOptions.map((opt) {
                final isSelected = _sortOption == opt.$1;
                return ListTile(
                  leading: Icon(
                    opt.$3,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : (isDark ? Colors.white70 : Colors.grey.shade700),
                  ),
                  title: Text(
                    opt.$2,
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : (isDark ? Colors.white : Colors.black87),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_rounded,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _sortOption = opt.$1);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _handleJoinProject(BuildContext context) {
    AuthUser? user;
    try {
      final authBloc = context.read<AuthBloc>();
      if (authBloc.state is Authenticated) {
        user = (authBloc.state as Authenticated).user;
      }
    } catch (_) {}

    if (user == null || user.isAnonymous) {
      AuthPromptBottomSheet.show(
        context,
        customTitle: AppLocalizations.of(context).translate('join_project_title'),
        customSubtitle: AppLocalizations.of(context).translate('auth_sheet_subtitle'),
        onSuccess: () => _handleJoinProject(context),
      );
      return;
    }

    CloudSyncRepository? cloudSync;
    try {
      cloudSync = context.read<CloudSyncRepository>();
    } catch (_) {}
    cloudSync ??= FirestoreCloudSyncRepository();

    InviteCodeDialog.show(
      context,
      cloudSyncRepository: cloudSync,
      userId: user.uid,
      userName: user.displayTitle,
      onJoined: (_) {
        context.read<ProjectBloc>().add(const GetAllProjects());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        key: const Key('projectScreenAppBar'),
        title: Text(loc.translate('projects')),
        actions: [
          IconButton(
            key: const Key('joinProjectButton'),
            icon: const Icon(Icons.group_add_outlined),
            tooltip: loc.translate('join_project_button'),
            onPressed: () => _handleJoinProject(context),
          ),
          IconButton(
            key: const Key('sortProjectsButton'),
            icon: const Icon(Icons.sort_rounded),
            tooltip: loc.translate('sort_projects'),
            onPressed: () => _showSortBottomSheet(context, loc),
          ),
        ],
      ),
      body: BlocBuilder<ProjectBloc, ProjectState>(
        builder: (context, state) {
          if (state is ProjectLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProjectError) {
            return Center(
              child: Text(
                '${loc.translate('error')}: ${state.message}',
                style: TextStyle(color: colorScheme.error),
              ),
            );
          }

          if (state is ProjectLoaded) {
            final allProjects = state.projects;
            final availableCurrencies = _getAvailableCurrencies(allProjects);
            final filtered = _applyFiltersAndSort(allProjects);

            return Column(
              children: [
                // ── Search Bar ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: TextField(
                    key: const Key('projectSearchField'),
                    controller: _searchController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: loc.translate('search_projects'),
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              key: const Key('clearSearchButton'),
                              icon: Icon(
                                Icons.clear_rounded,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade600,
                              ),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey.shade100,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white12
                              : Colors.grey.shade200,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Category Filter Chips ──────────────────────────────
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    key: const Key('categoryFilterList'),
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _categoryFilters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isSelected = _selectedCategoryIndex == index;
                      return FilterChip(
                        key: Key('categoryChip_$index'),
                        label: Text(
                          loc.translate(_categoryFilters[index].labelKey),
                          style: TextStyle(
                            color: isSelected
                                ? colorScheme.onPrimary
                                : (isDark ? Colors.white70 : Colors.grey.shade700),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 12.5,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _selectedCategoryIndex = index);
                        },
                        backgroundColor: isDark
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey.shade100,
                        selectedColor: colorScheme.primary,
                        checkmarkColor: colorScheme.onPrimary,
                        side: BorderSide(
                          color: isSelected
                              ? colorScheme.primary
                              : (isDark ? Colors.white12 : Colors.grey.shade300),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),

                // ── Currency Filter Chips ──────────────────────────────
                if (availableCurrencies.length > 1)
                  SizedBox(
                    height: 42,
                    child: ListView(
                      key: const Key('currencyFilterList'),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _currencyChip(
                          context,
                          label: loc.translate('filter_all'),
                          value: 'all',
                          isDark: isDark,
                          colorScheme: colorScheme,
                        ),
                        ...(availableCurrencies.toList()..sort())
                            .map((curr) => Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: _currencyChip(
                                    context,
                                    label: curr,
                                    value: curr,
                                    isDark: isDark,
                                    colorScheme: colorScheme,
                                  ),
                                )),
                      ],
                    ),
                  ),


                // ── Active filter indicator + Clear button ─────────────
                if (_hasActiveFilters)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          loc.translate('active_filters'),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          key: const Key('clearFiltersButton'),
                          onPressed: _clearFilters,
                          icon: Icon(Icons.close_rounded,
                              size: 14, color: colorScheme.primary),
                          label: Text(
                            loc.translate('clear_filters'),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Project List ───────────────────────────────────────
                Expanded(
                  child: _buildProjectList(
                    context,
                    loc,
                    isDark,
                    allProjects,
                    filtered,
                  ),
                ),
              ],
            );
          }

          return Center(child: Text(loc.translate('no_projects')));
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('addProjectButton'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
          );
        },
        tooltip: loc.translate('create_project'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _currencyChip(
    BuildContext context, {
    required String label,
    required String value,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _selectedCurrency == value;
    return FilterChip(
      key: Key('currencyChip_$value'),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? colorScheme.onPrimary
              : (isDark ? Colors.white70 : Colors.grey.shade700),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 12.5,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedCurrency = value),
      backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
      selectedColor: colorScheme.primary,
      checkmarkColor: colorScheme.onPrimary,
      side: BorderSide(
        color: isSelected
            ? colorScheme.primary
            : (isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildProjectList(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
    List<Project> allProjects,
    List<Project> filtered,
  ) {
    if (allProjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open,
                size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(
              loc.translate('no_projects'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        key: const Key('noMatchingProjectsState'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: isDark ? Colors.white30 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              loc.translate('no_matching_projects'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.translate('no_matching_projects_hint'),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              key: const Key('resetFiltersButton'),
              onPressed: _clearFilters,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(loc.translate('reset_filters')),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      key: const Key('projectList'),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final project = filtered[index];
        final iconColor = project.color.computeLuminance() > 0.5
            ? Colors.black87
            : Colors.white;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          elevation: 2,
          child: ListTile(
            key: Key('projectItem_${project.id}'),
            leading: CircleAvatar(
              backgroundColor: project.color,
              child: Icon(project.iconData, color: iconColor),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  key: Key('projectCurrencyBadge_${project.id}'),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: project.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: project.color.withOpacity(0.35)),
                  ),
                  child: Text(
                    '${project.currency} (${project.currencySymbol})',
                    key: Key('projectCurrencyText_${project.id}'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: project.color,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (project.description != null &&
                    project.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(project.description!),
                ],
                const SizedBox(height: 4),
                Text(
                  '${loc.translate('members')}: ${project.members.join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: Key('editProject_${project.id}'),
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: loc.translate('edit_project'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CreateProjectScreen(project: project),
                      ),
                    );
                  },
                ),
                IconButton(
                  key: Key('deleteProject_${project.id}'),
                  icon: const Icon(Icons.delete, size: 20),
                  tooltip: loc.translate('delete_project'),
                  onPressed: () => _confirmDelete(context, project),
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProjectDetailScreen(project: project),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
