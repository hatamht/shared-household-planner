import 'package:equatable/equatable.dart';
import '../../domain/entities/remote_change_event.dart';

class RealtimeBlocState extends Equatable {
  /// Currently actively listened project IDs
  final Set<String> activeProjects;

  /// Latest remote change received (triggers in-app toast/banner)
  final RemoteBillChange? latestChange;

  /// Full history of remote changes received in this session
  final List<RemoteBillChange> changeHistory;

  /// Whether a remote notification banner should be shown
  final bool showNotification;

  /// Whether the real-time listeners are currently paused (e.g. backgrounded)
  final bool isPaused;

  const RealtimeBlocState({
    this.activeProjects = const {},
    this.latestChange,
    this.changeHistory = const [],
    this.showNotification = false,
    this.isPaused = false,
  });

  bool isProjectListening(String projectId) =>
      activeProjects.contains(projectId) && !isPaused;

  int get totalChangesReceived => changeHistory.length;

  RealtimeBlocState copyWith({
    Set<String>? activeProjects,
    RemoteBillChange? latestChange,
    List<RemoteBillChange>? changeHistory,
    bool? showNotification,
    bool? isPaused,
    bool clearLatestChange = false,
  }) {
    return RealtimeBlocState(
      activeProjects: activeProjects ?? this.activeProjects,
      latestChange: clearLatestChange ? null : (latestChange ?? this.latestChange),
      changeHistory: changeHistory ?? this.changeHistory,
      showNotification: showNotification ?? this.showNotification,
      isPaused: isPaused ?? this.isPaused,
    );
  }

  @override
  List<Object?> get props => [
        activeProjects,
        latestChange,
        changeHistory,
        showNotification,
        isPaused,
      ];
}
