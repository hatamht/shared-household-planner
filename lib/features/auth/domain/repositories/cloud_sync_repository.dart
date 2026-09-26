import '../entities/cloud_schema.dart';

/// Abstract contract for Cloud Firestore Sync & Sharing
abstract class CloudSyncRepository {
  /// Save or update user profile in Firestore
  Future<void> saveUserProfile(CloudUser user);

  /// Fetch user profile from Firestore
  Future<CloudUser?> getUserProfile(String uid);

  /// Save or update project in Firestore
  Future<void> saveProject(CloudProject project);

  /// Get project by ID from Firestore
  Future<CloudProject?> getProject(String projectId);

  /// Create a 6-character share invite code for a project
  Future<ShareInvite> createShareInvite({
    required String projectId,
    required String userId,
    Duration validDuration = const Duration(days: 7),
  });

  /// Look up a share invite code
  Future<ShareInvite?> getShareInvite(String inviteCode);

  /// Join a project using an invite code
  Future<CloudProject> joinProjectWithInviteCode({
    required String inviteCode,
    required String userId,
    required String userName,
  });

  /// Generate a unique invite code
  String generateInviteCode({String prefix = 'HS'});

  /// Stream real-time updates of bills for a project
  Stream<List<CloudBill>> listenToProjectBills(String projectId);

  /// Stream real-time updates of a project document
  Stream<CloudProject?> listenToProject(String projectId);

  /// Save or update a bill in Firestore
  Future<void> saveBill(CloudBill bill);

  /// Delete a bill from Firestore
  Future<void> deleteBill(String projectId, String billId);
}
