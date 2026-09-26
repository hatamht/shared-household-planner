import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../bloc/sync_bloc.dart';
import '../bloc/sync_event.dart';
import '../bloc/sync_state.dart';

/// Badge displaying sync state and last sync time
class SyncStatusBadge extends StatelessWidget {
  final bool isCompact;
  final VoidCallback? onTap;
  final SyncBloc? bloc;

  const SyncStatusBadge({
    super.key = const Key('syncStatusBadge'),
    this.isCompact = false,
    this.onTap,
    this.bloc,
  });

  SyncBloc? _resolveBloc(BuildContext context) {
    if (bloc != null) return bloc;
    try {
      final b = context.read<SyncBloc>();
      if (!b.isClosed) return b;
    } catch (_) {}
    if (getIt.isRegistered<SyncBloc>()) {
      final b = getIt<SyncBloc>();
      if (!b.isClosed) return b;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final resolvedBloc = _resolveBloc(context);

    if (resolvedBloc == null) {
      // Fallback display
      return _buildContent(
        context,
        const SyncBlocState(),
        loc,
        theme,
        null,
      );
    }

    return BlocBuilder<SyncBloc, SyncBlocState>(
      bloc: resolvedBloc,
      builder: (context, state) {
        return _buildContent(context, state, loc, theme, resolvedBloc);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    SyncBlocState state,
    AppLocalizations loc,
    ThemeData theme,
    SyncBloc? activeBloc,
  ) {
    final relativeTime = state.status.formatRelativeTime(
      justNowText: loc.translate('sync_just_now'),
      minutesAgoTemplate: loc.translate('sync_minutes_ago'),
      hoursAgoTemplate: loc.translate('sync_hours_ago'),
      neverText: loc.translate('sync_never'),
    );

    IconData icon;
    Color color;
    String statusLabel;

    if (state.isSyncing) {
      icon = Icons.sync;
      color = Colors.blue;
      statusLabel = loc.translate('sync_status_syncing');
    } else if (state.isOffline) {
      icon = Icons.cloud_off_outlined;
      color = Colors.grey;
      statusLabel = loc.translate('sync_status_offline');
    } else if (state.hasError) {
      icon = Icons.error_outline;
      color = theme.colorScheme.error;
      statusLabel = loc.translate('sync_status_error');
    } else if (state.hasPending) {
      icon = Icons.cloud_upload_outlined;
      color = Colors.orange;
      statusLabel = loc
          .translate('sync_status_pending')
          .replaceAll('{count}', '${state.pendingCount}');
    } else {
      icon = Icons.check_circle_outline;
      color = Colors.green;
      statusLabel = loc.translate('sync_status_synced');
    }

    if (isCompact) {
      return InkWell(
        key: const Key('syncStatusIndicator'),
        onTap: onTap ??
            () => _showSyncDetailsSheet(
                  context,
                  state,
                  relativeTime,
                  activeBloc,
                ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.35), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              state.isSyncing
                  ? SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  : Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                statusLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      key: const Key('syncStatusIndicator'),
      onTap: onTap ??
          () => _showSyncDetailsSheet(
                context,
                state,
                relativeTime,
                activeBloc,
              ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            state.isSyncing
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  loc.translate('sync_last_synced').replaceAll('{time}', relativeTime),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSyncDetailsSheet(
    BuildContext context,
    SyncBlocState state,
    String relativeTime,
    SyncBloc? activeBloc,
  ) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  loc.translate('sync_now'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    state.isOffline ? Icons.cloud_off : Icons.cloud_done,
                    color: state.isOffline ? Colors.grey : Colors.green,
                  ),
                  title: Text(
                    state.isOffline
                        ? loc.translate('sync_status_offline')
                        : loc.translate('sync_status_synced'),
                  ),
                  subtitle: Text(
                    loc.translate('sync_last_synced').replaceAll('{time}', relativeTime),
                  ),
                ),
                if (state.hasPending)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      loc
                          .translate('sync_status_pending')
                          .replaceAll('{count}', '${state.pendingCount}'),
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const Key('syncDetailsSyncNowButton'),
                    icon: const Icon(Icons.sync),
                    label: Text(loc.translate('sync_now')),
                    onPressed: state.isSyncing
                        ? null
                        : () {
                            Navigator.pop(bottomSheetContext);
                            if (activeBloc != null) {
                              activeBloc.add(const TriggerSyncEvent());
                            } else {
                              try {
                                context.read<SyncBloc>().add(const TriggerSyncEvent());
                              } catch (_) {}
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
