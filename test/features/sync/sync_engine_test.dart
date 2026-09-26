import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/features/auth/domain/repositories/cloud_sync_repository.dart';
import 'package:shared_household_planner/features/auth/data/repositories/fake_cloud_sync_repository.dart';
import 'package:shared_household_planner/features/sync/domain/entities/sync_status.dart';
import 'package:shared_household_planner/features/sync/domain/services/network_connectivity_service.dart';
import 'package:shared_household_planner/features/sync/domain/services/sync_service.dart';
import 'package:shared_household_planner/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:shared_household_planner/features/sync/presentation/bloc/sync_event.dart';
import 'package:shared_household_planner/features/sync/presentation/bloc/sync_state.dart';
import 'package:shared_household_planner/features/sync/presentation/widgets/manual_sync_button.dart';
import 'package:shared_household_planner/features/sync/presentation/widgets/sync_status_badge.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/project_detail_screen.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/core/injection_container.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_project_by_id_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/project_screen.dart';
import 'package:shared_household_planner/features/home/presentation/pages/home_screen.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:provider/provider.dart';

import 'package:flutter/foundation.dart';

class TestAppLocalizations extends AppLocalizations {
  final Locale _locale;
  TestAppLocalizations(this._locale) : super(_locale);

  static const Map<String, String> enStrings = {
    'sync_now': 'Sync now',
    'sync_in_progress': 'Syncing data...',
    'sync_success': 'Synced successfully',
    'sync_offline_message': 'You are offline. Data is saved locally and will sync when reconnected.',
    'sync_error_message': 'Sync failed. Will retry later.',
    'sync_status_synced': 'Synced',
    'sync_status_syncing': 'Syncing...',
    'sync_status_pending': 'Pending ({count})',
    'sync_status_offline': 'Offline',
    'sync_status_error': 'Sync error',
    'sync_last_synced': 'Last sync: {time}',
    'sync_just_now': 'Just now',
    'sync_minutes_ago': '{minutes}m ago',
    'sync_hours_ago': '{hours}h ago',
    'sync_never': 'Never',
    'projects': 'Projects',
    'members': 'members',
    'error': 'Error',
  };

  static const Map<String, String> viStrings = {
    'sync_now': 'Đồng bộ ngay',
    'sync_in_progress': 'Đang đồng bộ dữ liệu...',
    'sync_success': 'Đồng bộ thành công',
    'sync_offline_message': 'Bạn đang ngoại tuyến. Dữ liệu đã lưu trên máy và sẽ đồng bộ khi có mạng.',
    'sync_error_message': 'Đồng bộ thất bại. Sẽ thử lại sau.',
    'sync_status_synced': 'Đã đồng bộ',
    'sync_status_syncing': 'Đang đồng bộ...',
    'sync_status_pending': 'Chưa đồng bộ ({count})',
    'sync_status_offline': 'Ngoại tuyến',
    'sync_status_error': 'Lỗi đồng bộ',
    'sync_last_synced': 'Giờ đồng bộ cuối: {time}',
    'sync_just_now': 'Vừa xong',
    'sync_minutes_ago': '{minutes} phút trước',
    'sync_hours_ago': '{hours} giờ trước',
    'sync_never': 'Chưa đồng bộ',
    'projects': 'Dự án',
    'members': 'thành viên',
    'error': 'Lỗi',
  };

  @override
  String translate(String key) {
    if (_locale.languageCode == 'vi') {
      return viStrings[key] ?? key;
    }
    return enStrings[key] ?? key;
  }
}

class TestAppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const TestAppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(TestAppLocalizations(locale));
  }

  @override
  bool shouldReload(TestAppLocalizationsDelegate old) => false;
}

Widget createTestApp({
  required Widget child,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      TestAppLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('en'),
      Locale('vi'),
    ],
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Group 1: SyncState & SyncStatus Entities (AC 1, AC 3)', () {
    test('1. SyncState enum contains all required states', () {
      expect(SyncState.values, contains(SyncState.synced));
      expect(SyncState.values, contains(SyncState.syncing));
      expect(SyncState.values, contains(SyncState.pending));
      expect(SyncState.values, contains(SyncState.offline));
      expect(SyncState.values, contains(SyncState.error));
      expect(SyncState.values.length, 5);
    });

    test('2. SyncStatus default constructor values', () {
      const status = SyncStatus();
      expect(status.state, SyncState.synced);
      expect(status.pendingCount, 0);
      expect(status.lastSyncedAt, isNull);
      expect(status.errorMessage, isNull);
      expect(status.isSynced, isTrue);
      expect(status.isSyncing, isFalse);
      expect(status.isOffline, isFalse);
      expect(status.hasPending, isFalse);
      expect(status.hasError, isFalse);
    });

    test('3. SyncStatus isSyncing is true only when state == syncing', () {
      const s1 = SyncStatus(state: SyncState.syncing);
      expect(s1.isSyncing, isTrue);
      expect(s1.isSynced, isFalse);
    });

    test('4. SyncStatus isOffline is true only when state == offline', () {
      const s1 = SyncStatus(state: SyncState.offline);
      expect(s1.isOffline, isTrue);
      expect(s1.isSynced, isFalse);
    });

    test('5. SyncStatus hasPending is true when pendingCount > 0', () {
      const s1 = SyncStatus(pendingCount: 3);
      expect(s1.hasPending, isTrue);
      expect(s1.isSynced, isFalse);
    });

    test('6. SyncStatus hasError is true only when state == error', () {
      const s1 = SyncStatus(state: SyncState.error, errorMessage: 'Timeout');
      expect(s1.hasError, isTrue);
      expect(s1.errorMessage, 'Timeout');
      expect(s1.isSynced, isFalse);
    });

    test('7. SyncStatus copyWith preserves unedited fields', () {
      final now = DateTime(2026, 9, 26, 12, 0);
      final s1 = SyncStatus(
        state: SyncState.synced,
        pendingCount: 2,
        lastSyncedAt: now,
        errorMessage: 'Err',
      );

      final s2 = s1.copyWith(state: SyncState.syncing);
      expect(s2.state, SyncState.syncing);
      expect(s2.pendingCount, 2);
      expect(s2.lastSyncedAt, now);
      expect(s2.errorMessage, 'Err');
    });

    test('8. SyncStatus copyWith overrides fields correctly', () {
      const s1 = SyncStatus();
      final now = DateTime(2026, 9, 26, 15, 30);
      final s2 = s1.copyWith(
        state: SyncState.pending,
        pendingCount: 5,
        lastSyncedAt: now,
        errorMessage: 'Updated',
      );

      expect(s2.state, SyncState.pending);
      expect(s2.pendingCount, 5);
      expect(s2.lastSyncedAt, now);
      expect(s2.errorMessage, 'Updated');
    });

    test('9. SyncStatus equality & props', () {
      final now = DateTime(2026, 9, 26, 10, 0);
      final s1 = SyncStatus(state: SyncState.synced, lastSyncedAt: now);
      final s2 = SyncStatus(state: SyncState.synced, lastSyncedAt: now);
      final s3 = SyncStatus(state: SyncState.offline, lastSyncedAt: now);

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1, isNot(equals(s3)));
    });

    test('10. SyncStatus.formatRelativeTime returns neverText when lastSyncedAt is null', () {
      const s = SyncStatus();
      final result = s.formatRelativeTime(
        justNowText: 'Just now',
        minutesAgoTemplate: '{minutes}m ago',
        hoursAgoTemplate: '{hours}h ago',
        neverText: 'Never',
      );
      expect(result, 'Never');
    });

    test('11. SyncStatus.formatRelativeTime returns justNowText when diff < 45 seconds', () {
      final s = SyncStatus(lastSyncedAt: DateTime.now().subtract(const Duration(seconds: 15)));
      final result = s.formatRelativeTime(
        justNowText: 'Just now',
        minutesAgoTemplate: '{minutes}m ago',
        hoursAgoTemplate: '{hours}h ago',
        neverText: 'Never',
      );
      expect(result, 'Just now');
    });

    test('12. SyncStatus.formatRelativeTime returns minutes ago when diff < 60 minutes', () {
      final s = SyncStatus(lastSyncedAt: DateTime.now().subtract(const Duration(minutes: 12)));
      final result = s.formatRelativeTime(
        justNowText: 'Just now',
        minutesAgoTemplate: '{minutes}m ago',
        hoursAgoTemplate: '{hours}h ago',
        neverText: 'Never',
      );
      expect(result, '12m ago');
    });

    test('13. SyncStatus.formatRelativeTime returns hours ago when diff < 24 hours', () {
      final s = SyncStatus(lastSyncedAt: DateTime.now().subtract(const Duration(hours: 3)));
      final result = s.formatRelativeTime(
        justNowText: 'Just now',
        minutesAgoTemplate: '{minutes}m ago',
        hoursAgoTemplate: '{hours}h ago',
        neverText: 'Never',
      );
      expect(result, '3h ago');
    });

    test('14. SyncStatus.formatRelativeTime returns date string when diff >= 24 hours', () {
      final pastDate = DateTime(2026, 9, 20, 14, 5);
      final s = SyncStatus(lastSyncedAt: pastDate);
      final result = s.formatRelativeTime(
        justNowText: 'Just now',
        minutesAgoTemplate: '{minutes}m ago',
        hoursAgoTemplate: '{hours}h ago',
        neverText: 'Never',
      );
      expect(result, contains('20/9'));
      expect(result, contains('14:05'));
    });
  });

  group('Group 2: SyncQueueItem Entity (AC 4)', () {
    test('15. SyncQueueItem creation and properties', () {
      final now = DateTime(2026, 9, 26, 8, 30);
      final item = SyncQueueItem(
        id: 'q1',
        entityType: 'bill',
        entityId: 'b123',
        action: 'create',
        payload: {'title': 'Dinner', 'amount': 150.0},
        createdAt: now,
        retryCount: 1,
      );

      expect(item.id, 'q1');
      expect(item.entityType, 'bill');
      expect(item.entityId, 'b123');
      expect(item.action, 'create');
      expect(item.payload['title'], 'Dinner');
      expect(item.createdAt, now);
      expect(item.retryCount, 1);
    });

    test('16. SyncQueueItem copyWith', () {
      final item1 = SyncQueueItem(
        id: 'q1',
        entityType: 'project',
        entityId: 'p1',
        action: 'update',
        payload: {'name': 'Trip'},
        createdAt: DateTime.now(),
      );

      final item2 = item1.copyWith(retryCount: 3, action: 'delete');
      expect(item2.id, 'q1');
      expect(item2.entityType, 'project');
      expect(item2.retryCount, 3);
      expect(item2.action, 'delete');
    });

    test('17. SyncQueueItem toMap and fromMap serialization', () {
      final now = DateTime(2026, 9, 26, 11, 45);
      final item = SyncQueueItem(
        id: 'q10',
        entityType: 'settlement',
        entityId: 's99',
        action: 'mark_as_paid',
        payload: {'isPaid': true},
        createdAt: now,
        retryCount: 2,
      );

      final map = item.toMap();
      final restored = SyncQueueItem.fromMap(map);

      expect(restored.id, item.id);
      expect(restored.entityType, item.entityType);
      expect(restored.entityId, item.entityId);
      expect(restored.action, item.action);
      expect(restored.payload['isPaid'], true);
      expect(restored.retryCount, 2);
      expect(restored, equals(item));
    });

    test('18. SyncQueueItem fromMap handles fallback values', () {
      final map = {
        'id': 'q99',
        'entityType': 'bill',
        'entityId': 'b99',
        'action': 'delete',
        'payload': <String, dynamic>{},
      };

      final restored = SyncQueueItem.fromMap(map);
      expect(restored.id, 'q99');
      expect(restored.retryCount, 0);
      expect(restored.createdAt, isNotNull);
    });

    test('19. SyncQueueItem equality & props', () {
      final now = DateTime(2026, 9, 26, 12, 0);
      final item1 = SyncQueueItem(
        id: 'q1',
        entityType: 'bill',
        entityId: 'b1',
        action: 'create',
        payload: const {'amount': 10},
        createdAt: now,
      );
      final item2 = SyncQueueItem(
        id: 'q1',
        entityType: 'bill',
        entityId: 'b1',
        action: 'create',
        payload: const {'amount': 10},
        createdAt: now,
      );
      final item3 = item1.copyWith(id: 'q2');

      expect(item1, equals(item2));
      expect(item1, isNot(equals(item3)));
    });
  });

  group('Group 3: NetworkConnectivityService (AC 4, AC 5)', () {
    test('20. FakeNetworkConnectivityService defaults to connected', () async {
      final service = FakeNetworkConnectivityService();
      expect(await service.isConnected, isTrue);
      service.dispose();
    });

    test('21. FakeNetworkConnectivityService can set connected to false', () async {
      final service = FakeNetworkConnectivityService(initialConnected: true);
      service.setConnected(false);
      expect(await service.isConnected, isFalse);
      service.dispose();
    });

    test('22. FakeNetworkConnectivityService emits onConnectivityChanged stream', () async {
      final service = FakeNetworkConnectivityService(initialConnected: true);
      final emitted = <bool>[];
      final sub = service.onConnectivityChanged.listen(emitted.add);

      service.setConnected(false);
      service.setConnected(true);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(emitted, [false, true]);
      await sub.cancel();
      service.dispose();
    });

    test('23. FakeNetworkConnectivityService does not emit duplicate identical states', () async {
      final service = FakeNetworkConnectivityService(initialConnected: true);
      final emitted = <bool>[];
      final sub = service.onConnectivityChanged.listen(emitted.add);

      service.setConnected(true); // same state
      service.setConnected(false);
      service.setConnected(false); // same state
      await Future.delayed(const Duration(milliseconds: 10));

      expect(emitted, [false]);
      await sub.cancel();
      service.dispose();
    });
  });

  group('Group 4: SyncService Queue, Sync, and Offline Handling (AC 1, AC 4, AC 5)', () {
    late FakeCloudSyncRepository cloudRepo;
    late FakeNetworkConnectivityService connectivity;
    late SyncService syncService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      cloudRepo = FakeCloudSyncRepository();
      connectivity = FakeNetworkConnectivityService(initialConnected: true);
      syncService = SyncService(
        cloudSyncRepository: cloudRepo,
        connectivityService: connectivity,
      );
    });

    tearDown(() {
      syncService.dispose();
      connectivity.dispose();
    });

    test('24. SyncService initial status is synced with 0 pending', () {
      expect(syncService.status.state, SyncState.synced);
      expect(syncService.pendingCount, 0);
      expect(syncService.pendingQueue, isEmpty);
    });

    test('25. Enqueuing item updates pendingQueue and state to pending', () {
      final item = SyncQueueItem(
        id: 'q1',
        entityType: 'bill',
        entityId: 'b1',
        action: 'create',
        payload: {'name': 'Lunch'},
        createdAt: DateTime.now(),
      );

      syncService.enqueue(item);

      expect(syncService.pendingCount, 1);
      expect(syncService.pendingQueue.first.entityId, 'b1');
      expect(syncService.status.state, SyncState.pending);
      expect(syncService.status.pendingCount, 1);
    });

    test('26. Enqueuing duplicate entity updates existing item without increasing count', () {
      final item1 = SyncQueueItem(
        id: 'q1',
        entityType: 'bill',
        entityId: 'b1',
        action: 'create',
        payload: {'name': 'Lunch', 'amount': 20.0},
        createdAt: DateTime.now(),
      );
      final item2 = SyncQueueItem(
        id: 'q2',
        entityType: 'bill',
        entityId: 'b1',
        action: 'update',
        payload: {'name': 'Lunch', 'amount': 25.0},
        createdAt: DateTime.now(),
      );

      syncService.enqueue(item1);
      expect(syncService.pendingCount, 1);

      syncService.enqueue(item2);
      expect(syncService.pendingCount, 1);
      expect(syncService.pendingQueue.first.action, 'update');
      expect(syncService.pendingQueue.first.payload['amount'], 25.0);
    });

    test('27. ClearQueue empties queue and sets state to synced', () {
      syncService.enqueue(SyncQueueItem(
        id: 'q1',
        entityType: 'bill',
        entityId: 'b1',
        action: 'create',
        payload: {},
        createdAt: DateTime.now(),
      ));
      expect(syncService.pendingCount, 1);

      syncService.clearQueue();
      expect(syncService.pendingCount, 0);
      expect(syncService.status.state, SyncState.synced);
      expect(syncService.status.pendingCount, 0);
    });

    test('28. syncNow when offline returns offline result and sets status.offline', () async {
      connectivity.setConnected(false);

      final result = await syncService.syncNow();

      expect(result.success, isFalse);
      expect(result.isOffline, isTrue);
      expect(result.message, contains('ngoại tuyến'));
      expect(syncService.status.state, SyncState.offline);
      expect(syncService.status.isOffline, isTrue);
    });

    test('29. syncNow when online drains queue, sets status.synced, updates lastSyncedAt', () async {
      syncService.enqueue(SyncQueueItem(
        id: 'q1',
        entityType: 'bill',
        entityId: 'b1',
        action: 'create',
        payload: {},
        createdAt: DateTime.now(),
      ));

      final result = await syncService.syncNow();

      expect(result.success, isTrue);
      expect(result.isOffline, isFalse);
      expect(result.syncedItemsCount, 1);
      expect(result.lastSyncedAt, isNotNull);
      expect(syncService.pendingCount, 0);
      expect(syncService.status.state, SyncState.synced);
      expect(syncService.status.lastSyncedAt, isNotNull);
    });

    test('30. Network reconnection triggers auto-sync if queue is not empty', () async {
      connectivity.setConnected(false);

      syncService.enqueue(SyncQueueItem(
        id: 'q1',
        entityType: 'project',
        entityId: 'p1',
        action: 'create',
        payload: {},
        createdAt: DateTime.now(),
      ));
      expect(syncService.pendingCount, 1);

      // Reconnect network
      connectivity.setConnected(true);

      // Debounced sync will trigger
      await Future.delayed(const Duration(milliseconds: 1600));

      expect(syncService.pendingCount, 0);
      expect(syncService.status.state, SyncState.synced);
    });

    test('31. Network disconnection updates status to offline', () async {
      connectivity.setConnected(false);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(syncService.status.state, SyncState.offline);
    });

    test('32. Network reconnection when queue is empty restores synced state', () async {
      connectivity.setConnected(false);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(syncService.status.state, SyncState.offline);

      connectivity.setConnected(true);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(syncService.status.state, SyncState.synced);
    });

    test('33. SyncService loads persisted lastSyncedAt from SharedPreferences', () async {
      final savedTime = DateTime(2026, 9, 25, 20, 0);
      SharedPreferences.setMockInitialValues({
        SyncService.prefLastSyncedKey: savedTime.toIso8601String(),
      });
      final prefs = await SharedPreferences.getInstance();

      final s = SyncService(
        cloudSyncRepository: cloudRepo,
        connectivityService: connectivity,
        sharedPreferences: prefs,
      );

      expect(s.status.lastSyncedAt, equals(savedTime));
      s.dispose();
    });

    test('34. StatusStream emits updates as status changes', () async {
      final statuses = <SyncStatus>[];
      final sub = syncService.statusStream.listen(statuses.add);

      syncService.enqueue(SyncQueueItem(
        id: 'q1',
        entityType: 'bill',
        entityId: 'b1',
        action: 'create',
        payload: {},
        createdAt: DateTime.now(),
      ));

      await Future.delayed(const Duration(milliseconds: 10));
      expect(statuses.isNotEmpty, isTrue);
      expect(statuses.last.state, SyncState.pending);

      await sub.cancel();
    });
  });

  group('Group 5: SyncBloc & SyncBlocState (AC 1, AC 3)', () {
    late FakeCloudSyncRepository cloudRepo;
    late FakeNetworkConnectivityService connectivity;
    late SyncService syncService;
    late SyncBloc syncBloc;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      cloudRepo = FakeCloudSyncRepository();
      connectivity = FakeNetworkConnectivityService(initialConnected: true);
      syncService = SyncService(
        cloudSyncRepository: cloudRepo,
        connectivityService: connectivity,
      );
      syncBloc = SyncBloc(syncService: syncService);
    });

    tearDown(() {
      syncBloc.close();
      syncService.dispose();
      connectivity.dispose();
    });

    test('35. SyncBloc initial state matches syncService status', () {
      expect(syncBloc.state.status.state, SyncState.synced);
      expect(syncBloc.state.isSyncing, isFalse);
      expect(syncBloc.state.isOffline, isFalse);
      expect(syncBloc.state.hasPending, isFalse);
      expect(syncBloc.state.pendingCount, 0);
      expect(syncBloc.state.lastSyncedAt, isNull);
    });

    test('36. SyncBlocState helper getters', () {
      const s1 = SyncBlocState(
        status: SyncStatus(state: SyncState.syncing, pendingCount: 2),
      );
      expect(s1.isSyncing, isTrue);
      expect(s1.isSynced, isFalse);
      expect(s1.hasPending, isTrue);
      expect(s1.pendingCount, 2);

      const s2 = SyncBlocState(isTriggering: true);
      expect(s2.isSyncing, isTrue);
      expect(s2.isSynced, isFalse);

      const s3 = SyncBlocState(
        status: SyncStatus(state: SyncState.offline),
      );
      expect(s3.isOffline, isTrue);

      const s4 = SyncBlocState(
        status: SyncStatus(state: SyncState.error),
      );
      expect(s4.hasError, isTrue);
    });

    test('37. SyncBlocState copyWith updates fields correctly', () {
      const s = SyncBlocState();
      final updated = s.copyWith(
        status: const SyncStatus(state: SyncState.offline),
        lastSyncMessage: 'Offline',
        isTriggering: true,
      );

      expect(updated.status.state, SyncState.offline);
      expect(updated.lastSyncMessage, 'Offline');
      expect(updated.isTriggering, isTrue);
    });

    test('38. SyncBloc handles TriggerSyncEvent successfully when online', () async {
      syncService.enqueue(SyncQueueItem(
        id: 'q1',
        entityType: 'bill',
        entityId: 'b1',
        action: 'create',
        payload: {},
        createdAt: DateTime.now(),
      ));

      syncBloc.add(const TriggerSyncEvent());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(syncBloc.state.isSyncing, isFalse);
      expect(syncBloc.state.status.state, SyncState.synced);
      expect(syncBloc.state.pendingCount, 0);
      expect(syncBloc.state.lastSyncedAt, isNotNull);
    });

    test('39. SyncBloc handles TriggerSyncEvent with specific projectId', () async {
      syncBloc.add(const TriggerSyncEvent(projectId: 'proj_123'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(syncBloc.state.isSyncing, isFalse);
      expect(syncBloc.state.status.state, SyncState.synced);
    });

    test('40. SyncBloc handles TriggerSyncEvent when offline', () async {
      connectivity.setConnected(false);
      await Future.delayed(const Duration(milliseconds: 10));

      syncBloc.add(const TriggerSyncEvent());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(syncBloc.state.isOffline, isTrue);
      expect(syncBloc.state.lastSyncMessage, contains('ngoại tuyến'));
    });

    test('41. SyncBloc handles EnqueueSyncItemEvent', () async {
      final item = SyncQueueItem(
        id: 'q10',
        entityType: 'bill',
        entityId: 'b10',
        action: 'create',
        payload: {},
        createdAt: DateTime.now(),
      );

      syncBloc.add(EnqueueSyncItemEvent(item));
      await Future.delayed(const Duration(milliseconds: 20));

      expect(syncBloc.state.hasPending, isTrue);
      expect(syncBloc.state.pendingCount, 1);
    });

    test('42. SyncBloc handles ClearSyncQueueEvent', () async {
      syncBloc.add(EnqueueSyncItemEvent(SyncQueueItem(
        id: 'q1',
        entityType: 'bill',
        entityId: 'b1',
        action: 'create',
        payload: {},
        createdAt: DateTime.now(),
      )));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(syncBloc.state.pendingCount, 1);

      syncBloc.add(const ClearSyncQueueEvent());
      await Future.delayed(const Duration(milliseconds: 20));
      expect(syncBloc.state.pendingCount, 0);
      expect(syncBloc.state.status.state, SyncState.synced);
    });

    test('43. SyncBloc events equality and props', () {
      const e1 = TriggerSyncEvent(projectId: 'p1');
      const e2 = TriggerSyncEvent(projectId: 'p1');
      const e3 = TriggerSyncEvent(projectId: 'p2');
      expect(e1, equals(e2));
      expect(e1, isNot(equals(e3)));

      const clear1 = ClearSyncQueueEvent();
      const clear2 = ClearSyncQueueEvent();
      expect(clear1, equals(clear2));

      const statusEvent = SyncStatusUpdatedEvent(SyncStatus());
      expect(statusEvent.props, [const SyncStatus()]);
    });
  });

  group('Group 6: ManualSyncButton Widget (AC 2, AC 5)', () {
    late FakeCloudSyncRepository cloudRepo;
    late FakeNetworkConnectivityService connectivity;
    late SyncService syncService;
    late SyncBloc syncBloc;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      cloudRepo = FakeCloudSyncRepository();
      connectivity = FakeNetworkConnectivityService(initialConnected: true);
      syncService = SyncService(
        cloudSyncRepository: cloudRepo,
        connectivityService: connectivity,
      );
      syncBloc = SyncBloc(syncService: syncService);
    });

    tearDown(() {
      syncBloc.close();
      syncService.dispose();
      connectivity.dispose();
    });

    testWidgets('44. Renders with default key and sync icon', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: ManualSyncButton(bloc: syncBloc),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('manualSyncButton')), findsOneWidget);
      expect(find.byKey(const Key('manualSyncButtonAction')), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
    });

    testWidgets('45. Renders RotationTransition for animation', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: ManualSyncButton(bloc: syncBloc),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(ManualSyncButton),
          matching: find.byType(RotationTransition),
        ),
        findsOneWidget,
      );
    });

    testWidgets('46. Shows tooltip on manual sync button', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: ManualSyncButton(bloc: syncBloc),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(ManualSyncButton),
          matching: find.byType(Tooltip),
        ),
        findsOneWidget,
      );
    });

    testWidgets('47. Tapping button triggers TriggerSyncEvent and callback', (tester) async {
      bool triggered = false;
      await tester.pumpWidget(
        createTestApp(
          child: ManualSyncButton(
            bloc: syncBloc,
            onSyncTriggered: () => triggered = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('manualSyncButtonAction')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(triggered, isTrue);
    });

    testWidgets('48. Shows offline snackbar when tapping while offline', (tester) async {
      syncBloc.add(const SyncStatusUpdatedEvent(
        SyncStatus(state: SyncState.offline),
      ));

      await tester.pumpWidget(
        createTestApp(
          child: ManualSyncButton(bloc: syncBloc),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('manualSyncButtonAction')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('offline'), findsWidgets);

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('49. Displays pending orange dot indicator when hasPending is true', (tester) async {
      syncBloc.add(const SyncStatusUpdatedEvent(
        SyncStatus(state: SyncState.pending, pendingCount: 1),
      ));

      await tester.pumpWidget(
        createTestApp(
          child: ManualSyncButton(bloc: syncBloc),
        ),
      );
      await tester.pumpAndSettle();

      expect(syncBloc.state.hasPending, isTrue);
      // Verify Stack contains container for orange dot
      expect(
        find.descendant(
          of: find.byType(ManualSyncButton),
          matching: find.byType(Stack),
        ),
        findsOneWidget,
      );
    });

    testWidgets('50. ManualSyncButton works in Vietnamese locale', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          locale: const Locale('vi'),
          child: ManualSyncButton(bloc: syncBloc),
        ),
      );
      await tester.pumpAndSettle();

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, contains('Đồng bộ ngay'));
    });

    testWidgets('51. ManualSyncButton fallback renders when no SyncBloc provided', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ManualSyncButton(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('manualSyncButtonAction')), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
    });

    testWidgets('52. ManualSyncButton passes projectId to TriggerSyncEvent', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: ManualSyncButton(bloc: syncBloc, projectId: 'proj_abc'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('manualSyncButtonAction')));
      await tester.pump();

      expect(syncBloc.state.status.state, SyncState.synced);
    });
  });

  group('Group 7: SyncStatusBadge Widget (AC 3, AC 5)', () {
    late FakeCloudSyncRepository cloudRepo;
    late FakeNetworkConnectivityService connectivity;
    late SyncService syncService;
    late SyncBloc syncBloc;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      cloudRepo = FakeCloudSyncRepository();
      connectivity = FakeNetworkConnectivityService(initialConnected: true);
      syncService = SyncService(
        cloudSyncRepository: cloudRepo,
        connectivityService: connectivity,
      );
      syncBloc = SyncBloc(syncService: syncService);
    });

    tearDown(() {
      syncBloc.close();
      syncService.dispose();
      connectivity.dispose();
    });

    testWidgets('53. Renders synced state with check circle icon', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: SyncStatusBadge(bloc: syncBloc),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('syncStatusBadge')), findsOneWidget);
      expect(find.byKey(const Key('syncStatusIndicator')), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.text('Synced'), findsOneWidget);
    });

    testWidgets('54. Renders compact mode with pill container', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: SyncStatusBadge(bloc: syncBloc, isCompact: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('syncStatusIndicator')), findsOneWidget);
      expect(find.text('Synced'), findsOneWidget);
    });

    testWidgets('55. Renders offline state with cloud_off icon', (tester) async {
      syncBloc.add(const SyncStatusUpdatedEvent(
        SyncStatus(state: SyncState.offline),
      ));
      await tester.pumpWidget(
        createTestApp(
          child: SyncStatusBadge(bloc: syncBloc),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('56. Renders pending state with count', (tester) async {
      syncBloc.add(const SyncStatusUpdatedEvent(
        SyncStatus(state: SyncState.pending, pendingCount: 1),
      ));

      await tester.pumpWidget(
        createTestApp(
          child: SyncStatusBadge(bloc: syncBloc),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
      expect(find.text('Pending (1)'), findsOneWidget);
    });

    testWidgets('57. Renders in Vietnamese locale correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          locale: const Locale('vi'),
          child: SyncStatusBadge(bloc: syncBloc),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đã đồng bộ'), findsOneWidget);
      expect(find.textContaining('Giờ đồng bộ cuối'), findsOneWidget);
    });

    testWidgets('58. Tapping badge opens modal bottom sheet with sync details', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: SyncStatusBadge(bloc: syncBloc),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('syncStatusIndicator')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('syncDetailsSyncNowButton')), findsOneWidget);
      expect(find.text('Sync now'), findsWidgets);
    });

    testWidgets('59. Tapping sync button inside bottom sheet triggers sync and closes modal', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: SyncStatusBadge(bloc: syncBloc),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('syncStatusIndicator')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('syncDetailsSyncNowButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('syncDetailsSyncNowButton')));
      await tester.pumpAndSettle();

      // Modal closed
      expect(find.byKey(const Key('syncDetailsSyncNowButton')), findsNothing);
    });

    testWidgets('60. Custom onTap callback overrides bottom sheet', (tester) async {
      bool customTapped = false;
      await tester.pumpWidget(
        createTestApp(
          child: SyncStatusBadge(
            bloc: syncBloc,
            onTap: () => customTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('syncStatusIndicator')));
      await tester.pump();

      expect(customTapped, isTrue);
      expect(find.byKey(const Key('syncDetailsSyncNowButton')), findsNothing);
    });

    testWidgets('61. SyncStatusBadge fallback renders gracefully without SyncBloc', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const SyncStatusBadge(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('syncStatusIndicator')), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('62. Non-compact badge displays last sync relative time subtitle', (tester) async {
      final now = DateTime.now().subtract(const Duration(minutes: 5));
      final s = SyncService(
        cloudSyncRepository: cloudRepo,
        connectivityService: connectivity,
      );
      final bloc = SyncBloc(syncService: s);
      bloc.add(SyncStatusUpdatedEvent(SyncStatus(
        state: SyncState.synced,
        lastSyncedAt: now,
      )));

      await tester.pumpWidget(
        createTestApp(
          child: SyncStatusBadge(bloc: bloc),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('5m ago'), findsOneWidget);
      bloc.close();
      s.dispose();
    });
  });

  group('Group 8: Localization Verification (AC 3, AC 5)', () {
    testWidgets('63. English localization contains all sync keys', (tester) async {
      late AppLocalizations loc;
      await tester.pumpWidget(
        createTestApp(
          locale: const Locale('en'),
          child: Builder(
            builder: (context) {
              loc = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(loc.translate('sync_now'), 'Sync now');
      expect(loc.translate('sync_status_synced'), 'Synced');
      expect(loc.translate('sync_status_syncing'), 'Syncing...');
      expect(loc.translate('sync_status_pending'), contains('{count}'));
      expect(loc.translate('sync_status_offline'), 'Offline');
      expect(loc.translate('sync_offline_message'), contains('offline'));
      expect(loc.translate('sync_just_now'), 'Just now');
      expect(loc.translate('sync_minutes_ago'), contains('{minutes}'));
      expect(loc.translate('sync_hours_ago'), contains('{hours}'));
      expect(loc.translate('sync_never'), 'Never');
    });

    testWidgets('64. Vietnamese localization contains all sync keys', (tester) async {
      late AppLocalizations loc;
      await tester.pumpWidget(
        createTestApp(
          locale: const Locale('vi'),
          child: Builder(
            builder: (context) {
              loc = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(loc.translate('sync_now'), 'Đồng bộ ngay');
      expect(loc.translate('sync_status_synced'), 'Đã đồng bộ');
      expect(loc.translate('sync_status_syncing'), 'Đang đồng bộ...');
      expect(loc.translate('sync_status_pending'), contains('{count}'));
      expect(loc.translate('sync_status_offline'), 'Ngoại tuyến');
      expect(loc.translate('sync_offline_message'), contains('ngoại tuyến'));
      expect(loc.translate('sync_just_now'), 'Vừa xong');
      expect(loc.translate('sync_minutes_ago'), contains('phút trước'));
      expect(loc.translate('sync_hours_ago'), contains('giờ trước'));
      expect(loc.translate('sync_never'), 'Chưa đồng bộ');
    });
  });

  group('Group 9: Comprehensive Boundary & Edge Cases (AC 1-6)', () {
    late FakeCloudSyncRepository cloudRepo;
    late FakeNetworkConnectivityService connectivity;
    late SyncService syncService;
    late SyncBloc syncBloc;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      cloudRepo = FakeCloudSyncRepository();
      connectivity = FakeNetworkConnectivityService(initialConnected: true);
      syncService = SyncService(
        cloudSyncRepository: cloudRepo,
        connectivityService: connectivity,
      );
      syncBloc = SyncBloc(syncService: syncService);
    });

    tearDown(() {
      syncBloc.close();
      syncService.dispose();
      connectivity.dispose();
    });

    test('65. SyncResult data holder getters', () {
      final now = DateTime(2026, 9, 26);
      const r1 = SyncResult(success: true, syncedItemsCount: 5);
      expect(r1.success, isTrue);
      expect(r1.isOffline, isFalse);
      expect(r1.syncedItemsCount, 5);

      final r2 = SyncResult(
        success: false,
        isOffline: true,
        message: 'No internet',
        lastSyncedAt: now,
      );
      expect(r2.success, isFalse);
      expect(r2.isOffline, isTrue);
      expect(r2.message, 'No internet');
      expect(r2.lastSyncedAt, now);
    });

    test('66. Multiple queue items with different types are preserved', () {
      syncService.enqueue(SyncQueueItem(
        id: 'q1',
        entityType: 'project',
        entityId: 'p1',
        action: 'create',
        payload: {},
        createdAt: DateTime.now(),
      ));
      syncService.enqueue(SyncQueueItem(
        id: 'q2',
        entityType: 'bill',
        entityId: 'b1',
        action: 'create',
        payload: {},
        createdAt: DateTime.now(),
      ));
      syncService.enqueue(SyncQueueItem(
        id: 'q3',
        entityType: 'settlement',
        entityId: 's1',
        action: 'create',
        payload: {},
        createdAt: DateTime.now(),
      ));

      expect(syncService.pendingCount, 3);
      expect(syncService.pendingQueue.length, 3);
    });

    test('67. Rapid successive syncNow calls do not corrupt queue', () async {
      syncService.enqueue(SyncQueueItem(
        id: 'q1',
        entityType: 'bill',
        entityId: 'b1',
        action: 'create',
        payload: {},
        createdAt: DateTime.now(),
      ));

      final f1 = syncService.syncNow();
      final f2 = syncService.syncNow();

      final results = await Future.wait([f1, f2]);
      expect(results[0].success, isTrue);
      expect(results[1].success, isTrue);
      expect(syncService.pendingCount, 0);
    });

    test('68. SyncBloc handles status update when syncService is disposed cleanly', () async {
      final s = SyncService(
        cloudSyncRepository: cloudRepo,
        connectivityService: connectivity,
      );
      final b = SyncBloc(syncService: s);
      await b.close();
      s.dispose();
      expect(b.isClosed, isTrue);
    });

    testWidgets('69. ManualSyncButton does not rotate when offline', (tester) async {
      syncBloc.add(const SyncStatusUpdatedEvent(
        SyncStatus(state: SyncState.offline),
      ));
      await tester.pumpWidget(
        createTestApp(
          child: ManualSyncButton(bloc: syncBloc),
        ),
      );
      await tester.pumpAndSettle();

      final rotation = tester.widget<RotationTransition>(
        find.descendant(
          of: find.byType(ManualSyncButton),
          matching: find.byType(RotationTransition),
        ),
      );
      expect(rotation.turns.value, 0.0);
    });

    testWidgets('70. ManualSyncButton rotates when state is syncing', (tester) async {
      syncBloc.add(const SyncStatusUpdatedEvent(
        SyncStatus(state: SyncState.syncing),
      ));

      await tester.pumpWidget(
        createTestApp(
          child: ManualSyncButton(bloc: syncBloc),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final rotation = tester.widget<RotationTransition>(
        find.descendant(
          of: find.byType(ManualSyncButton),
          matching: find.byType(RotationTransition),
        ),
      );
      expect(rotation.turns.status, equals(AnimationStatus.forward));
    });

    testWidgets('71. SyncStatusBadge compact mode displays circular progress when syncing', (tester) async {
      syncBloc.add(const SyncStatusUpdatedEvent(
        SyncStatus(state: SyncState.syncing),
      ));

      await tester.pumpWidget(
        createTestApp(
          child: SyncStatusBadge(bloc: syncBloc, isCompact: true),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('72. SyncStatusBadge non-compact mode displays circular progress when syncing', (tester) async {
      syncBloc.add(const SyncStatusUpdatedEvent(
        SyncStatus(state: SyncState.syncing),
      ));

      await tester.pumpWidget(
        createTestApp(
          child: SyncStatusBadge(bloc: syncBloc, isCompact: false),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('73. SyncStatusBadge error state renders red error icon', (tester) async {
      syncBloc.add(const SyncStatusUpdatedEvent(
        SyncStatus(state: SyncState.error, errorMessage: 'Failed'),
      ));

      await tester.pumpWidget(
        createTestApp(
          child: SyncStatusBadge(bloc: syncBloc),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Sync error'), findsOneWidget);
    });

    testWidgets('74. Tooltip reflects pending count dynamically', (tester) async {
      syncBloc.add(const SyncStatusUpdatedEvent(
        SyncStatus(state: SyncState.pending, pendingCount: 7),
      ));

      await tester.pumpWidget(
        createTestApp(
          child: ManualSyncButton(bloc: syncBloc),
        ),
      );
      await tester.pumpAndSettle();

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, contains('7'));
    });

    testWidgets('75. Tooltip reflects offline status dynamically', (tester) async {
      syncBloc.add(const SyncStatusUpdatedEvent(
        SyncStatus(state: SyncState.offline),
      ));
      await tester.pumpWidget(
        createTestApp(
          child: ManualSyncButton(bloc: syncBloc),
        ),
      );
      await tester.pumpAndSettle();

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, contains('Offline'));
    });

    testWidgets('76. Tooltip reflects syncing status dynamically', (tester) async {
      syncBloc.add(const SyncStatusUpdatedEvent(
        SyncStatus(state: SyncState.syncing),
      ));

      await tester.pumpWidget(
        createTestApp(
          child: ManualSyncButton(bloc: syncBloc),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Syncing...');
    });

    test('77. DefaultNetworkConnectivityService creates without error', () {
      final s = DefaultNetworkConnectivityService();
      expect(s, isNotNull);
      s.dispose();
    });

    test('78. SyncStatus copyWith with null values preserves previous', () {
      final original = SyncStatus(
        state: SyncState.pending,
        pendingCount: 4,
        errorMessage: 'Err',
        lastSyncedAt: DateTime(2026, 9, 26),
      );
      final copied = original.copyWith();
      expect(copied, equals(original));
    });

    test('79. SyncQueueItem copyWith with null values preserves previous', () {
      final original = SyncQueueItem(
        id: 'q1',
        entityType: 'bill',
        entityId: 'b1',
        action: 'create',
        payload: const {'amount': 100},
        createdAt: DateTime(2026, 9, 26),
        retryCount: 2,
      );
      final copied = original.copyWith();
      expect(copied, equals(original));
    });

    test('80. SyncResult handles optional fields correctly', () {
      const r = SyncResult(success: true);
      expect(r.success, isTrue);
      expect(r.isOffline, isFalse);
      expect(r.message, isNull);
      expect(r.lastSyncedAt, isNull);
      expect(r.syncedItemsCount, 0);
    });

    testWidgets('81. Tapping manual sync button when syncing is ignored (disabled button)', (tester) async {
      syncBloc.add(const SyncStatusUpdatedEvent(
        SyncStatus(state: SyncState.syncing),
      ));

      await tester.pumpWidget(
        createTestApp(
          child: ManualSyncButton(bloc: syncBloc),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final iconBtn = tester.widget<IconButton>(find.byKey(const Key('manualSyncButtonAction')));
      expect(iconBtn.onPressed, isNull);
    });

    testWidgets('82. Bottom sheet sync button is disabled when state is syncing', (tester) async {
      syncBloc.add(const SyncStatusUpdatedEvent(
        SyncStatus(state: SyncState.syncing),
      ));

      await tester.pumpWidget(
        createTestApp(
          child: SyncStatusBadge(bloc: syncBloc),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byKey(const Key('syncStatusIndicator')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final elevatedBtn = tester.widget<ElevatedButton>(find.byKey(const Key('syncDetailsSyncNowButton')));
      expect(elevatedBtn.onPressed, isNull);
    });

    testWidgets('83. Bottom sheet shows pending count notice if pendingCount > 0', (tester) async {
      syncBloc.add(const SyncStatusUpdatedEvent(
        SyncStatus(state: SyncState.pending, pendingCount: 3),
      ));

      await tester.pumpWidget(
        createTestApp(
          child: SyncStatusBadge(bloc: syncBloc),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('syncStatusIndicator')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pending (3)'), findsWidgets);
    });

    testWidgets('84. Bottom sheet shows offline subtitle if state is offline', (tester) async {
      syncBloc.add(const SyncStatusUpdatedEvent(
        SyncStatus(state: SyncState.offline),
      ));

      await tester.pumpWidget(
        createTestApp(
          child: SyncStatusBadge(bloc: syncBloc),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('syncStatusIndicator')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Offline'), findsWidgets);
    });

    testWidgets('85. SnackBar floating behavior and auto-dismiss', (tester) async {
      syncBloc.add(const SyncStatusUpdatedEvent(
        SyncStatus(state: SyncState.offline),
      ));

      await tester.pumpWidget(
        createTestApp(
          child: ManualSyncButton(bloc: syncBloc),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('manualSyncButtonAction')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.duration, const Duration(seconds: 2));

      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('Group 10: Screen Integration Tests (AC 2, AC 3)', () {
    testWidgets('86. ProjectDetailScreen renders ManualSyncButton in AppBar and SyncStatusBadge in header', (tester) async {
      if (!getIt.isRegistered<BillRepository>()) {
        getIt.registerSingleton<BillRepository>(_FakeBillRepoIntegration());
      }

      final testProject = Project(
        id: 'proj_sync_test',
        name: 'Sync Engine Project',
        description: 'Testing sync engine integration',
        members: const ['Alice', 'Bob'],
        createdAt: DateTime(2026, 9, 26),
        updatedAt: DateTime(2026, 9, 26),
      );

      await tester.pumpWidget(
        createTestApp(
          child: ProjectDetailScreen(project: testProject),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ManualSyncButton), findsOneWidget);
      expect(find.byType(SyncStatusBadge), findsOneWidget);
    });

    testWidgets('87. ProjectScreen renders ManualSyncButton in AppBar', (tester) async {
      final testProject = Project(
        id: 'proj_screen_test',
        name: 'Project Screen Test',
        members: const ['Alice', 'Bob'],
        createdAt: DateTime(2026, 9, 26),
        updatedAt: DateTime(2026, 9, 26),
      );

      final pRepo = _FakeProjectRepoIntegration([testProject]);
      final projectBloc = ProjectBloc(
        getAllProjectsUseCase: GetAllProjectsUseCase(pRepo),
        createProjectUseCase: CreateProjectUseCase(pRepo),
        getProjectByIdUseCase: GetProjectByIdUseCase(pRepo),
        updateProjectUseCase: UpdateProjectUseCase(pRepo),
        deleteProjectUseCase: DeleteProjectUseCase(pRepo),
      )..emit(ProjectLoaded(projects: [testProject]));

      await tester.pumpWidget(
        createTestApp(
          child: BlocProvider<ProjectBloc>.value(
            value: projectBloc,
            child: const ProjectScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ManualSyncButton), findsOneWidget);
    });

    testWidgets('88. HomeScreen renders ManualSyncButton in AppBar', (tester) async {
      final testProject = Project(
        id: 'home_screen_test',
        name: 'Home Project Test',
        members: const ['Alice', 'Bob'],
        createdAt: DateTime(2026, 9, 26),
        updatedAt: DateTime(2026, 9, 26),
      );

      final pRepo = _FakeProjectRepoIntegration([testProject]);
      final projectBloc = ProjectBloc(
        getAllProjectsUseCase: GetAllProjectsUseCase(pRepo),
        createProjectUseCase: CreateProjectUseCase(pRepo),
        getProjectByIdUseCase: GetProjectByIdUseCase(pRepo),
        updateProjectUseCase: UpdateProjectUseCase(pRepo),
        deleteProjectUseCase: DeleteProjectUseCase(pRepo),
      )..emit(ProjectLoaded(projects: [testProject]));

      final bRepo = _FakeBillRepoIntegration();
      final billsBloc = BillsBloc(
        getBillsUseCase: GetBillsUseCase(bRepo),
        addBillUseCase: AddBillUseCase(bRepo),
      );

      await tester.pumpWidget(
        createTestApp(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
              RepositoryProvider<BillRepository>.value(value: bRepo),
              BlocProvider<BillsBloc>.value(value: billsBloc),
              BlocProvider<ProjectBloc>.value(value: projectBloc),
            ],
            child: const HomeScreen(showAppBar: true, autoRestoreLastProject: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ManualSyncButton), findsOneWidget);
    });
  });
}

class _FakeBillRepoIntegration implements BillRepository {
  @override
  Future<Either<Failure, Bill>> create(Bill bill) async => Right(bill);
  @override
  Future<Either<Failure, void>> delete(String billId) async => const Right(null);
  @override
  Future<Either<Failure, List<Bill>>> getAll() async => const Right([]);
  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(String projectId) async => const Right([]);
  @override
  Future<Either<Failure, Bill>> getById(String billId) async => const Left(LocalFailure('not found'));
  @override
  Future<Either<Failure, Bill>> update(Bill bill) async => Right(bill);
}

class _FakeProjectRepoIntegration implements ProjectRepository {
  final List<Project> projects;
  _FakeProjectRepoIntegration(this.projects);

  @override
  Future<Either<Failure, List<Project>>> getAll() async => Right(projects);
  @override
  Future<Either<Failure, Project>> create(Project p) async => Right(p);
  @override
  Future<Either<Failure, Project>> getById(String id) async =>
      Right(projects.firstWhere((p) => p.id == id, orElse: () => projects.first));
  @override
  Future<Either<Failure, Project>> update(Project p) async => Right(p);
  @override
  Future<Either<Failure, void>> delete(String id) async => const Right(null);
}
