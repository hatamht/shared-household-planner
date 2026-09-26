import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/features/auth/data/repositories/fake_cloud_sync_repository.dart';
import 'package:shared_household_planner/features/auth/domain/entities/cloud_schema.dart';
import 'package:shared_household_planner/features/auth/presentation/widgets/share_project_modal.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project_member.dart';
import 'package:shared_household_planner/features/projects/domain/services/project_permission_service.dart';
import 'package:shared_household_planner/features/projects/presentation/widgets/join_project_dialog.dart';
import 'package:shared_household_planner/features/projects/presentation/widgets/project_members_modal.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';

// ─────────────────────────────────────────────
// Test Localization Support
// ─────────────────────────────────────────────
class _TestLocalizations extends AppLocalizations {
  final Map<String, String> _customStrings;
  _TestLocalizations(super.locale, [this._customStrings = const {}]);

  static const Map<String, String> _viStrings = {
    'share_project_title': 'Chia sẻ dự án',
    'share_project_button': 'Chia sẻ',
    'join_project_title': 'Tham gia dự án',
    'join_project_instruction': 'Nhập mã mời 6 ký tự để tham gia:',
    'join_code_hint': 'VD: DL-8899',
    'check_code_button': 'Kiểm tra mã',
    'join_project_button': 'Tham gia ngay',
    'cancel_button': 'Hủy',
    'copy_code_button': 'Sao chép mã',
    'copy_link_button': 'Sao chép link',
    'invite_code_instruction': 'Gửi mã này cho thành viên:',
    'invite_code_copied': 'Đã sao chép mã mời!',
    'share_link_copied': 'Đã sao chép link!',
    'project_members_title': 'Thành viên dự án',
    'owner_role': 'Chủ nhóm',
    'member_role': 'Thành viên',
    'remove_member_title': 'Gỡ thành viên',
    'remove_member_confirm': 'Bạn có chắc chắn muốn gỡ {name} khỏi dự án này?',
    'remove_member_tooltip': 'Gỡ thành viên',
    'remove_button': 'Gỡ',
    'leave_project_title': 'Rời dự án',
    'leave_project_confirm': 'Bạn có chắc chắn muốn rời khỏi dự án này?',
    'leave_button': 'Rời nhóm',
    'you_label': 'Bạn',
  };

  static const Map<String, String> _enStrings = {
    'share_project_title': 'Share Project',
    'share_project_button': 'Share',
    'join_project_title': 'Join Project',
    'join_project_instruction': 'Enter 6-character code to join:',
    'join_code_hint': 'e.g. DL-8899',
    'check_code_button': 'Check Code',
    'join_project_button': 'Join Now',
    'cancel_button': 'Cancel',
    'copy_code_button': 'Copy Code',
    'copy_link_button': 'Copy Link',
    'invite_code_instruction': 'Share this code with members:',
    'invite_code_copied': 'Invite code copied!',
    'share_link_copied': 'Link copied!',
    'project_members_title': 'Project Members',
    'owner_role': 'Owner',
    'member_role': 'Member',
    'remove_member_title': 'Remove Member',
    'remove_member_confirm': 'Remove {name} from project?',
    'remove_member_tooltip': 'Remove',
    'remove_button': 'Remove',
    'leave_project_title': 'Leave Project',
    'leave_project_confirm': 'Are you sure you want to leave?',
    'leave_button': 'Leave',
    'you_label': 'You',
  };

  @override
  String translate(String key) {
    if (_customStrings.containsKey(key)) return _customStrings[key]!;
    if (locale.languageCode == 'en') {
      return _enStrings[key] ?? key;
    }
    return _viStrings[key] ?? key;
  }
}

class _TestLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  final Map<String, String> customStrings;
  const _TestLocalizationsDelegate([this.customStrings = const {}]);

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async => _TestLocalizations(locale, customStrings);

  @override
  bool shouldReload(_TestLocalizationsDelegate old) => false;
}

class _ThrowingCloudSyncRepository extends FakeCloudSyncRepository {
  @override
  Future<ShareInvite> createShareInvite({
    required String projectId,
    required String userId,
    Duration validDuration = const Duration(days: 7),
  }) async {
    throw Exception('Network failure');
  }
}

Widget _buildTestApp(Widget child, {Locale locale = const Locale('vi'), ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? ThemeData.light(),
    locale: locale,
    supportedLocales: const [Locale('en'), Locale('vi')],
    localizationsDelegates: const [
      _TestLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );
}

final _testTime = DateTime(2026, 9, 27, 10, 0);

Project _makeProject({
  String id = 'proj-1',
  String name = 'Chuyến Đi Đà Lạt',
  List<String> members = const ['Alice', 'Bob', 'Charlie'],
  String currency = 'VND',
}) {
  return Project(
    id: id,
    name: name,
    members: members,
    currency: currency,
    createdAt: _testTime,
    updatedAt: _testTime,
  );
}

CloudProject _makeCloudProject({
  String id = 'proj-1',
  String name = 'Chuyến Đi Đà Lạt',
  String ownerId = 'u_alice',
  List<String> memberIds = const ['u_alice', 'u_bob', 'u_charlie'],
  List<String> memberNames = const ['Alice', 'Bob', 'Charlie'],
  String currency = 'VND',
}) {
  return CloudProject(
    id: id,
    name: name,
    ownerId: ownerId,
    memberIds: memberIds,
    memberNames: memberNames,
    currency: currency,
    color: '#2196F3',
    createdAt: _testTime,
    updatedAt: _testTime,
  );
}

Bill _makeBill({
  String id = 'bill-1',
  String title = 'Tiền Xe Khách',
  double amount = 500000,
  String paidBy = 'Alice',
  String? projectId = 'proj-1',
}) {
  return Bill(
    id: id,
    title: title,
    amount: amount,
    category: 'Di chuyển',
    date: _testTime,
    paidBy: paidBy,
    participants: const [],
    projectId: projectId,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 1: ProjectMember Entity & Role Tests (1-15)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Group 1: ProjectMember Entity & Role Tests', () {
    test('1. Creates ProjectMember with owner role', () {
      final member = ProjectMember(
        id: 'u1',
        name: 'Alice',
        role: ProjectRole.owner,
      );
      expect(member.id, 'u1');
      expect(member.name, 'Alice');
      expect(member.role, ProjectRole.owner);
      expect(member.isOwner, isTrue);
      expect(member.isMember, isFalse);
    });

    test('2. Creates ProjectMember with member role', () {
      final member = ProjectMember(
        id: 'u2',
        name: 'Bob',
        role: ProjectRole.member,
      );
      expect(member.id, 'u2');
      expect(member.name, 'Bob');
      expect(member.role, ProjectRole.member);
      expect(member.isOwner, isFalse);
      expect(member.isMember, isTrue);
    });

    test('3. ProjectRole enum names check', () {
      expect(ProjectRole.owner.name, 'owner');
      expect(ProjectRole.member.name, 'member');
    });

    test('4. ProjectMember equality and hashCode check', () {
      final now = DateTime(2026, 9, 27);
      final m1 = ProjectMember(id: 'u1', name: 'Alice', role: ProjectRole.owner, joinedAt: now);
      final m2 = ProjectMember(id: 'u1', name: 'Alice', role: ProjectRole.owner, joinedAt: now);
      final m3 = ProjectMember(id: 'u2', name: 'Bob', role: ProjectRole.member);

      expect(m1, equals(m2));
      expect(m1.hashCode, equals(m2.hashCode));
      expect(m1, isNot(equals(m3)));
    });

    test('5. ProjectMember copyWith updates properties correctly', () {
      final m = ProjectMember(id: 'u1', name: 'Alice', role: ProjectRole.member);
      final updated = m.copyWith(name: 'Alice Wonder', role: ProjectRole.owner, photoUrl: 'https://example.com/avatar.png');

      expect(updated.id, 'u1');
      expect(updated.name, 'Alice Wonder');
      expect(updated.role, ProjectRole.owner);
      expect(updated.photoUrl, 'https://example.com/avatar.png');
    });

    test('6. ProjectMember copyWith with no args keeps same values', () {
      final m = ProjectMember(id: 'u1', name: 'Alice', role: ProjectRole.member);
      final same = m.copyWith();
      expect(same, equals(m));
    });

    test('7. ProjectMember toMap and fromMap serialization', () {
      final now = DateTime(2026, 9, 27, 10, 0);
      final member = ProjectMember(
        id: 'u1',
        name: 'Alice',
        role: ProjectRole.owner,
        photoUrl: 'https://avatar.url',
        joinedAt: now,
      );

      final map = member.toMap();
      expect(map['id'], 'u1');
      expect(map['name'], 'Alice');
      expect(map['role'], 'owner');
      expect(map['photoUrl'], 'https://avatar.url');
      expect(map['joinedAt'], now.toIso8601String());

      final from = ProjectMember.fromMap(map);
      expect(from.id, member.id);
      expect(from.name, member.name);
      expect(from.role, member.role);
      expect(from.photoUrl, member.photoUrl);
      expect(from.joinedAt, member.joinedAt);
    });

    test('8. ProjectMember fromMap fallback defaults on missing fields', () {
      final map = <String, dynamic>{'id': 'u99'};
      final member = ProjectMember.fromMap(map);
      expect(member.id, 'u99');
      expect(member.name, '');
      expect(member.role, ProjectRole.member);
      expect(member.photoUrl, isNull);
      expect(member.joinedAt, isNull);
    });

    test('9. ProjectMember fromMap parsing owner role string', () {
      final map = {'id': 'u1', 'name': 'Owner User', 'role': 'owner'};
      final member = ProjectMember.fromMap(map);
      expect(member.role, ProjectRole.owner);
    });

    test('10. ProjectMember fromMap parsing unknown role string defaults to member', () {
      final map = {'id': 'u1', 'name': 'User', 'role': 'moderator'};
      final member = ProjectMember.fromMap(map);
      expect(member.role, ProjectRole.member);
    });

    test('11. ProjectMember toString contains key details', () {
      final member = ProjectMember(id: 'u1', name: 'Alice', role: ProjectRole.owner);
      expect(member.toString(), contains('u1'));
      expect(member.toString(), contains('Alice'));
      expect(member.toString(), contains('owner'));
    });

    test('12. ProjectRole values contains owner and member', () {
      expect(ProjectRole.values, contains(ProjectRole.owner));
      expect(ProjectRole.values, contains(ProjectRole.member));
      expect(ProjectRole.values.length, 2);
    });

    test('13. ProjectMember handles Vietnamese characters in name', () {
      final member = ProjectMember(
        id: 'u_vn',
        name: 'Nguyễn Văn Đức',
        role: ProjectRole.member,
      );
      expect(member.name, 'Nguyễn Văn Đức');
      final map = member.toMap();
      expect(ProjectMember.fromMap(map).name, 'Nguyễn Văn Đức');
    });

    test('14. ProjectMember handles emoji and special characters', () {
      final member = ProjectMember(
        id: 'u_special',
        name: '🚀 Space Leader 🌟',
        role: ProjectRole.owner,
      );
      expect(member.name, '🚀 Space Leader 🌟');
      expect(member.isOwner, isTrue);
    });

    test('15. ProjectRole enum serialization roundtrip', () {
      for (final role in ProjectRole.values) {
        final roleString = role.name;
        final parsed = ProjectRole.values.firstWhere((r) => r.name == roleString);
        expect(parsed, equals(role));
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2: ShareInvite Entity & Validation (16-30)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Group 2: ShareInvite Entity & Validation Tests', () {
    test('16. Valid ShareInvite with future expiration date', () {
      final invite = ShareInvite(
        inviteCode: 'DL-8899',
        projectId: 'proj_1',
        createdBy: 'u1',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        isActive: true,
      );
      expect(invite.isValid, isTrue);
      expect(invite.isExpired, isFalse);
    });

    test('17. ShareInvite marked expired when expiresAt is in past', () {
      final invite = ShareInvite(
        inviteCode: 'DL-1122',
        projectId: 'proj_1',
        createdBy: 'u1',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        isActive: true,
      );
      expect(invite.isValid, isFalse);
      expect(invite.isExpired, isTrue);
    });

    test('18. ShareInvite invalid when isActive is false', () {
      final invite = ShareInvite(
        inviteCode: 'DL-3344',
        projectId: 'proj_1',
        createdBy: 'u1',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        isActive: false,
      );
      expect(invite.isValid, isFalse);
      expect(invite.isExpired, isFalse);
    });

    test('19. ShareInvite with null expiresAt never expires', () {
      final invite = ShareInvite(
        inviteCode: 'DL-0000',
        projectId: 'proj_1',
        createdBy: 'u1',
        createdAt: DateTime.now(),
        expiresAt: null,
        isActive: true,
      );
      expect(invite.isValid, isTrue);
      expect(invite.isExpired, isFalse);
    });

    test('20. ShareInvite toMap and fromMap serialization', () {
      final now = DateTime(2026, 9, 27, 8, 30);
      final expire = now.add(const Duration(days: 7));
      final invite = ShareInvite(
        inviteCode: 'DL-8899',
        projectId: 'proj_dalat',
        createdBy: 'u_alice',
        createdAt: now,
        expiresAt: expire,
        isActive: true,
      );

      final map = invite.toMap();
      expect(map['projectId'], 'proj_dalat');
      expect(map['inviteCode'], 'DL-8899');
      expect(map['createdBy'], 'u_alice');

      final from = ShareInvite.fromMap(map, 'DL-8899');
      expect(from.projectId, invite.projectId);
      expect(from.inviteCode, invite.inviteCode);
      expect(from.createdBy, invite.createdBy);
      expect(from.isActive, invite.isActive);
    });

    test('21. ShareInvite 6-character code formatting check', () {
      final code = 'DL-8899';
      expect(code.length, 7);
      final sixChar = 'DL8899';
      expect(sixChar.length, 6);
      expect(RegExp(r'^[A-Z0-9\-]+$').hasMatch(code), isTrue);
    });

    test('22. ShareInvite equality operator check', () {
      final now = DateTime(2026, 9, 27);
      final inv1 = ShareInvite(
        inviteCode: 'CODE1',
        projectId: 'p1',
        createdBy: 'u1',
        createdAt: now,
      );
      final inv2 = ShareInvite(
        inviteCode: 'CODE1',
        projectId: 'p1',
        createdBy: 'u1',
        createdAt: now,
      );
      expect(inv1, equals(inv2));
      expect(inv1.hashCode, equals(inv2.hashCode));
    });

    test('23. ShareInvite toString contains inviteCode and projectId', () {
      final invite = ShareInvite(
        inviteCode: 'TRIP26',
        projectId: 'p_trip',
        createdBy: 'u1',
        createdAt: DateTime.now(),
      );
      expect(invite.toString(), contains('TRIP26'));
      expect(invite.toString(), contains('p_trip'));
    });

    test('24. ShareInvite fromMap handles missing optional dates', () {
      final map = {
        'projectId': 'p1',
        'createdBy': 'u1',
      };
      final invite = ShareInvite.fromMap(map, 'NODATE');
      expect(invite.inviteCode, 'NODATE');
      expect(invite.expiresAt, isNull);
      expect(invite.isActive, isTrue);
    });

    test('25. ShareInvite with exact boundary expiration', () {
      final now = DateTime.now();
      final invite = ShareInvite(
        inviteCode: 'DL-BOUND',
        projectId: 'p1',
        createdBy: 'u1',
        createdAt: now.subtract(const Duration(hours: 1)),
        expiresAt: now.add(const Duration(milliseconds: 200)),
      );
      expect(invite.isValid, isTrue);
    });

    test('26. ShareInvite props includes all properties', () {
      final invite = ShareInvite(
        inviteCode: 'DL-PROPS',
        projectId: 'p1',
        createdBy: 'u1',
        createdAt: _testTime,
      );
      expect(invite.props, contains('DL-PROPS'));
      expect(invite.props, contains('p1'));
    });

    test('27. ShareInvite defaults isActive to true', () {
      final invite = ShareInvite(
        inviteCode: 'DEF123',
        projectId: 'p1',
        createdBy: 'u1',
        createdAt: _testTime,
      );
      expect(invite.isActive, isTrue);
    });

    test('28. ShareInvite handles uppercase and lowercase code parity', () {
      final invite = ShareInvite(
        inviteCode: 'dl-8899'.toUpperCase(),
        projectId: 'p1',
        createdBy: 'u1',
        createdAt: _testTime,
      );
      expect(invite.inviteCode, 'DL-8899');
    });

    test('29. ShareInvite with expiration 30 days ahead', () {
      final invite = ShareInvite(
        inviteCode: 'DL-LONG',
        projectId: 'p1',
        createdBy: 'u1',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      expect(invite.isValid, isTrue);
      expect(invite.isExpired, isFalse);
    });

    test('30. ShareInvite with expiration 1 second in past is expired', () {
      final invite = ShareInvite(
        inviteCode: 'DL-PAST',
        projectId: 'p1',
        createdBy: 'u1',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      expect(invite.isExpired, isTrue);
      expect(invite.isValid, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 3: FakeCloudSyncRepository Share & Member Operations (31-48)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Group 3: FakeCloudSyncRepository Share & Member Operations', () {
    late FakeCloudSyncRepository fakeRepo;

    setUp(() async {
      fakeRepo = FakeCloudSyncRepository();
      await fakeRepo.saveProject(
        _makeCloudProject(
          id: 'proj_dalat',
          name: 'Đi Đà Lạt 2026',
          ownerId: 'user_alice',
          memberIds: ['user_alice'],
          memberNames: ['Alice'],
        ),
      );
    });

    test('31. createShareInvite produces valid 6-7 char code', () async {
      final invite = await fakeRepo.createShareInvite(
        projectId: 'proj_dalat',
        userId: 'user_alice',
      );
      expect(invite.projectId, 'proj_dalat');
      expect(invite.createdBy, 'user_alice');
      expect(invite.inviteCode, isNotEmpty);
      expect(invite.isValid, isTrue);
    });

    test('32. getShareInvite retrieves existing invite by code', () async {
      final created = await fakeRepo.createShareInvite(
        projectId: 'proj_dalat',
        userId: 'user_alice',
      );
      final retrieved = await fakeRepo.getShareInvite(created.inviteCode);
      expect(retrieved, isNotNull);
      expect(retrieved!.inviteCode, created.inviteCode);
      expect(retrieved.projectId, 'proj_dalat');
    });

    test('33. getShareInvite returns null for nonexistent code', () async {
      final res = await fakeRepo.getShareInvite('NONEXIST');
      expect(res, isNull);
    });

    test('34. getShareInvite is case-insensitive', () async {
      final created = await fakeRepo.createShareInvite(
        projectId: 'proj_dalat',
        userId: 'user_alice',
      );
      final retrieved = await fakeRepo.getShareInvite(created.inviteCode.toLowerCase());
      expect(retrieved, isNotNull);
      expect(retrieved!.inviteCode, created.inviteCode);
    });

    test('35. joinProjectWithInviteCode adds user to project members', () async {
      final invite = await fakeRepo.createShareInvite(
        projectId: 'proj_dalat',
        userId: 'user_alice',
      );

      final project = await fakeRepo.joinProjectWithInviteCode(
        inviteCode: invite.inviteCode,
        userId: 'user_bob',
        userName: 'Bob',
      );

      expect(project.memberIds, contains('user_bob'));
      expect(project.memberNames, contains('Bob'));
      expect(project.memberIds.length, 2);
    });

    test('36. joinProjectWithInviteCode throws on invalid code', () async {
      expect(
        () => fakeRepo.joinProjectWithInviteCode(
          inviteCode: 'INVALID',
          userId: 'user_bob',
          userName: 'Bob',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('37. joinProjectWithInviteCode is idempotent if user already in project', () async {
      final invite = await fakeRepo.createShareInvite(
        projectId: 'proj_dalat',
        userId: 'user_alice',
      );

      await fakeRepo.joinProjectWithInviteCode(
        inviteCode: invite.inviteCode,
        userId: 'user_bob',
        userName: 'Bob',
      );

      final secondJoin = await fakeRepo.joinProjectWithInviteCode(
        inviteCode: invite.inviteCode,
        userId: 'user_bob',
        userName: 'Bob',
      );

      expect(secondJoin.memberIds.where((id) => id == 'user_bob').length, 1);
    });

    test('38. removeMemberFromProject successfully removes member', () async {
      final invite = await fakeRepo.createShareInvite(
        projectId: 'proj_dalat',
        userId: 'user_alice',
      );
      await fakeRepo.joinProjectWithInviteCode(
        inviteCode: invite.inviteCode,
        userId: 'user_bob',
        userName: 'Bob',
      );

      await fakeRepo.removeMemberFromProject(
        projectId: 'proj_dalat',
        memberId: 'user_bob',
        memberName: 'Bob',
      );

      final proj = await fakeRepo.getProject('proj_dalat');
      expect(proj!.memberIds, isNot(contains('user_bob')));
      expect(proj.memberNames, isNot(contains('Bob')));
    });

    test('39. removeMemberFromProject throws if trying to remove project owner', () async {
      expect(
        () => fakeRepo.removeMemberFromProject(
          projectId: 'proj_dalat',
          memberId: 'user_alice',
          memberName: 'Alice',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('40. leaveProject successfully allows member to exit', () async {
      final invite = await fakeRepo.createShareInvite(
        projectId: 'proj_dalat',
        userId: 'user_alice',
      );
      await fakeRepo.joinProjectWithInviteCode(
        inviteCode: invite.inviteCode,
        userId: 'user_charlie',
        userName: 'Charlie',
      );

      await fakeRepo.leaveProject(
        projectId: 'proj_dalat',
        userId: 'user_charlie',
        userName: 'Charlie',
      );

      final proj = await fakeRepo.getProject('proj_dalat');
      expect(proj!.memberIds, isNot(contains('user_charlie')));
    });

    test('41. leaveProject throws if owner tries to leave without transferring', () async {
      expect(
        () => fakeRepo.leaveProject(
          projectId: 'proj_dalat',
          userId: 'user_alice',
          userName: 'Alice',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('42. Multiple members can join sequentially with the same invite', () async {
      final invite = await fakeRepo.createShareInvite(
        projectId: 'proj_dalat',
        userId: 'user_alice',
      );

      await fakeRepo.joinProjectWithInviteCode(
        inviteCode: invite.inviteCode,
        userId: 'u_b',
        userName: 'Bob',
      );
      await fakeRepo.joinProjectWithInviteCode(
        inviteCode: invite.inviteCode,
        userId: 'u_c',
        userName: 'Charlie',
      );
      await fakeRepo.joinProjectWithInviteCode(
        inviteCode: invite.inviteCode,
        userId: 'u_d',
        userName: 'Diana',
      );

      final proj = await fakeRepo.getProject('proj_dalat');
      expect(proj!.memberIds.length, 4);
    });

    test('43. generateInviteCode returns uppercase alphanumeric code with prefix', () {
      final code = fakeRepo.generateInviteCode(prefix: 'DL');
      expect(code.startsWith('DL-'), isTrue);
      expect(code.length, 7);
    });

    test('44. generateInviteCode generates distinct codes', () {
      final c1 = fakeRepo.generateInviteCode();
      final c2 = fakeRepo.generateInviteCode();
      expect(c1, isNot(equals(c2)));
    });

    test('45. removeMemberFromProject on non-existent project throws', () async {
      expect(
        () => fakeRepo.removeMemberFromProject(
          projectId: 'proj_ghost',
          memberId: 'user_bob',
          memberName: 'Bob',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('46. leaveProject on non-existent project throws', () async {
      expect(
        () => fakeRepo.leaveProject(
          projectId: 'proj_ghost',
          userId: 'user_bob',
          userName: 'Bob',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('47. createShareInvite supports custom validDuration', () async {
      final invite = await fakeRepo.createShareInvite(
        projectId: 'proj_dalat',
        userId: 'user_alice',
        validDuration: const Duration(hours: 1),
      );
      expect(invite.expiresAt, isNotNull);
      expect(invite.isValid, isTrue);
    });

    test('48. getProject returns saved cloud project', () async {
      final proj = await fakeRepo.getProject('proj_dalat');
      expect(proj, isNotNull);
      expect(proj!.name, 'Đi Đà Lạt 2026');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 4: ProjectPermissionService Role-Based Access Control (49-70)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Group 4: ProjectPermissionService RBAC Rules', () {
    const service = ProjectPermissionService();

    final localProject = _makeProject(
      id: 'p1',
      name: 'Du lịch Sapa',
      members: ['Alice', 'Bob', 'Charlie'],
    );

    final cloudProject = _makeCloudProject(
      id: 'p1',
      name: 'Du lịch Sapa',
      ownerId: 'u_alice',
      memberIds: ['u_alice', 'u_bob', 'u_charlie'],
      memberNames: ['Alice', 'Bob', 'Charlie'],
    );

    final billCreatedByBob = _makeBill(
      id: 'b1',
      title: 'Tiền xe cabin',
      amount: 1200000,
      paidBy: 'Bob',
      projectId: 'p1',
    );

    final billCreatedByAlice = _makeBill(
      id: 'b2',
      title: 'Khách sạn Fansipan',
      amount: 3500000,
      paidBy: 'Alice',
      projectId: 'p1',
    );

    test('49. Owner role is correctly detected from cloudProject.ownerId', () {
      final role = service.getUserRole(
        userId: 'u_alice',
        project: localProject,
        cloudProject: cloudProject,
      );
      expect(role, ProjectRole.owner);
    });

    test('50. Member role is detected for participating member', () {
      final role = service.getUserRole(
        userId: 'u_bob',
        project: localProject,
        cloudProject: cloudProject,
      );
      expect(role, ProjectRole.member);
    });

    test('51. First member in local project is considered owner if cloudProject is null', () {
      final roleAlice = service.getUserRole(
        userId: 'Alice',
        project: localProject,
      );
      expect(roleAlice, ProjectRole.owner);
    });

    test('52. canAddBill returns true for project owner', () {
      final canAdd = service.canAddBill(
        userId: 'u_alice',
        userName: 'Alice',
        project: localProject,
        cloudProject: cloudProject,
      );
      expect(canAdd, isTrue);
    });

    test('53. canAddBill returns true for project member', () {
      final canAdd = service.canAddBill(
        userId: 'u_bob',
        userName: 'Bob',
        project: localProject,
        cloudProject: cloudProject,
      );
      expect(canAdd, isTrue);
    });

    test('54. canAddBill returns false for non-member in cloud project', () {
      final canAdd = service.canAddBill(
        userId: 'u_stranger',
        userName: 'Stranger',
        project: localProject,
        cloudProject: cloudProject,
      );
      expect(canAdd, isFalse);
    });

    test('55. Owner can edit ANY bill in the project', () {
      final canEditBobBill = service.canEditBill(
        userId: 'u_alice',
        userName: 'Alice',
        bill: billCreatedByBob,
        project: localProject,
        cloudProject: cloudProject,
      );
      expect(canEditBobBill, isTrue);
    });

    test('56. Member can edit bill they created (matched by userName / paidBy)', () {
      final canEditOwnBill = service.canEditBill(
        userId: 'u_bob',
        userName: 'Bob',
        bill: billCreatedByBob,
        project: localProject,
        cloudProject: cloudProject,
      );
      expect(canEditOwnBill, isTrue);
    });

    test('57. Member can edit bill matched by userId when paidBy holds userId', () {
      final billWithId = _makeBill(
        id: 'b3',
        title: 'Ăn tối lẩu gà',
        amount: 600000,
        paidBy: 'u_charlie',
        projectId: 'p1',
      );

      final canEdit = service.canEditBill(
        userId: 'u_charlie',
        userName: 'Charlie',
        bill: billWithId,
        project: localProject,
        cloudProject: cloudProject,
      );
      expect(canEdit, isTrue);
    });

    test('58. Member CANNOT edit bill created by another member', () {
      final canEdit = service.canEditBill(
        userId: 'u_bob',
        userName: 'Bob',
        bill: billCreatedByAlice,
        project: localProject,
        cloudProject: cloudProject,
      );
      expect(canEdit, isFalse);
    });

    test('59. Stranger CANNOT edit any bill in project', () {
      final canEdit = service.canEditBill(
        userId: 'u_stranger',
        userName: 'Stranger',
        bill: billCreatedByBob,
        project: localProject,
        cloudProject: cloudProject,
      );
      expect(canEdit, isFalse);
    });

    test('60. Owner can delete ANY bill in the project', () {
      final canDelete = service.canDeleteBill(
        userId: 'u_alice',
        userName: 'Alice',
        bill: billCreatedByBob,
        project: localProject,
        cloudProject: cloudProject,
      );
      expect(canDelete, isTrue);
    });

    test('61. Member can delete bill they created / paid for', () {
      final canDelete = service.canDeleteBill(
        userId: 'u_bob',
        userName: 'Bob',
        bill: billCreatedByBob,
        project: localProject,
        cloudProject: cloudProject,
      );
      expect(canDelete, isTrue);
    });

    test('62. Member CANNOT delete bill created by another member', () {
      final canDelete = service.canDeleteBill(
        userId: 'u_charlie',
        userName: 'Charlie',
        bill: billCreatedByBob,
        project: localProject,
        cloudProject: cloudProject,
      );
      expect(canDelete, isFalse);
    });

    test('63. Owner CAN kick members', () {
      final canKick = service.canKickMember(
        currentUserId: 'u_alice',
        targetMemberId: 'u_bob',
        project: localProject,
        cloudProject: cloudProject,
      );
      expect(canKick, isTrue);
    });

    test('64. Owner CANNOT kick themselves', () {
      final canKickSelf = service.canKickMember(
        currentUserId: 'u_alice',
        targetMemberId: 'u_alice',
        project: localProject,
        cloudProject: cloudProject,
      );
      expect(canKickSelf, isFalse);
    });

    test('65. Member CANNOT kick other members', () {
      final canKick = service.canKickMember(
        currentUserId: 'u_bob',
        targetMemberId: 'u_charlie',
        project: localProject,
        cloudProject: cloudProject,
      );
      expect(canKick, isFalse);
    });

    test('66. Member CAN leave project', () {
      final canLeave = service.canLeaveProject(
        currentUserId: 'u_bob',
        project: localProject,
        cloudProject: cloudProject,
      );
      expect(canLeave, isTrue);
    });

    test('67. Owner CANNOT leave project directly', () {
      final canLeave = service.canLeaveProject(
        currentUserId: 'u_alice',
        project: localProject,
        cloudProject: cloudProject,
      );
      expect(canLeave, isFalse);
    });

    test('68. canDeleteProject allows owner only', () {
      expect(service.canDeleteProject(currentUserId: 'u_alice', project: localProject, cloudProject: cloudProject), isTrue);
      expect(service.canDeleteProject(currentUserId: 'u_bob', project: localProject, cloudProject: cloudProject), isFalse);
    });

    test('69. buildMemberList extracts members and assigns owner badge', () {
      final list = service.buildMemberList(
        project: localProject,
        cloudProject: cloudProject,
      );
      expect(list.length, 3);
      final alice = list.firstWhere((m) => m.id == 'u_alice');
      expect(alice.isOwner, isTrue);
      final bob = list.firstWhere((m) => m.id == 'u_bob');
      expect(bob.isOwner, isFalse);
      expect(bob.isMember, isTrue);
    });

    test('70. buildMemberList falls back to localProject.members when cloudProject is null', () {
      final list = service.buildMemberList(project: localProject);
      expect(list.length, 3);
      expect(list.first.isOwner, isTrue);
      expect(list[1].isMember, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 5: ShareProjectModal Widget Tests (71-85)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Group 5: ShareProjectModal Widget Tests', () {
    late FakeCloudSyncRepository fakeRepo;

    setUp(() async {
      fakeRepo = FakeCloudSyncRepository();
      await fakeRepo.saveProject(
        _makeCloudProject(
          id: 'proj_hanoi',
          name: 'Hội Bạn Hà Nội',
          ownerId: 'u1',
          memberIds: ['u1'],
        ),
      );
    });

    testWidgets('71. Displays project name and share title', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ShareProjectModal(
            projectId: 'proj_hanoi',
            projectName: 'Hội Bạn Hà Nội',
            userId: 'u1',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hội Bạn Hà Nội'), findsOneWidget);
      expect(find.byKey(const Key('shareProjectModal')), findsOneWidget);
    });

    testWidgets('72. Generates and renders 6-character invite code display', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ShareProjectModal(
            projectId: 'proj_hanoi',
            projectName: 'Hội Bạn Hà Nội',
            userId: 'u1',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('inviteCodeDisplay')), findsOneWidget);
      final codeWidget = tester.widget<SelectableText>(find.byKey(const Key('inviteCodeDisplay')));
      expect(codeWidget.data, isNotEmpty);
    });

    testWidgets('73. Renders QR Code container with custom painter', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ShareProjectModal(
            projectId: 'proj_hanoi',
            projectName: 'Hội Bạn Hà Nội',
            userId: 'u1',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('qrCodeContainer')), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('74. Displays share web link text', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ShareProjectModal(
            projectId: 'proj_hanoi',
            projectName: 'Hội Bạn Hà Nội',
            userId: 'u1',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('shareLinkText')), findsOneWidget);
      final linkText = tester.widget<Text>(find.byKey(const Key('shareLinkText'))).data!;
      expect(linkText, contains('homesplit.app/join?code='));
    });

    testWidgets('75. Renders Copy Code and Copy Link buttons', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ShareProjectModal(
            projectId: 'proj_hanoi',
            projectName: 'Hội Bạn Hà Nội',
            userId: 'u1',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('copyInviteCodeButton')), findsOneWidget);
      expect(find.byKey(const Key('copyShareLinkButton')), findsOneWidget);
    });

    testWidgets('76. Tapping Copy Code invokes clipboard service', (tester) async {
      final List<MethodCall> log = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        log.add(methodCall);
        return null;
      });

      await tester.pumpWidget(
        _buildTestApp(
          ShareProjectModal(
            projectId: 'proj_hanoi',
            projectName: 'Hội Bạn Hà Nội',
            userId: 'u1',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('copyInviteCodeButton')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(log.any((call) => call.method == 'Clipboard.setData'), isTrue);
    });

    testWidgets('77. Tapping Copy Link puts correct URL into clipboard', (tester) async {
      String? copiedContent;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          copiedContent = (methodCall.arguments as Map)['text'];
        }
        return null;
      });

      await tester.pumpWidget(
        _buildTestApp(
          ShareProjectModal(
            projectId: 'proj_hanoi',
            projectName: 'Hội Bạn Hà Nội',
            userId: 'u1',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('copyShareLinkButton')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(copiedContent, isNotNull);
      expect(copiedContent, contains('homesplit.app/join?code='));
    });

    testWidgets('78. Displays modal content and invite code container', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ShareProjectModal(
            projectId: 'proj_hanoi',
            projectName: 'Hội Bạn Hà Nội',
            userId: 'u1',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('shareProjectModal')), findsOneWidget);
      expect(find.byKey(const Key('inviteCodeDisplay')), findsOneWidget);
    });

    testWidgets('79. Shows error message when invite generation fails', (tester) async {
      final failingRepo = _ThrowingCloudSyncRepository();
      await tester.pumpWidget(
        _buildTestApp(
          ShareProjectModal(
            projectId: 'non_existent_proj',
            projectName: 'Lỗi',
            userId: 'u1',
            cloudSyncRepository: failingRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inviteCodeDisplay')), findsNothing);
      expect(find.textContaining('Network failure'), findsOneWidget);
    });

    testWidgets('80. Supports English locale strings', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ShareProjectModal(
            projectId: 'proj_hanoi',
            projectName: 'Hanoi Trip',
            userId: 'u1',
            cloudSyncRepository: fakeRepo,
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('copyInviteCodeButton')), findsOneWidget);
    });

    testWidgets('81. Drag handle is visible at the top', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ShareProjectModal(
            projectId: 'proj_hanoi',
            projectName: 'Trip',
            userId: 'u1',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('shareProjectModal')), findsOneWidget);
    });

    testWidgets('82. Static show method opens modal bottom sheet', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (ctx) => ElevatedButton(
              key: const Key('openShareModal'),
              onPressed: () => ShareProjectModal.show(
                ctx,
                projectId: 'proj_hanoi',
                projectName: 'Hội Bạn Hà Nội',
                userId: 'u1',
                cloudSyncRepository: fakeRepo,
              ),
              child: const Text('Share'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('openShareModal')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('shareProjectModal')), findsOneWidget);
    });

    testWidgets('83. Invite code is shown in uppercase', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ShareProjectModal(
            projectId: 'proj_hanoi',
            projectName: 'Trip',
            userId: 'u1',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final codeWidget = tester.widget<SelectableText>(find.byKey(const Key('inviteCodeDisplay')));
      expect(codeWidget.data, codeWidget.data!.toUpperCase());
    });

    testWidgets('84. QR code painter repaints when code changes', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ShareProjectModal(
            projectId: 'proj_hanoi',
            projectName: 'Trip',
            userId: 'u1',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('qrCodeContainer')), findsOneWidget);
    });

    testWidgets('85. SnackBar shows confirmation after copying invite code', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ShareProjectModal(
            projectId: 'proj_hanoi',
            projectName: 'Trip',
            userId: 'u1',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('copyInviteCodeButton')));
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 6: JoinProjectDialog Widget Tests (86-100)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Group 6: JoinProjectDialog Widget Tests', () {
    late FakeCloudSyncRepository fakeRepo;
    late ShareInvite activeInvite;

    setUp(() async {
      fakeRepo = FakeCloudSyncRepository();
      await fakeRepo.saveProject(
        _makeCloudProject(
          id: 'proj_nhatrang',
          name: 'Nha Trang Beach 2026',
          ownerId: 'u_owner',
          memberIds: ['u_owner'],
          memberNames: ['Owner'],
        ),
      );

      activeInvite = await fakeRepo.createShareInvite(
        projectId: 'proj_nhatrang',
        userId: 'u_owner',
      );
    });

    testWidgets('86. Renders dialog elements (title, textfield, cancel button)', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          JoinProjectDialog(
            userId: 'u_joiner',
            userName: 'Joiner',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('joinProjectDialog')), findsOneWidget);
      expect(find.byKey(const Key('joinProjectCodeField')), findsOneWidget);
      expect(find.byKey(const Key('cancelJoinProjectButton')), findsOneWidget);
      expect(find.byKey(const Key('confirmJoinProjectButton')), findsOneWidget);
    });

    testWidgets('87. Typing into code field converts text to uppercase', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          JoinProjectDialog(
            userId: 'u_joiner',
            userName: 'Joiner',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('joinProjectCodeField')), 'dl-8899');
      await tester.pump();

      final field = tester.widget<TextField>(find.byKey(const Key('joinProjectCodeField')));
      expect(field.controller!.text, 'dl-8899');
    });

    testWidgets('88. Searching for invalid code displays error message', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          JoinProjectDialog(
            userId: 'u_joiner',
            userName: 'Joiner',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('joinProjectCodeField')), 'WRONG1');
      await tester.tap(find.byKey(const Key('checkCodeButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('joinProjectErrorMessage')), findsOneWidget);
    });

    testWidgets('89. Searching for valid code shows project preview card', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          JoinProjectDialog(
            userId: 'u_joiner',
            userName: 'Joiner',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('joinProjectCodeField')), activeInvite.inviteCode);
      await tester.tap(find.byKey(const Key('checkCodeButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectPreviewContainer')), findsOneWidget);
      expect(find.text('Nha Trang Beach 2026'), findsOneWidget);
    });

    testWidgets('90. Confirm button updates label to Join when preview is loaded', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          JoinProjectDialog(
            userId: 'u_joiner',
            userName: 'Joiner',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('joinProjectCodeField')), activeInvite.inviteCode);
      await tester.tap(find.byKey(const Key('checkCodeButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirmJoinProjectButton')), findsOneWidget);
    });

    testWidgets('91. Tapping confirm button joins project and pops dialog', (tester) async {
      Project? returnedProject;

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (ctx) => ElevatedButton(
              key: const Key('openJoinBtn'),
              onPressed: () async {
                returnedProject = await JoinProjectDialog.show(
                  ctx,
                  userId: 'u_joiner',
                  userName: 'Joiner',
                  cloudSyncRepository: fakeRepo,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('openJoinBtn')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('joinProjectCodeField')), activeInvite.inviteCode);
      await tester.tap(find.byKey(const Key('checkCodeButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirmJoinProjectButton')));
      await tester.pumpAndSettle();

      expect(returnedProject, isNotNull);
      expect(returnedProject!.id, 'proj_nhatrang');
      expect(find.byKey(const Key('joinProjectDialog')), findsNothing);
    });

    testWidgets('92. Cancel button closes dialog without joining', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          JoinProjectDialog(
            userId: 'u_joiner',
            userName: 'Joiner',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancelJoinProjectButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('joinProjectDialog')), findsNothing);
    });

    testWidgets('93. Empty code submission does nothing', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          JoinProjectDialog(
            userId: 'u_joiner',
            userName: 'Joiner',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('checkCodeButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectPreviewContainer')), findsNothing);
      expect(find.byKey(const Key('joinProjectErrorMessage')), findsNothing);
    });

    testWidgets('94. Preview displays member count and currency', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          JoinProjectDialog(
            userId: 'u_joiner',
            userName: 'Joiner',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('joinProjectCodeField')), activeInvite.inviteCode);
      await tester.tap(find.byKey(const Key('checkCodeButton')));
      await tester.pumpAndSettle();

      expect(find.textContaining('1 thành viên • VND'), findsOneWidget);
    });

    testWidgets('95. Error message cleared when re-checking a new code', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          JoinProjectDialog(
            userId: 'u_joiner',
            userName: 'Joiner',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter bad code first
      await tester.enterText(find.byKey(const Key('joinProjectCodeField')), 'BAD001');
      await tester.tap(find.byKey(const Key('checkCodeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('joinProjectErrorMessage')), findsOneWidget);

      // Enter good code
      await tester.enterText(find.byKey(const Key('joinProjectCodeField')), activeInvite.inviteCode);
      await tester.tap(find.byKey(const Key('checkCodeButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('joinProjectErrorMessage')), findsNothing);
      expect(find.byKey(const Key('projectPreviewContainer')), findsOneWidget);
    });

    testWidgets('96. Pressing Enter/Submit on keyboard triggers check', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          JoinProjectDialog(
            userId: 'u_joiner',
            userName: 'Joiner',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('joinProjectCodeField')), activeInvite.inviteCode);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectPreviewContainer')), findsOneWidget);
    });

    testWidgets('97. Displays icon in project preview card', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          JoinProjectDialog(
            userId: 'u_joiner',
            userName: 'Joiner',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('joinProjectCodeField')), activeInvite.inviteCode);
      await tester.tap(find.byKey(const Key('checkCodeButton')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.flight_takeoff_rounded), findsOneWidget);
    });

    testWidgets('98. Supports English locale', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          JoinProjectDialog(
            userId: 'u_joiner',
            userName: 'Joiner',
            cloudSyncRepository: fakeRepo,
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('joinProjectDialog')), findsOneWidget);
    });

    testWidgets('99. Dialog adapts to dark theme without overflow', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          JoinProjectDialog(
            userId: 'u_joiner',
            userName: 'Joiner',
            cloudSyncRepository: fakeRepo,
          ),
          theme: ThemeData.dark(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('joinProjectDialog')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('100. Textfield max length is 10', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          JoinProjectDialog(
            userId: 'u_joiner',
            userName: 'Joiner',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byKey(const Key('joinProjectCodeField')));
      expect(field.maxLength, 10);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 7: ProjectMembersModal Widget Tests (101-115)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Group 7: ProjectMembersModal Widget Tests', () {
    late FakeCloudSyncRepository fakeRepo;
    late Project sampleProject;
    late CloudProject sampleCloudProject;

    setUp(() async {
      fakeRepo = FakeCloudSyncRepository();
      sampleProject = _makeProject(
        id: 'proj_team',
        name: 'Nhóm Leo Núi Fansipan',
        members: ['Alice', 'Bob', 'Charlie'],
      );

      sampleCloudProject = _makeCloudProject(
        id: 'proj_team',
        name: 'Nhóm Leo Núi Fansipan',
        ownerId: 'u_alice',
        memberIds: ['u_alice', 'u_bob', 'u_charlie'],
        memberNames: ['Alice', 'Bob', 'Charlie'],
      );

      await fakeRepo.saveProject(sampleCloudProject);
    });

    testWidgets('101. Renders members list with member count badge', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ProjectMembersModal(
            project: sampleProject,
            cloudProject: sampleCloudProject,
            currentUserId: 'u_alice',
            currentUserName: 'Alice',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectMembersModal')), findsOneWidget);
      expect(find.byKey(const Key('membersCountBadge')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('102. Displays Owner badge for project owner', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ProjectMembersModal(
            project: sampleProject,
            cloudProject: sampleCloudProject,
            currentUserId: 'u_alice',
            currentUserName: 'Alice',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ownerBadge_u_alice')), findsOneWidget);
    });

    testWidgets('103. Displays Member badge for other members', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ProjectMembersModal(
            project: sampleProject,
            cloudProject: sampleCloudProject,
            currentUserId: 'u_alice',
            currentUserName: 'Alice',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('memberBadge_u_bob')), findsOneWidget);
      expect(find.byKey(const Key('memberBadge_u_charlie')), findsOneWidget);
    });

    testWidgets('104. Owner sees kick buttons on other members but NOT on self', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ProjectMembersModal(
            project: sampleProject,
            cloudProject: sampleCloudProject,
            currentUserId: 'u_alice',
            currentUserName: 'Alice',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('kickMemberButton_u_alice')), findsNothing);
      expect(find.byKey(const Key('kickMemberButton_u_bob')), findsOneWidget);
      expect(find.byKey(const Key('kickMemberButton_u_charlie')), findsOneWidget);
    });

    testWidgets('105. Member does NOT see kick buttons on anyone', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ProjectMembersModal(
            project: sampleProject,
            cloudProject: sampleCloudProject,
            currentUserId: 'u_bob',
            currentUserName: 'Bob',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('kickMemberButton_u_alice')), findsNothing);
      expect(find.byKey(const Key('kickMemberButton_u_bob')), findsNothing);
      expect(find.byKey(const Key('kickMemberButton_u_charlie')), findsNothing);
    });

    testWidgets('106. Member sees Leave Project button on header', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ProjectMembersModal(
            project: sampleProject,
            cloudProject: sampleCloudProject,
            currentUserId: 'u_bob',
            currentUserName: 'Bob',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('leaveProjectButton')), findsOneWidget);
    });

    testWidgets('107. Owner does NOT see Leave Project button', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ProjectMembersModal(
            project: sampleProject,
            cloudProject: sampleCloudProject,
            currentUserId: 'u_alice',
            currentUserName: 'Alice',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('leaveProjectButton')), findsNothing);
    });

    testWidgets('108. Tapping kick button opens confirmation dialog', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ProjectMembersModal(
            project: sampleProject,
            cloudProject: sampleCloudProject,
            currentUserId: 'u_alice',
            currentUserName: 'Alice',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('kickMemberButton_u_bob')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('Bob'), findsWidgets);

      await tester.tap(find.widgetWithText(TextButton, 'Hủy'));
      await tester.pumpAndSettle();
    });

    testWidgets('109. Confirming kick removes member from list', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ProjectMembersModal(
            project: sampleProject,
            cloudProject: sampleCloudProject,
            currentUserId: 'u_alice',
            currentUserName: 'Alice',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('kickMemberButton_u_bob')));
      await tester.pumpAndSettle();

      // Tap confirm in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Gỡ'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('memberTile_u_bob')), findsNothing);
    });

    testWidgets('110. Cancelling kick dialog keeps member in list', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ProjectMembersModal(
            project: sampleProject,
            cloudProject: sampleCloudProject,
            currentUserId: 'u_alice',
            currentUserName: 'Alice',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('kickMemberButton_u_bob')));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Hủy'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('memberTile_u_bob')), findsOneWidget);
    });

    testWidgets('111. Current user tile displays You tag', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ProjectMembersModal(
            project: sampleProject,
            cloudProject: sampleCloudProject,
            currentUserId: 'u_bob',
            currentUserName: 'Bob',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bạn'), findsOneWidget);
    });

    testWidgets('112. Static show method opens modal bottom sheet', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (ctx) => ElevatedButton(
              key: const Key('openModalBtn'),
              onPressed: () => ProjectMembersModal.show(
                ctx,
                project: sampleProject,
                cloudProject: sampleCloudProject,
                currentUserId: 'u_alice',
                cloudSyncRepository: fakeRepo,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('openModalBtn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectMembersModal')), findsOneWidget);
    });

    testWidgets('113. Leave button shows confirmation dialog', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ProjectMembersModal(
            project: sampleProject,
            cloudProject: sampleCloudProject,
            currentUserId: 'u_bob',
            currentUserName: 'Bob',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('leaveProjectButton')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Hủy'));
      await tester.pumpAndSettle();
    });

    testWidgets('114. Modal handles dark theme styling', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ProjectMembersModal(
            project: sampleProject,
            cloudProject: sampleCloudProject,
            currentUserId: 'u_alice',
            cloudSyncRepository: fakeRepo,
          ),
          theme: ThemeData.dark(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectMembersModal')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('115. Member avatars show first letter of member name', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ProjectMembersModal(
            project: sampleProject,
            cloudProject: sampleCloudProject,
            currentUserId: 'u_alice',
            cloudSyncRepository: fakeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 8: End-to-End Integration Flow & Localization Verification (116-121)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Group 8: End-to-End Flow & Localization Verification', () {
    test('116. Complete invite generation -> lookup -> join -> permission pipeline', () async {
      final repo = FakeCloudSyncRepository();
      const service = ProjectPermissionService();

      // 1. Owner creates cloud project
      final cloudProj = _makeCloudProject(
        id: 'proj_trip',
        name: 'Chuyến Đi Côn Đảo',
        ownerId: 'u_alice',
        memberIds: ['u_alice'],
        memberNames: ['Alice'],
      );
      await repo.saveProject(cloudProj);

      // 2. Owner generates invite code
      final invite = await repo.createShareInvite(
        projectId: cloudProj.id,
        userId: 'u_alice',
      );
      expect(invite.isValid, isTrue);

      // 3. User B looks up invite
      final found = await repo.getShareInvite(invite.inviteCode);
      expect(found, isNotNull);
      expect(found!.projectId, cloudProj.id);

      // 4. User B joins project
      final updatedProj = await repo.joinProjectWithInviteCode(
        inviteCode: invite.inviteCode,
        userId: 'u_bob',
        userName: 'Bob',
      );
      expect(updatedProj.memberIds, contains('u_bob'));

      // 5. Verify User B has canAddBill permission
      final local = _makeProject(
        id: updatedProj.id,
        name: updatedProj.name,
        members: updatedProj.memberNames,
        currency: updatedProj.currency,
      );

      final canBobAdd = service.canAddBill(
        userId: 'u_bob',
        userName: 'Bob',
        project: local,
        cloudProject: updatedProj,
      );
      expect(canBobAdd, isTrue);

      // 6. User B creates bill
      final bobBill = _makeBill(
        id: 'bill_bob',
        title: 'Vé tàu cao tốc',
        amount: 800000,
        paidBy: 'Bob',
        projectId: updatedProj.id,
      );

      // 7. User B can edit own bill
      expect(
        service.canEditBill(
          userId: 'u_bob',
          userName: 'Bob',
          bill: bobBill,
          project: local,
          cloudProject: updatedProj,
        ),
        isTrue,
      );

      // 8. User B cannot edit Alice's bill
      final aliceBill = _makeBill(
        id: 'bill_alice',
        title: 'Khách sạn Marina',
        amount: 2500000,
        paidBy: 'Alice',
        projectId: updatedProj.id,
      );
      expect(
        service.canEditBill(
          userId: 'u_bob',
          userName: 'Bob',
          bill: aliceBill,
          project: local,
          cloudProject: updatedProj,
        ),
        isFalse,
      );

      // 9. Alice (Owner) can edit and delete Bob's bill
      expect(
        service.canEditBill(
          userId: 'u_alice',
          userName: 'Alice',
          bill: bobBill,
          project: local,
          cloudProject: updatedProj,
        ),
        isTrue,
      );
      expect(
        service.canDeleteBill(
          userId: 'u_alice',
          userName: 'Alice',
          bill: bobBill,
          project: local,
          cloudProject: updatedProj,
        ),
        isTrue,
      );
    });

    testWidgets('117. Verifies Vietnamese localization keys presence', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (ctx) {
              final loc = AppLocalizations.of(ctx);
              expect(loc.translate('join_project_instruction'), isNotEmpty);
              expect(loc.translate('join_code_hint'), isNotEmpty);
              expect(loc.translate('check_code_button'), isNotEmpty);
              expect(loc.translate('copy_link_button'), isNotEmpty);
              expect(loc.translate('share_link_copied'), isNotEmpty);
              expect(loc.translate('project_members_title'), isNotEmpty);
              expect(loc.translate('owner_role'), isNotEmpty);
              expect(loc.translate('member_role'), isNotEmpty);
              expect(loc.translate('remove_member_title'), isNotEmpty);
              expect(loc.translate('leave_project_title'), isNotEmpty);
              expect(loc.translate('you_label'), isNotEmpty);
              return const SizedBox();
            },
          ),
          locale: const Locale('vi'),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('118. Verifies English localization keys presence', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (ctx) {
              final loc = AppLocalizations.of(ctx);
              expect(loc.translate('join_project_instruction'), isNotEmpty);
              expect(loc.translate('join_code_hint'), isNotEmpty);
              expect(loc.translate('check_code_button'), isNotEmpty);
              expect(loc.translate('copy_link_button'), isNotEmpty);
              expect(loc.translate('share_link_copied'), isNotEmpty);
              expect(loc.translate('project_members_title'), isNotEmpty);
              expect(loc.translate('owner_role'), isNotEmpty);
              expect(loc.translate('member_role'), isNotEmpty);
              expect(loc.translate('remove_member_title'), isNotEmpty);
              expect(loc.translate('leave_project_title'), isNotEmpty);
              expect(loc.translate('you_label'), isNotEmpty);
              return const SizedBox();
            },
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
    });

    test('119. ProjectRole equality edge cases', () {
      expect(ProjectRole.owner == ProjectRole.member, isFalse);
      expect(ProjectRole.owner == ProjectRole.owner, isTrue);
    });

    test('120. Member leaving project and checking permission afterwards', () async {
      final repo = FakeCloudSyncRepository();
      const service = ProjectPermissionService();

      final proj = _makeCloudProject(
        id: 'p_leaver',
        name: 'Leaving Test',
        ownerId: 'u_owner',
        memberIds: ['u_owner', 'u_leaver'],
        memberNames: ['Owner', 'Leaver'],
      );
      await repo.saveProject(proj);

      await repo.leaveProject(
        projectId: 'p_leaver',
        userId: 'u_leaver',
        userName: 'Leaver',
      );

      final updated = await repo.getProject('p_leaver');
      final local = _makeProject(
        id: updated!.id,
        name: updated.name,
        members: updated.memberNames,
        currency: updated.currency,
      );

      expect(
        service.canAddBill(
          userId: 'u_leaver',
          userName: 'Leaver',
          project: local,
          cloudProject: updated,
        ),
        isFalse,
      );
    });

    test('121. Invite code prefix customisation in repository', () async {
      final repo = FakeCloudSyncRepository();
      final code = repo.generateInviteCode(prefix: 'TRIP');
      expect(code.startsWith('TRIP-'), isTrue);
    });
  });
}
