import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/conflict_item.dart';
import '../bloc/conflict_bloc.dart';
import '../bloc/conflict_event.dart';
import '../bloc/conflict_state.dart';
import '../../../../core/localization/app_localizations.dart';

/// A widget that listens to [ConflictBloc] and displays a SnackBar/Toast
/// whenever a conflict is resolved.
///
/// Wrap your app's root Scaffold (or a high-level widget) with this.
class ConflictNotificationListener extends StatelessWidget {
  final Widget child;
  final ConflictBloc? bloc;

  const ConflictNotificationListener({
    super.key,
    required this.child,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    ConflictBloc? resolvedBloc;
    try {
      resolvedBloc = bloc ?? context.read<ConflictBloc>();
    } catch (_) {}

    if (resolvedBloc == null || resolvedBloc.isClosed) {
      return child;
    }

    return BlocListener<ConflictBloc, ConflictBlocState>(
      bloc: resolvedBloc,
      listenWhen: (prev, curr) =>
          curr.showNotification &&
          curr.lastResolved != null &&
          curr.lastResolved != prev.lastResolved,
      listener: (context, state) {
        final result = state.lastResolved;
        if (result == null) return;

        _showConflictSnackBar(context, result);

        // Auto-dismiss notification flag
        try {
          context
              .read<ConflictBloc>()
              .add(const DismissConflictNotificationEvent());
        } catch (_) {}
      },
      child: child,
    );
  }

  void _showConflictSnackBar(BuildContext context, ConflictResult result) {
    final loc = AppLocalizations.of(context);

    String title;
    String message;
    IconData icon;
    Color color;

    switch (result.resolution) {
      case ConflictResolution.remoteWins:
        title = loc.translate('conflict_lww_wins');
        message = loc.translate('conflict_lww_wins_message');
        icon = Icons.cloud_download_outlined;
        color = Colors.blue;
        break;
      case ConflictResolution.localWins:
        title = loc.translate('conflict_local_wins');
        message = loc.translate('conflict_local_wins_message');
        icon = Icons.phone_android;
        color = Colors.green;
        break;
      case ConflictResolution.deleteVsEditPreserveLocal:
        title = loc.translate('conflict_delete_vs_edit');
        message = loc.translate('conflict_delete_vs_edit_message');
        icon = Icons.warning_amber_outlined;
        color = Colors.orange;
        break;
      case ConflictResolution.rollback:
        title = loc.translate('conflict_rollback_success');
        message = loc.translate('conflict_rollback_message');
        icon = Icons.restore_outlined;
        color = Colors.deepPurple;
        break;
      case ConflictResolution.bothDeleted:
        return; // Silent — no notification needed
    }

    final snackBar = SnackBar(
      key: const Key('conflictResolutionSnackBar'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      backgroundColor: color.withOpacity(0.92),
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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

/// A compact inline badge showing the count of pending conflicts.
/// Tapping opens a summary bottom sheet.
class ConflictStatusBadge extends StatelessWidget {
  final ConflictBloc? bloc;

  const ConflictStatusBadge({super.key, this.bloc});

  @override
  Widget build(BuildContext context) {
    ConflictBloc? resolvedBloc;
    try {
      resolvedBloc = bloc ?? context.read<ConflictBloc>();
    } catch (_) {}

    if (resolvedBloc == null || resolvedBloc.isClosed) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<ConflictBloc, ConflictBlocState>(
      bloc: resolvedBloc,
      builder: (context, state) {
        if (!state.hasPendingConflicts && state.totalResolved == 0) {
          return const SizedBox.shrink();
        }

        final label = state.hasPendingConflicts
            ? '${state.totalPending} conflict${state.totalPending > 1 ? 's' : ''}'
            : '${state.totalResolved} resolved';

        final badgeColor = state.hasPendingConflicts ? Colors.red : Colors.green;

        return GestureDetector(
          key: const Key('conflictStatusBadge'),
          onTap: () => _showConflictSummarySheet(context, state, resolvedBloc!),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: badgeColor.withOpacity(0.5), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state.hasPendingConflicts
                      ? Icons.merge_type
                      : Icons.check_circle_outline,
                  size: 13,
                  color: badgeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: badgeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConflictSummarySheet(
      BuildContext context, ConflictBlocState state, ConflictBloc conflictBloc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conflict Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text('Pending conflicts: ${state.totalPending}'),
            Text('Resolved this session: ${state.totalResolved}'),
            if (state.totalResolved > 0) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                key: const Key('clearConflictHistoryButton'),
                onPressed: () {
                  conflictBloc.add(const ClearConflictHistoryEvent());
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear History'),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
