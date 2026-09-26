import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../bloc/realtime_bloc.dart';
import '../bloc/realtime_event.dart';
import '../bloc/realtime_state.dart';
import '../../domain/entities/remote_change_event.dart';

/// Listens to [RealtimeBloc] and displays an in-app SnackBar notification
/// whenever another member adds, edits, or deletes an expense in the project.
class RemoteChangeNotificationListener extends StatelessWidget {
  final Widget child;
  final RealtimeBloc? bloc;

  const RemoteChangeNotificationListener({
    super.key,
    required this.child,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    RealtimeBloc? resolvedBloc;
    try {
      resolvedBloc = bloc ?? context.read<RealtimeBloc>();
    } catch (_) {}

    if (resolvedBloc == null || resolvedBloc.isClosed) {
      return child;
    }

    return BlocListener<RealtimeBloc, RealtimeBlocState>(
      bloc: resolvedBloc,
      listenWhen: (prev, curr) =>
          curr.showNotification &&
          curr.latestChange != null &&
          curr.latestChange != prev.latestChange,
      listener: (context, state) {
        final change = state.latestChange;
        if (change == null) return;

        _showNotificationSnackBar(context, change);

        try {
          context.read<RealtimeBloc>().add(const DismissRemoteNotificationEvent());
        } catch (_) {}
      },
      child: child,
    );
  }

  void _showNotificationSnackBar(BuildContext context, RemoteBillChange change) {
    final loc = AppLocalizations.of(context);
    final formatter = NumberFormat('#,###');
    final formattedAmt = '${formatter.format(change.amount)} ${change.currency}';

    final message = change.formatMessage(
      addedTemplate: loc.translate('remote_bill_added'),
      updatedTemplate: loc.translate('remote_bill_updated'),
      removedTemplate: loc.translate('remote_bill_deleted'),
      formattedAmount: formattedAmt,
    );

    IconData icon;
    Color color;

    switch (change.type) {
      case RemoteChangeType.added:
        icon = Icons.add_circle_outline;
        color = const Color(0xFF2E7D32); // Green
        break;
      case RemoteChangeType.modified:
        icon = Icons.edit_outlined;
        color = const Color(0xFF1565C0); // Blue
        break;
      case RemoteChangeType.removed:
        icon = Icons.delete_outline;
        color = const Color(0xFFC62828); // Red
        break;
    }

    final snackBar = SnackBar(
      key: const Key('remoteChangeSnackBar'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      backgroundColor: color.withOpacity(0.94),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              key: const Key('remoteChangeMessageText'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}

/// A subtle live sync indicator badge showing that real-time sync is currently active
class RemoteSyncStatusIndicator extends StatelessWidget {
  final String projectId;
  final RealtimeBloc? bloc;

  const RemoteSyncStatusIndicator({
    super.key,
    required this.projectId,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    RealtimeBloc? resolvedBloc;
    try {
      resolvedBloc = bloc ?? context.read<RealtimeBloc>();
    } catch (_) {}

    if (resolvedBloc == null || resolvedBloc.isClosed) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<RealtimeBloc, RealtimeBlocState>(
      bloc: resolvedBloc,
      builder: (context, state) {
        final isListening = state.isProjectListening(projectId);
        if (!isListening) return const SizedBox.shrink();

        final loc = AppLocalizations.of(context);
        return Container(
          key: const Key('remoteSyncStatusIndicator'),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withOpacity(0.4), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                loc.translate('remote_sync_active'),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
