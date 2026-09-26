import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/features/auth/domain/entities/auth_user.dart';
import 'package:shared_household_planner/features/auth/domain/entities/cloud_schema.dart';
import 'package:shared_household_planner/features/auth/data/repositories/fake_auth_repository.dart';
import 'package:shared_household_planner/features/auth/data/repositories/fake_cloud_sync_repository.dart';
import 'package:shared_household_planner/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shared_household_planner/features/auth/presentation/bloc/auth_event.dart';
import 'package:shared_household_planner/features/auth/presentation/bloc/auth_state.dart';
import 'package:shared_household_planner/features/auth/presentation/widgets/auth_prompt_bottom_sheet.dart';
import 'package:shared_household_planner/features/auth/presentation/widgets/invite_code_dialog.dart';
import 'package:shared_household_planner/features/auth/presentation/widgets/share_project_modal.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';

// Test localization helper
class _TestAuthLoc extends AppLocalizations {
  _TestAuthLoc(super.locale);

  static const _dict = <String, String>{
    'guest_account': 'Guest Account',
    'offline_mode': 'Offline Mode',
    'sign_in': 'Sign In',
    'sign_out': 'Sign Out',
    'register': 'Register',
    'email': 'Email',
    'password': 'Password',
    'display_name': 'Full Name',
    'continue_with_google': 'Continue with Google',
    'continue_offline': 'Continue Offline',
    'already_have_account': 'Already have an account? Sign In',
    'dont_have_account': "Don't have an account? Register",
    'auth_email_required': 'Please enter an email',
    'auth_email_invalid': 'Please enter a valid email',
    'auth_password_required': 'Please enter a password',
    'auth_password_min_length': 'Please enter a password (min 6 chars)',
    'auth_sign_in_google': 'Continue with Google',
    'auth_continue_offline': 'Continue Offline',
    'auth_sign_in_tab': 'Sign In',
    'auth_register_tab': 'Register',
    'auth_sign_in_button': 'Sign In',
    'auth_register_button': 'Register',
    'auth_display_name_label': 'Full Name',
    'auth_email_label': 'Email',
    'auth_password_label': 'Password',
    'auth_or': 'OR',
    'auth_sheet_title': 'Account Sign In',
    'auth_sheet_subtitle': 'Sign in to sync your household data',
    'auth_register_title': 'Create Account',
    'auth_prompt_share_title': 'Sign in to Share Project',
    'auth_prompt_share_subtitle': 'Sign in to invite members and sync expenses.',
    'auth_prompt_join_title': 'Sign in to Join Project',
    'auth_prompt_join_subtitle': 'Sign in to participate and split bills.',
    'share_project_title': 'Share Project',
    'share_project_subtitle': 'Give this code to members to join',
    'invite_code_label': 'Invite Code',
    'copy_code': 'Copy Code',
    'copy_code_button': 'Copy Code',
    'share_code_button': 'Share Code',
    'code_copied': 'Invite code copied!',
    'invite_code_copied': 'Invite code copied!',
    'generating_invite': 'Generating invite code...',
    'invite_error': 'Failed to generate invite code',
    'invite_code_instruction': 'Share this 6-character code with members',
    'join_project_title': 'Join Project',
    'join_project_subtitle': 'Enter the 6-character code you received',
    'join_project_button': 'Join Project',
    'share_project_button': 'Share Project',
    'enter_invite_code': 'Enter code (e.g. DL-8899)',
    'joining': 'Joining...',
    'join': 'Join',
    'cancel': 'Cancel',
    'close': 'Close',
    'account_info': 'Account Info',
    'account_name': 'Household Admin',
    'account_role_owner': 'Owner',
    'bills_tab': 'Bills',
    'settlement_tab': 'Settlement',
    'statistics_tab': 'Statistics',
    'add_expense_button': 'Add Expense',
    'error': 'Error',
  };

  @override
  String translate(String key) => _dict[key] ?? key;
}

class _TestAuthLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestAuthLocDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => _TestAuthLoc(locale);
  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

Widget _buildTestApp({
  required Widget child,
  AuthBloc? authBloc,
  ThemeMode themeMode = ThemeMode.light,
}) {
  final app = MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      _TestAuthLocDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('vi')],
    theme: ThemeData.light(useMaterial3: true),
    darkTheme: ThemeData.dark(useMaterial3: true),
    themeMode: themeMode,
    home: child,
  );

  if (authBloc != null) {
    return BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: app,
    );
  }
  return app;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ══════════════════════════════════════════════════════════
  // GROUP 1: AuthUser Entity Tests (20 tests)
  // ══════════════════════════════════════════════════════════
  group('1. AuthUser Entity Tests', () {
    test('1.1 creates AuthUser with all properties', () {
      final user = AuthUser(
        uid: 'u-1',
        email: 'alice@example.com',
        displayName: 'Alice Johnson',
        photoUrl: 'https://example.com/avatar.png',
        isAnonymous: false,
      );

      expect(user.uid, 'u-1');
      expect(user.email, 'alice@example.com');
      expect(user.displayName, 'Alice Johnson');
      expect(user.photoUrl, 'https://example.com/avatar.png');
      expect(user.isAnonymous, false);
    });

    test('1.2 default constructor assigns false for isAnonymous', () {
      const user = AuthUser(uid: 'u-anon');
      expect(user.uid, 'u-anon');
      expect(user.isAnonymous, false);
      expect(user.email, isNull);
      expect(user.displayName, isNull);
    });

    test('1.3 initial returns uppercase first character from single word displayName', () {
      const user = AuthUser(uid: 'u', displayName: 'bob');
      expect(user.initial, 'B');
    });

    test('1.4 initial returns uppercase first character from multi-word displayName', () {
      const user = AuthUser(uid: 'u', displayName: 'Charlie Brown');
      expect(user.initial, 'C');
    });

    test('1.5 initial trims whitespace before computing initial', () {
      const user = AuthUser(uid: 'u', displayName: '   david   ');
      expect(user.initial, 'D');
    });

    test('1.6 initial falls back to email if displayName is empty', () {
      const user = AuthUser(uid: 'u', email: 'emma@test.com', displayName: '');
      expect(user.initial, 'E');
    });

    test('1.7 initial falls back to email if displayName is whitespace only', () {
      const user = AuthUser(uid: 'u', email: 'frank@test.com', displayName: '   ');
      expect(user.initial, 'F');
    });

    test('1.8 initial returns "U" when displayName and email are empty or null', () {
      const user = AuthUser(uid: 'u', email: '', displayName: '');
      expect(user.initial, 'U');
    });

    test('1.9 displayTitle returns displayName when present', () {
      const user = AuthUser(uid: 'u', email: 'test@mail.com', displayName: 'Grace Hopper');
      expect(user.displayTitle, 'Grace Hopper');
    });

    test('1.10 displayTitle returns email prefix when displayName is empty', () {
      const user = AuthUser(uid: 'u', email: 'grace@hopper.com', displayName: '');
      expect(user.displayTitle, 'grace');
    });

    test('1.11 displayTitle returns "Thành viên" when displayName and email are empty', () {
      const user = AuthUser(uid: 'u', email: '', displayName: '');
      expect(user.displayTitle, 'Thành viên');
    });

    test('1.12 copyWith updates uid', () {
      const u1 = AuthUser(uid: 'u1', email: 'e', displayName: 'd');
      final u2 = u1.copyWith(uid: 'u2');
      expect(u2.uid, 'u2');
      expect(u2.email, 'e');
    });

    test('1.13 copyWith updates email', () {
      const u1 = AuthUser(uid: 'u1', email: 'e1', displayName: 'd');
      final u2 = u1.copyWith(email: 'e2');
      expect(u2.email, 'e2');
      expect(u2.uid, 'u1');
    });

    test('1.14 copyWith updates displayName', () {
      const u1 = AuthUser(uid: 'u1', email: 'e', displayName: 'd1');
      final u2 = u1.copyWith(displayName: 'd2');
      expect(u2.displayName, 'd2');
    });

    test('1.15 copyWith updates photoUrl', () {
      const u1 = AuthUser(uid: 'u1', email: 'e', displayName: 'd');
      final u2 = u1.copyWith(photoUrl: 'http://pic.png');
      expect(u2.photoUrl, 'http://pic.png');
    });

    test('1.16 copyWith updates isAnonymous', () {
      const u1 = AuthUser(uid: 'u1', email: 'e', displayName: 'd', isAnonymous: false);
      final u2 = u1.copyWith(isAnonymous: true);
      expect(u2.isAnonymous, true);
    });

    test('1.17 toJson and fromJson serialization roundtrip', () {
      final user = AuthUser(
        uid: 'user-42',
        email: 'ada@lovelace.org',
        displayName: 'Ada Lovelace',
        photoUrl: 'https://ada.org/pic.png',
        isAnonymous: false,
        createdAt: DateTime(2026, 1, 1),
        lastLoginAt: DateTime(2026, 1, 2),
      );

      final json = user.toJson();
      expect(json['uid'], 'user-42');
      expect(json['email'], 'ada@lovelace.org');
      expect(json['displayName'], 'Ada Lovelace');
      expect(json['photoUrl'], 'https://ada.org/pic.png');
      expect(json['isAnonymous'], false);

      final deserialized = AuthUser.fromJson(json);
      expect(deserialized, equals(user));
    });

    test('1.18 fromJson handles missing optional fields gracefully', () {
      final json = {'uid': 'u-minimal'};
      final user = AuthUser.fromJson(json);
      expect(user.uid, 'u-minimal');
      expect(user.email, isNull);
      expect(user.displayName, isNull);
      expect(user.photoUrl, isNull);
      expect(user.isAnonymous, false);
    });

    test('1.19 equality: instances with identical fields are equal', () {
      const u1 = AuthUser(uid: 'same', email: 'a@b.com', displayName: 'Name');
      const u2 = AuthUser(uid: 'same', email: 'a@b.com', displayName: 'Name');
      expect(u1, equals(u2));
      expect(u1 == u2, isTrue);
    });

    test('1.20 equality: instances with different uid are not equal', () {
      const u1 = AuthUser(uid: 'id-1', email: 'a@b.com', displayName: 'Name');
      const u2 = AuthUser(uid: 'id-2', email: 'a@b.com', displayName: 'Name');
      expect(u1 == u2, isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 2: Cloud Schema Entities Tests (26 tests)
  // ══════════════════════════════════════════════════════════
  group('2. Cloud Schema Entities Tests', () {
    test('2.1 CloudCollections constants match specifications', () {
      expect(CloudCollections.users, 'users');
      expect(CloudCollections.projects, 'projects');
      expect(CloudCollections.bills, 'bills');
      expect(CloudCollections.settlements, 'settlements');
      expect(CloudCollections.shareInvites, 'share_invites');
    });

    test('2.2 CloudUser constructor and properties', () {
      final now = DateTime.now();
      final user = CloudUser(
        uid: 'cu-1',
        email: 'user@cloud.com',
        displayName: 'Cloud User',
        photoUrl: 'https://pic.jpg',
        createdAt: now,
        lastLoginAt: now,
      );
      expect(user.uid, 'cu-1');
      expect(user.email, 'user@cloud.com');
      expect(user.displayName, 'Cloud User');
      expect(user.photoUrl, 'https://pic.jpg');
      expect(user.createdAt, now);
      expect(user.lastLoginAt, now);
    });

    test('2.3 CloudUser toMap and fromMap serialization', () {
      final now = DateTime(2026, 3, 1, 10, 0, 0);
      final user = CloudUser(
        uid: 'cu-ser',
        email: 'ser@user.com',
        displayName: 'Ser User',
        photoUrl: 'http://photo.com',
        createdAt: now,
        lastLoginAt: now,
      );

      final map = user.toMap();
      expect(map['uid'], 'cu-ser');
      expect(map['email'], 'ser@user.com');
      expect(map['displayName'], 'Ser User');
      expect(map['photoUrl'], 'http://photo.com');

      final from = CloudUser.fromMap(map, 'cu-ser');
      expect(from.uid, 'cu-ser');
      expect(from.email, 'ser@user.com');
      expect(from.displayName, 'Ser User');
      expect(from.photoUrl, 'http://photo.com');
      expect(from.createdAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('2.4 CloudProject constructor and properties', () {
      final now = DateTime.now();
      final proj = CloudProject(
        id: 'cp-1',
        name: 'Household Project',
        currency: 'VND',
        color: '#FF123456',
        iconIndex: 1,
        ownerId: 'owner-1',
        memberIds: const ['owner-1', 'member-2'],
        memberNames: const ['Owner', 'Member 2'],
        inviteCode: 'HS-1234',
        createdAt: now,
        updatedAt: now,
      );
      expect(proj.id, 'cp-1');
      expect(proj.name, 'Household Project');
      expect(proj.currency, 'VND');
      expect(proj.color, '#FF123456');
      expect(proj.iconIndex, 1);
      expect(proj.ownerId, 'owner-1');
      expect(proj.memberIds, contains('member-2'));
      expect(proj.memberNames, contains('Member 2'));
      expect(proj.inviteCode, 'HS-1234');
    });

    test('2.5 CloudProject toMap and fromMap serialization', () {
      final now = DateTime(2026, 3, 15, 12, 0, 0);
      final proj = CloudProject(
        id: 'cp-round',
        name: 'Trip 2026',
        currency: 'VND',
        color: '#FFAABBCC',
        iconIndex: 2,
        ownerId: 'owner-42',
        memberIds: const ['owner-42', 'alice', 'bob'],
        memberNames: const ['Owner', 'Alice', 'Bob'],
        createdAt: now,
        updatedAt: now,
      );

      final map = proj.toMap();
      expect(map['name'], 'Trip 2026');
      expect(map['currency'], 'VND');
      expect(map['color'], '#FFAABBCC');
      expect(map['iconIndex'], 2);
      expect(map['ownerId'], 'owner-42');
      expect((map['memberIds'] as List).length, 3);

      final from = CloudProject.fromMap(map, 'cp-round');
      expect(from.id, 'cp-round');
      expect(from.name, 'Trip 2026');
      expect(from.currency, 'VND');
      expect(from.memberIds, equals(['owner-42', 'alice', 'bob']));
    });

    test('2.6 CloudProject fromMap handles null or empty lists', () {
      final map = {
        'name': 'Minimal Proj',
        'currency': 'USD',
        'color': '#000000',
        'ownerId': 'owner-min',
      };
      final proj = CloudProject.fromMap(map, 'min-id');
      expect(proj.memberIds, isEmpty);
      expect(proj.memberNames, isEmpty);
      expect(proj.iconIndex, 0);
    });

    test('2.7 CloudBill constructor and properties', () {
      final date = DateTime(2026, 4, 1);
      final now = DateTime.now();
      final bill = CloudBill(
        id: 'cb-1',
        projectId: 'cp-1',
        amount: 250000.0,
        description: 'Dinner',
        payerId: 'u-alice',
        payerName: 'Alice',
        splitMethod: 'equal',
        splits: const {'Alice': 125000.0, 'Bob': 125000.0},
        date: date,
        createdAt: now,
        updatedAt: now,
        createdBy: 'u-alice',
      );
      expect(bill.id, 'cb-1');
      expect(bill.projectId, 'cp-1');
      expect(bill.amount, 250000.0);
      expect(bill.description, 'Dinner');
      expect(bill.payerId, 'u-alice');
      expect(bill.payerName, 'Alice');
      expect(bill.splitMethod, 'equal');
      expect(bill.splits.length, 2);
      expect(bill.date, date);
      expect(bill.createdBy, 'u-alice');
    });

    test('2.8 CloudBill toMap and fromMap serialization', () {
      final date = DateTime(2026, 5, 10, 18, 30, 0);
      final now = DateTime(2026, 5, 10, 18, 35, 0);
      final bill = CloudBill(
        id: 'cb-ser',
        projectId: 'cp-ser',
        amount: 320000.0,
        description: 'Groceries',
        payerId: 'u-charlie',
        payerName: 'Charlie',
        splitMethod: 'exact',
        splits: const {'Charlie': 160000.0, 'David': 160000.0},
        date: date,
        createdAt: now,
        updatedAt: now,
        createdBy: 'u-charlie',
      );

      final map = bill.toMap();
      expect(map['id'], 'cb-ser');
      expect(map['projectId'], 'cp-ser');
      expect(map['amount'], 320000.0);
      expect(map['description'], 'Groceries');
      expect(map['payerId'], 'u-charlie');
      expect(map['payerName'], 'Charlie');

      final from = CloudBill.fromMap(map, 'cb-ser');
      expect(from.id, 'cb-ser');
      expect(from.description, 'Groceries');
      expect(from.amount, 320000.0);
      expect(from.splitMethod, 'exact');
      expect(from.splits['Charlie'], 160000.0);
    });

    test('2.9 CloudSettlement constructor and properties', () {
      final now = DateTime.now();
      final set = CloudSettlement(
        id: 'cs-1',
        projectId: 'cp-1',
        payerId: 'u-alice',
        payerName: 'Alice',
        receiverId: 'u-bob',
        receiverName: 'Bob',
        amount: 100000.0,
        date: now,
        createdAt: now,
        createdBy: 'u-alice',
      );
      expect(set.id, 'cs-1');
      expect(set.projectId, 'cp-1');
      expect(set.payerId, 'u-alice');
      expect(set.payerName, 'Alice');
      expect(set.receiverId, 'u-bob');
      expect(set.receiverName, 'Bob');
      expect(set.amount, 100000.0);
      expect(set.date, now);
      expect(set.createdBy, 'u-alice');
    });

    test('2.10 CloudSettlement toMap and fromMap serialization', () {
      final now = DateTime(2026, 6, 1, 14, 0, 0);
      final set = CloudSettlement(
        id: 'cs-round',
        projectId: 'cp-round',
        payerId: 'u-a',
        payerName: 'UserA',
        receiverId: 'u-b',
        receiverName: 'UserB',
        amount: 88000.0,
        date: now,
        createdAt: now,
        createdBy: 'u-a',
      );

      final map = set.toMap();
      expect(map['payerName'], 'UserA');
      expect(map['receiverName'], 'UserB');
      expect(map['amount'], 88000.0);

      final from = CloudSettlement.fromMap(map, 'cs-round');
      expect(from.id, 'cs-round');
      expect(from.payerName, 'UserA');
      expect(from.receiverName, 'UserB');
      expect(from.amount, 88000.0);
    });

    test('2.11 ShareInvite constructor and properties', () {
      final now = DateTime.now();
      final expires = now.add(const Duration(days: 7));
      final invite = ShareInvite(
        inviteCode: 'DL-8899',
        projectId: 'proj-1',
        createdBy: 'user-1',
        createdAt: now,
        expiresAt: expires,
        isActive: true,
      );

      expect(invite.inviteCode, 'DL-8899');
      expect(invite.projectId, 'proj-1');
      expect(invite.createdBy, 'user-1');
      expect(invite.expiresAt, expires);
      expect(invite.isActive, true);
    });

    test('2.12 ShareInvite toMap and fromMap serialization', () {
      final now = DateTime(2026, 7, 10, 8, 0, 0);
      final expires = DateTime(2026, 7, 17, 8, 0, 0);
      final invite = ShareInvite(
        inviteCode: 'XY-9999',
        projectId: 'proj-xy',
        createdBy: 'user-xy',
        createdAt: now,
        expiresAt: expires,
        isActive: true,
      );

      final map = invite.toMap();
      expect(map['inviteCode'], 'XY-9999');
      expect(map['projectId'], 'proj-xy');
      expect(map['createdBy'], 'user-xy');
      expect(map['isActive'], true);

      final from = ShareInvite.fromMap(map, 'XY-9999');
      expect(from.inviteCode, 'XY-9999');
      expect(from.projectId, 'proj-xy');
      expect(from.createdBy, 'user-xy');
      expect(from.isActive, true);
    });

    test('2.13 ShareInvite.isExpired is true when expiresAt has passed', () {
      final past = DateTime.now().subtract(const Duration(minutes: 5));
      final invite = ShareInvite(
        inviteCode: 'EX-0001',
        projectId: 'p',
        createdBy: 'u',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        expiresAt: past,
      );
      expect(invite.isExpired, isTrue);
    });

    test('2.14 ShareInvite.isExpired is false when expiresAt is in the future', () {
      final future = DateTime.now().add(const Duration(days: 5));
      final invite = ShareInvite(
        inviteCode: 'EX-0002',
        projectId: 'p',
        createdBy: 'u',
        createdAt: DateTime.now(),
        expiresAt: future,
      );
      expect(invite.isExpired, isFalse);
    });

    test('2.15 ShareInvite.isExpired is false when expiresAt is null', () {
      final invite = ShareInvite(
        inviteCode: 'EX-NULL',
        projectId: 'p',
        createdBy: 'u',
        createdAt: DateTime.now(),
        expiresAt: null,
      );
      expect(invite.isExpired, isFalse);
    });

    test('2.16 ShareInvite.isValid returns true for active non-expired invite', () {
      final invite = ShareInvite(
        inviteCode: 'OK-0001',
        projectId: 'p',
        createdBy: 'u',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 2)),
        isActive: true,
      );
      expect(invite.isValid, isTrue);
    });

    test('2.17 ShareInvite.isValid returns false when isActive is false', () {
      final invite = ShareInvite(
        inviteCode: 'NO-0001',
        projectId: 'p',
        createdBy: 'u',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 2)),
        isActive: false,
      );
      expect(invite.isValid, isFalse);
    });

    test('2.18 ShareInvite.isValid returns false when expired', () {
      final invite = ShareInvite(
        inviteCode: 'NO-0002',
        projectId: 'p',
        createdBy: 'u',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        isActive: true,
      );
      expect(invite.isValid, isFalse);
    });

    test('2.19 ShareInvite.generateCode produces 6 or 7 character code with default prefix', () {
      final code = ShareInvite.generateCode();
      expect(code.startsWith('HS-'), isTrue);
      expect(code.length, 7);
    });

    test('2.20 ShareInvite.generateCode with custom prefix formats correctly', () {
      final code = ShareInvite.generateCode(prefix: 'DL');
      expect(code.startsWith('DL-'), isTrue);
      final remainder = code.substring(3);
      expect(int.tryParse(remainder), isNotNull);
    });

    test('2.21 ShareInvite.generateCode produces diverse codes', () {
      final codes = <String>{};
      for (int i = 0; i < 20; i++) {
        codes.add(ShareInvite.generateCode());
      }
      expect(codes.length, greaterThan(1));
    });

    test('2.22 Equatable props of CloudUser contain all fields', () {
      final now = DateTime.now();
      final u = CloudUser(
        uid: 'uid-test',
        createdAt: now,
        lastLoginAt: now,
      );
      expect(u.props, contains('uid-test'));
      expect(u.props, contains(now));
    });

    test('2.23 Equatable props of CloudProject contain id and name', () {
      final now = DateTime.now();
      final p = CloudProject(
        id: 'p-prop',
        name: 'Prop Project',
        currency: 'USD',
        color: '#fff',
        ownerId: 'u-1',
        memberIds: const ['u-1'],
        createdAt: now,
        updatedAt: now,
      );
      expect(p.props, contains('p-prop'));
      expect(p.props, contains('Prop Project'));
    });

    test('2.24 Equatable props of CloudBill contain id and amount', () {
      final now = DateTime.now();
      final b = CloudBill(
        id: 'b-prop',
        projectId: 'p-prop',
        amount: 50.0,
        description: 'Coffee',
        payerId: 'u-1',
        payerName: 'U1',
        splitMethod: 'equal',
        splits: const {'U1': 50.0},
        date: now,
        createdAt: now,
        updatedAt: now,
        createdBy: 'u-1',
      );
      expect(b.props, contains('b-prop'));
      expect(b.props, contains(50.0));
    });

    test('2.25 Equatable props of CloudSettlement contain payer and receiver', () {
      final now = DateTime.now();
      final s = CloudSettlement(
        id: 's-prop',
        projectId: 'p-prop',
        payerId: 'u1',
        payerName: 'P1',
        receiverId: 'u2',
        receiverName: 'P2',
        amount: 25.0,
        date: now,
        createdAt: now,
        createdBy: 'u1',
      );
      expect(s.props, contains('u1'));
      expect(s.props, contains('u2'));
      expect(s.props, contains(25.0));
    });

    test('2.26 Equatable props of ShareInvite contain inviteCode and projectId', () {
      final now = DateTime.now();
      final inv = ShareInvite(
        inviteCode: 'CODE-1',
        projectId: 'proj-1',
        createdBy: 'u1',
        createdAt: now,
      );
      expect(inv.props, contains('CODE-1'));
      expect(inv.props, contains('proj-1'));
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 3: FakeAuthRepository Unit Tests (14 tests)
  // ══════════════════════════════════════════════════════════
  group('3. FakeAuthRepository Unit Tests', () {
    late FakeAuthRepository authRepo;

    setUp(() {
      authRepo = FakeAuthRepository();
    });

    tearDown(() {
      authRepo.dispose();
    });

    test('3.1 initial currentUser is null', () {
      expect(authRepo.currentUser, isNull);
    });

    test('3.2 initial currentUser can be provided in constructor', () {
      const seeded = AuthUser(uid: 'seed', email: 's@test.com', displayName: 'Seed');
      final repo = FakeAuthRepository(initialUser: seeded);
      expect(repo.currentUser, equals(seeded));
      repo.dispose();
    });

    test('3.3 authStateChanges stream emits updates when signing in with Google', () async {
      final states = <AuthUser?>[];
      final sub = authRepo.authStateChanges.listen((u) => states.add(u));

      final user = await authRepo.signInWithGoogle();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(user.displayName, contains('Alex'));
      expect(authRepo.currentUser, equals(user));
      expect(states, contains(user));

      await sub.cancel();
    });

    test('3.4 signInWithGoogle returns a valid Google AuthUser', () async {
      final user = await authRepo.signInWithGoogle();
      expect(user.uid, isNotEmpty);
      expect(user.email, contains('@example.com'));
      expect(user.isAnonymous, isFalse);
    });

    test('3.5 signInWithGoogle throws exception when shouldFail is true', () async {
      authRepo.shouldFail = true;
      authRepo.failureMessage = 'Google sign-in was aborted';
      expect(() => authRepo.signInWithGoogle(), throwsA(isA<Exception>()));
    });

    test('3.6 signInWithEmailPassword succeeds with valid credentials', () async {
      final user = await authRepo.signInWithEmailPassword('alice@test.com', 'password123');
      expect(user.email, 'alice@test.com');
      expect(authRepo.currentUser, equals(user));
    });

    test('3.7 signInWithEmailPassword fails when shouldFail is true', () async {
      authRepo.shouldFail = true;
      authRepo.failureMessage = 'Invalid credentials';
      expect(
        () => authRepo.signInWithEmailPassword('bad@test.com', 'wrongPass'),
        throwsA(isA<Exception>()),
      );
    });

    test('3.8 signInWithEmailPassword derives displayName from email if none exists', () async {
      final user = await authRepo.signInWithEmailPassword('john.doe@domain.com', 'secretPass');
      expect(user.displayName, 'john.doe');
    });

    test('3.9 registerWithEmailPassword creates new user and sets displayName', () async {
      final user = await authRepo.registerWithEmailPassword(
        'sarah@test.com',
        'securePass',
        displayName: 'Sarah Connor',
      );
      expect(user.email, 'sarah@test.com');
      expect(user.displayName, 'Sarah Connor');
      expect(authRepo.currentUser, equals(user));
    });

    test('3.10 registerWithEmailPassword fails when shouldFail is true', () async {
      authRepo.shouldFail = true;
      authRepo.failureMessage = 'Email already exists';
      expect(
        () => authRepo.registerWithEmailPassword('dup@test.com', 'pwd123', displayName: 'Dup'),
        throwsA(isA<Exception>()),
      );
    });

    test('3.11 signOut clears currentUser and notifies authStateChanges', () async {
      await authRepo.signInWithEmailPassword('out@test.com', 'pwd123');
      expect(authRepo.currentUser, isNotNull);

      final states = <AuthUser?>[];
      final sub = authRepo.authStateChanges.listen((u) => states.add(u));

      await authRepo.signOut();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(authRepo.currentUser, isNull);
      expect(states, contains(null));

      await sub.cancel();
    });

    test('3.12 signOut throws when shouldFail is true', () async {
      authRepo.shouldFail = true;
      expect(() => authRepo.signOut(), throwsA(isA<Exception>()));
    });

    test('3.13 multiple listeners can listen to authStateChanges broadcast stream', () async {
      int count1 = 0;
      int count2 = 0;

      final s1 = authRepo.authStateChanges.listen((_) => count1++);
      final s2 = authRepo.authStateChanges.listen((_) => count2++);

      await authRepo.signInWithGoogle();
      await authRepo.signOut();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(count1, greaterThanOrEqualTo(2));
      expect(count2, greaterThanOrEqualTo(2));

      await s1.cancel();
      await s2.cancel();
    });

    test('3.14 simulated delay works as expected', () async {
      authRepo.delay = const Duration(milliseconds: 50);
      final sw = Stopwatch()..start();
      await authRepo.signInWithGoogle();
      sw.stop();
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(40));
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 4: FakeCloudSyncRepository Unit Tests (14 tests)
  // ══════════════════════════════════════════════════════════
  group('4. FakeCloudSyncRepository Unit Tests', () {
    late FakeCloudSyncRepository cloudRepo;

    setUp(() {
      cloudRepo = FakeCloudSyncRepository();
    });

    test('4.1 saveUserProfile stores user and getUserProfile retrieves it', () async {
      final user = CloudUser(
        uid: 'u-100',
        email: 'test@user.com',
        displayName: 'Test User',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      await cloudRepo.saveUserProfile(user);
      final fetched = await cloudRepo.getUserProfile('u-100');
      expect(fetched, isNotNull);
      expect(fetched!.email, 'test@user.com');
      expect(fetched.displayName, 'Test User');
    });

    test('4.2 getUserProfile returns null for non-existent userId', () async {
      final fetched = await cloudRepo.getUserProfile('non-existent');
      expect(fetched, isNull);
    });

    test('4.3 saveProject stores project and getProject retrieves it', () async {
      final project = CloudProject(
        id: 'cp-10',
        name: 'Apartment Bills',
        currency: 'VND',
        color: '#223344',
        iconIndex: 1,
        ownerId: 'u-100',
        memberIds: const ['u-100'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await cloudRepo.saveProject(project);
      final fetched = await cloudRepo.getProject('cp-10');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Apartment Bills');
      expect(fetched.ownerId, 'u-100');
    });

    test('4.4 getProject returns null for non-existent project', () async {
      final fetched = await cloudRepo.getProject('p-none');
      expect(fetched, isNull);
    });

    test('4.5 createShareInvite generates 6/7 character code and stores invite', () async {
      final invite = await cloudRepo.createShareInvite(
        projectId: 'proj-xyz',
        userId: 'user-creator',
      );
      expect(invite.inviteCode.isNotEmpty, isTrue);
      expect(invite.projectId, 'proj-xyz');
      expect(invite.createdBy, 'user-creator');

      final found = await cloudRepo.getShareInvite(invite.inviteCode);
      expect(found, isNotNull);
      expect(found!.inviteCode, invite.inviteCode);
    });

    test('4.6 getShareInvite normalizes code to uppercase and trims', () async {
      final invite = await cloudRepo.createShareInvite(
        projectId: 'proj-norm',
        userId: 'u',
      );
      final lower = invite.inviteCode.toLowerCase();
      final found = await cloudRepo.getShareInvite('  $lower  ');
      expect(found, isNotNull);
      expect(found!.inviteCode, invite.inviteCode);
    });

    test('4.7 getShareInvite returns null for unknown code', () async {
      final found = await cloudRepo.getShareInvite('UNKNOWN-99');
      expect(found, isNull);
    });

    test('4.8 joinProjectWithInviteCode adds user to members and updates project', () async {
      // 1. Create project
      final proj = CloudProject(
        id: 'proj-join',
        name: 'Shared Room',
        currency: 'VND',
        color: '#000',
        ownerId: 'u-owner',
        memberIds: const ['u-owner'],
        memberNames: const ['Owner'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await cloudRepo.saveProject(proj);

      // 2. Create invite
      final invite = await cloudRepo.createShareInvite(
        projectId: 'proj-join',
        userId: 'u-owner',
      );

      // 3. User joins
      final joined = await cloudRepo.joinProjectWithInviteCode(
        inviteCode: invite.inviteCode,
        userId: 'u-joiner',
        userName: 'Joiner',
      );

      expect(joined, isNotNull);
      expect(joined.id, 'proj-join');
      expect(joined.memberIds, contains('u-joiner'));
      expect(joined.memberNames, contains('Joiner'));
    });

    test('4.9 joinProjectWithInviteCode throws if invite is invalid or non-existent', () async {
      expect(
        () => cloudRepo.joinProjectWithInviteCode(
          inviteCode: 'INVALID-CODE',
          userId: 'u-joiner',
          userName: 'Joiner',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('4.10 joinProjectWithInviteCode throws if referenced project does not exist', () async {
      final invite = ShareInvite(
        inviteCode: 'GHOST-01',
        projectId: 'ghost-project',
        createdBy: 'u',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 2)),
      );
      cloudRepo.invites['GHOST-01'] = invite;

      expect(
        () => cloudRepo.joinProjectWithInviteCode(
          inviteCode: 'GHOST-01',
          userId: 'u-joiner',
          userName: 'Joiner',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('4.11 joinProjectWithInviteCode does not duplicate user in memberIds if already present', () async {
      final proj = CloudProject(
        id: 'proj-dup',
        name: 'Dup Member',
        currency: 'USD',
        color: '#000',
        ownerId: 'u-owner',
        memberIds: const ['u-owner'],
        memberNames: const ['Owner'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await cloudRepo.saveProject(proj);

      final invite = await cloudRepo.createShareInvite(
        projectId: 'proj-dup',
        userId: 'u-owner',
      );

      final j1 = await cloudRepo.joinProjectWithInviteCode(
        inviteCode: invite.inviteCode,
        userId: 'u-owner',
        userName: 'Owner',
      );
      expect(j1.memberIds.where((m) => m == 'u-owner').length, 1);
    });

    test('4.12 generateInviteCode with custom prefix', () {
      final code = cloudRepo.generateInviteCode(prefix: 'TEST');
      expect(code.startsWith('TEST-'), isTrue);
    });

    test('4.13 simulated failure throws exception on saveProject', () async {
      cloudRepo.shouldFail = true;
      final proj = CloudProject(
        id: 'p-fail',
        name: 'Fail',
        currency: 'USD',
        color: '#000',
        ownerId: 'u',
        memberIds: const ['u'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(() => cloudRepo.saveProject(proj), throwsA(isA<Exception>()));
    });

    test('4.14 simulated failure throws exception on getUserProfile', () async {
      cloudRepo.shouldFail = true;
      expect(() => cloudRepo.getUserProfile('uid'), throwsA(isA<Exception>()));
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 5: AuthBloc Unit Tests (12 tests)
  // ══════════════════════════════════════════════════════════
  group('5. AuthBloc Unit Tests', () {
    late FakeAuthRepository authRepo;
    late AuthBloc authBloc;

    setUp(() {
      authRepo = FakeAuthRepository();
      authBloc = AuthBloc(authRepository: authRepo);
    });

    tearDown(() {
      authBloc.close();
      authRepo.dispose();
    });

    test('5.1 initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    test('5.2 CheckAuthStatusEvent emits Unauthenticated when no user exists', () async {
      authBloc.add(const CheckAuthStatusEvent());
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<Unauthenticated>(),
        ]),
      );
    });

    test('5.3 CheckAuthStatusEvent emits Authenticated when user exists', () async {
      const user = AuthUser(uid: 'u-exist', email: 'exist@test.com', displayName: 'Existing');
      final seededRepo = FakeAuthRepository(initialUser: user);
      final seededBloc = AuthBloc(authRepository: seededRepo);

      seededBloc.add(const CheckAuthStatusEvent());
      await expectLater(
        seededBloc.stream,
        emitsInOrder([
          isA<Authenticated>().having((s) => s.user.uid, 'uid', 'u-exist'),
        ]),
      );

      await seededBloc.close();
      seededRepo.dispose();
    });

    test('5.4 SignInWithGoogleEvent emits [AuthLoading, Authenticated] on success', () async {
      authBloc.add(const SignInWithGoogleEvent());
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Authenticated>().having((s) => s.user.email, 'email', contains('@example.com')),
        ]),
      );
    });

    test('5.5 SignInWithGoogleEvent emits [AuthLoading, AuthError] on failure', () async {
      authRepo.shouldFail = true;
      authRepo.failureMessage = 'Google sign-in failed';

      authBloc.add(const SignInWithGoogleEvent());
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthError>().having((s) => s.message, 'message', contains('Google sign-in failed')),
        ]),
      );
    });

    test('5.6 SignInWithEmailEvent emits [AuthLoading, Authenticated] on success', () async {
      authBloc.add(const SignInWithEmailEvent(email: 'bob@test.com', password: 'secretPass'));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Authenticated>().having((s) => s.user.email, 'email', 'bob@test.com'),
        ]),
      );
    });

    test('5.7 SignInWithEmailEvent emits [AuthLoading, AuthError] on failure', () async {
      authRepo.shouldFail = true;
      authRepo.failureMessage = 'Wrong password';

      authBloc.add(const SignInWithEmailEvent(email: 'bob@test.com', password: 'badPass'));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthError>().having((s) => s.message, 'message', contains('Wrong password')),
        ]),
      );
    });

    test('5.8 RegisterWithEmailEvent emits [AuthLoading, Authenticated] on success', () async {
      authBloc.add(const RegisterWithEmailEvent(
        email: 'claire@test.com',
        password: 'pass123',
        displayName: 'Claire Bennet',
      ));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Authenticated>().having((s) => s.user.displayName, 'displayName', 'Claire Bennet'),
        ]),
      );
    });

    test('5.9 RegisterWithEmailEvent emits [AuthLoading, AuthError] on failure', () async {
      authRepo.shouldFail = true;
      authRepo.failureMessage = 'Account registration failed';

      authBloc.add(const RegisterWithEmailEvent(
        email: 'claire@test.com',
        password: 'pass123',
        displayName: 'Claire',
      ));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthError>().having((s) => s.message, 'message', contains('Account registration failed')),
        ]),
      );
    });

    test('5.10 SignOutEvent emits [AuthLoading, Unauthenticated]', () async {
      await authRepo.signInWithGoogle();
      authBloc.add(const SignOutEvent());

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Unauthenticated>(),
        ]),
      );
    });

    test('5.11 AuthUserChangedEvent emits Authenticated when user is provided', () async {
      const user = AuthUser(uid: 'u-ext', email: 'ext@test.com', displayName: 'External');
      authBloc.add(const AuthUserChangedEvent(user));

      await expectLater(
        authBloc.stream,
        emits(isA<Authenticated>().having((s) => s.user.uid, 'uid', 'u-ext')),
      );
    });

    test('5.12 AuthUserChangedEvent emits Unauthenticated when user is null', () async {
      authBloc.add(const AuthUserChangedEvent(null));

      await expectLater(
        authBloc.stream,
        emits(isA<Unauthenticated>()),
      );
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 6: AuthPromptBottomSheet Widget Tests (10 tests)
  // ══════════════════════════════════════════════════════════
  group('6. AuthPromptBottomSheet Widget Tests', () {
    late FakeAuthRepository authRepo;
    late AuthBloc authBloc;

    setUp(() {
      authRepo = FakeAuthRepository();
      authBloc = AuthBloc(authRepository: authRepo);
    });

    tearDown(() {
      authBloc.close();
      authRepo.dispose();
    });

    testWidgets('6.1 renders custom title and subtitle correctly', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          authBloc: authBloc,
          child: const Scaffold(
            body: AuthPromptBottomSheet(
              customTitle: 'Sign in to Share Project',
              customSubtitle: 'Sign in to invite members and sync expenses.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign in to Share Project'), findsOneWidget);
      expect(find.text('Sign in to invite members and sync expenses.'), findsOneWidget);
    });

    testWidgets('6.2 renders Google 1-Tap sign in button', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          authBloc: authBloc,
          child: const Scaffold(
            body: AuthPromptBottomSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('googleSignInButton')), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('6.3 tapping Google button triggers Google sign-in and closes sheet with true', (tester) async {
      bool? returnedSuccess;
      await tester.pumpWidget(
        _buildTestApp(
          authBloc: authBloc,
          child: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                key: const Key('openAuthBtn'),
                onPressed: () async {
                  returnedSuccess = await AuthPromptBottomSheet.show(ctx);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('openAuthBtn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('googleSignInButton')), findsOneWidget);
      await tester.tap(find.byKey(const Key('googleSignInButton')));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(returnedSuccess, isTrue);
      expect(authRepo.currentUser, isNotNull);
    });

    testWidgets('6.4 renders email and password text fields and submit button', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          authBloc: authBloc,
          child: const Scaffold(
            body: AuthPromptBottomSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('emailAuthField')), findsOneWidget);
      expect(find.byKey(const Key('passwordAuthField')), findsOneWidget);
      expect(find.byKey(const Key('submitEmailAuthButton')), findsOneWidget);
    });

    testWidgets('6.5 toggles between Sign In mode and Register mode', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          authBloc: authBloc,
          child: const Scaffold(
            body: AuthPromptBottomSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('displayNameAuthField')), findsNothing);

      await tester.tap(find.byKey(const Key('toggleRegisterMode')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('displayNameAuthField')), findsOneWidget);

      await tester.tap(find.byKey(const Key('toggleSignInMode')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('displayNameAuthField')), findsNothing);
    });

    testWidgets('6.6 shows validation error when submitting with empty email', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          authBloc: authBloc,
          child: const Scaffold(
            body: AuthPromptBottomSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submitEmailAuthButton')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter an email'), findsOneWidget);
    });

    testWidgets('6.7 shows validation error when submitting with short password', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          authBloc: authBloc,
          child: const Scaffold(
            body: AuthPromptBottomSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('emailAuthField')), 'valid@test.com');
      await tester.enterText(find.byKey(const Key('passwordAuthField')), '123');
      await tester.tap(find.byKey(const Key('submitEmailAuthButton')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a password (min 6 chars)'), findsOneWidget);
    });

    testWidgets('6.8 submitting valid email and password in Sign In mode succeeds', (tester) async {
      bool? result;
      await tester.pumpWidget(
        _buildTestApp(
          authBloc: authBloc,
          child: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                key: const Key('openModalBtn'),
                onPressed: () async {
                  result = await AuthPromptBottomSheet.show(ctx);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('openModalBtn')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('emailAuthField')), 'signin@test.com');
      await tester.enterText(find.byKey(const Key('passwordAuthField')), 'secretPassword');
      await tester.ensureVisible(find.byKey(const Key('submitEmailAuthButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('submitEmailAuthButton')));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(authRepo.currentUser?.email, 'signin@test.com');
    });

    testWidgets('6.9 continue offline button dismisses modal with false/null', (tester) async {
      bool? result;
      await tester.pumpWidget(
        _buildTestApp(
          authBloc: authBloc,
          child: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                key: const Key('openModalBtn'),
                onPressed: () async {
                  result = await AuthPromptBottomSheet.show(ctx);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('openModalBtn')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('continueOfflineButton')));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('6.10 renders properly in dark theme without overflow', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          authBloc: authBloc,
          themeMode: ThemeMode.dark,
          child: const Scaffold(
            body: AuthPromptBottomSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('googleSignInButton')), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 7: ShareProjectModal Widget Tests (6 tests)
  // ══════════════════════════════════════════════════════════
  group('7. ShareProjectModal Widget Tests', () {
    late FakeCloudSyncRepository cloudRepo;

    setUp(() {
      cloudRepo = FakeCloudSyncRepository();
    });

    testWidgets('7.1 renders project title and share instructions', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: Scaffold(
            body: ShareProjectModal(
              projectId: 'p-dummy',
              projectName: 'Weekend Trip',
              userId: 'u-alice',
              cloudSyncRepository: cloudRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Share Project'), findsOneWidget);
      expect(find.textContaining('Weekend Trip'), findsOneWidget);
    });

    testWidgets('7.2 generates and displays 6-character invite code', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: Scaffold(
            body: ShareProjectModal(
              projectId: 'p-dummy',
              projectName: 'Weekend Trip',
              userId: 'u-alice',
              cloudSyncRepository: cloudRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('inviteCodeDisplay')), findsOneWidget);
    });

    testWidgets('7.3 copy button copies code and displays feedback', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: Scaffold(
            body: ShareProjectModal(
              projectId: 'p-dummy',
              projectName: 'Weekend Trip',
              userId: 'u-alice',
              cloudSyncRepository: cloudRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('copyInviteCodeButton')), findsOneWidget);
      await tester.tap(find.byKey(const Key('copyInviteCodeButton')));
      await tester.pumpAndSettle();

      expect(find.text('Invite code copied!'), findsOneWidget);
    });

    testWidgets('7.4 close button dismisses modal', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                key: const Key('openModal'),
                onPressed: () => ShareProjectModal.show(
                  ctx,
                  projectId: 'p-dummy',
                  projectName: 'Weekend Trip',
                  userId: 'u-alice',
                  cloudSyncRepository: cloudRepo,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('openModal')));
      await tester.pumpAndSettle();

      expect(find.text('Share Project'), findsOneWidget);
      // Tap outside modal to dismiss
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Share Project'), findsNothing);
    });

    testWidgets('7.5 displays share button', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: Scaffold(
            body: ShareProjectModal(
              projectId: 'p-dummy',
              projectName: 'Weekend Trip',
              userId: 'u-alice',
              cloudSyncRepository: cloudRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('shareInviteCodeButton')), findsOneWidget);
    });

    testWidgets('7.6 dark theme renders without errors', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          themeMode: ThemeMode.dark,
          child: Scaffold(
            body: ShareProjectModal(
              projectId: 'p-dummy',
              projectName: 'Weekend Trip',
              userId: 'u-alice',
              cloudSyncRepository: cloudRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('inviteCodeDisplay')), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 8: InviteCodeDialog Widget Tests (5 tests)
  // ══════════════════════════════════════════════════════════
  group('8. InviteCodeDialog Widget Tests', () {
    late FakeCloudSyncRepository cloudRepo;

    setUp(() {
      cloudRepo = FakeCloudSyncRepository();
    });

    testWidgets('8.1 renders title, description, and input field', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: Scaffold(
            body: InviteCodeDialog(
              cloudSyncRepository: cloudRepo,
              userId: 'u-alice',
              userName: 'Alice',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Join Project'), findsOneWidget);
      expect(find.byKey(const Key('inviteCodeField')), findsOneWidget);
      expect(find.byKey(const Key('submitInviteCodeButton')), findsOneWidget);
      expect(find.byKey(const Key('cancelInviteCodeButton')), findsOneWidget);
    });

    testWidgets('8.2 auto-uppercases entered invite code text', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: Scaffold(
            body: InviteCodeDialog(
              cloudSyncRepository: cloudRepo,
              userId: 'u-alice',
              userName: 'Alice',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('inviteCodeField')), 'dl-8899');
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byKey(const Key('inviteCodeField')));
      expect(textField.controller?.text, 'DL-8899');
    });

    testWidgets('8.3 submits valid code, joins project and invokes onJoined callback', (tester) async {
      // Create project & invite in cloudRepo
      final proj = CloudProject(
        id: 'p-test',
        name: 'Test Project',
        currency: 'VND',
        color: '#000',
        ownerId: 'u-owner',
        memberIds: const ['u-owner'],
        memberNames: const ['Owner'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await cloudRepo.saveProject(proj);
      final invite = await cloudRepo.createShareInvite(projectId: 'p-test', userId: 'u-owner');

      String? joinedProjectId;
      await tester.pumpWidget(
        _buildTestApp(
          child: Scaffold(
            body: InviteCodeDialog(
              cloudSyncRepository: cloudRepo,
              userId: 'u-joiner',
              userName: 'Joiner',
              onJoined: (id) => joinedProjectId = id,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('inviteCodeField')), invite.inviteCode);
      await tester.tap(find.byKey(const Key('submitInviteCodeButton')));
      await tester.pumpAndSettle();

      expect(joinedProjectId, 'p-test');
    });

    testWidgets('8.4 cancel button dismisses dialog', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                key: const Key('openDialogBtn'),
                onPressed: () => InviteCodeDialog.show(
                  ctx,
                  cloudSyncRepository: cloudRepo,
                  userId: 'u-alice',
                  userName: 'Alice',
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('openDialogBtn')));
      await tester.pumpAndSettle();

      expect(find.text('Join Project'), findsOneWidget);
      await tester.tap(find.byKey(const Key('cancelInviteCodeButton')));
      await tester.pumpAndSettle();

      expect(find.text('Join Project'), findsNothing);
    });

    testWidgets('8.5 displays error message when joining with non-existent code', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: Scaffold(
            body: InviteCodeDialog(
              cloudSyncRepository: cloudRepo,
              userId: 'u-joiner',
              userName: 'Joiner',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('inviteCodeField')), 'FAKE-9999');
      await tester.tap(find.byKey(const Key('submitInviteCodeButton')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Mã mời không tồn tại'), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 9: Firestore Rules File Verification Tests (8 tests)
  // ══════════════════════════════════════════════════════════
  group('9. Firestore Rules Security Verification', () {
    late String rulesContent;

    setUpAll(() {
      final file = File('firestore.rules');
      expect(file.existsSync(), isTrue, reason: 'firestore.rules must exist at the project root');
      rulesContent = file.readAsStringSync();
    });

    test('9.1 specifies rules_version = 2', () {
      expect(rulesContent, contains("rules_version = '2'"));
    });

    test('9.2 contains cloud.firestore service and documents match block', () {
      expect(rulesContent, contains('service cloud.firestore'));
      expect(rulesContent, contains('match /databases/{database}/documents'));
    });

    test('9.3 contains helper functions for authentication check', () {
      expect(rulesContent, contains('function isAuthenticated()'));
      expect(rulesContent, contains('request.auth != null'));
    });

    test('9.4 secures users collection (/users/{userId})', () {
      expect(rulesContent, contains('match /users/{userId}'));
      expect(rulesContent, contains('allow create, update: if isOwner(userId)'));
    });

    test('9.5 secures projects collection (/projects/{projectId})', () {
      expect(rulesContent, contains('match /projects/{projectId}'));
      expect(rulesContent, contains('allow create: if isAuthenticated()'));
      expect(rulesContent, contains('request.auth.uid in resource.data.memberIds'));
    });

    test('9.6 secures bills subcollection inside projects', () {
      expect(rulesContent, contains('match /bills/{billId}'));
      expect(rulesContent, contains('isProjectMember(projectId)'));
    });

    test('9.7 secures settlements subcollection inside projects', () {
      expect(rulesContent, contains('match /settlements/{settlementId}'));
      expect(rulesContent, contains('isProjectMember(projectId)'));
    });

    test('9.8 secures share_invites collection with 6-char codes', () {
      expect(rulesContent, contains('match /share_invites/{inviteCode}'));
      expect(rulesContent, contains('allow read: if isAuthenticated()'));
      expect(rulesContent, contains('allow create: if isAuthenticated()'));
    });
  });
}
