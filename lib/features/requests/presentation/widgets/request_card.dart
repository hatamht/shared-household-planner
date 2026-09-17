import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../projects/domain/entities/project.dart';
import '../../domain/entities/request_item.dart';

class RequestCard extends StatelessWidget {
  final RequestItem request;
  final List<Project> projects;
  final VoidCallback? onMarkCompleted;
  final VoidCallback? onMarkCancelled;
  final VoidCallback? onRevertPending;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RequestCard({
    Key? key,
    required this.request,
    this.projects = const [],
    this.onMarkCompleted,
    this.onMarkCancelled,
    this.onRevertPending,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  Color _getStatusColor(RequestStatus status, bool isDark) {
    switch (status) {
      case RequestStatus.completed:
        return Colors.green;
      case RequestStatus.cancelled:
        return Colors.redAccent;
      case RequestStatus.pending:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(RequestStatus status) {
    switch (status) {
      case RequestStatus.completed:
        return Icons.check_circle_outline;
      case RequestStatus.cancelled:
        return Icons.cancel_outlined;
      case RequestStatus.pending:
        return Icons.pending_actions_outlined;
    }
  }

  String _getStatusText(RequestStatus status, AppLocalizations loc) {
    switch (status) {
      case RequestStatus.completed:
        return loc.translate('request_status_completed');
      case RequestStatus.cancelled:
        return loc.translate('request_status_cancelled');
      case RequestStatus.pending:
        return loc.translate('request_status_pending');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(request.status, isDark);
    final statusIcon = _getStatusIcon(request.status);
    final statusText = _getStatusText(request.status, loc);

    final project = projects.where((p) => p.id == request.projectId).firstOrNull;
    final projectName = project?.name ?? request.projectId;

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final dateStr = dateFormat.format(request.createdAt);

    return Card(
      key: Key('requestCard_${request.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: request.isCompleted
              ? Colors.green.withOpacity(0.3)
              : (request.isCancelled
                  ? Colors.red.withOpacity(0.2)
                  : Colors.transparent),
        ),
      ),
      elevation: 2,
      color: isDark ? const Color(0xFF222222) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title & Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.title,
                        key: Key('requestTitle_${request.id}'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: request.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: request.isCompleted
                              ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Project name badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C3E50) : const Color(0xFFEBF5FB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 13,
                              color: isDark ? Colors.lightBlueAccent : const Color(0xFF2980B9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              projectName,
                              key: Key('requestProjectName_${request.id}'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.lightBlueAccent : const Color(0xFF2980B9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status Chip
                Container(
                  key: Key('requestStatusChip_${request.id}'),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (request.description != null && request.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                request.description!,
                key: Key('requestDescription_${request.id}'),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Footer: Date and Action Buttons
            Row(
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
                const Spacer(),
                // Actions
                if (request.isPending) ...[
                  IconButton(
                    key: Key('markCompletedButton_${request.id}'),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                    tooltip: loc.translate('mark_completed'),
                    onPressed: onMarkCompleted,
                  ),
                  IconButton(
                    key: Key('markCancelledButton_${request.id}'),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                    tooltip: loc.translate('mark_cancelled'),
                    onPressed: onMarkCancelled,
                  ),
                ] else ...[
                  TextButton.icon(
                    key: Key('revertPendingButton_${request.id}'),
                    icon: const Icon(Icons.undo, size: 16),
                    label: Text(loc.translate('revert_pending'), style: const TextStyle(fontSize: 12)),
                    onPressed: onRevertPending,
                  ),
                ],
                IconButton(
                  key: Key('editRequestButton_${request.id}'),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: loc.translate('edit'),
                  onPressed: onEdit,
                ),
                IconButton(
                  key: Key('deleteRequestButton_${request.id}'),
                  icon: Icon(Icons.delete_outline, size: 20, color: Theme.of(context).colorScheme.error),
                  tooltip: loc.translate('delete'),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
