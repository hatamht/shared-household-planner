import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import '../../domain/entities/remote_change_event.dart';

abstract class RealtimeEvent extends Equatable {
  const RealtimeEvent();

  @override
  List<Object?> get props => [];
}

/// Attach real-time listener to a project
class StartProjectRealtimeEvent extends RealtimeEvent {
  final String projectId;
  const StartProjectRealtimeEvent(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

/// Detach real-time listener from a project
class StopProjectRealtimeEvent extends RealtimeEvent {
  final String projectId;
  const StopProjectRealtimeEvent(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

/// Detach all active real-time listeners
class StopAllRealtimeEvent extends RealtimeEvent {
  const StopAllRealtimeEvent();
}

/// Remote bill change received from service
class RemoteChangeReceivedEvent extends RealtimeEvent {
  final RemoteBillChange change;
  const RemoteChangeReceivedEvent(this.change);

  @override
  List<Object?> get props => [change];
}

/// Dismiss currently displayed remote notification
class DismissRemoteNotificationEvent extends RealtimeEvent {
  const DismissRemoteNotificationEvent();
}

/// Clear history of remote changes
class ClearRemoteChangeHistoryEvent extends RealtimeEvent {
  const ClearRemoteChangeHistoryEvent();
}

/// App lifecycle changed (background / foreground)
class RealtimeAppLifecycleChangedEvent extends RealtimeEvent {
  final AppLifecycleState state;
  const RealtimeAppLifecycleChangedEvent(this.state);

  @override
  List<Object?> get props => [state];
}
