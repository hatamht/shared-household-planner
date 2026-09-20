import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/project.dart';
import '../bloc/project_bloc.dart';

import '../../domain/entities/project_palette.dart';

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
  bool _isLoading = false;

  // Icon & Color palette options
  static const List<IconData> projectIcons = ProjectPalette.icons;
  static const List<Color> projectColors = ProjectPalette.colors;

  int _selectedIconIndex = 0;
  int _selectedColorIndex = 0;

  Color get _activeColor => projectColors[_selectedColorIndex];
  IconData get _activeIcon => projectIcons[_selectedIconIndex];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descriptionController = TextEditingController(text: widget.project?.description ?? '');
    if (widget.project != null) {
      _members.addAll(widget.project!.members);
      _selectedIconIndex = widget.project!.iconIndex.clamp(0, projectIcons.length - 1);
      _selectedColorIndex = widget.project!.colorIndex.clamp(0, projectColors.length - 1);
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
      final loc = AppLocalizations.of(context);
      setState(() {
        _memberError = loc.translate('member_already_exists');
        if (_memberError == 'member_already_exists') {
          _memberError = 'Member already exists';
        }
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

    setState(() {
      _isLoading = true;
    });

    final now = DateTime.now();
    final isEditing = widget.project != null;

    final project = Project(
      id: isEditing ? widget.project!.id : now.millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      members: List.unmodifiable(_members),
      iconIndex: _selectedIconIndex,
      colorIndex: _selectedColorIndex,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.project != null;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final cardBorder = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.translate(isEditing ? 'edit_project' : 'create_project'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1F1F1F), const Color(0xFF121212)]
                  : [_activeColor.withOpacity(0.9), _activeColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<ProjectBloc, ProjectState>(
        builder: (context, projectState) {
          final isBlocLoading = projectState is ProjectLoading;
          final showLoading = _isLoading || isBlocLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 1. Avatar / Preview Card ─────────────────────────
                  Center(
                    child: Container(
                      key: const Key('projectAvatarPreview'),
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: _activeColor.withOpacity(isDark ? 0.25 : 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: _activeColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: _activeColor.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _activeIcon,
                        size: 42,
                        color: _activeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 2. Project Name Field ───────────────────────────
                  Text(
                    loc.translate('project_name'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const Key('projectNameField'),
                    controller: _nameController,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: loc.translate('project_name_example'),
                      prefixIcon: Icon(Icons.business_rounded, color: _activeColor),
                      filled: true,
                      fillColor: cardBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: _activeColor, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return loc.translate('project_name_required');
                      }
                      if (projectState is ProjectLoaded) {
                        final trimmed = value.trim().toLowerCase();
                        final isDuplicate = projectState.projects.any((p) =>
                            p.name.trim().toLowerCase() == trimmed &&
                            p.id != widget.project?.id);
                        if (isDuplicate) {
                          return loc.translate('project_name_duplicate');
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // ── 3. Project Description Field ────────────────────
                  Text(
                    loc.translate('description'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const Key('projectDescriptionField'),
                    controller: _descriptionController,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 200,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: loc.translate('description_example'),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 48),
                        child: Icon(Icons.notes_rounded, color: _activeColor),
                      ),
                      filled: true,
                      fillColor: cardBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: _activeColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── 4. Avatar / Icon Picker ─────────────────────────
                  Text(
                    loc.translate('project_icon'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    key: const Key('projectIconPicker'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.spaceAround,
                      children: List.generate(projectIcons.length, (index) {
                        final isSelected = _selectedIconIndex == index;
                        final icon = projectIcons[index];

                        return InkWell(
                          key: Key('projectIconOption_$index'),
                          onTap: () {
                            setState(() {
                              _selectedIconIndex = index;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _activeColor.withOpacity(0.18)
                                  : (isDark ? Colors.white10 : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? _activeColor : Colors.transparent,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              icon,
                              key: Key('projectIcon_$index'),
                              color: isSelected
                                  ? _activeColor
                                  : (isDark ? Colors.white70 : Colors.grey.shade700),
                              size: 26,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── 5. Color Theme Picker ───────────────────────────
                  Text(
                    loc.translate('project_color'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    key: const Key('projectColorPicker'),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(projectColors.length, (index) {
                        final isSelected = _selectedColorIndex == index;
                        final color = projectColors[index];

                        return InkWell(
                          key: Key('colorChip_$index'),
                          onTap: () {
                            setState(() {
                              _selectedColorIndex = index;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: color.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 6. Members Section ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.translate('members'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey.shade800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _activeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_members.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _activeColor,
                          ),
                        ),
                      ),
                    ],
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
                            filled: true,
                            fillColor: cardBg,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: cardBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: cardBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _activeColor, width: 2),
                            ),
                          ),
                          onSubmitted: (_) => _addMember(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        key: const Key('addMemberButton'),
                        onPressed: _addMember,
                        style: IconButton.styleFrom(
                          backgroundColor: _activeColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(12),
                        ),
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
                  if (_members.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loc.translate('initial_member_hint'),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: List.generate(_members.length, (index) {
                        final member = _members[index];
                        return Chip(
                          key: Key('memberChip_$index'),
                          avatar: CircleAvatar(
                            backgroundColor: _activeColor.withOpacity(0.2),
                            child: Text(
                              member.isNotEmpty ? member[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _activeColor,
                              ),
                            ),
                          ),
                          label: Text(member),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _removeMember(index),
                          backgroundColor: cardBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: cardBorder),
                          ),
                        );
                      }),
                    ),
                  const SizedBox(height: 32),

                  // ── 7. Save Button ──────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      key: const Key('saveProjectButton'),
                      onPressed: showLoading ? null : () => _saveProject(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _activeColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: showLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              loc.translate('save'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── 8. Cancel Button ────────────────────────────────
                  TextButton(
                    key: const Key('cancelProjectButton'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      loc.translate('cancel'),
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
