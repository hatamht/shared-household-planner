import 'dart:math';
import 'package:equatable/equatable.dart';

/// Cloud Firestore Collections Schema Constants
abstract class CloudCollections {
  static const String users = 'users';
  static const String projects = 'projects';
  static const String bills = 'bills';
  static const String settlements = 'settlements';
  static const String shareInvites = 'share_invites';
}

/// Cloud User entity in Firestore
class CloudUser extends Equatable {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  const CloudUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'createdAt': createdAt.toIso8601String(),
        'lastLoginAt': lastLoginAt.toIso8601String(),
      };

  factory CloudUser.fromMap(Map<String, dynamic> map, String uid) => CloudUser(
        uid: uid,
        email: map['email'] as String?,
        displayName: map['displayName'] as String?,
        photoUrl: map['photoUrl'] as String?,
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        lastLoginAt: map['lastLoginAt'] != null
            ? DateTime.tryParse(map['lastLoginAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  @override
  List<Object?> get props => [uid, email, displayName, photoUrl, createdAt, lastLoginAt];
}

/// Cloud Project entity in Firestore
class CloudProject extends Equatable {
  final String id;
  final String name;
  final String currency;
  final String? category;
  final String color;
  final int iconIndex;
  final String ownerId;
  final List<String> memberIds;
  final List<String> memberNames;
  final String? inviteCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CloudProject({
    required this.id,
    required this.name,
    required this.currency,
    this.category,
    required this.color,
    this.iconIndex = 0,
    required this.ownerId,
    required this.memberIds,
    this.memberNames = const [],
    this.inviteCode,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'currency': currency,
        'category': category,
        'color': color,
        'iconIndex': iconIndex,
        'ownerId': ownerId,
        'memberIds': memberIds,
        'memberNames': memberNames,
        'inviteCode': inviteCode,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CloudProject.fromMap(Map<String, dynamic> map, String id) => CloudProject(
        id: id,
        name: map['name'] as String? ?? '',
        currency: map['currency'] as String? ?? 'VND',
        category: map['category'] as String?,
        color: map['color'] as String? ?? '#2196F3',
        iconIndex: (map['iconIndex'] as num?)?.toInt() ?? 0,
        ownerId: map['ownerId'] as String? ?? '',
        memberIds: (map['memberIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        memberNames: (map['memberNames'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        inviteCode: map['inviteCode'] as String?,
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: map['updatedAt'] != null
            ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  @override
  List<Object?> get props => [
        id,
        name,
        currency,
        category,
        color,
        iconIndex,
        ownerId,
        memberIds,
        memberNames,
        inviteCode,
        createdAt,
        updatedAt,
      ];
}

/// Cloud Bill entity in Firestore
class CloudBill extends Equatable {
  final String id;
  final String projectId;
  final double amount;
  final String description;
  final String payerId;
  final String payerName;
  final String splitMethod;
  final Map<String, double> splits;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const CloudBill({
    required this.id,
    required this.projectId,
    required this.amount,
    required this.description,
    required this.payerId,
    required this.payerName,
    required this.splitMethod,
    required this.splits,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'projectId': projectId,
        'amount': amount,
        'description': description,
        'payerId': payerId,
        'payerName': payerName,
        'splitMethod': splitMethod,
        'splits': splits,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'createdBy': createdBy,
      };

  factory CloudBill.fromMap(Map<String, dynamic> map, String id) => CloudBill(
        id: id,
        projectId: map['projectId'] as String? ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        description: map['description'] as String? ?? '',
        payerId: map['payerId'] as String? ?? '',
        payerName: map['payerName'] as String? ?? '',
        splitMethod: map['splitMethod'] as String? ?? 'equal',
        splits: (map['splits'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            {},
        date: map['date'] != null
            ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
            : DateTime.now(),
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: map['updatedAt'] != null
            ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        createdBy: map['createdBy'] as String? ?? '',
      );

  @override
  List<Object?> get props => [
        id,
        projectId,
        amount,
        description,
        payerId,
        payerName,
        splitMethod,
        splits,
        date,
        createdAt,
        updatedAt,
        createdBy,
      ];
}

/// Cloud Settlement entity in Firestore
class CloudSettlement extends Equatable {
  final String id;
  final String projectId;
  final String payerId;
  final String payerName;
  final String receiverId;
  final String receiverName;
  final double amount;
  final DateTime date;
  final DateTime createdAt;
  final String createdBy;

  const CloudSettlement({
    required this.id,
    required this.projectId,
    required this.payerId,
    required this.payerName,
    required this.receiverId,
    required this.receiverName,
    required this.amount,
    required this.date,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'projectId': projectId,
        'payerId': payerId,
        'payerName': payerName,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'amount': amount,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'createdBy': createdBy,
      };

  factory CloudSettlement.fromMap(Map<String, dynamic> map, String id) => CloudSettlement(
        id: id,
        projectId: map['projectId'] as String? ?? '',
        payerId: map['payerId'] as String? ?? '',
        payerName: map['payerName'] as String? ?? '',
        receiverId: map['receiverId'] as String? ?? '',
        receiverName: map['receiverName'] as String? ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        date: map['date'] != null
            ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
            : DateTime.now(),
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        createdBy: map['createdBy'] as String? ?? '',
      );

  @override
  List<Object?> get props => [
        id,
        projectId,
        payerId,
        payerName,
        receiverId,
        receiverName,
        amount,
        date,
        createdAt,
        createdBy,
      ];
}

/// Share Invite Entity in Firestore
class ShareInvite extends Equatable {
  final String inviteCode; // 6-character code e.g. DL-8899 or HS-1234
  final String projectId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;

  const ShareInvite({
    required this.inviteCode,
    required this.projectId,
    required this.createdBy,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isValid => isActive && !isExpired;

  Map<String, dynamic> toMap() => {
        'inviteCode': inviteCode,
        'projectId': projectId,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'isActive': isActive,
      };

  factory ShareInvite.fromMap(Map<String, dynamic> map, String inviteCode) => ShareInvite(
        inviteCode: inviteCode,
        projectId: map['projectId'] as String? ?? '',
        createdBy: map['createdBy'] as String? ?? '',
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        expiresAt: map['expiresAt'] != null
            ? DateTime.tryParse(map['expiresAt'] as String)
            : null,
        isActive: map['isActive'] as bool? ?? true,
      );

  /// Helper to generate a human-friendly 6-character code (e.g. HS-4821 or DL-8899)
  static String generateCode({String prefix = 'HS'}) {
    final random = Random();
    final number = 1000 + random.nextInt(9000);
    return '$prefix-$number';
  }

  @override
  List<Object?> get props => [inviteCode, projectId, createdBy, createdAt, expiresAt, isActive];
}
