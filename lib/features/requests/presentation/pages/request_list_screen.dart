import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/presentation/bloc/project_bloc.dart';
import '../../domain/entities/request_item.dart';
import '../bloc/request_bloc.dart';
import '../bloc/request_event.dart';
import '../bloc/request_state.dart';
import '../widgets/create_request_bottom_sheet.dart';
import '../widgets/request_card.dart';

class RequestListScreen extends StatefulWidget {
  final String? initialProjectId;
  final bool showAppBar;
  final bool hideFab;

  const RequestListScreen({
    Key? key,
    this.initialProjectId,
    this.showAppBar = true,
    this.hideFab = false,
  }) : super(key: key);

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  String? _selectedProjectId;
  RequestStatus? _statusFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.initialProjectId;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    try {
      context.read<RequestBloc>().add(LoadRequestsEvent(projectId: _selectedProjectId));
    } catch (_) {}
    try {
      final pBloc = context.read<ProjectBloc>();
      if (pBloc.state is! ProjectLoaded) {
        pBloc.add(const GetAllProjects());
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, RequestItem request) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(loc.translate('delete_request')),
        content: Text(loc.translate('delete_request_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(loc.translate('cancel')),
          ),
          TextButton(
            key: const Key('confirmDeleteRequestButton'),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<RequestBloc>().add(DeleteRequestEvent(request.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.translate('request_deleted'))),
              );
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

  void _openCreateRequestModal([RequestItem? requestToEdit]) {
    CreateRequestBottomSheet.show(
      context,
      initialProjectId: _selectedProjectId,
      requestToEdit: requestToEdit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = Column(
      children: [
        // Filter Bar (Project selector & Search)
        _buildFilterHeader(loc, isDark),

        // Status Tabs (All, Pending, Completed, Cancelled)
        _buildStatusFilterRow(loc, isDark),

        // Request List
        Expanded(
          child: BlocBuilder<RequestBloc, RequestState>(
            builder: (context, state) {
              if (state is RequestLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is RequestError) {
                return Center(child: Text(state.message));
              }

              if (state is RequestLoaded) {
                var list = state.allRequests;

                // Project filter
                if (_selectedProjectId != null && _selectedProjectId!.isNotEmpty) {
                  list = list.where((r) => r.projectId == _selectedProjectId).toList();
                }

                // Status filter
                if (_statusFilter != null) {
                  list = list.where((r) => r.status == _statusFilter).toList();
                }

                // Search query
                if (_searchQuery.isNotEmpty) {
                  list = list.where((r) {
                    final t = r.title.toLowerCase();
                    final d = (r.description ?? '').toLowerCase();
                    return t.contains(_searchQuery) || d.contains(_searchQuery);
                  }).toList();
                }

                if (list.isEmpty) {
                  return Center(
                    key: const Key('emptyRequestsView'),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loc.translate('no_requests'),
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          key: const Key('emptyAddRequestButton'),
                          icon: const Icon(Icons.add),
                          label: Text(loc.translate('create_request')),
                          onPressed: () => _openCreateRequestModal(),
                        ),
                      ],
                    ),
                  );
                }

                // Get projects for card display
                List<Project> projects = [];
                final pState = context.watch<ProjectBloc>().state;
                if (pState is ProjectLoaded) {
                  projects = pState.projects;
                }

                return ListView.builder(
                  key: const Key('requestsListView'),
                  itemCount: list.length,
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemBuilder: (context, index) {
                    final req = list[index];
                    return RequestCard(
                      request: req,
                      projects: projects,
                      onMarkCompleted: () {
                        context.read<RequestBloc>().add(
                              ChangeRequestStatusEvent(
                                requestId: req.id,
                                newStatus: RequestStatus.completed,
                              ),
                            );
                      },
                      onMarkCancelled: () {
                        context.read<RequestBloc>().add(
                              ChangeRequestStatusEvent(
                                requestId: req.id,
                                newStatus: RequestStatus.cancelled,
                              ),
                            );
                      },
                      onRevertPending: () {
                        context.read<RequestBloc>().add(
                              ChangeRequestStatusEvent(
                                requestId: req.id,
                                newStatus: RequestStatus.pending,
                              ),
                            );
                      },
                      onEdit: () => _openCreateRequestModal(req),
                      onDelete: () => _confirmDelete(context, req),
                    );
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );

    if (!widget.showAppBar) {
      return Scaffold(
        body: content,
        floatingActionButton: widget.hideFab
            ? null
            : FloatingActionButton(
                key: const Key('addRequestFab'),
                tooltip: loc.translate('create_request'),
                onPressed: () => _openCreateRequestModal(),
                child: const Icon(Icons.add),
              ),
      );
    }

    return Scaffold(
      key: const Key('requestListScreen'),
      appBar: AppBar(
        title: Text(loc.translate('requests')),
      ),
      body: content,
      floatingActionButton: widget.hideFab
          ? null
          : FloatingActionButton(
              key: const Key('addRequestFab'),
              tooltip: loc.translate('create_request'),
              onPressed: () => _openCreateRequestModal(),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildFilterHeader(AppLocalizations loc, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        children: [
          // Project Dropdown Filter
          BlocBuilder<ProjectBloc, ProjectState>(
            builder: (context, state) {
              List<Project> projects = [];
              if (state is ProjectLoaded) {
                projects = state.projects;
              }

              return DropdownButtonFormField<String?>(
                key: const Key('requestProjectFilterDropdown'),
                value: _selectedProjectId,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  labelText: loc.translate('project'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.filter_list, size: 20),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(loc.translate('all_projects')),
                  ),
                  ...projects.map((p) => DropdownMenuItem<String?>(
                        value: p.id,
                        child: Text(p.name, overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedProjectId = val;
                  });
                  context.read<RequestBloc>().add(
                        FilterRequestsEvent(
                          projectId: val,
                          statusFilter: _statusFilter,
                        ),
                      );
                },
              );
            },
          ),
          const SizedBox(height: 8),
          // Search Field
          TextField(
            key: const Key('requestSearchField'),
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '${loc.translate('request_title')} / ${loc.translate('request_description')}...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      key: const Key('clearRequestSearchButton'),
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterRow(AppLocalizations loc, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildStatusFilterChip(
            key: const Key('filterStatusAll'),
            label: loc.translate('filter_all'),
            status: null,
            isSelected: _statusFilter == null,
          ),
          const SizedBox(width: 8),
          _buildStatusFilterChip(
            key: const Key('filterStatusPending'),
            label: loc.translate('filter_pending'),
            status: RequestStatus.pending,
            isSelected: _statusFilter == RequestStatus.pending,
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          _buildStatusFilterChip(
            key: const Key('filterStatusCompleted'),
            label: loc.translate('filter_completed'),
            status: RequestStatus.completed,
            isSelected: _statusFilter == RequestStatus.completed,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          _buildStatusFilterChip(
            key: const Key('filterStatusCancelled'),
            label: loc.translate('filter_cancelled'),
            status: RequestStatus.cancelled,
            isSelected: _statusFilter == RequestStatus.cancelled,
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip({
    required Key key,
    required String label,
    required RequestStatus? status,
    required bool isSelected,
    Color? color,
  }) {
    return ChoiceChip(
      key: key,
      label: Text(label),
      selected: isSelected,
      selectedColor: color != null ? color.withOpacity(0.2) : Theme.of(context).colorScheme.primary.withOpacity(0.2),
      onSelected: (_) {
        setState(() {
          _statusFilter = status;
        });
        context.read<RequestBloc>().add(
              FilterRequestsEvent(
                projectId: _selectedProjectId,
                statusFilter: status,
              ),
            );
      },
    );
  }
}
