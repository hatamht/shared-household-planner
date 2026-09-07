import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/project.dart';
import '../bloc/project_bloc.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProjectBloc>().add(const GetAllProjects());
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('projects')),
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
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }

          if (state is ProjectLoaded) {
            final projects = state.projects;
            if (projects.isEmpty) {
              return Center(
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 2,
                  child: ListTile(
                    key: Key('projectItem_${project.id}'),
                    leading: CircleAvatar(
                      child: Text(
                        project.name.isNotEmpty ? project.name[0].toUpperCase() : 'P',
                      ),
                    ),
                    title: Text(
                      project.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (project.description != null && project.description!.isNotEmpty) ...[
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

          return Center(child: Text(loc.translate('no_projects')));
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('addProjectButton'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreateProjectScreen(),
            ),
          );
        },
        tooltip: loc.translate('create_project'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
