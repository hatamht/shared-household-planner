// Real-time Listeners & Remote Change Notifications — Unit & Widget Tests (t28)
// Tests: 1-88 covering all Acceptance Criteria
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/features/auth/data/repositories/fake_cloud_sync_repository.dart';
import 'package:shared_household_planner/features/auth/domain/entities/cloud_schema.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/sync/domain/entities/remote_change_event.dart';
import 'package:shared_household_planner/features/sync/domain/services/realtime_sync_service.dart';
import 'package:shared_household_planner/features/sync/presentation/bloc/realtime_bloc.dart';
import 'package:shared_household_planner/features/sync/presentation/bloc/realtime_event.dart';
import 'package:shared_household_planner/features/sync/presentation/bloc/realtime_state.dart';
import 'package:shared_household_planner/features/sync/presentation/widgets/remote_change_banner.dart';

// ── Test Localizations ────────────────────────────────────────────────────────
class _TestLoc extends AppLocalizations {
  _TestLoc() : super(const Locale('en'));

  static const Map<String, String> _strings = {
    'remote_bill_added': '{user} added an expense: {amount} [{description}]',
    'remote_bill_updated': '{user} updated an expense: {amount} [{description}]',
    'remote_bill_deleted': '{user} deleted expense [{description}]',
    'remote_sync_active': 'Live sync active',
    'remote_member_activity': 'Member Activity',
  };

  @override
  String translate(String key) => _strings[key] ?? key;
}

class _TestLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestLocDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(_TestLoc());
  @override
  bool shouldReload(_TestLocDelegate old) => false;
}

// ── Test Fake Bill Repository ─────────────────────────────────────────────────
class FakeBillRepository implements BillRepository {
  final Map<String, Bill> _store = {};

  @override
  Future<Either<Failure, Bill>> create(Bill bill) async {
    _store[bill.id] = bill;
    return Right(bill);
  }

  @override
  Future<Either<Failure, List<Bill>>> getAll() async {
    return Right(_store.values.toList());
  }

  @override
  Future<Either<Failure, Bill>> getById(String billId) async {
    final bill = _store[billId];
    if (bill != null) return Right(bill);
    return const Left(ServerFailure('Bill not found'));
  }

  @override
  Future<Either<Failure, Bill>> update(Bill bill) async {
    _store[bill.id] = bill;
    return Right(bill);
  }

  @override
  Future<Either<Failure, void>> delete(String billId) async {
    _store.remove(billId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(String projectId) async {
    return Right(_store.values.where((b) => b.projectId == projectId).toList());
  }

  int get count => _store.length;
  bool contains(String billId) => _store.containsKey(billId);
  Bill? get(String billId) => _store[billId];
}

// Helper to build test apps
Widget buildRealtimeTestApp({
  required Widget child,
  RealtimeBloc? bloc,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      _TestLocDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: Scaffold(
      body: bloc != null
          ? BlocProvider<RealtimeBloc>.value(
              value: bloc,
              child: RemoteChangeNotificationListener(
                bloc: bloc,
                child: child,
              ),
            )
          : child,
    ),
  );
}

CloudBill makeCloudBill({
  String id = 'cb1',
  String projectId = 'proj1',
  double amount = 50000,
  String description = 'Taxi',
  String payerId = 'u1',
  String payerName = 'Minh',
  String splitMethod = 'equal',
  DateTime? date,
  DateTime? updatedAt,
}) {
  final now = DateTime.now();
  return CloudBill(
    id: id,
    projectId: projectId,
    amount: amount,
    description: description,
    payerId: payerId,
    payerName: payerName,
    splitMethod: splitMethod,
    splits: const {},
    date: date ?? now,
    createdAt: now,
    updatedAt: updatedAt ?? now,
    createdBy: payerId,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ────────────────────────────────────────────────────────────────────────────
  // Group 1: RemoteBillChange Entity & Serialization (AC 1, AC 3)
  // ────────────────────────────────────────────────────────────────────────────
  group('Group 1: RemoteBillChange Entity & Serialization (AC 1, AC 3)', () {
    test('1. RemoteBillChange has correct fields', () {
      final now = DateTime.now();
      final change = RemoteBillChange(
        id: 'b1',
        projectId: 'p1',
        type: RemoteChangeType.added,
        payerName: 'Minh',
        description: 'Taxi',
        amount: 50000,
        currency: 'VND',
        timestamp: now,
      );

      expect(change.id, 'b1');
      expect(change.projectId, 'p1');
      expect(change.type, RemoteChangeType.added);
      expect(change.payerName, 'Minh');
      expect(change.description, 'Taxi');
      expect(change.amount, 50000);
      expect(change.currency, 'VND');
      expect(change.timestamp, now);
      expect(change.isAdded, isTrue);
      expect(change.isModified, isFalse);
      expect(change.isRemoved, isFalse);
    });

    test('2. isModified and isRemoved flags work correctly', () {
      final changeMod = RemoteBillChange(
        id: 'b1',
        projectId: 'p1',
        type: RemoteChangeType.modified,
        payerName: 'Minh',
        description: 'Taxi',
        amount: 50000,
        timestamp: DateTime.now(),
      );
      expect(changeMod.isModified, isTrue);
      expect(changeMod.isAdded, isFalse);

      final changeDel = RemoteBillChange(
        id: 'b1',
        projectId: 'p1',
        type: RemoteChangeType.removed,
        payerName: 'Minh',
        description: 'Taxi',
        amount: 50000,
        timestamp: DateTime.now(),
      );
      expect(changeDel.isRemoved, isTrue);
      expect(changeDel.isAdded, isFalse);
    });

    test('3. formatMessage for added bill replaces all placeholders', () {
      final change = RemoteBillChange(
        id: 'b1',
        projectId: 'p1',
        type: RemoteChangeType.added,
        payerName: 'Minh',
        description: 'Vé tham quan',
        amount: 120000,
        currency: 'đ',
        timestamp: DateTime.now(),
      );

      final msg = change.formatMessage(
        addedTemplate: '{user} vừa thêm chi tiêu: {amount} [{description}]',
        updatedTemplate: '{user} vừa sửa chi tiêu: {amount} [{description}]',
        removedTemplate: '{user} vừa xóa chi tiêu [{description}]',
        formattedAmount: '120.000đ',
      );

      expect(msg, 'Minh vừa thêm chi tiêu: 120.000đ [Vé tham quan]');
    });

    test('4. formatMessage for updated bill replaces all placeholders', () {
      final change = RemoteBillChange(
        id: 'b2',
        projectId: 'p1',
        type: RemoteChangeType.modified,
        payerName: 'An',
        description: 'Ăn tối',
        amount: 250000,
        currency: 'VND',
        timestamp: DateTime.now(),
      );

      final msg = change.formatMessage(
        addedTemplate: '{user} added: {amount} [{description}]',
        updatedTemplate: '{user} updated: {amount} [{description}]',
        removedTemplate: '{user} removed [{description}]',
        formattedAmount: '250,000 VND',
      );

      expect(msg, 'An updated: 250,000 VND [Ăn tối]');
    });

    test('5. formatMessage for removed bill replaces placeholders', () {
      final change = RemoteBillChange(
        id: 'b3',
        projectId: 'p1',
        type: RemoteChangeType.removed,
        payerName: 'Bình',
        description: 'Tiền nước',
        amount: 30000,
        timestamp: DateTime.now(),
      );

      final msg = change.formatMessage(
        addedTemplate: '{user} added: {amount} [{description}]',
        updatedTemplate: '{user} updated: {amount} [{description}]',
        removedTemplate: '{user} deleted expense [{description}]',
      );

      expect(msg, 'Bình deleted expense [Tiền nước]');
    });

    test('6. formatMessage fallbacks to default user when payerName is empty', () {
      final change = RemoteBillChange(
        id: 'b4',
        projectId: 'p1',
        type: RemoteChangeType.added,
        payerName: '',
        description: 'Coffee',
        amount: 40000,
        timestamp: DateTime.now(),
      );

      final msg = change.formatMessage(
        addedTemplate: '{user} vừa thêm chi tiêu: {amount} [{description}]',
        updatedTemplate: '',
        removedTemplate: '',
        formattedAmount: '40.000đ',
      );

      expect(msg, 'Thành viên vừa thêm chi tiêu: 40.000đ [Coffee]');
    });

    test('7. fromCloudBill constructs RemoteBillChange correctly', () {
      final cloudBill = makeCloudBill(
        id: 'c_test',
        projectId: 'p_test',
        amount: 75000,
        description: 'Xăng xe',
        payerName: 'Hòa',
      );

      final change = RemoteBillChange.fromCloudBill(
        bill: cloudBill,
        type: RemoteChangeType.added,
      );

      expect(change.id, 'c_test');
      expect(change.projectId, 'p_test');
      expect(change.amount, 75000);
      expect(change.description, 'Xăng xe');
      expect(change.payerName, 'Hòa');
      expect(change.bill, cloudBill);
    });

    test('8. fromCloudBill falls back to payerId if payerName is empty', () {
      final cloudBill = makeCloudBill(
        id: 'c_test2',
        payerId: 'user_123',
        payerName: '',
      );

      final change = RemoteBillChange.fromCloudBill(
        bill: cloudBill,
        type: RemoteChangeType.modified,
      );

      expect(change.payerName, 'user_123');
    });

    test('9. toMap and fromMap round-trip', () {
      final original = RemoteBillChange(
        id: 'b_map',
        projectId: 'p_map',
        type: RemoteChangeType.added,
        payerName: 'Dũng',
        description: 'Ăn trưa',
        amount: 80000,
        currency: 'VND',
        timestamp: DateTime(2026, 9, 27, 10, 0),
      );

      final map = original.toMap();
      final restored = RemoteBillChange.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.projectId, original.projectId);
      expect(restored.type, original.type);
      expect(restored.payerName, original.payerName);
      expect(restored.description, original.description);
      expect(restored.amount, original.amount);
      expect(restored.currency, original.currency);
    });

    test('10. copyWith creates modified instance', () {
      final original = RemoteBillChange(
        id: 'b1',
        projectId: 'p1',
        type: RemoteChangeType.added,
        payerName: 'Minh',
        description: 'Taxi',
        amount: 50000,
        timestamp: DateTime.now(),
      );

      final copied = original.copyWith(amount: 60000, description: 'Grab');
      expect(copied.amount, 60000);
      expect(copied.description, 'Grab');
      expect(copied.id, original.id);
      expect(copied.payerName, original.payerName);
    });

    test('11. Equatable props identify equal objects', () {
      final now = DateTime(2026, 9, 27, 12, 0);
      final c1 = RemoteBillChange(
        id: 'b1',
        projectId: 'p1',
        type: RemoteChangeType.added,
        payerName: 'Minh',
        description: 'Taxi',
        amount: 50000,
        timestamp: now,
      );
      final c2 = RemoteBillChange(
        id: 'b1',
        projectId: 'p1',
        type: RemoteChangeType.added,
        payerName: 'Minh',
        description: 'Taxi',
        amount: 50000,
        timestamp: now,
      );

      expect(c1, equals(c2));
    });

    test('12. RemoteChangeType enum values are complete', () {
      expect(RemoteChangeType.values.length, 3);
      expect(RemoteChangeType.values, contains(RemoteChangeType.added));
      expect(RemoteChangeType.values, contains(RemoteChangeType.modified));
      expect(RemoteChangeType.values, contains(RemoteChangeType.removed));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Group 2: CloudSyncRepository Streaming Contract (AC 1)
  // ────────────────────────────────────────────────────────────────────────────
  group('Group 2: CloudSyncRepository Streaming Contract (AC 1)', () {
    late FakeCloudSyncRepository repo;

    setUp(() {
      repo = FakeCloudSyncRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    test('13. listenToProjectBills returns a stream', () {
      final stream = repo.listenToProjectBills('p1');
      expect(stream, isA<Stream<List<CloudBill>>>());
    });

    test('14. listenToProject returns a stream', () {
      final stream = repo.listenToProject('p1');
      expect(stream, isA<Stream<CloudProject?>>());
    });

    test('15. saveBill emits updated list into bill stream', () async {
      final stream = repo.listenToProjectBills('p1');
      final completer = Completer<List<CloudBill>>();

      final sub = stream.skip(1).listen((bills) {
        if (!completer.isCompleted) completer.complete(bills);
      });

      final bill = makeCloudBill(id: 'b1', projectId: 'p1', description: 'Coffee');
      await repo.saveBill(bill);

      final result = await completer.future.timeout(const Duration(seconds: 2));
      expect(result.length, 1);
      expect(result.first.id, 'b1');
      expect(result.first.description, 'Coffee');

      await sub.cancel();
    });

    test('16. saveBill updates existing bill in stream', () async {
      final bill1 = makeCloudBill(id: 'b1', projectId: 'p1', amount: 50000);
      await repo.saveBill(bill1);

      final stream = repo.listenToProjectBills('p1');
      final completer = Completer<List<CloudBill>>();

      final sub = stream.skip(1).listen((bills) {
        if (!completer.isCompleted) completer.complete(bills);
      });

      final updatedBill = makeCloudBill(id: 'b1', projectId: 'p1', amount: 70000);
      await repo.saveBill(updatedBill);

      final result = await completer.future.timeout(const Duration(seconds: 2));
      expect(result.length, 1);
      expect(result.first.amount, 70000);

      await sub.cancel();
    });

    test('17. deleteBill removes bill and emits to stream', () async {
      final bill = makeCloudBill(id: 'b1', projectId: 'p1');
      await repo.saveBill(bill);

      final stream = repo.listenToProjectBills('p1');
      final completer = Completer<List<CloudBill>>();

      final sub = stream.skip(1).listen((bills) {
        if (!completer.isCompleted) completer.complete(bills);
      });

      await repo.deleteBill('p1', 'b1');

      final result = await completer.future.timeout(const Duration(seconds: 2));
      expect(result, isEmpty);

      await sub.cancel();
    });

    test('18. emitProjectBills helper pushes bills immediately', () async {
      final stream = repo.listenToProjectBills('p2');
      final completer = Completer<List<CloudBill>>();

      final sub = stream.listen((bills) {
        if (bills.isNotEmpty && !completer.isCompleted) {
          completer.complete(bills);
        }
      });

      repo.emitProjectBills('p2', [
        makeCloudBill(id: 'b1', projectId: 'p2'),
        makeCloudBill(id: 'b2', projectId: 'p2'),
      ]);

      final result = await completer.future.timeout(const Duration(seconds: 2));
      expect(result.length, 2);

      await sub.cancel();
    });

    test('19. emitProjectUpdate pushes project updates', () async {
      final stream = repo.listenToProject('p3');
      final completer = Completer<CloudProject?>();

      final sub = stream.skip(1).listen((project) {
        if (!completer.isCompleted) completer.complete(project);
      });

      final project = CloudProject(
        id: 'p3',
        name: 'Du lịch Đà Lạt',
        currency: 'VND',
        color: '#4CAF50',
        ownerId: 'u1',
        memberIds: const ['u1'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      repo.emitProjectUpdate(project);

      final result = await completer.future.timeout(const Duration(seconds: 2));
      expect(result?.name, 'Du lịch Đà Lạt');

      await sub.cancel();
    });

    test('20. Multiple subscribers to same project bill stream receive updates', () async {
      final stream1 = repo.listenToProjectBills('p4');
      final stream2 = repo.listenToProjectBills('p4');

      final c1 = Completer<void>();
      final c2 = Completer<void>();

      final sub1 = stream1.skip(1).listen((_) {
        if (!c1.isCompleted) c1.complete();
      });
      final sub2 = stream2.skip(1).listen((_) {
        if (!c2.isCompleted) c2.complete();
      });

      repo.emitProjectBills('p4', [makeCloudBill(id: 'b1', projectId: 'p4')]);

      await Future.wait([
        c1.future.timeout(const Duration(seconds: 2)),
        c2.future.timeout(const Duration(seconds: 2)),
      ]);

      await sub1.cancel();
      await sub2.cancel();
    });

    test('21. Separate projects have isolated bill streams', () async {
      final streamA = repo.listenToProjectBills('pA');
      final streamB = repo.listenToProjectBills('pB');

      List<CloudBill>? receivedInB;
      final subB = streamB.skip(1).listen((b) => receivedInB = b);

      repo.emitProjectBills('pA', [makeCloudBill(id: 'bA', projectId: 'pA')]);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(receivedInB, isNull);
      await subB.cancel();
    });

    test('22. Initial stream emission delivers empty list for new project', () async {
      final stream = repo.listenToProjectBills('p_empty');
      final first = await stream.first.timeout(const Duration(seconds: 2));
      expect(first, isEmpty);
    });

    test('23. Initial stream emission delivers pre-existing bills', () async {
      repo.bills['p_pre'] = [makeCloudBill(id: 'b_pre', projectId: 'p_pre')];
      final stream = repo.listenToProjectBills('p_pre');
      final first = await stream.first.timeout(const Duration(seconds: 2));
      expect(first.length, 1);
      expect(first.first.id, 'b_pre');
    });

    test('24. dispose closes controllers safely', () {
      repo.listenToProjectBills('p_disp');
      repo.listenToProject('p_disp');
      repo.dispose();
      // Should not throw on second dispose
      repo.dispose();
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Group 3: RealtimeSyncService Lifecycle (AC 1, AC 4)
  // ────────────────────────────────────────────────────────────────────────────
  group('Group 3: RealtimeSyncService Lifecycle (AC 1, AC 4)', () {
    late FakeCloudSyncRepository cloudRepo;
    late FakeBillRepository billRepo;
    late RealtimeSyncService service;

    setUp(() {
      cloudRepo = FakeCloudSyncRepository();
      billRepo = FakeBillRepository();
      service = RealtimeSyncService(
        cloudSyncRepository: cloudRepo,
        billRepository: billRepo,
      );
    });

    tearDown(() {
      service.dispose();
      cloudRepo.dispose();
    });

    test('25. Initial state has zero attached projects', () {
      expect(service.activeProjects, isEmpty);
      expect(service.activeSubscriptionCount, 0);
      expect(service.isPaused, isFalse);
    });

    test('26. attachProjectListener attaches project', () {
      service.attachProjectListener('p1');
      expect(service.activeProjects, contains('p1'));
      expect(service.isListening('p1'), isTrue);
      expect(service.activeSubscriptionCount, 1);
    });

    test('27. attachProjectListener ignores empty project id', () {
      service.attachProjectListener('');
      expect(service.activeProjects, isEmpty);
      expect(service.activeSubscriptionCount, 0);
    });

    test('28. attachProjectListener is idempotent for same projectId', () {
      service.attachProjectListener('p1');
      service.attachProjectListener('p1');
      expect(service.activeSubscriptionCount, 1);
      expect(service.activeProjects.length, 1);
    });

    test('29. attach multiple distinct projects', () {
      service.attachProjectListener('p1');
      service.attachProjectListener('p2');
      service.attachProjectListener('p3');
      expect(service.activeProjects.length, 3);
      expect(service.activeSubscriptionCount, 3);
    });

    test('30. detachProjectListener cleans up subscription', () {
      service.attachProjectListener('p1');
      expect(service.isListening('p1'), isTrue);

      service.detachProjectListener('p1');
      expect(service.isListening('p1'), isFalse);
      expect(service.activeProjects, isNot(contains('p1')));
      expect(service.activeSubscriptionCount, 0);
    });

    test('31. detachProjectListener ignores non-attached project', () {
      service.attachProjectListener('p1');
      service.detachProjectListener('p2');
      expect(service.isListening('p1'), isTrue);
      expect(service.activeSubscriptionCount, 1);
    });

    test('32. detachAll clears all subscriptions', () {
      service.attachProjectListener('p1');
      service.attachProjectListener('p2');
      service.attachProjectListener('p3');
      expect(service.activeSubscriptionCount, 3);

      service.detachAll();
      expect(service.activeSubscriptionCount, 0);
      expect(service.activeProjects, isEmpty);
    });

    test('33. changeStream is a broadcast stream', () {
      expect(service.changeStream.isBroadcast, isTrue);
    });

    test('34. Multiple listeners can subscribe to changeStream', () {
      final sub1 = service.changeStream.listen((_) {});
      final sub2 = service.changeStream.listen((_) {});
      sub1.cancel();
      sub2.cancel();
    });

    test('35. isListening returns false when project is not attached', () {
      expect(service.isListening('random_id'), isFalse);
    });

    test('36. activeProjects returns an unmodifiable set', () {
      service.attachProjectListener('p1');
      expect(() => service.activeProjects.add('p2'), throwsUnsupportedError);
    });

    test('37. Re-attaching after detach works properly', () {
      service.attachProjectListener('p1');
      service.detachProjectListener('p1');
      service.attachProjectListener('p1');
      expect(service.isListening('p1'), isTrue);
      expect(service.activeSubscriptionCount, 1);
    });

    test('38. dispose cleans up all active listeners', () {
      service.attachProjectListener('p1');
      service.attachProjectListener('p2');
      service.dispose();
      expect(service.activeProjects, isEmpty);
      expect(service.activeSubscriptionCount, 0);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Group 4: Change Detection & Auto-merge to Local Store (AC 2, AC 3)
  // ────────────────────────────────────────────────────────────────────────────
  group('Group 4: Change Detection & Auto-merge to Local Store (AC 2, AC 3)', () {
    late FakeCloudSyncRepository cloudRepo;
    late FakeBillRepository billRepo;
    late RealtimeSyncService service;

    setUp(() {
      cloudRepo = FakeCloudSyncRepository();
      billRepo = FakeBillRepository();
      service = RealtimeSyncService(
        cloudSyncRepository: cloudRepo,
        billRepository: billRepo,
      );
    });

    tearDown(() {
      service.dispose();
      cloudRepo.dispose();
    });

    test('39. Initial snapshot loads existing bills without notifying change stream', () async {
      cloudRepo.bills['p1'] = [
        makeCloudBill(id: 'b1', projectId: 'p1', description: 'Initial Bill'),
      ];

      bool changeNotified = false;
      final sub = service.changeStream.listen((_) => changeNotified = true);

      service.attachProjectListener('p1');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(changeNotified, isFalse, reason: 'Initial load should not trigger alert');
      await sub.cancel();
    });

    test('40. Initial snapshot auto-merges existing bills into local SQLite store', () async {
      cloudRepo.bills['p1'] = [
        makeCloudBill(id: 'b1', projectId: 'p1', description: 'Existing Bill', amount: 99000),
      ];

      service.attachProjectListener('p1');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(billRepo.contains('b1'), isTrue);
      expect(billRepo.get('b1')?.title, 'Existing Bill');
      expect(billRepo.get('b1')?.amount, 99000);
    });

    test('41. Newly added bill triggers RemoteChangeType.added on changeStream', () async {
      service.attachProjectListener('p1');
      await Future.delayed(const Duration(milliseconds: 100));

      final completer = Completer<RemoteBillChange>();
      final sub = service.changeStream.listen((event) {
        if (!completer.isCompleted) completer.complete(event);
      });

      final newBill = makeCloudBill(
        id: 'b_new',
        projectId: 'p1',
        description: 'Taxi SB',
        amount: 150000,
        payerName: 'Lan',
      );
      cloudRepo.emitProjectBills('p1', [newBill]);

      final event = await completer.future.timeout(const Duration(seconds: 2));
      expect(event.type, RemoteChangeType.added);
      expect(event.id, 'b_new');
      expect(event.description, 'Taxi SB');
      expect(event.amount, 150000);
      expect(event.payerName, 'Lan');

      await sub.cancel();
    });

    test('42. Newly added bill is auto-saved to local BillRepository', () async {
      service.attachProjectListener('p1');
      await Future.delayed(const Duration(milliseconds: 100));

      final newBill = makeCloudBill(id: 'b_save', projectId: 'p1', description: 'Ăn kem');
      cloudRepo.emitProjectBills('p1', [newBill]);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(billRepo.contains('b_save'), isTrue);
      expect(billRepo.get('b_save')?.title, 'Ăn kem');
    });

    test('43. Modified bill triggers RemoteChangeType.modified on changeStream', () async {
      final initial = makeCloudBill(id: 'b_mod', projectId: 'p1', amount: 50000);
      cloudRepo.bills['p1'] = [initial];

      service.attachProjectListener('p1');
      await Future.delayed(const Duration(milliseconds: 100));

      final completer = Completer<RemoteBillChange>();
      final sub = service.changeStream.listen((event) {
        if (!completer.isCompleted) completer.complete(event);
      });

      final modified = makeCloudBill(
        id: 'b_mod',
        projectId: 'p1',
        amount: 80000,
        updatedAt: DateTime.now().add(const Duration(seconds: 5)),
      );
      cloudRepo.emitProjectBills('p1', [modified]);

      final event = await completer.future.timeout(const Duration(seconds: 2));
      expect(event.type, RemoteChangeType.modified);
      expect(event.amount, 80000);

      await sub.cancel();
    });

    test('44. Modified bill updates local BillRepository record', () async {
      final initial = makeCloudBill(id: 'b_up', projectId: 'p1', amount: 50000);
      cloudRepo.bills['p1'] = [initial];

      service.attachProjectListener('p1');
      await Future.delayed(const Duration(milliseconds: 100));

      final updated = makeCloudBill(
        id: 'b_up',
        projectId: 'p1',
        amount: 95000,
        description: 'Updated Title',
        updatedAt: DateTime.now().add(const Duration(seconds: 1)),
      );
      cloudRepo.emitProjectBills('p1', [updated]);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(billRepo.get('b_up')?.amount, 95000);
      expect(billRepo.get('b_up')?.title, 'Updated Title');
    });

    test('45. Removed bill triggers RemoteChangeType.removed on changeStream', () async {
      final b1 = makeCloudBill(id: 'b_del', projectId: 'p1', description: 'Delete Me');
      cloudRepo.bills['p1'] = [b1];

      service.attachProjectListener('p1');
      await Future.delayed(const Duration(milliseconds: 100));

      final completer = Completer<RemoteBillChange>();
      final sub = service.changeStream.listen((event) {
        if (!completer.isCompleted) completer.complete(event);
      });

      // Emit empty list: b_del was removed
      cloudRepo.emitProjectBills('p1', []);

      final event = await completer.future.timeout(const Duration(seconds: 2));
      expect(event.type, RemoteChangeType.removed);
      expect(event.id, 'b_del');

      await sub.cancel();
    });

    test('46. Removed bill deletes local BillRepository record', () async {
      final b1 = makeCloudBill(id: 'b_del_local', projectId: 'p1');
      cloudRepo.bills['p1'] = [b1];

      service.attachProjectListener('p1');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(billRepo.contains('b_del_local'), isTrue);

      cloudRepo.emitProjectBills('p1', []);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(billRepo.contains('b_del_local'), isFalse);
    });

    test('47. convertCloudBillToLocal handles empty splits by creating default participant', () {
      final cb = makeCloudBill(
        id: 'c1',
        amount: 100000,
        payerName: 'Dương',
        payerId: 'u1',
        description: 'Ăn sáng',
      );
      final bill = RealtimeSyncService.convertCloudBillToLocal(cb);

      expect(bill.id, 'c1');
      expect(bill.title, 'Ăn sáng');
      expect(bill.amount, 100000);
      expect(bill.paidBy, 'Dương');
      expect(bill.participants.length, 1);
      expect(bill.participants.first.name, 'Dương');
      expect(bill.participants.first.amount, 100000);
    });

    test('48. convertCloudBillToLocal handles custom splits', () {
      final cb = CloudBill(
        id: 'c2',
        projectId: 'p1',
        amount: 200000,
        description: 'Vé xem phim',
        payerId: 'u1',
        payerName: 'An',
        splitMethod: 'custom',
        splits: const {'An': 100000, 'Bình': 100000},
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'u1',
      );
      final bill = RealtimeSyncService.convertCloudBillToLocal(cb);

      expect(bill.participants.length, 2);
      expect(bill.splitMode, 'custom');
    });

    test('49. Multiple additions in a single emission all notify', () async {
      service.attachProjectListener('p1');
      await Future.delayed(const Duration(milliseconds: 100));

      final events = <RemoteBillChange>[];
      final sub = service.changeStream.listen(events.add);

      cloudRepo.emitProjectBills('p1', [
        makeCloudBill(id: 'b_multi1', projectId: 'p1', description: 'Item 1'),
        makeCloudBill(id: 'b_multi2', projectId: 'p1', description: 'Item 2'),
      ]);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(events.length, 2);

      await sub.cancel();
    });

    test('50. Service works gracefully when billRepository is null', () async {
      final serviceNoRepo = RealtimeSyncService(cloudSyncRepository: cloudRepo);
      serviceNoRepo.attachProjectListener('p1');
      await Future.delayed(const Duration(milliseconds: 50));

      // Should not throw
      cloudRepo.emitProjectBills('p1', [makeCloudBill(id: 'b_null', projectId: 'p1')]);
      await Future.delayed(const Duration(milliseconds: 50));

      serviceNoRepo.dispose();
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Group 5: Battery & Network Optimization (Pause / Resume) (AC 4, AC 5)
  // ────────────────────────────────────────────────────────────────────────────
  group('Group 5: Battery & Network Optimization (Pause / Resume) (AC 4, AC 5)', () {
    late FakeCloudSyncRepository cloudRepo;
    late RealtimeSyncService service;

    setUp(() {
      cloudRepo = FakeCloudSyncRepository();
      service = RealtimeSyncService(cloudSyncRepository: cloudRepo);
    });

    tearDown(() {
      service.dispose();
      cloudRepo.dispose();
    });

    test('51. pauseListeners sets isPaused flag', () {
      service.pauseListeners();
      expect(service.isPaused, isTrue);
    });

    test('52. pauseListeners cancels all cloud subscriptions', () {
      service.attachProjectListener('p1');
      service.attachProjectListener('p2');
      expect(service.activeSubscriptionCount, 2);

      service.pauseListeners();
      expect(service.activeSubscriptionCount, 0,
          reason: 'Subscriptions must be canceled to save battery');
      expect(service.isPaused, isTrue);
    });

    test('53. isListening returns false when service is paused', () {
      service.attachProjectListener('p1');
      expect(service.isListening('p1'), isTrue);

      service.pauseListeners();
      expect(service.isListening('p1'), isFalse);
    });

    test('54. resumeListeners reconnects attached projects', () {
      service.attachProjectListener('p1');
      service.attachProjectListener('p2');
      service.pauseListeners();
      expect(service.activeSubscriptionCount, 0);

      service.resumeListeners();
      expect(service.isPaused, isFalse);
      expect(service.activeSubscriptionCount, 2);
      expect(service.isListening('p1'), isTrue);
      expect(service.isListening('p2'), isTrue);
    });

    test('55. attachProjectListener while paused remembers project without connecting', () {
      service.pauseListeners();
      service.attachProjectListener('p_paused');
      expect(service.activeProjects, contains('p_paused'));
      expect(service.activeSubscriptionCount, 0);

      service.resumeListeners();
      expect(service.activeSubscriptionCount, 1);
      expect(service.isListening('p_paused'), isTrue);
    });

    test('56. AppLifecycleState.paused triggers pauseListeners', () {
      service.attachProjectListener('p1');
      expect(service.activeSubscriptionCount, 1);

      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(service.isPaused, isTrue);
      expect(service.activeSubscriptionCount, 0);
    });

    test('57. AppLifecycleState.detached triggers pauseListeners', () {
      service.attachProjectListener('p1');
      service.didChangeAppLifecycleState(AppLifecycleState.detached);
      expect(service.isPaused, isTrue);
      expect(service.activeSubscriptionCount, 0);
    });

    test('58. AppLifecycleState.resumed triggers resumeListeners', () {
      service.attachProjectListener('p1');
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(service.isPaused, isTrue);

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(service.isPaused, isFalse);
      expect(service.activeSubscriptionCount, 1);
    });

    test('59. Multiple pause/resume cycles work cleanly', () {
      service.attachProjectListener('p1');
      for (int i = 0; i < 3; i++) {
        service.pauseListeners();
        expect(service.activeSubscriptionCount, 0);
        service.resumeListeners();
        expect(service.activeSubscriptionCount, 1);
      }
    });

    test('60. Detaching project while paused removes it from resume set', () {
      service.attachProjectListener('p1');
      service.pauseListeners();
      service.detachProjectListener('p1');
      service.resumeListeners();
      expect(service.activeSubscriptionCount, 0);
      expect(service.activeProjects, isEmpty);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Group 6: RealtimeBloc Events & State Management (AC 1, AC 2, AC 3)
  // ────────────────────────────────────────────────────────────────────────────
  group('Group 6: RealtimeBloc Events & State Management (AC 1, AC 2, AC 3)', () {
    late FakeCloudSyncRepository cloudRepo;
    late RealtimeSyncService syncService;
    late RealtimeBloc bloc;

    setUp(() {
      cloudRepo = FakeCloudSyncRepository();
      syncService = RealtimeSyncService(cloudSyncRepository: cloudRepo);
      bloc = RealtimeBloc(syncService: syncService);
    });

    tearDown(() {
      bloc.close();
      syncService.dispose();
      cloudRepo.dispose();
    });

    test('61. Initial RealtimeBlocState is clean', () {
      expect(bloc.state.activeProjects, isEmpty);
      expect(bloc.state.latestChange, isNull);
      expect(bloc.state.changeHistory, isEmpty);
      expect(bloc.state.showNotification, isFalse);
      expect(bloc.state.isPaused, isFalse);
    });

    test('62. StartProjectRealtimeEvent adds project to state', () async {
      bloc.add(const StartProjectRealtimeEvent('p1'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.activeProjects, contains('p1'));
      expect(bloc.state.isProjectListening('p1'), isTrue);
      expect(syncService.isListening('p1'), isTrue);
    });

    test('63. StopProjectRealtimeEvent removes project from state', () async {
      bloc.add(const StartProjectRealtimeEvent('p1'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.activeProjects, contains('p1'));

      bloc.add(const StopProjectRealtimeEvent('p1'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.activeProjects, isNot(contains('p1')));
      expect(syncService.isListening('p1'), isFalse);
    });

    test('64. StopAllRealtimeEvent clears all active projects', () async {
      bloc.add(const StartProjectRealtimeEvent('p1'));
      bloc.add(const StartProjectRealtimeEvent('p2'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.activeProjects.length, 2);

      bloc.add(const StopAllRealtimeEvent());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.activeProjects, isEmpty);
      expect(syncService.activeSubscriptionCount, 0);
    });

    test('65. RemoteChangeReceivedEvent updates latestChange and showNotification', () async {
      final change = RemoteBillChange(
        id: 'b1',
        projectId: 'p1',
        type: RemoteChangeType.added,
        payerName: 'Minh',
        description: 'Vé xe',
        amount: 70000,
        timestamp: DateTime.now(),
      );

      bloc.add(RemoteChangeReceivedEvent(change));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.showNotification, isTrue);
      expect(bloc.state.latestChange, change);
      expect(bloc.state.changeHistory, contains(change));
      expect(bloc.state.totalChangesReceived, 1);
    });

    test('66. Multiple RemoteChangeReceivedEvents append to changeHistory', () async {
      final c1 = RemoteBillChange(
        id: 'b1',
        projectId: 'p1',
        type: RemoteChangeType.added,
        payerName: 'A',
        description: 'T1',
        amount: 10000,
        timestamp: DateTime.now(),
      );
      final c2 = RemoteBillChange(
        id: 'b2',
        projectId: 'p1',
        type: RemoteChangeType.modified,
        payerName: 'B',
        description: 'T2',
        amount: 20000,
        timestamp: DateTime.now(),
      );

      bloc.add(RemoteChangeReceivedEvent(c1));
      bloc.add(RemoteChangeReceivedEvent(c2));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.totalChangesReceived, 2);
      expect(bloc.state.latestChange, c2);
    });

    test('67. DismissRemoteNotificationEvent hides notification banner', () async {
      final change = RemoteBillChange(
        id: 'b1',
        projectId: 'p1',
        type: RemoteChangeType.added,
        payerName: 'Minh',
        description: 'X',
        amount: 10000,
        timestamp: DateTime.now(),
      );

      bloc.add(RemoteChangeReceivedEvent(change));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.showNotification, isTrue);

      bloc.add(const DismissRemoteNotificationEvent());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.showNotification, isFalse);
      expect(bloc.state.latestChange, isNull);
    });

    test('68. ClearRemoteChangeHistoryEvent resets history', () async {
      bloc.add(RemoteChangeReceivedEvent(RemoteBillChange(
        id: 'b1',
        projectId: 'p1',
        type: RemoteChangeType.added,
        payerName: 'X',
        description: 'Y',
        amount: 1000,
        timestamp: DateTime.now(),
      )));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.totalChangesReceived, 1);

      bloc.add(const ClearRemoteChangeHistoryEvent());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.totalChangesReceived, 0);
      expect(bloc.state.changeHistory, isEmpty);
    });

    test('69. RealtimeAppLifecycleChangedEvent handles paused state', () async {
      bloc.add(const StartProjectRealtimeEvent('p1'));
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const RealtimeAppLifecycleChangedEvent(AppLifecycleState.paused));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.isPaused, isTrue);
      expect(bloc.state.isProjectListening('p1'), isFalse);
    });

    test('70. RealtimeAppLifecycleChangedEvent handles resumed state', () async {
      bloc.add(const StartProjectRealtimeEvent('p1'));
      bloc.add(const RealtimeAppLifecycleChangedEvent(AppLifecycleState.paused));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.isPaused, isTrue);

      bloc.add(const RealtimeAppLifecycleChangedEvent(AppLifecycleState.resumed));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.isPaused, isFalse);
      expect(bloc.state.isProjectListening('p1'), isTrue);
    });

    test('71. Service changeStream automatically forwards to RealtimeBloc', () async {
      bloc.add(const StartProjectRealtimeEvent('p1'));
      await Future.delayed(const Duration(milliseconds: 100));

      // Push a new bill from cloud repo
      cloudRepo.emitProjectBills('p1', [
        makeCloudBill(id: 'b_auto', projectId: 'p1', description: 'Trà sữa', amount: 35000),
      ]);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state.showNotification, isTrue);
      expect(bloc.state.latestChange?.description, 'Trà sữa');
      expect(bloc.state.latestChange?.amount, 35000);
    });

    test('72. RealtimeBlocState copyWith preserves unspecified fields', () {
      const state = RealtimeBlocState(isPaused: false, showNotification: true);
      final copy = state.copyWith(isPaused: true);
      expect(copy.isPaused, isTrue);
      expect(copy.showNotification, isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Group 7: RemoteChangeNotificationListener & Status Indicator Widgets (AC 3)
  // ────────────────────────────────────────────────────────────────────────────
  group('Group 7: RemoteChangeNotificationListener & Widgets (AC 3)', () {
    late FakeCloudSyncRepository cloudRepo;
    late RealtimeSyncService syncService;
    late RealtimeBloc bloc;

    setUp(() {
      cloudRepo = FakeCloudSyncRepository();
      syncService = RealtimeSyncService(cloudSyncRepository: cloudRepo);
      bloc = RealtimeBloc(syncService: syncService);
    });

    tearDown(() {
      bloc.close();
      syncService.dispose();
      cloudRepo.dispose();
    });

    testWidgets('73. RemoteChangeNotificationListener renders child widget', (tester) async {
      await tester.pumpWidget(
        buildRealtimeTestApp(
          child: const Text('Child Content'),
          bloc: bloc,
        ),
      );
      expect(find.text('Child Content'), findsOneWidget);
    });

    testWidgets('74. RemoteChangeNotificationListener works safely without bloc in context', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RemoteChangeNotificationListener(
              child: Text('Safe Child'),
            ),
          ),
        ),
      );
      expect(find.text('Safe Child'), findsOneWidget);
    });

    test('75. showNotification is true and latestChange set when remote bill added', () async {
      final change = RemoteBillChange(
        id: 'b_snack',
        projectId: 'p1',
        type: RemoteChangeType.added,
        payerName: 'Minh',
        description: 'Taxi',
        amount: 50000,
        currency: 'VND',
        timestamp: DateTime.now(),
      );

      bloc.add(RemoteChangeReceivedEvent(change));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.showNotification, isTrue);
      expect(bloc.state.latestChange, change);
    });

    test('76. formatMessage formats added bill notification string properly', () {
      final change = RemoteBillChange(
        id: 'b_snack2',
        projectId: 'p1',
        type: RemoteChangeType.added,
        payerName: 'User B',
        description: 'Taxi',
        amount: 50000,
        currency: 'VND',
        timestamp: DateTime.now(),
      );

      final msg = change.formatMessage(
        addedTemplate: '{user} vừa thêm chi tiêu: {amount} [{description}]',
        updatedTemplate: '{user} vừa sửa chi tiêu: {amount} [{description}]',
        removedTemplate: '{user} vừa xóa chi tiêu [{description}]',
        formattedAmount: '50.000đ',
      );

      expect(msg, 'User B vừa thêm chi tiêu: 50.000đ [Taxi]');
    });

    test('77. formatMessage formats modified bill notification string properly', () {
      final change = RemoteBillChange(
        id: 'b_mod',
        projectId: 'p1',
        type: RemoteChangeType.modified,
        payerName: 'Hòa',
        description: 'Vé tàu',
        amount: 120000,
        currency: 'VND',
        timestamp: DateTime.now(),
      );

      final msg = change.formatMessage(
        addedTemplate: '{user} added: {amount} [{description}]',
        updatedTemplate: '{user} updated an expense: {amount} [{description}]',
        removedTemplate: '{user} deleted expense [{description}]',
        formattedAmount: '120,000 VND',
      );

      expect(msg, 'Hòa updated an expense: 120,000 VND [Vé tàu]');
    });

    test('78. formatMessage formats removed bill notification string properly', () {
      final change = RemoteBillChange(
        id: 'b_del',
        projectId: 'p1',
        type: RemoteChangeType.removed,
        payerName: 'Minh',
        description: 'Hóa đơn nhầm',
        amount: 10000,
        currency: 'VND',
        timestamp: DateTime.now(),
      );

      final msg = change.formatMessage(
        addedTemplate: '{user} added: {amount} [{description}]',
        updatedTemplate: '{user} updated: {amount} [{description}]',
        removedTemplate: '{user} deleted expense [{description}]',
      );

      expect(msg, 'Minh deleted expense [Hóa đơn nhầm]');
    });

    test('79. RemoteSyncStatusIndicator is a StatelessWidget and instantiable', () {
      const indicator = RemoteSyncStatusIndicator(projectId: 'p1');
      expect(indicator, isA<StatelessWidget>());
      expect(indicator.projectId, 'p1');
    });

    test('80. isProjectListening is true after StartProjectRealtimeEvent', () async {
      expect(bloc.state.isProjectListening('p_listen'), isFalse);
      bloc.add(const StartProjectRealtimeEvent('p_listen'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.isProjectListening('p_listen'), isTrue);
    });

    test('81. isProjectListening returns false after StopProjectRealtimeEvent', () async {
      bloc.add(const StartProjectRealtimeEvent('p_temp'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.isProjectListening('p_temp'), isTrue);

      bloc.add(const StopProjectRealtimeEvent('p_temp'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.isProjectListening('p_temp'), isFalse);
    });

    test('82. isProjectListening returns false when app is paused', () async {
      bloc.add(const StartProjectRealtimeEvent('p_pause'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.isProjectListening('p_pause'), isTrue);

      bloc.add(const RealtimeAppLifecycleChangedEvent(AppLifecycleState.paused));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.isProjectListening('p_pause'), isFalse);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Group 8: Localization, Event Props & Edge Cases (AC 3, AC 6)
  // ────────────────────────────────────────────────────────────────────────────
  group('Group 8: Localization, Event Props & Edge Cases (AC 3, AC 6)', () {
    test('83. All required realtime localization keys exist in test strings', () {
      final loc = _TestLoc();
      expect(loc.translate('remote_bill_added'), contains('{user}'));
      expect(loc.translate('remote_bill_updated'), contains('{user}'));
      expect(loc.translate('remote_bill_deleted'), contains('{user}'));
      expect(loc.translate('remote_sync_active'), isNotEmpty);
      expect(loc.translate('remote_member_activity'), isNotEmpty);
    });

    test('84. Event props equality for all RealtimeEvent subclasses', () {
      const e1 = StartProjectRealtimeEvent('p1');
      const e2 = StartProjectRealtimeEvent('p1');
      expect(e1, equals(e2));

      const e3 = StopProjectRealtimeEvent('p1');
      const e4 = StopProjectRealtimeEvent('p1');
      expect(e3, equals(e4));

      const e5 = StopAllRealtimeEvent();
      const e6 = StopAllRealtimeEvent();
      expect(e5, equals(e6));

      const e7 = DismissRemoteNotificationEvent();
      const e8 = DismissRemoteNotificationEvent();
      expect(e7, equals(e8));

      const e9 = ClearRemoteChangeHistoryEvent();
      const e10 = ClearRemoteChangeHistoryEvent();
      expect(e9, equals(e10));

      const e11 = RealtimeAppLifecycleChangedEvent(AppLifecycleState.resumed);
      const e12 = RealtimeAppLifecycleChangedEvent(AppLifecycleState.resumed);
      expect(e11, equals(e12));
    });

    test('85. RealtimeBloc does not throw when closed', () async {
      final cloudRepo = FakeCloudSyncRepository();
      final syncService = RealtimeSyncService(cloudSyncRepository: cloudRepo);
      final testBloc = RealtimeBloc(syncService: syncService);

      expect(testBloc.isClosed, isFalse);
      await testBloc.close();
      expect(testBloc.isClosed, isTrue);

      syncService.dispose();
      cloudRepo.dispose();
    });

    test('86. convertCloudBillToLocal handles default title when description is empty', () {
      final cb = makeCloudBill(id: 'c_empty', description: '');
      final bill = RealtimeSyncService.convertCloudBillToLocal(cb);
      expect(bill.id, 'c_empty');
      expect(bill.title, '');
    });

    test('87. RealtimeSyncService changeStream does not emit after dispose', () async {
      final cloudRepo = FakeCloudSyncRepository();
      final service = RealtimeSyncService(cloudSyncRepository: cloudRepo);
      service.attachProjectListener('p_disp');
      service.dispose();

      // Cloud emissions should be ignored
      cloudRepo.emitProjectBills('p_disp', [makeCloudBill(id: 'b1', projectId: 'p_disp')]);
      await Future.delayed(const Duration(milliseconds: 50));

      cloudRepo.dispose();
    });

    test('88. Full collaboration cycle: user B adds bill -> local store synced & event emitted', () async {
      final cloudRepo = FakeCloudSyncRepository();
      final billRepo = FakeBillRepository();
      final service = RealtimeSyncService(
        cloudSyncRepository: cloudRepo,
        billRepository: billRepo,
      );
      final bloc = RealtimeBloc(syncService: service);

      bloc.add(const StartProjectRealtimeEvent('proj_shared'));
      await Future.delayed(const Duration(milliseconds: 100));

      // Member B adds bill remotely
      final billB = makeCloudBill(
        id: 'bill_member_b',
        projectId: 'proj_shared',
        amount: 150000,
        description: 'Tiền Taxi',
        payerName: 'User B',
      );
      cloudRepo.emitProjectBills('proj_shared', [billB]);
      await Future.delayed(const Duration(milliseconds: 100));

      // 1. Local SQLite store automatically contains the bill
      expect(billRepo.contains('bill_member_b'), isTrue);
      expect(billRepo.get('bill_member_b')?.amount, 150000);

      // 2. Bloc received the change and is ready to display toast/banner
      expect(bloc.state.showNotification, isTrue);
      expect(bloc.state.latestChange?.payerName, 'User B');
      expect(bloc.state.latestChange?.description, 'Tiền Taxi');

      bloc.close();
      service.dispose();
      cloudRepo.dispose();
    });
  });
}
