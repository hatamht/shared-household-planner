import '../../../split_bills/domain/entities/bill.dart';
import '../../../auth/domain/entities/cloud_schema.dart';
import '../entities/project.dart';
import '../entities/project_member.dart';

/// Role-based access control and permission rules for shared projects
class ProjectPermissionService {
  const ProjectPermissionService();

  /// Determine user's role in a project
  ProjectRole getUserRole({
    required String? userId,
    required Project project,
    CloudProject? cloudProject,
  }) {
    if (userId == null || userId.isEmpty) {
      return ProjectRole.member;
    }

    // Check CloudProject ownerId
    if (cloudProject != null && cloudProject.ownerId == userId) {
      return ProjectRole.owner;
    }

    // Default to owner if it's the first member and no cloud project
    if (cloudProject == null && project.members.isNotEmpty) {
      return ProjectRole.owner;
    }

    return ProjectRole.member;
  }

  /// Whether user can add a bill to the project
  bool canAddBill({
    required String? userId,
    required String? userName,
    required Project project,
    CloudProject? cloudProject,
  }) {
    if (userId == null || userId.isEmpty) return true; // offline/guest allowed

    if (cloudProject == null) return true;

    // Must be either owner or member
    return cloudProject.ownerId == userId ||
        cloudProject.memberIds.contains(userId) ||
        (userName != null && cloudProject.memberNames.contains(userName));
  }

  /// Whether user can edit an expense in the project
  /// - Owner can edit any bill
  /// - Member can edit bills they created or paid for
  bool canEditBill({
    required String? userId,
    required String? userName,
    required Bill bill,
    required Project project,
    CloudProject? cloudProject,
  }) {
    // If not a shared cloud project, user can edit anything locally
    if (cloudProject == null) return true;

    // Owner can edit any bill
    if (cloudProject.ownerId == userId) return true;

    // Member can only edit their own bill
    if (userName != null && userName.isNotEmpty && bill.paidBy.toLowerCase() == userName.toLowerCase()) {
      return true;
    }

    if (userId != null && userId.isNotEmpty && bill.paidBy == userId) {
      return true;
    }

    return false;
  }

  /// Whether user can delete an expense in the project
  /// - Owner can delete any bill
  /// - Member can only delete bills they created or paid for
  bool canDeleteBill({
    required String? userId,
    required String? userName,
    required Bill bill,
    required Project project,
    CloudProject? cloudProject,
  }) {
    // If not a shared cloud project, user can delete anything locally
    if (cloudProject == null) return true;

    // Owner can delete any bill
    if (cloudProject.ownerId == userId) return true;

    // Member can only delete their own bill
    if (userName != null && userName.isNotEmpty && bill.paidBy.toLowerCase() == userName.toLowerCase()) {
      return true;
    }

    if (userId != null && userId.isNotEmpty && bill.paidBy == userId) {
      return true;
    }

    return false;
  }

  /// Whether user can kick a member from the project
  /// Only project owner can kick members, and cannot kick themselves
  bool canKickMember({
    required String? currentUserId,
    required String targetMemberId,
    required Project project,
    CloudProject? cloudProject,
  }) {
    if (cloudProject == null) return false;
    if (currentUserId == null || currentUserId.isEmpty) return false;

    // Current user must be owner
    if (cloudProject.ownerId != currentUserId) return false;

    // Owner cannot kick themselves
    if (targetMemberId == currentUserId) return false;

    // Target must be in project
    return cloudProject.memberIds.contains(targetMemberId);
  }

  /// Whether user can leave the project
  /// Only regular members can leave; owner must transfer or delete project
  bool canLeaveProject({
    required String? currentUserId,
    required Project project,
    CloudProject? cloudProject,
  }) {
    if (cloudProject == null) return false;
    if (currentUserId == null || currentUserId.isEmpty) return false;

    // Owner cannot leave project
    if (cloudProject.ownerId == currentUserId) return false;

    // Must be a member
    return cloudProject.memberIds.contains(currentUserId);
  }

  /// Whether user can delete the entire project
  /// Only the owner can delete the project
  bool canDeleteProject({
    required String? currentUserId,
    required Project project,
    CloudProject? cloudProject,
  }) {
    if (cloudProject == null) return true; // Local project: owner by default
    return cloudProject.ownerId == currentUserId;
  }

  /// Build list of ProjectMember from CloudProject
  List<ProjectMember> buildMemberList({
    required Project project,
    CloudProject? cloudProject,
  }) {
    if (cloudProject == null) {
      // Local project: treat members as local members, first one is owner
      return project.members.asMap().entries.map((entry) {
        return ProjectMember(
          id: entry.value,
          name: entry.value,
          role: entry.key == 0 ? ProjectRole.owner : ProjectRole.member,
        );
      }).toList();
    }

    final members = <ProjectMember>[];

    // Owner
    final ownerName = cloudProject.memberNames.isNotEmpty
        ? cloudProject.memberNames.first
        : 'Chủ nhóm';
    members.add(ProjectMember(
      id: cloudProject.ownerId,
      name: ownerName,
      role: ProjectRole.owner,
      joinedAt: cloudProject.createdAt,
    ));

    // Other members
    for (int i = 0; i < cloudProject.memberIds.length; i++) {
      final mId = cloudProject.memberIds[i];
      if (mId == cloudProject.ownerId) continue;

      final mName = (i < cloudProject.memberNames.length)
          ? cloudProject.memberNames[i]
          : 'Thành viên ${i + 1}';

      members.add(ProjectMember(
        id: mId,
        name: mName,
        role: ProjectRole.member,
        joinedAt: cloudProject.updatedAt,
      ));
    }

    return members;
  }
}
