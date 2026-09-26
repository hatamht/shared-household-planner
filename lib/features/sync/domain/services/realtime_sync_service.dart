import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../../auth/domain/entities/cloud_schema.dart';
import '../../../auth/domain/repositories/cloud_sync_repository.dart';
import '../../../split_bills/domain/entities/bill.dart';
import '../../../split_bills/domain/entities/bill_participant.dart';
import '../../../split_bills/domain/repositories/bill_repository.dart';
import '../entities/remote_change_event.dart';

/// Real-time listener service for shared projects.
///
/// Listens to remote Firestore changes for bills and projects, detects
/// additions, modifications, and removals, automatically merges them
/// into local SQLite storage, and notifies listeners via a reactive stream.
class RealtimeSyncService with WidgetsBindingObserver {
  final CloudSyncRepository cloudSyncRepository;
  final BillRepository? billRepository;

  /// Active bill stream subscriptions per projectId
  final Map<String, StreamSubscription<List<CloudBill>>> _billSubscriptions = {};

  /// Active project stream subscriptions per projectId
  final Map<String, StreamSubscription<CloudProject?>> _projectSubscriptions = {};

  /// Cached known bills per projectId to detect additions/updates/deletions
  final Map<String, Map<String, CloudBill>> _knownBills = {};

  /// Initial snapshot loaded flags to prevent notifying for pre-existing items
  final Map<String, bool> _initialSnapshotLoaded = {};

  /// Broadcast stream for remote bill changes
  final StreamController<RemoteBillChange> _changeController =
      StreamController<RemoteBillChange>.broadcast();

  /// Whether real-time listeners are currently paused (e.g. app in background)
  bool _isPaused = false;

  /// Set of active project IDs that should be listened to
  final Set<String> _attachedProjects = {};

  RealtimeSyncService({
    required this.cloudSyncRepository,
    this.billRepository,
  }) {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {
      // In test environments without binding initialized
    }
  }

  /// Reactive stream of remote bill changes
  Stream<RemoteBillChange> get changeStream => _changeController.stream;

  /// Set of currently attached project IDs
  Set<String> get activeProjects => Set.unmodifiable(_attachedProjects);

  /// Check if a project is actively being listened to
  bool isListening(String projectId) =>
      _attachedProjects.contains(projectId) &&
      _billSubscriptions.containsKey(projectId) &&
      !_isPaused;

  /// Whether listeners are paused due to app being in the background
  bool get isPaused => _isPaused;

  /// Number of active project stream subscriptions
  int get activeSubscriptionCount => _billSubscriptions.length;

  /// Attach real-time listener to a shared project
  void attachProjectListener(String projectId) {
    if (projectId.isEmpty) return;
    _attachedProjects.add(projectId);

    if (_isPaused) return;

    if (_billSubscriptions.containsKey(projectId)) return;

    _initialSnapshotLoaded[projectId] = false;

    // Listen to bills collection
    final billStream = cloudSyncRepository.listenToProjectBills(projectId);
    _billSubscriptions[projectId] = billStream.listen(
      (remoteBills) => _handleRemoteBillsUpdate(projectId, remoteBills),
      onError: (error) {
        // Stream error handling
      },
    );

    // Listen to project document
    final projStream = cloudSyncRepository.listenToProject(projectId);
    _projectSubscriptions[projectId] = projStream.listen(
      (updatedProject) {
        // Project document changes can be handled if needed
      },
      onError: (_) {},
    );
  }

  /// Detach real-time listener for a shared project (e.g. leaving screen)
  void detachProjectListener(String projectId) {
    _attachedProjects.remove(projectId);

    _billSubscriptions[projectId]?.cancel();
    _billSubscriptions.remove(projectId);

    _projectSubscriptions[projectId]?.cancel();
    _projectSubscriptions.remove(projectId);

    _knownBills.remove(projectId);
    _initialSnapshotLoaded.remove(projectId);
  }

  /// Detach all active project listeners
  void detachAll() {
    for (final sub in _billSubscriptions.values) {
      sub.cancel();
    }
    _billSubscriptions.clear();

    for (final sub in _projectSubscriptions.values) {
      sub.cancel();
    }
    _projectSubscriptions.clear();

    _attachedProjects.clear();
    _knownBills.clear();
    _initialSnapshotLoaded.clear();
  }

  /// Handle incoming list of bills from remote Firestore stream
  Future<void> _handleRemoteBillsUpdate(
    String projectId,
    List<CloudBill> remoteBills,
  ) async {
    final knownMap = _knownBills.putIfAbsent(projectId, () => {});
    final isInitial = !(_initialSnapshotLoaded[projectId] ?? false);

    final incomingIds = <String>{};

    for (final remoteBill in remoteBills) {
      incomingIds.add(remoteBill.id);
      final existing = knownMap[remoteBill.id];

      if (existing == null) {
        // New bill
        knownMap[remoteBill.id] = remoteBill;

        // Auto-merge to local SQLite store
        await _mergeBillToLocal(remoteBill);

        if (!isInitial) {
          final event = RemoteBillChange.fromCloudBill(
            bill: remoteBill,
            type: RemoteChangeType.added,
          );
          _changeController.add(event);
        }
      } else if (existing.updatedAt != remoteBill.updatedAt ||
          existing.amount != remoteBill.amount ||
          existing.description != remoteBill.description) {
        // Updated bill
        knownMap[remoteBill.id] = remoteBill;

        // Auto-merge to local SQLite store
        await _mergeBillToLocal(remoteBill);

        if (!isInitial) {
          final event = RemoteBillChange.fromCloudBill(
            bill: remoteBill,
            type: RemoteChangeType.modified,
          );
          _changeController.add(event);
        }
      }
    }

    // Check for removed bills
    final removedIds = knownMap.keys.where((id) => !incomingIds.contains(id)).toList();
    for (final removedId in removedIds) {
      final removedBill = knownMap.remove(removedId);
      if (removedBill != null) {
        // Delete from local store
        try {
          await billRepository?.delete(removedId);
        } catch (_) {}

        if (!isInitial) {
          final event = RemoteBillChange.fromCloudBill(
            bill: removedBill,
            type: RemoteChangeType.removed,
          );
          _changeController.add(event);
        }
      }
    }

    _initialSnapshotLoaded[projectId] = true;
  }

  /// Automatically convert and merge a CloudBill into local SQLite store
  Future<void> _mergeBillToLocal(CloudBill cloudBill) async {
    if (billRepository == null) return;

    try {
      final localBill = convertCloudBillToLocal(cloudBill);
      final existingResult = await billRepository!.getById(localBill.id);
      final exists = existingResult.isRight();
      if (exists) {
        await billRepository!.update(localBill);
      } else {
        await billRepository!.create(localBill);
      }
    } catch (_) {}
  }

  /// Helper to convert CloudBill to local Bill model
  static Bill convertCloudBillToLocal(CloudBill cloudBill) {
    List<BillParticipant> participants = [];
    if (cloudBill.splits.isNotEmpty) {
      participants = cloudBill.splits.entries.map((e) {
        return BillParticipant(
          participantId: e.key,
          name: e.key,
          amount: e.value,
        );
      }).toList();
    } else {
      final pName = cloudBill.payerName.isNotEmpty
          ? cloudBill.payerName
          : cloudBill.payerId;
      participants = [
        BillParticipant(
          participantId: cloudBill.payerId.isNotEmpty ? cloudBill.payerId : 'p1',
          name: pName,
          amount: cloudBill.amount,
        ),
      ];
    }

    return Bill(
      id: cloudBill.id,
      title: cloudBill.description,
      amount: cloudBill.amount,
      category: 'other',
      date: cloudBill.date,
      paidBy: cloudBill.payerName.isNotEmpty
          ? cloudBill.payerName
          : cloudBill.payerId,
      participants: participants,
      projectId: cloudBill.projectId,
      currency: 'VND',
      splitMode: cloudBill.splitMethod.isNotEmpty
          ? cloudBill.splitMethod
          : 'equal',
    );
  }

  /// Pause all active listeners when app enters background (saves battery & network)
  void pauseListeners() {
    if (_isPaused) return;
    _isPaused = true;

    for (final sub in _billSubscriptions.values) {
      sub.cancel();
    }
    _billSubscriptions.clear();

    for (final sub in _projectSubscriptions.values) {
      sub.cancel();
    }
    _projectSubscriptions.clear();
  }

  /// Resume listeners when app returns to foreground
  void resumeListeners() {
    if (!_isPaused) return;
    _isPaused = false;

    final projectsToResume = Set<String>.from(_attachedProjects);
    _attachedProjects.clear();

    for (final pid in projectsToResume) {
      attachProjectListener(pid);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      pauseListeners();
    } else if (state == AppLifecycleState.resumed) {
      resumeListeners();
    }
  }

  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}

    detachAll();
    _changeController.close();
  }
}
