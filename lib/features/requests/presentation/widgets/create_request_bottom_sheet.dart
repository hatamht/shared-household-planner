import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/presentation/bloc/project_bloc.dart';
import '../../domain/entities/request_item.dart';
import '../bloc/request_bloc.dart';
import '../bloc/request_event.dart';

class CreateRequestBottomSheet extends StatefulWidget {
  final String? initialProjectId;
  final RequestItem? requestToEdit;

  const CreateRequestBottomSheet({
    Key? key,
    this.initialProjectId,
    this.requestToEdit,
  }) : super(key: key);

  static Future<RequestItem?> show(
    BuildContext context, {
    String? initialProjectId,
    RequestItem? requestToEdit,
  }) {
    return showModalBottomSheet<RequestItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CreateRequestBottomSheet(
        initialProjectId: initialProjectId,
        requestToEdit: requestToEdit,
      ),
    );
  }

  @override
  State<CreateRequestBottomSheet> createState() => _CreateRequestBottomSheetState();
}

class _CreateRequestBottomSheetState extends State<CreateRequestBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  String? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.requestToEdit?.title ?? '');
    _descController = TextEditingController(text: widget.requestToEdit?.description ?? '');
    _selectedProjectId = widget.requestToEdit?.projectId ?? widget.initialProjectId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    final loc = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProjectId == null || _selectedProjectId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('select_project_required'))),
      );
      return;
    }

    final isEditing = widget.requestToEdit != null;
    final request = isEditing
        ? widget.requestToEdit!.copyWith(
            projectId: _selectedProjectId,
            title: _titleController.text.trim(),
            description: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
            clearDescription: _descController.text.trim().isEmpty,
            updatedAt: DateTime.now(),
          )
        : RequestItem(
            id: const Uuid().v4(),
            projectId: _selectedProjectId!,
            title: _titleController.text.trim(),
            description: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
            status: RequestStatus.pending,
            createdAt: DateTime.now(),
          );

    try {
      final bloc = context.read<RequestBloc>();
      if (isEditing) {
        bloc.add(UpdateRequestEvent(request));
      } else {
        bloc.add(CreateRequestEvent(request));
      }
    } catch (_) {}

    Navigator.of(context).pop(request);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.requestToEdit != null
                        ? loc.translate('edit_request')
                        : loc.translate('create_request'),
                    key: const Key('createRequestModalTitle'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    key: const Key('closeRequestModalButton'),
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Project Selector Dropdown
              BlocBuilder<ProjectBloc, ProjectState>(
                builder: (context, state) {
                  List<Project> projects = [];
                  if (state is ProjectLoaded) {
                    projects = state.projects;
                  }

                  // Auto select first project if none selected
                  if (_selectedProjectId == null && projects.isNotEmpty) {
                    _selectedProjectId = projects.first.id;
                  }

                  final selectedVal = projects.any((p) => p.id == _selectedProjectId)
                      ? _selectedProjectId
                      : (projects.isNotEmpty ? projects.first.id : null);

                  return DropdownButtonFormField<String>(
                    key: const Key('requestProjectDropdown'),
                    value: selectedVal,
                    decoration: InputDecoration(
                      labelText: loc.translate('project'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.folder_outlined),
                    ),
                    items: projects.map((p) {
                      return DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(
                          p.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedProjectId = val;
                      });
                    },
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return loc.translate('select_project_required');
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Title Field
              TextFormField(
                key: const Key('requestTitleField'),
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: loc.translate('request_title'),
                  hintText: loc.translate('request_title_hint'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.title),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return loc.translate('request_title_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                key: const Key('requestDescriptionField'),
                controller: _descController,
                decoration: InputDecoration(
                  labelText: loc.translate('request_description'),
                  hintText: loc.translate('request_description_hint'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.notes),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton.icon(
                key: const Key('saveRequestButton'),
                icon: const Icon(Icons.check),
                label: Text(
                  widget.requestToEdit != null
                      ? loc.translate('save')
                      : loc.translate('create_request'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
