import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../auth/domain/entities/cloud_schema.dart';
import '../../../auth/domain/repositories/cloud_sync_repository.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';

/// Modal dialog allowing users to enter a 6-character invite code and join a shared project
class JoinProjectDialog extends StatefulWidget {
  final String userId;
  final String userName;
  final CloudSyncRepository cloudSyncRepository;
  final ProjectRepository? projectRepository;

  const JoinProjectDialog({
    super.key,
    required this.userId,
    required this.userName,
    required this.cloudSyncRepository,
    this.projectRepository,
  });

  static Future<Project?> show(
    BuildContext context, {
    required String userId,
    required String userName,
    required CloudSyncRepository cloudSyncRepository,
    ProjectRepository? projectRepository,
  }) {
    return showDialog<Project?>(
      context: context,
      builder: (_) => JoinProjectDialog(
        userId: userId,
        userName: userName,
        cloudSyncRepository: cloudSyncRepository,
        projectRepository: projectRepository,
      ),
    );
  }

  @override
  State<JoinProjectDialog> createState() => _JoinProjectDialogState();
}

class _JoinProjectDialogState extends State<JoinProjectDialog> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isChecking = false;
  String? _errorMessage;
  CloudProject? _previewProject;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _checkInviteCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _previewProject = null;
    });

    try {
      final invite = await widget.cloudSyncRepository.getShareInvite(code);
      if (invite == null || !invite.isValid) {
        if (mounted) {
          setState(() {
            _isChecking = false;
            _errorMessage = 'Mã mời không tồn tại hoặc đã hết hạn';
          });
        }
        return;
      }

      final project = await widget.cloudSyncRepository.getProject(invite.projectId);
      if (mounted) {
        setState(() {
          _isChecking = false;
          _previewProject = project;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _joinProject() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cloudProject = await widget.cloudSyncRepository.joinProjectWithInviteCode(
        inviteCode: code,
        userId: widget.userId,
        userName: widget.userName,
      );

      // Convert to local Project entity and save to SQLite
      final localProject = Project(
        id: cloudProject.id,
        name: cloudProject.name,
        members: cloudProject.memberNames.isNotEmpty
            ? cloudProject.memberNames
            : cloudProject.memberIds,
        currency: cloudProject.currency,
        iconIndex: cloudProject.iconIndex,
        createdAt: cloudProject.createdAt,
        updatedAt: cloudProject.updatedAt,
      );

      if (widget.projectRepository != null) {
        try {
          await widget.projectRepository!.create(localProject);
        } catch (_) {
          // If project already exists locally, update it
          try {
            await widget.projectRepository!.update(localProject);
          } catch (_) {}
        }
      }

      if (mounted) {
        Navigator.of(context).pop(localProject);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    final primary = theme.colorScheme.primary;

    return Dialog(
      key: const Key('joinProjectDialog'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.group_add_rounded, color: primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      loc.translate('join_project_title'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                loc.translate('join_project_instruction'),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 18),

              // Code Input Field
              TextField(
                key: const Key('joinProjectCodeField'),
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 10,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  color: primary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: loc.translate('join_code_hint'),
                  hintStyle: TextStyle(
                    fontSize: 16,
                    letterSpacing: 2,
                    color: isDark ? Colors.white24 : Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    key: const Key('checkCodeButton'),
                    icon: _isChecking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search_rounded),
                    onPressed: _isChecking ? null : _checkInviteCode,
                  ),
                ),
                onSubmitted: (_) => _checkInviteCode(),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  key: const Key('joinProjectErrorMessage'),
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              // Project preview card if found
              if (_previewProject != null) ...[
                const SizedBox(height: 16),
                Container(
                  key: const Key('projectPreviewContainer'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _previewProject!.name,
                              key: const Key('previewProjectName'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_previewProject!.memberIds.length} thành viên • ${_previewProject!.currency}',
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('cancelJoinProjectButton'),
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(loc.translate('cancel_button')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('confirmJoinProjectButton'),
                      onPressed: _isLoading ? null : (_previewProject != null ? _joinProject : _checkInviteCode),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _previewProject != null
                                  ? loc.translate('join_project_button')
                                  : loc.translate('check_code_button'),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
