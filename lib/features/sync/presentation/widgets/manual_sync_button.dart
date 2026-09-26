import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../bloc/sync_bloc.dart';
import '../bloc/sync_event.dart';
import '../bloc/sync_state.dart';

/// Manual Sync Button (🔄) placed in AppBar actions
class ManualSyncButton extends StatefulWidget {
  final String? projectId;
  final VoidCallback? onSyncTriggered;
  final SyncBloc? bloc;

  const ManualSyncButton({
    super.key = const Key('manualSyncButton'),
    this.projectId,
    this.onSyncTriggered,
    this.bloc,
  });

  @override
  State<ManualSyncButton> createState() => _ManualSyncButtonState();
}

class _ManualSyncButtonState extends State<ManualSyncButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = _resolveBloc(context);
    if (bloc != null && bloc.state.isSyncing && !_animController.isAnimating) {
      _animController.repeat();
    }
  }

  SyncBloc? _resolveBloc(BuildContext context) {
    if (widget.bloc != null) return widget.bloc;
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
    final bloc = _resolveBloc(context);

    if (bloc == null) {
      // Safe fallback when SyncBloc is not registered
      return Tooltip(
        message: loc.translate('sync_now'),
        child: IconButton(
          key: const Key('manualSyncButtonAction'),
          icon: const Icon(Icons.sync),
          onPressed: () {
            widget.onSyncTriggered?.call();
          },
        ),
      );
    }

    return BlocConsumer<SyncBloc, SyncBlocState>(
      bloc: bloc,
      listenWhen: (previous, current) =>
          previous.isSyncing != current.isSyncing ||
          previous.lastSyncMessage != current.lastSyncMessage,
      listener: (context, state) {
        if (state.isSyncing) {
          if (!_animController.isAnimating) {
            _animController.repeat();
          }
        } else {
          if (_animController.isAnimating) {
            _animController.stop();
            _animController.reset();
          }
        }

        if (state.lastSyncMessage != null && state.lastSyncMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.isOffline
                    ? loc.translate('sync_offline_message')
                    : state.lastSyncMessage!,
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final tooltip = _buildTooltipText(context, state, loc);

        Color? iconColor;
        if (state.isOffline) {
          iconColor = theme.colorScheme.onSurface.withOpacity(0.45);
        } else if (state.hasError) {
          iconColor = theme.colorScheme.error;
        } else if (state.hasPending) {
          iconColor = Colors.orangeAccent;
        } else {
          iconColor = null;
        }

        return Tooltip(
          message: tooltip,
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                key: const Key('manualSyncButtonAction'),
                icon: RotationTransition(
                  turns: _animController,
                  child: Icon(
                    Icons.sync,
                    color: iconColor,
                  ),
                ),
                onPressed: state.isSyncing
                    ? null
                    : () {
                        widget.onSyncTriggered?.call();
                        bloc.add(
                          TriggerSyncEvent(projectId: widget.projectId),
                        );

                        if (state.isOffline) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loc.translate('sync_offline_message')),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
              ),
              if (state.hasPending && !state.isSyncing)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _buildTooltipText(
    BuildContext context,
    SyncBlocState state,
    AppLocalizations loc,
  ) {
    if (state.isSyncing) {
      return loc.translate('sync_status_syncing');
    }

    final relativeTime = state.status.formatRelativeTime(
      justNowText: loc.translate('sync_just_now'),
      minutesAgoTemplate: loc.translate('sync_minutes_ago'),
      hoursAgoTemplate: loc.translate('sync_hours_ago'),
      neverText: loc.translate('sync_never'),
    );

    if (state.isOffline) {
      return '${loc.translate('sync_status_offline')} - ${loc.translate('sync_last_synced').replaceAll('{time}', relativeTime)}';
    }

    if (state.hasPending) {
      final pendingText = loc
          .translate('sync_status_pending')
          .replaceAll('{count}', '${state.pendingCount}');
      return '$pendingText - ${loc.translate('sync_now')}';
    }

    return '${loc.translate('sync_now')} (${loc.translate('sync_last_synced').replaceAll('{time}', relativeTime)})';
  }
}
