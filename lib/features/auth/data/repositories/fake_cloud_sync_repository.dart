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
    return updatedProject;
  }
}
