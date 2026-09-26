import 'dart:async';
import 'dart:math';
import '../../domain/entities/cloud_schema.dart';
import '../../domain/repositories/cloud_sync_repository.dart';

/// Testable in-memory fake implementation of [CloudSyncRepository]
class FakeCloudSyncRepository implements CloudSyncRepository {
  final Map<String, CloudUser> users = {};
  final Map<String, CloudProject> projects = {};
  final Map<String, ShareInvite> invites = {};

  bool shouldFail = false;
  String failureMessage = 'Cloud sync operation failed';

  void _checkFailure() {
    if (shouldFail) {
      throw Exception(failureMessage);
    }
  }

  @override
  Future<void> saveUserProfile(CloudUser user) async {
    _checkFailure();
    users[user.uid] = user;
  }

  @override
  Future<CloudUser?> getUserProfile(String uid) async {
    _checkFailure();
    return users[uid];
  }

  @override
  Future<void> saveProject(CloudProject project) async {
    _checkFailure();
    projects[project.id] = project;
  }

  @override
  Future<CloudProject?> getProject(String projectId) async {
    _checkFailure();
    return projects[projectId];
  }

  @override
  String generateInviteCode({String prefix = 'HS'}) {
    final random = Random();
    final number = 1000 + random.nextInt(9000);
    return '$prefix-$number';
  }

  @override
  Future<ShareInvite> createShareInvite({
    required String projectId,
    required String userId,
    Duration validDuration = const Duration(days: 7),
  }) async {
    _checkFailure();
    final code = generateInviteCode();
    final invite = ShareInvite(
      inviteCode: code,
      projectId: projectId,
      createdBy: userId,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(validDuration),
      isActive: true,
    );
    invites[code] = invite;

    // Update project with invite code
    final project = projects[projectId];
    if (project != null) {
      projects[projectId] = CloudProject(
        id: project.id,
        name: project.name,
        currency: project.currency,
        category: project.category,
        color: project.color,
        iconIndex: project.iconIndex,
        ownerId: project.ownerId,
        memberIds: project.memberIds,
        memberNames: project.memberNames,
        inviteCode: code,
        createdAt: project.createdAt,
        updatedAt: DateTime.now(),
      );
    }

    return invite;
  }

  @override
  Future<ShareInvite?> getShareInvite(String inviteCode) async {
    _checkFailure();
    return invites[inviteCode.trim().toUpperCase()];
  }

  @override
  Future<CloudProject> joinProjectWithInviteCode({
    required String inviteCode,
    required String userId,
    required String userName,
  }) async {
    _checkFailure();
    final code = inviteCode.trim().toUpperCase();
    final invite = invites[code];
    if (invite == null || !invite.isValid) {
      throw Exception('Mã mời không tồn tại hoặc đã hết hạn');
    }

    final project = projects[invite.projectId];
    if (project == null) {
      throw Exception('Dự án không tồn tại');
    }

    // Add user to project if not already member
    final updatedMemberIds = List<String>.from(project.memberIds);
    final updatedMemberNames = List<String>.from(project.memberNames);

    if (!updatedMemberIds.contains(userId)) {
      updatedMemberIds.add(userId);
      if (!updatedMemberNames.contains(userName)) {
        updatedMemberNames.add(userName);
      }
    }

    final updatedProject = CloudProject(
      id: project.id,
      name: project.name,
      currency: project.currency,
      category: project.category,
      color: project.color,
      iconIndex: project.iconIndex,
      ownerId: project.ownerId,
      memberIds: updatedMemberIds,
      memberNames: updatedMemberNames,
      inviteCode: project.inviteCode,
      createdAt: project.createdAt,
      updatedAt: DateTime.now(),
    );

    projects[project.id] = updatedProject;
    _projectStreamControllers[project.id]?.add(updatedProject);
    return updatedProject;
  }

  // --- Real-time Streams & Bill Storage ---
  final Map<String, List<CloudBill>> bills = {};
  final Map<String, StreamController<List<CloudBill>>> _billStreamControllers = {};
  final Map<String, StreamController<CloudProject?>> _projectStreamControllers = {};

  @override
  Stream<List<CloudBill>> listenToProjectBills(String projectId) {
    if (!_billStreamControllers.containsKey(projectId)) {
      _billStreamControllers[projectId] = StreamController<List<CloudBill>>.broadcast();
    }
    // Emit initial snapshot on microtask
    Future.microtask(() {
      if (_billStreamControllers.containsKey(projectId) &&
          !_billStreamControllers[projectId]!.isClosed) {
        _billStreamControllers[projectId]!.add(List.unmodifiable(bills[projectId] ?? []));
      }
    });
    return _billStreamControllers[projectId]!.stream;
  }

  @override
  Stream<CloudProject?> listenToProject(String projectId) {
    if (!_projectStreamControllers.containsKey(projectId)) {
      _projectStreamControllers[projectId] = StreamController<CloudProject?>.broadcast();
    }
    Future.microtask(() {
      if (_projectStreamControllers.containsKey(projectId) &&
          !_projectStreamControllers[projectId]!.isClosed) {
        _projectStreamControllers[projectId]!.add(projects[projectId]);
      }
    });
    return _projectStreamControllers[projectId]!.stream;
  }

  @override
  Future<void> saveBill(CloudBill bill) async {
    _checkFailure();
    final list = bills.putIfAbsent(bill.projectId, () => []);
    final idx = list.indexWhere((b) => b.id == bill.id);
    if (idx != -1) {
      list[idx] = bill;
    } else {
      list.add(bill);
    }
    _billStreamControllers[bill.projectId]?.add(List.unmodifiable(list));
  }

  @override
  Future<void> deleteBill(String projectId, String billId) async {
    _checkFailure();
    final list = bills[projectId];
    if (list != null) {
      list.removeWhere((b) => b.id == billId);
      _billStreamControllers[projectId]?.add(List.unmodifiable(list));
    }
  }

  @override
  Future<CloudProject> removeMemberFromProject({
    required String projectId,
    required String memberId,
    required String memberName,
  }) async {
    _checkFailure();
    final project = projects[projectId];
    if (project == null) {
      throw Exception('Dự án không tồn tại');
    }
    if (project.ownerId == memberId) {
      throw Exception('Không thể xóa chủ dự án');
    }
    final updatedMemberIds = List<String>.from(project.memberIds)..remove(memberId);
    final updatedMemberNames = List<String>.from(project.memberNames)..remove(memberName);

    final updated = CloudProject(
      id: project.id,
      name: project.name,
      currency: project.currency,
      category: project.category,
      color: project.color,
      iconIndex: project.iconIndex,
      ownerId: project.ownerId,
      memberIds: updatedMemberIds,
      memberNames: updatedMemberNames,
      inviteCode: project.inviteCode,
      createdAt: project.createdAt,
      updatedAt: DateTime.now(),
    );
    projects[projectId] = updated;
    _projectStreamControllers[projectId]?.add(updated);
    return updated;
  }

  @override
  Future<void> leaveProject({
    required String projectId,
    required String userId,
    required String userName,
  }) async {
    _checkFailure();
    final project = projects[projectId];
    if (project == null) {
      throw Exception('Dự án không tồn tại');
    }
    if (project.ownerId == userId) {
      throw Exception('Chủ dự án không thể rời dự án');
    }
    await removeMemberFromProject(
      projectId: projectId,
      memberId: userId,
      memberName: userName,
    );
  }

  /// Simulation helper: push an arbitrary list of bills for a project
  void emitProjectBills(String projectId, List<CloudBill> newBills) {
    bills[projectId] = List.from(newBills);
    if (!_billStreamControllers.containsKey(projectId)) {
      _billStreamControllers[projectId] = StreamController<List<CloudBill>>.broadcast();
    }
    _billStreamControllers[projectId]!.add(List.unmodifiable(newBills));
  }

  /// Simulation helper: push a project update
  void emitProjectUpdate(CloudProject project) {
    projects[project.id] = project;
    if (!_projectStreamControllers.containsKey(project.id)) {
      _projectStreamControllers[project.id] = StreamController<CloudProject?>.broadcast();
    }
    _projectStreamControllers[project.id]!.add(project);
  }

  void dispose() {
    for (final c in _billStreamControllers.values) {
      c.close();
    }
    for (final c in _projectStreamControllers.values) {
      c.close();
    }
    _billStreamControllers.clear();
    _projectStreamControllers.clear();
  }
}
