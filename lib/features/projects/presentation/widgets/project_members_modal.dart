import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../auth/domain/entities/cloud_schema.dart';
import '../../../auth/domain/repositories/cloud_sync_repository.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/project_member.dart';
import '../../domain/services/project_permission_service.dart';

/// Modal bottom sheet displaying project members with role badges and kick/leave actions
class ProjectMembersModal extends StatefulWidget {
  final Project project;
  final CloudProject? cloudProject;
  final String? currentUserId;
  final String? currentUserName;
  final CloudSyncRepository cloudSyncRepository;
  final VoidCallback? onMembersChanged;

  const ProjectMembersModal({
    super.key,
    required this.project,
    this.cloudProject,
    this.currentUserId,
    this.currentUserName,
    required this.cloudSyncRepository,
    this.onMembersChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required Project project,
    CloudProject? cloudProject,
    String? currentUserId,
    String? currentUserName,
    required CloudSyncRepository cloudSyncRepository,
    VoidCallback? onMembersChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProjectMembersModal(
        project: project,
        cloudProject: cloudProject,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        cloudSyncRepository: cloudSyncRepository,
        onMembersChanged: onMembersChanged,
      ),
    );
  }

  @override
  State<ProjectMembersModal> createState() => _ProjectMembersModalState();
}

class _ProjectMembersModalState extends State<ProjectMembersModal> {
  final ProjectPermissionService _permissionService = const ProjectPermissionService();
  bool _isLoading = false;
  late List<ProjectMember> _members;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() {
    _members = _permissionService.buildMemberList(
      project: widget.project,
      cloudProject: widget.cloudProject,
    );
  }

  Future<void> _handleKickMember(ProjectMember member) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.translate('remove_member_title')),
        content: Text(
          loc.translate('remove_member_confirm').replaceAll('{name}', member.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.translate('cancel_button')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.translate('remove_button')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await widget.cloudSyncRepository.removeMemberFromProject(
        projectId: widget.project.id,
        memberId: member.id,
        memberName: member.name,
      );

      setState(() {
        _members.removeWhere((m) => m.id == member.id);
        _isLoading = false;
      });

      widget.onMembersChanged?.call();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    }
  }

  Future<void> _handleLeaveProject() async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.translate('leave_project_title')),
        content: Text(loc.translate('leave_project_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.translate('cancel_button')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.translate('leave_button')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await widget.cloudSyncRepository.leaveProject(
        projectId: widget.project.id,
        userId: widget.currentUserId ?? '',
        userName: widget.currentUserName ?? '',
      );

      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        widget.onMembersChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    final primary = theme.colorScheme.primary;

    final canLeave = _permissionService.canLeaveProject(
      currentUserId: widget.currentUserId,
      project: widget.project,
      cloudProject: widget.cloudProject,
    );

    return Container(
      key: const Key('projectMembersModal'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Text(
                loc.translate('project_members_title'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_members.length}',
                  key: const Key('membersCountBadge'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ),
              const Spacer(),
              if (canLeave)
                TextButton.icon(
                  key: const Key('leaveProjectButton'),
                  onPressed: _isLoading ? null : _handleLeaveProject,
                  icon: const Icon(Icons.exit_to_app_rounded, size: 18, color: Colors.red),
                  label: Text(
                    loc.translate('leave_button'),
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),

          // Members list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    key: const Key('projectMembersListView'),
                    itemCount: _members.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      final isOwner = member.isOwner;
                      final isCurrentUser = member.id == widget.currentUserId;

                      final canKick = _permissionService.canKickMember(
                        currentUserId: widget.currentUserId,
                        targetMemberId: member.id,
                        project: widget.project,
                        cloudProject: widget.cloudProject,
                      );

                      return ListTile(
                        key: Key('memberTile_${member.id}'),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: isOwner
                              ? Colors.amber.shade700
                              : primary.withOpacity(0.8),
                          child: Text(
                            member.name.isNotEmpty
                                ? member.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                member.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrentUser) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  loc.translate('you_label'),
                                  style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Role Badge
                            Container(
                              key: Key(isOwner ? 'ownerBadge_${member.id}' : 'memberBadge_${member.id}'),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isOwner
                                    ? Colors.amber.withOpacity(0.15)
                                    : Colors.grey.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isOwner
                                      ? Colors.amber.shade700.withOpacity(0.4)
                                      : Colors.grey.withOpacity(0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                isOwner
                                    ? loc.translate('owner_role')
                                    : loc.translate('member_role'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isOwner ? Colors.amber.shade800 : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            if (canKick) ...[
                              const SizedBox(width: 6),
                              IconButton(
                                key: Key('kickMemberButton_${member.id}'),
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                tooltip: loc.translate('remove_member_tooltip'),
                                onPressed: () => _handleKickMember(member),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
