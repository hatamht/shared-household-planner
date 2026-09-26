import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../domain/entities/cloud_schema.dart';
import '../../domain/repositories/cloud_sync_repository.dart';
import 'fake_cloud_sync_repository.dart';

/// Real Firestore implementation of [CloudSyncRepository]
class FirestoreCloudSyncRepository implements CloudSyncRepository {
  final FirebaseFirestore? _firestore;
  final FakeCloudSyncRepository _fallback = FakeCloudSyncRepository();

  FirestoreCloudSyncRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  FirebaseFirestore? get _db {
    if (_firestore != null) return _firestore;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  @override
  String generateInviteCode({String prefix = 'HS'}) {
    final random = Random();
    final number = 1000 + random.nextInt(9000);
    return '$prefix-$number';
  }

  @override
  Future<void> saveUserProfile(CloudUser user) async {
    final db = _db;
    if (db != null) {
      await db
          .collection(CloudCollections.users)
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
      return;
    }
    await _fallback.saveUserProfile(user);
  }

  @override
  Future<CloudUser?> getUserProfile(String uid) async {
    final db = _db;
    if (db != null) {
      final doc = await db.collection(CloudCollections.users).doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return CloudUser.fromMap(doc.data()!, uid);
    }
    return _fallback.getUserProfile(uid);
  }

  @override
  Future<void> saveProject(CloudProject project) async {
    final db = _db;
    if (db != null) {
      await db
          .collection(CloudCollections.projects)
          .doc(project.id)
          .set(project.toMap(), SetOptions(merge: true));
      return;
    }
    await _fallback.saveProject(project);
  }

  @override
  Future<CloudProject?> getProject(String projectId) async {
    final db = _db;
    if (db != null) {
      final doc = await db.collection(CloudCollections.projects).doc(projectId).get();
      if (!doc.exists || doc.data() == null) return null;
      return CloudProject.fromMap(doc.data()!, projectId);
    }
    return _fallback.getProject(projectId);
  }

  @override
  Future<ShareInvite> createShareInvite({
    required String projectId,
    required String userId,
    Duration validDuration = const Duration(days: 7),
  }) async {
    final code = generateInviteCode();
    final invite = ShareInvite(
      inviteCode: code,
      projectId: projectId,
      createdBy: userId,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(validDuration),
      isActive: true,
    );

    final db = _db;
    if (db != null) {
      await db
          .collection(CloudCollections.shareInvites)
          .doc(code)
          .set(invite.toMap());
      await db.collection(CloudCollections.projects).doc(projectId).update({
        'inviteCode': code,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return invite;
    }

    return _fallback.createShareInvite(
      projectId: projectId,
      userId: userId,
      validDuration: validDuration,
    );
  }

  @override
  Future<ShareInvite?> getShareInvite(String inviteCode) async {
    final code = inviteCode.trim().toUpperCase();
    final db = _db;
    if (db != null) {
      final doc = await db.collection(CloudCollections.shareInvites).doc(code).get();
      if (!doc.exists || doc.data() == null) return null;
      return ShareInvite.fromMap(doc.data()!, code);
    }
    return _fallback.getShareInvite(code);
  }

  @override
  Future<CloudProject> joinProjectWithInviteCode({
    required String inviteCode,
    required String userId,
    required String userName,
  }) async {
    final code = inviteCode.trim().toUpperCase();
    final db = _db;
    if (db != null) {
      final invite = await getShareInvite(code);
      if (invite == null || !invite.isValid) {
        throw Exception('Mã mời không tồn tại hoặc đã hết hạn');
      }

      final projectRef = db.collection(CloudCollections.projects).doc(invite.projectId);
      final doc = await projectRef.get();
      if (!doc.exists || doc.data() == null) {
        throw Exception('Dự án không tồn tại');
      }

      await projectRef.update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'memberNames': FieldValue.arrayUnion([userName]),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final updatedDoc = await projectRef.get();
      return CloudProject.fromMap(updatedDoc.data()!, invite.projectId);
    }

    return _fallback.joinProjectWithInviteCode(
      inviteCode: code,
      userId: userId,
      userName: userName,
    );
  }

  @override
  Stream<List<CloudBill>> listenToProjectBills(String projectId) {
    final db = _db;
    if (db != null) {
      return db
          .collection(CloudCollections.projects)
          .doc(projectId)
          .collection(CloudCollections.bills)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => CloudBill.fromMap(doc.data(), doc.id))
            .toList();
      });
    }
    return _fallback.listenToProjectBills(projectId);
  }

  @override
  Stream<CloudProject?> listenToProject(String projectId) {
    final db = _db;
    if (db != null) {
      return db
          .collection(CloudCollections.projects)
          .doc(projectId)
          .snapshots()
          .map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        return CloudProject.fromMap(doc.data()!, doc.id);
      });
    }
    return _fallback.listenToProject(projectId);
  }

  @override
  Future<void> saveBill(CloudBill bill) async {
    final db = _db;
    if (db != null) {
      await db
          .collection(CloudCollections.projects)
          .doc(bill.projectId)
          .collection(CloudCollections.bills)
          .doc(bill.id)
          .set(bill.toMap(), SetOptions(merge: true));
      return;
    }
    await _fallback.saveBill(bill);
  }

  @override
  Future<void> deleteBill(String projectId, String billId) async {
    final db = _db;
    if (db != null) {
      await db
          .collection(CloudCollections.projects)
          .doc(projectId)
          .collection(CloudCollections.bills)
          .doc(billId)
          .delete();
      return;
    }
    await _fallback.deleteBill(projectId, billId);
  }

  @override
  Future<CloudProject> removeMemberFromProject({
    required String projectId,
    required String memberId,
    required String memberName,
  }) async {
    final db = _db;
    if (db != null) {
      final projectRef = db.collection(CloudCollections.projects).doc(projectId);
      await projectRef.update({
        'memberIds': FieldValue.arrayRemove([memberId]),
        'memberNames': FieldValue.arrayRemove([memberName]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      final updatedDoc = await projectRef.get();
      return CloudProject.fromMap(updatedDoc.data()!, projectId);
    }
    return _fallback.removeMemberFromProject(
      projectId: projectId,
      memberId: memberId,
      memberName: memberName,
    );
  }

  @override
  Future<void> leaveProject({
    required String projectId,
    required String userId,
    required String userName,
  }) async {
    await removeMemberFromProject(
      projectId: projectId,
      memberId: userId,
      memberName: userName,
    );
  }
}
