import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/project.dart';
import '../bloc/project_bloc.dart';

class CreateProjectScreen extends StatefulWidget {
  final Project? project;

  const CreateProjectScreen({super.key, this.project});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  final TextEditingController _memberController = TextEditingController();
  final List<String> _members = [];
  String? _memberError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descriptionController = TextEditingController(text: widget.project?.description ?? '');
    if (widget.project != null) {
      _members.addAll(widget.project!.members);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _memberController.dispose();
    super.dispose();
  }

  void _addMember() {
    final memberName = _memberController.text.trim();
    if (memberName.isEmpty) return;

    if (_members.contains(memberName)) {
      setState(() {
        _memberError = 'Member already exists';
      });
      return;
    }

    setState(() {
      _members.add(memberName);
      _memberController.clear();
      _memberError = null;
    });
  }

  void _removeMember(int index) {
    setState(() {
      _members.removeAt(index);
    });
  }

  void _saveProject(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_members.isEmpty) {
      setState(() {
        _memberError = loc.translate('min_1_member');
      });
      return;
    }

    final now = DateTime.now();
    final isEditing = widget.project != null;

    final project = Project(
      id: isEditing ? widget.project!.id : now.millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      members: List.unmodifiable(_members),
      createdAt: isEditing ? widget.project!.createdAt : now,
      updatedAt: now,
    );

    if (isEditing) {
      context.read<ProjectBloc>().add(UpdateProject(project));
    } else {
      context.read<ProjectBloc>().add(CreateProject(project));
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isEditing = widget.project != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.translate(isEditing ? 'edit_project' : 'create_project'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('projectNameField'),
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: loc.translate('project_name'),
                  hintText: loc.translate('project_name_example'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return loc.translate('project_name_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('projectDescriptionField'),
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: loc.translate('description'),
                  hintText: loc.translate('description_example'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                loc.translate('members'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('memberNameField'),
                      controller: _memberController,
                      decoration: InputDecoration(
                        labelText: loc.translate('member_name'),
                        hintText: loc.translate('enter_name'),
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addMember(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const Key('addMemberButton'),
                    onPressed: _addMember,
                    icon: const Icon(Icons.add),
                    tooltip: loc.translate('add_member'),
                  ),
                ],
              ),
              if (_memberError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _memberError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: List.generate(_members.length, (index) {
                  final member = _members[index];
                  return Chip(
                    key: Key('memberChip_$index'),
                    label: Text(member),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeMember(index),
                  );
                }),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                key: const Key('saveProjectButton'),
                onPressed: () => _saveProject(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(loc.translate('save')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
