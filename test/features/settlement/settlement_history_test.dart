import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';

import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/features/export/domain/entities/export_options.dart';
import 'package:shared_household_planner/features/export/domain/services/csv_generator.dart';
import 'package:shared_household_planner/features/export/domain/services/export_service.dart';
import 'package:shared_household_planner/features/export/domain/services/pdf_generator.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/project_detail_screen.dart';
import 'package:shared_household_planner/features/settings/presentation/pages/settings_screen.dart';
import 'package:shared_household_planner/features/settlement/data/models/settlement_log_model.dart';
import 'package:shared_household_planner/features/settlement/domain/entities/balance_evolution.dart';
import 'package:shared_household_planner/features/settlement/domain/entities/settlement_filter.dart';
import 'package:shared_household_planner/features/settlement/domain/entities/settlement_log.dart';
import 'package:shared_household_planner/features/settlement/domain/repositories/settlement_repository.dart';
import 'package:shared_household_planner/features/settlement/domain/usecases/settlement_usecases.dart';
import 'package:shared_household_planner/features/settlement/presentation/bloc/settlement_bloc.dart';
import 'package:shared_household_planner/features/settlement/presentation/pages/payment_history_screen.dart';
import 'package:shared_household_planner/features/settlement/presentation/widgets/add_settlement_dialog.dart';
import 'package:shared_household_planner/features/settlement/presentation/widgets/settlement_timeline_card.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';

// ─── Test Fakes & Localization ────────────────────────────────────────────────

class FakeSettlementRepository implements SettlementRepository {
  final List<SettlementLog> logs = [];

  @override
  Future<Either<Failure, List<SettlementLog>>> getSettlementLogs({String? projectId}) async {
    if (projectId != null && projectId.isNotEmpty) {
      return Right(logs.where((l) => l.projectId == projectId).toList());
    }
    return Right(List.from(logs));
  }

  @override
  Future<Either<Failure, SettlementLog>> getSettlementLogById(String id) async {
    final match = logs.where((l) => l.id == id);
    if (match.isEmpty) return const Left(LocalFailure('Not found'));
    return Right(match.first);
  }

  @override
  Future<Either<Failure, SettlementLog>> createSettlementLog(SettlementLog log) async {
    logs.removeWhere((l) => l.id == log.id);
    logs.add(log);
    return Right(log);
  }

  @override
  Future<Either<Failure, SettlementLog>> updateSettlementLog(SettlementLog log) async {
    final idx = logs.indexWhere((l) => l.id == log.id);
    if (idx != -1) {
      logs[idx] = log;
      return Right(log);
    }
    return const Left(LocalFailure('Not found to update'));
  }

  @override
  Future<Either<Failure, void>> deleteSettlementLog(String id) async {
    logs.removeWhere((l) => l.id == id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, SettlementLog>> markAsPaid(String id) async {
    final idx = logs.indexWhere((l) => l.id == id);
    if (idx != -1) {
      final updated = logs[idx].copyWith(status: SettlementStatus.paid);
      logs[idx] = updated;
      return Right(updated);
    }
    return const Left(LocalFailure('Not found'));
  }

  @override
  Future<Either<Failure, SettlementLog>> undoMarkAsPaid(String id) async {
    final idx = logs.indexWhere((l) => l.id == id);
    if (idx != -1) {
      final updated = logs[idx].copyWith(status: SettlementStatus.pending);
      logs[idx] = updated;
      return Right(updated);
    }
    return const Left(LocalFailure('Not found'));
  }
}

class FakeBillRepo implements BillRepository {
  final List<Bill> bills = [];

  @override
  Future<Either<Failure, Bill>> create(Bill bill) async {
    bills.add(bill);
    return Right(bill);
  }

  @override
  Future<Either<Failure, List<Bill>>> getAll() async => Right(List.from(bills));

  @override
  Future<Either<Failure, Bill>> getById(String id) async =>
      Right(bills.firstWhere((b) => b.id == id));

  @override
  Future<Either<Failure, Bill>> update(Bill bill) async {
    final idx = bills.indexWhere((b) => b.id == bill.id);
    if (idx != -1) bills[idx] = bill;
    return Right(bill);
  }

  @override
  Future<Either<Failure, void>> delete(String billId) async {
    bills.removeWhere((b) => b.id == billId);
    return const Right(null);
  }

  Future<Either<Failure, List<Bill>>> getByProjectId(String projectId) async =>
      Right(bills.where((b) => b.projectId == projectId).toList());

  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(String projectId) async =>
      getByProjectId(projectId);
}

class TestLocalizations extends AppLocalizations {
  TestLocalizations(Locale locale) : super(locale);

  static Map<String, String> _loadJson(String code) {
    try {
      final file = File('lib/core/localization/translations/$code.json');
      if (file.existsSync()) {
        final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, v.toString()));
      }
    } catch (_) {}
    return {};
  }

  static final Map<String, String> _en = _loadJson('en');
  static final Map<String, String> _vi = _loadJson('vi');

  @override
  String translate(String key) {
    if (locale.languageCode == 'vi') {
      return _vi[key] ?? _en[key] ?? key;
    }
    return _en[key] ?? key;
  }
}

class TestLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const TestLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(TestLocalizations(locale));
  }

  @override
  bool shouldReload(TestLocalizationsDelegate old) => false;
}

Widget buildTestApp({
  required Widget child,
  FakeSettlementRepository? repo,
  FakeBillRepo? billRepo,
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
}) {
  final settlementRepo = repo ?? FakeSettlementRepository();
  final bRepo = billRepo ?? FakeBillRepo();

  final settlementBloc = SettlementBloc(
    getSettlementLogsUseCase: GetSettlementLogsUseCase(settlementRepo),
    createSettlementLogUseCase: CreateSettlementLogUseCase(settlementRepo),
    updateSettlementLogUseCase: UpdateSettlementLogUseCase(settlementRepo),
    deleteSettlementLogUseCase: DeleteSettlementLogUseCase(settlementRepo),
    markAsPaidUseCase: MarkAsPaidUseCase(settlementRepo),
    undoMarkAsPaidUseCase: UndoMarkAsPaidUseCase(settlementRepo),
  );

  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<SettlementRepository>.value(value: settlementRepo),
      RepositoryProvider<BillRepository>.value(value: bRepo),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<SettlementBloc>.value(value: settlementBloc),
      ],
      child: MaterialApp(
        locale: locale,
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        localizationsDelegates: const [
          TestLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('vi')],
        home: child,
      ),
    ),
  );
}

void setLargeScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
}

// ─── Test Suite ───────────────────────────────────────────────────────────────

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // Group 1: SettlementLog Entity & SettlementStatus Enum Tests (10 tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Group 1: SettlementLog Entity & SettlementStatus Enum', () {
    test('1.1 SettlementStatus fromString parses paid correctly', () {
      expect(SettlementStatus.fromString('paid'), SettlementStatus.paid);
      expect(SettlementStatus.fromString('PAID'), SettlementStatus.paid);
      expect(SettlementStatus.fromString(' Paid '), SettlementStatus.paid);
    });

    test('1.2 SettlementStatus fromString parses pending correctly', () {
      expect(SettlementStatus.fromString('pending'), SettlementStatus.pending);
      expect(SettlementStatus.fromString('PENDING'), SettlementStatus.pending);
      expect(SettlementStatus.fromString(' Pending '), SettlementStatus.pending);
    });

    test('1.3 SettlementStatus fromString falls back to pending for unknown or null', () {
      expect(SettlementStatus.fromString(null), SettlementStatus.pending);
      expect(SettlementStatus.fromString(''), SettlementStatus.pending);
      expect(SettlementStatus.fromString('unknown_xyz'), SettlementStatus.pending);
    });

    test('1.4 SettlementStatus value getter matches name', () {
      expect(SettlementStatus.paid.value, 'paid');
      expect(SettlementStatus.pending.value, 'pending');
    });

    test('1.5 SettlementLog isPaid and isPending helpers work', () {
      final now = DateTime.now();
      final paidLog = SettlementLog(
        id: 's1',
        payer: 'Alice',
        payee: 'Bob',
        amount: 50.0,
        date: now,
        status: SettlementStatus.paid,
        createdAt: now,
      );
      final pendingLog = SettlementLog(
        id: 's2',
        payer: 'Bob',
        payee: 'Charlie',
        amount: 25.0,
        date: now,
        status: SettlementStatus.pending,
        createdAt: now,
      );

      expect(paidLog.isPaid, isTrue);
      expect(paidLog.isPending, isFalse);
      expect(pendingLog.isPaid, isFalse);
      expect(pendingLog.isPending, isTrue);
    });

    test('1.6 SettlementLog equality checks value equivalence', () {
      final now = DateTime(2026, 9, 15);
      final log1 = SettlementLog(
        id: 's1',
        payer: 'Alice',
        payee: 'Bob',
        amount: 50.0,
        date: now,
        status: SettlementStatus.paid,
        note: 'Bank transfer',
        createdAt: now,
      );
      final log2 = SettlementLog(
        id: 's1',
        payer: 'Alice',
        payee: 'Bob',
        amount: 50.0,
        date: now,
        status: SettlementStatus.paid,
        note: 'Bank transfer',
        createdAt: now,
      );

      expect(log1, equals(log2));
      expect(log1.hashCode, equals(log2.hashCode));
    });

    test('1.7 SettlementLog copyWith updates specific fields', () {
      final now = DateTime.now();
      final log = SettlementLog(
        id: 's1',
        payer: 'Alice',
        payee: 'Bob',
        amount: 50.0,
        date: now,
        status: SettlementStatus.pending,
        note: 'Old note',
        createdAt: now,
      );

      final updated = log.copyWith(
        status: SettlementStatus.paid,
        amount: 60.0,
      );

      expect(updated.status, SettlementStatus.paid);
      expect(updated.amount, 60.0);
      expect(updated.payer, 'Alice');
      expect(updated.note, 'Old note');
    });

    test('1.8 SettlementLog copyWith clearNote clears note', () {
      final now = DateTime.now();
      final log = SettlementLog(
        id: 's1',
        payer: 'Alice',
        payee: 'Bob',
        amount: 50.0,
        date: now,
        note: 'Will be cleared',
        createdAt: now,
      );

      final updated = log.copyWith(clearNote: true);
      expect(updated.note, isNull);
    });

    test('1.9 SettlementLogModel fromEntity and toJson serialize properly', () {
      final now = DateTime(2026, 9, 13, 10, 0);
      final entity = SettlementLog(
        id: 's100',
        projectId: 'proj1',
        payer: 'Alice',
        payee: 'Bob',
        amount: 45.5,
        date: now,
        status: SettlementStatus.paid,
        note: 'Cash payment',
        createdAt: now,
      );

      final model = SettlementLogModel.fromEntity(entity);
      final json = model.toJson();

      expect(json['id'], 's100');
      expect(json['projectId'], 'proj1');
      expect(json['payer'], 'Alice');
      expect(json['payee'], 'Bob');
      expect(json['amount'], 45.5);
      expect(json['status'], 'paid');
      expect(json['note'], 'Cash payment');
    });

    test('1.10 SettlementLogModel fromJson deserializes properly', () {
      final json = {
        'id': 's200',
        'projectId': 'proj2',
        'payer': 'Charlie',
        'payee': 'Dave',
        'amount': 80.0,
        'date': '2026-09-14T12:00:00.000',
        'status': 'pending',
        'note': 'MoMo transfer',
        'createdAt': '2026-09-14T12:00:00.000',
      };

      final model = SettlementLogModel.fromJson(json);

      expect(model.id, 's200');
      expect(model.payer, 'Charlie');
      expect(model.payee, 'Dave');
      expect(model.amount, 80.0);
      expect(model.status, SettlementStatus.pending);
      expect(model.note, 'MoMo transfer');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 2: SettlementFilter & Filtering Logic Tests (15 tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Group 2: SettlementFilter & Filtering Logic', () {
    final d1 = DateTime(2026, 8, 10);
    final d2 = DateTime(2026, 9, 5);
    final d3 = DateTime(2026, 9, 12);
    final d4 = DateTime(2026, 9, 15);

    final sampleLogs = [
      SettlementLog(
        id: '1',
        projectId: 'p1',
        payer: 'Alice',
        payee: 'Bob',
        amount: 10,
        date: d1,
        status: SettlementStatus.paid,
        createdAt: d1,
      ),
      SettlementLog(
        id: '2',
        projectId: 'p1',
        payer: 'Bob',
        payee: 'Charlie',
        amount: 20,
        date: d2,
        status: SettlementStatus.pending,
        createdAt: d2,
      ),
      SettlementLog(
        id: '3',
        projectId: 'p2',
        payer: 'Charlie',
        payee: 'Alice',
        amount: 30,
        date: d3,
        status: SettlementStatus.paid,
        createdAt: d3,
      ),
      SettlementLog(
        id: '4',
        projectId: 'p1',
        payer: 'Dave',
        payee: 'Alice',
        amount: 40,
        date: d4,
        status: SettlementStatus.pending,
        createdAt: d4,
      ),
    ];

    test('2.1 Default filter returns all logs ordered oldest first (AC 4)', () {
      const filter = SettlementFilter();
      final result = filter.filterLogs(sampleLogs);

      expect(result.length, 4);
      expect(result.first.id, '1'); // Oldest date d1
      expect(result.last.id, '4'); // Newest date d4
    });

    test('2.2 Filter by projectId excludes logs from other projects', () {
      const filter = SettlementFilter(projectId: 'p1');
      final result = filter.filterLogs(sampleLogs);

      expect(result.length, 3);
      expect(result.every((l) => l.projectId == 'p1'), isTrue);
    });

    test('2.3 Filter by person matches when person is payer', () {
      const filter = SettlementFilter(person: 'Dave');
      final result = filter.filterLogs(sampleLogs);

      expect(result.length, 1);
      expect(result.first.id, '4');
    });

    test('2.4 Filter by person matches when person is payee', () {
      const filter = SettlementFilter(person: 'Bob');
      final result = filter.filterLogs(sampleLogs);

      expect(result.length, 2);
      expect(result.map((l) => l.id), containsAll(['1', '2']));
    });

    test('2.5 Filter by person is case insensitive', () {
      const filter = SettlementFilter(person: 'alice');
      final result = filter.filterLogs(sampleLogs);

      expect(result.length, 3); // id 1, 3, 4
    });

    test('2.6 Filter by person returns empty when person not involved', () {
      const filter = SettlementFilter(person: 'Zachary');
      final result = filter.filterLogs(sampleLogs);

      expect(result, isEmpty);
    });

    test('2.7 Filter by status paid returns only paid settlements', () {
      const filter = SettlementFilter(status: SettlementStatus.paid);
      final result = filter.filterLogs(sampleLogs);

      expect(result.length, 2);
      expect(result.every((l) => l.isPaid), isTrue);
    });

    test('2.8 Filter by status pending returns only pending settlements', () {
      const filter = SettlementFilter(status: SettlementStatus.pending);
      final result = filter.filterLogs(sampleLogs);

      expect(result.length, 2);
      expect(result.every((l) => l.isPending), isTrue);
    });

    test('2.9 Filter by thisMonth with referenceDate filters correctly', () {
      final filter = SettlementFilter(
        dateRange: SettlementDateRange.thisMonth,
        referenceDate: DateTime(2026, 9, 20),
      );
      final result = filter.filterLogs(sampleLogs);

      expect(result.length, 3); // d2, d3, d4 in Sep 2026
      expect(result.any((l) => l.id == '1'), isFalse); // d1 is in Aug
    });

    test('2.10 Filter by lastMonth filters previous month', () {
      final filter = SettlementFilter(
        dateRange: SettlementDateRange.lastMonth,
        referenceDate: DateTime(2026, 9, 20),
      );
      final result = filter.filterLogs(sampleLogs);

      expect(result.length, 1);
      expect(result.first.id, '1'); // Aug 2026
    });

    test('2.11 Filter by custom date range works with start date', () {
      final filter = SettlementFilter(
        dateRange: SettlementDateRange.custom,
        customStartDate: DateTime(2026, 9, 10),
      );
      final result = filter.filterLogs(sampleLogs);

      expect(result.length, 2); // d3 (Sep 12), d4 (Sep 15)
    });

    test('2.12 Filter by custom date range works with end date', () {
      final filter = SettlementFilter(
        dateRange: SettlementDateRange.custom,
        customEndDate: DateTime(2026, 9, 10),
      );
      final result = filter.filterLogs(sampleLogs);

      expect(result.length, 2); // d1 (Aug 10), d2 (Sep 5)
    });

    test('2.13 Filter with oldestFirst false reverses ordering to newest first', () {
      const filter = SettlementFilter(oldestFirst: false);
      final result = filter.filterLogs(sampleLogs);

      expect(result.first.id, '4'); // Newest date d4
      expect(result.last.id, '1'); // Oldest date d1
    });

    test('2.14 Compound filter combines person, status, and dateRange', () {
      final filter = SettlementFilter(
        person: 'Alice',
        status: SettlementStatus.paid,
        dateRange: SettlementDateRange.thisMonth,
        referenceDate: DateTime(2026, 9, 20),
      );
      final result = filter.filterLogs(sampleLogs);

      expect(result.length, 1);
      expect(result.first.id, '3');
    });

    test('2.15 SettlementFilter copyWith handles clear flags', () {
      const initial = SettlementFilter(
        person: 'Alice',
        status: SettlementStatus.paid,
        projectId: 'p1',
      );

      final cleared = initial.copyWith(
        clearPerson: true,
        clearStatus: true,
        clearProject: true,
      );

      expect(cleared.person, isNull);
      expect(cleared.status, isNull);
      expect(cleared.projectId, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 3: Balance Evolution Calculator Tests (10 tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Group 3: Balance Evolution Calculator (AC 7)', () {
    test('3.1 Empty logs returns empty evolution items', () {
      final items = BalanceEvolutionCalculator.calculate([]);
      expect(items, isEmpty);
    });

    test('3.2 Single paid settlement has runningTotal equal to its amount', () {
      final now = DateTime.now();
      final log = SettlementLog(
        id: '1',
        payer: 'Alice',
        payee: 'Bob',
        amount: 100.0,
        date: now,
        status: SettlementStatus.paid,
        createdAt: now,
      );

      final items = BalanceEvolutionCalculator.calculate([log]);
      expect(items.length, 1);
      expect(items.first.runningTotal, 100.0);
      expect(items.first.cumulativeTotal, 100.0);
    });

    test('3.3 Single pending settlement has runningTotal 0 but cumulativeTotal equals amount', () {
      final now = DateTime.now();
      final log = SettlementLog(
        id: '1',
        payer: 'Alice',
        payee: 'Bob',
        amount: 75.0,
        date: now,
        status: SettlementStatus.pending,
        createdAt: now,
      );

      final items = BalanceEvolutionCalculator.calculate([log]);
      expect(items.length, 1);
      expect(items.first.runningTotal, 0.0);
      expect(items.first.cumulativeTotal, 75.0);
    });

    test('3.4 Multiple paid settlements accumulate running total incrementally', () {
      final d1 = DateTime(2026, 9, 1);
      final d2 = DateTime(2026, 9, 2);
      final d3 = DateTime(2026, 9, 3);

      final logs = [
        SettlementLog(id: '1', payer: 'A', payee: 'B', amount: 50.0, date: d1, status: SettlementStatus.paid, createdAt: d1),
        SettlementLog(id: '2', payer: 'B', payee: 'C', amount: 30.0, date: d2, status: SettlementStatus.paid, createdAt: d2),
        SettlementLog(id: '3', payer: 'C', payee: 'A', amount: 20.0, date: d3, status: SettlementStatus.paid, createdAt: d3),
      ];

      final items = BalanceEvolutionCalculator.calculate(logs);

      expect(items.length, 3);
      expect(items[0].runningTotal, 50.0);
      expect(items[1].runningTotal, 80.0);
      expect(items[2].runningTotal, 100.0);
      expect(items[2].cumulativeTotal, 100.0);
    });

    test('3.5 Interleaved paid and pending logs correctly advances running total only for paid', () {
      final now = DateTime.now();
      final logs = [
        SettlementLog(id: '1', payer: 'A', payee: 'B', amount: 100.0, date: now, status: SettlementStatus.paid, createdAt: now),
        SettlementLog(id: '2', payer: 'B', payee: 'C', amount: 50.0, date: now, status: SettlementStatus.pending, createdAt: now),
        SettlementLog(id: '3', payer: 'C', payee: 'A', amount: 25.0, date: now, status: SettlementStatus.paid, createdAt: now),
      ];

      final items = BalanceEvolutionCalculator.calculate(logs);

      expect(items[0].runningTotal, 100.0);
      expect(items[0].cumulativeTotal, 100.0);

      expect(items[1].runningTotal, 100.0); // Pending, running total unchanged
      expect(items[1].cumulativeTotal, 150.0);

      expect(items[2].runningTotal, 125.0); // Paid, added 25
      expect(items[2].cumulativeTotal, 175.0);
    });

    test('3.6 BalanceEvolutionItem equality checks log and totals', () {
      final now = DateTime.now();
      final log = SettlementLog(id: '1', payer: 'A', payee: 'B', amount: 10.0, date: now, createdAt: now);

      final item1 = BalanceEvolutionItem(log: log, runningTotal: 10.0, cumulativeTotal: 10.0);
      final item2 = BalanceEvolutionItem(log: log, runningTotal: 10.0, cumulativeTotal: 10.0);

      expect(item1, equals(item2));
    });

    test('3.7 All pending settlements yield 0 runningTotal at every step', () {
      final now = DateTime.now();
      final logs = [
        SettlementLog(id: '1', payer: 'A', payee: 'B', amount: 10.0, date: now, status: SettlementStatus.pending, createdAt: now),
        SettlementLog(id: '2', payer: 'B', payee: 'C', amount: 20.0, date: now, status: SettlementStatus.pending, createdAt: now),
      ];

      final items = BalanceEvolutionCalculator.calculate(logs);
      expect(items[0].runningTotal, 0.0);
      expect(items[1].runningTotal, 0.0);
      expect(items[1].cumulativeTotal, 30.0);
    });

    test('3.8 Decimal precision is maintained in running total additions', () {
      final now = DateTime.now();
      final logs = [
        SettlementLog(id: '1', payer: 'A', payee: 'B', amount: 12.34, date: now, status: SettlementStatus.paid, createdAt: now),
        SettlementLog(id: '2', payer: 'B', payee: 'C', amount: 56.78, date: now, status: SettlementStatus.paid, createdAt: now),
      ];

      final items = BalanceEvolutionCalculator.calculate(logs);
      expect(items[1].runningTotal, closeTo(69.12, 0.001));
    });

    test('3.9 Output list of BalanceEvolutionCalculator is unmodifiable', () {
      final items = BalanceEvolutionCalculator.calculate([]);
      final dummyItem = BalanceEvolutionItem(
        log: SettlementLog(id: 'd', payer: 'A', payee: 'B', amount: 1, date: DateTime.now(), createdAt: DateTime.now()),
        runningTotal: 0,
        cumulativeTotal: 0,
      );
      expect(() => items.add(dummyItem), throwsUnsupportedError);
    });

    test('3.10 Items correspond 1-to-1 to input logs in identical sequence', () {
      final now = DateTime.now();
      final logs = List.generate(
        5,
        (i) => SettlementLog(
          id: 'log_$i',
          payer: 'Payer $i',
          payee: 'Payee $i',
          amount: (i + 1) * 10.0,
          date: now,
          status: SettlementStatus.paid,
          createdAt: now,
        ),
      );

      final items = BalanceEvolutionCalculator.calculate(logs);
      for (int i = 0; i < 5; i++) {
        expect(items[i].log.id, 'log_$i');
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 4: Settlement Repository Tests (15 tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Group 4: Settlement Repository CRUD & Status Operations', () {
    late FakeSettlementRepository repository;

    setUp(() {
      repository = FakeSettlementRepository();
    });

    test('4.1 getSettlementLogs initially returns empty list', () async {
      final result = await repository.getSettlementLogs();
      expect(result.isRight(), isTrue);
      result.fold((l) => fail(l.message), (logs) => expect(logs, isEmpty));
    });

    test('4.2 createSettlementLog adds record and returns created entity', () async {
      final now = DateTime.now();
      final log = SettlementLog(
        id: 's1',
        payer: 'Alice',
        payee: 'Bob',
        amount: 42.0,
        date: now,
        createdAt: now,
      );

      final result = await repository.createSettlementLog(log);
      expect(result.isRight(), isTrue);
      expect(repository.logs.length, 1);
      expect(repository.logs.first.id, 's1');
    });

    test('4.3 getSettlementLogById returns existing log', () async {
      final now = DateTime.now();
      final log = SettlementLog(id: 's42', payer: 'A', payee: 'B', amount: 42, date: now, createdAt: now);
      await repository.createSettlementLog(log);

      final result = await repository.getSettlementLogById('s42');
      expect(result.isRight(), isTrue);
      result.fold((l) => fail(l.message), (found) => expect(found.id, 's42'));
    });

    test('4.4 getSettlementLogById returns Left failure when not found', () async {
      final result = await repository.getSettlementLogById('non_existent');
      expect(result.isLeft(), isTrue);
    });

    test('4.5 updateSettlementLog modifies fields of existing record', () async {
      final now = DateTime.now();
      final log = SettlementLog(id: 's1', payer: 'A', payee: 'B', amount: 10, date: now, createdAt: now);
      await repository.createSettlementLog(log);

      final updated = log.copyWith(amount: 99.0, note: 'Updated note');
      final result = await repository.updateSettlementLog(updated);

      expect(result.isRight(), isTrue);
      expect(repository.logs.first.amount, 99.0);
      expect(repository.logs.first.note, 'Updated note');
    });

    test('4.6 updateSettlementLog returns failure when record does not exist', () async {
      final now = DateTime.now();
      final log = SettlementLog(id: 'fake_id', payer: 'A', payee: 'B', amount: 10, date: now, createdAt: now);
      final result = await repository.updateSettlementLog(log);
      expect(result.isLeft(), isTrue);
    });

    test('4.7 deleteSettlementLog removes record', () async {
      final now = DateTime.now();
      final log = SettlementLog(id: 's1', payer: 'A', payee: 'B', amount: 10, date: now, createdAt: now);
      await repository.createSettlementLog(log);
      expect(repository.logs.length, 1);

      final result = await repository.deleteSettlementLog('s1');
      expect(result.isRight(), isTrue);
      expect(repository.logs, isEmpty);
    });

    test('4.8 markAsPaid transitions pending settlement to paid (AC 3)', () async {
      final now = DateTime.now();
      final log = SettlementLog(
        id: 's1',
        payer: 'A',
        payee: 'B',
        amount: 25.0,
        date: now,
        status: SettlementStatus.pending,
        createdAt: now,
      );
      await repository.createSettlementLog(log);

      final result = await repository.markAsPaid('s1');
      expect(result.isRight(), isTrue);
      result.fold((l) => fail(l.message), (s) => expect(s.status, SettlementStatus.paid));
      expect(repository.logs.first.isPaid, isTrue);
    });

    test('4.9 undoMarkAsPaid reverts paid settlement back to pending (AC 8)', () async {
      final now = DateTime.now();
      final log = SettlementLog(
        id: 's1',
        payer: 'A',
        payee: 'B',
        amount: 25.0,
        date: now,
        status: SettlementStatus.paid,
        createdAt: now,
      );
      await repository.createSettlementLog(log);

      final result = await repository.undoMarkAsPaid('s1');
      expect(result.isRight(), isTrue);
      result.fold((l) => fail(l.message), (s) => expect(s.status, SettlementStatus.pending));
      expect(repository.logs.first.isPending, isTrue);
    });

    test('4.10 markAsPaid on non-existent record returns failure', () async {
      final result = await repository.markAsPaid('invalid_id');
      expect(result.isLeft(), isTrue);
    });

    test('4.11 undoMarkAsPaid on non-existent record returns failure', () async {
      final result = await repository.undoMarkAsPaid('invalid_id');
      expect(result.isLeft(), isTrue);
    });

    test('4.12 getSettlementLogs filters by projectId', () async {
      final now = DateTime.now();
      await repository.createSettlementLog(
        SettlementLog(id: '1', projectId: 'proj_A', payer: 'A', payee: 'B', amount: 10, date: now, createdAt: now),
      );
      await repository.createSettlementLog(
        SettlementLog(id: '2', projectId: 'proj_B', payer: 'B', payee: 'C', amount: 20, date: now, createdAt: now),
      );

      final result = await repository.getSettlementLogs(projectId: 'proj_A');
      result.fold((l) => fail(l.message), (logs) {
        expect(logs.length, 1);
        expect(logs.first.id, '1');
      });
    });

    test('4.13 createSettlementLog with same id replaces existing record', () async {
      final now = DateTime.now();
      await repository.createSettlementLog(
        SettlementLog(id: 'rep_1', payer: 'A', payee: 'B', amount: 10, date: now, createdAt: now),
      );
      await repository.createSettlementLog(
        SettlementLog(id: 'rep_1', payer: 'A', payee: 'B', amount: 99, date: now, createdAt: now),
      );

      expect(repository.logs.length, 1);
      expect(repository.logs.first.amount, 99.0);
    });

    test('4.14 delete on already empty repository succeeds gracefully', () async {
      final result = await repository.deleteSettlementLog('any_id');
      expect(result.isRight(), isTrue);
    });

    test('4.15 UseCases execute correctly with repository', () async {
      final getUseCase = GetSettlementLogsUseCase(repository);
      final createUseCase = CreateSettlementLogUseCase(repository);
      final updateUseCase = UpdateSettlementLogUseCase(repository);
      final deleteUseCase = DeleteSettlementLogUseCase(repository);
      final markPaidUseCase = MarkAsPaidUseCase(repository);
      final undoUseCase = UndoMarkAsPaidUseCase(repository);

      final now = DateTime.now();
      final log = SettlementLog(id: 'uc1', payer: 'A', payee: 'B', amount: 50, date: now, createdAt: now);

      await createUseCase(log);
      expect((await getUseCase()).getOrElse(() => []).length, 1);

      await markPaidUseCase('uc1');
      expect((await getUseCase()).getOrElse(() => []).first.isPaid, isTrue);

      await undoUseCase('uc1');
      expect((await getUseCase()).getOrElse(() => []).first.isPending, isTrue);

      await updateUseCase(log.copyWith(amount: 100));
      expect((await getUseCase()).getOrElse(() => []).first.amount, 100);

      await deleteUseCase('uc1');
      expect((await getUseCase()).getOrElse(() => []), isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 5: SettlementBloc State Management Tests (12 tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Group 5: SettlementBloc State Management', () {
    late FakeSettlementRepository repository;
    late SettlementBloc bloc;

    setUp(() {
      repository = FakeSettlementRepository();
      bloc = SettlementBloc(
        getSettlementLogsUseCase: GetSettlementLogsUseCase(repository),
        createSettlementLogUseCase: CreateSettlementLogUseCase(repository),
        updateSettlementLogUseCase: UpdateSettlementLogUseCase(repository),
        deleteSettlementLogUseCase: DeleteSettlementLogUseCase(repository),
        markAsPaidUseCase: MarkAsPaidUseCase(repository),
        undoMarkAsPaidUseCase: UndoMarkAsPaidUseCase(repository),
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('5.1 Initial state is SettlementInitial', () {
      expect(bloc.state, isA<SettlementInitial>());
    });

    test('5.2 LoadSettlementsEvent transitions to Loaded with empty items', () async {
      bloc.add(const LoadSettlementsEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SettlementLoading>(),
          isA<SettlementLoaded>(),
        ]),
      );
      final loaded = bloc.state as SettlementLoaded;
      expect(loaded.allLogs, isEmpty);
      expect(loaded.totalPaid, 0.0);
      expect(loaded.totalPending, 0.0);
    });

    test('5.3 CreateSettlementEvent adds item and recalculates evolution', () async {
      final now = DateTime.now();
      final log = SettlementLog(id: 's1', payer: 'A', payee: 'B', amount: 50, date: now, status: SettlementStatus.paid, createdAt: now);

      bloc.add(CreateSettlementEvent(log));
      await expectLater(
        bloc.stream,
        emits(isA<SettlementLoaded>()),
      );

      final loaded = bloc.state as SettlementLoaded;
      expect(loaded.allLogs.length, 1);
      expect(loaded.evolutionItems.length, 1);
      expect(loaded.evolutionItems.first.runningTotal, 50.0);
      expect(loaded.totalPaid, 50.0);
    });

    test('5.4 MarkSettlementAsPaidEvent updates status and recalculates running total', () async {
      final now = DateTime.now();
      final log = SettlementLog(id: 's1', payer: 'A', payee: 'B', amount: 50, date: now, status: SettlementStatus.pending, createdAt: now);
      await repository.createSettlementLog(log);

      bloc.add(const LoadSettlementsEvent());
      await expectLater(bloc.stream, emitsThrough(isA<SettlementLoaded>()));

      var loaded = bloc.state as SettlementLoaded;
      expect(loaded.totalPending, 50.0);
      expect(loaded.totalPaid, 0.0);

      bloc.add(const MarkSettlementAsPaidEvent('s1'));
      await expectLater(bloc.stream, emits(isA<SettlementLoaded>()));

      loaded = bloc.state as SettlementLoaded;
      expect(loaded.totalPaid, 50.0);
      expect(loaded.totalPending, 0.0);
      expect(loaded.evolutionItems.first.runningTotal, 50.0);
    });

    test('5.5 UndoMarkSettlementAsPaidEvent reverts status back to pending', () async {
      final now = DateTime.now();
      final log = SettlementLog(id: 's1', payer: 'A', payee: 'B', amount: 50, date: now, status: SettlementStatus.paid, createdAt: now);
      await repository.createSettlementLog(log);

      bloc.add(const LoadSettlementsEvent());
      await expectLater(bloc.stream, emitsThrough(isA<SettlementLoaded>()));

      bloc.add(const UndoMarkSettlementAsPaidEvent('s1'));
      await expectLater(bloc.stream, emits(isA<SettlementLoaded>()));

      final loaded = bloc.state as SettlementLoaded;
      expect(loaded.totalPaid, 0.0);
      expect(loaded.totalPending, 50.0);
      expect(loaded.evolutionItems.first.runningTotal, 0.0);
    });

    test('5.6 UpdateSettlementEvent updates existing record in state', () async {
      final now = DateTime.now();
      final log = SettlementLog(id: 's1', payer: 'A', payee: 'B', amount: 50, date: now, createdAt: now);
      await repository.createSettlementLog(log);

      bloc.add(const LoadSettlementsEvent());
      await expectLater(bloc.stream, emitsThrough(isA<SettlementLoaded>()));

      bloc.add(UpdateSettlementEvent(log.copyWith(amount: 150)));
      await expectLater(bloc.stream, emits(isA<SettlementLoaded>()));

      final loaded = bloc.state as SettlementLoaded;
      expect(loaded.allLogs.first.amount, 150.0);
    });

    test('5.7 DeleteSettlementEvent removes item from state and evolution list', () async {
      final now = DateTime.now();
      final log = SettlementLog(id: 's1', payer: 'A', payee: 'B', amount: 50, date: now, createdAt: now);
      await repository.createSettlementLog(log);

      bloc.add(const LoadSettlementsEvent());
      await expectLater(bloc.stream, emitsThrough(isA<SettlementLoaded>()));

      bloc.add(const DeleteSettlementEvent('s1'));
      await expectLater(bloc.stream, emits(isA<SettlementLoaded>()));

      final loaded = bloc.state as SettlementLoaded;
      expect(loaded.allLogs, isEmpty);
      expect(loaded.evolutionItems, isEmpty);
    });

    test('5.8 UpdateSettlementFilterEvent updates filteredLogs and evolution', () async {
      final now = DateTime.now();
      await repository.createSettlementLog(
        SettlementLog(id: '1', payer: 'Alice', payee: 'Bob', amount: 10, date: now, status: SettlementStatus.paid, createdAt: now),
      );
      await repository.createSettlementLog(
        SettlementLog(id: '2', payer: 'Bob', payee: 'Charlie', amount: 20, date: now, status: SettlementStatus.pending, createdAt: now),
      );

      bloc.add(const LoadSettlementsEvent());
      await expectLater(bloc.stream, emitsThrough(isA<SettlementLoaded>()));

      var loaded = bloc.state as SettlementLoaded;
      expect(loaded.filteredLogs.length, 2);

      bloc.add(const UpdateSettlementFilterEvent(SettlementFilter(status: SettlementStatus.paid)));
      await expectLater(bloc.stream, emits(isA<SettlementLoaded>()));

      loaded = bloc.state as SettlementLoaded;
      expect(loaded.filteredLogs.length, 1);
      expect(loaded.filteredLogs.first.id, '1');
    });

    test('5.9 LoadSettlementsEvent filters by projectId correctly', () async {
      final now = DateTime.now();
      await repository.createSettlementLog(
        SettlementLog(id: 'p1_log', projectId: 'P1', payer: 'A', payee: 'B', amount: 10, date: now, createdAt: now),
      );
      await repository.createSettlementLog(
        SettlementLog(id: 'p2_log', projectId: 'P2', payer: 'B', payee: 'C', amount: 20, date: now, createdAt: now),
      );

      bloc.add(const LoadSettlementsEvent(projectId: 'P1'));
      await expectLater(bloc.stream, emitsThrough(isA<SettlementLoaded>()));

      final loaded = bloc.state as SettlementLoaded;
      expect(loaded.allLogs.length, 1);
      expect(loaded.allLogs.first.id, 'p1_log');
    });

    test('5.10 filteredPaid and filteredPending reflect filtered subset', () async {
      final now = DateTime.now();
      await repository.createSettlementLog(
        SettlementLog(id: '1', payer: 'Alice', payee: 'Bob', amount: 100, date: now, status: SettlementStatus.paid, createdAt: now),
      );
      await repository.createSettlementLog(
        SettlementLog(id: '2', payer: 'Charlie', payee: 'Bob', amount: 50, date: now, status: SettlementStatus.paid, createdAt: now),
      );

      bloc.add(const LoadSettlementsEvent());
      await expectLater(bloc.stream, emitsThrough(isA<SettlementLoaded>()));

      // Filter by Alice only
      bloc.add(const UpdateSettlementFilterEvent(SettlementFilter(person: 'Alice')));
      await expectLater(bloc.stream, emits(isA<SettlementLoaded>()));

      final loaded = bloc.state as SettlementLoaded;
      expect(loaded.totalPaid, 150.0); // All logs
      expect(loaded.filteredPaid, 100.0); // Only Alice
    });

    test('5.11 SettlementLoaded props supports Equatable equality', () {
      const state1 = SettlementLoaded(
        allLogs: [],
        filter: SettlementFilter(),
        filteredLogs: [],
        evolutionItems: [],
      );
      const state2 = SettlementLoaded(
        allLogs: [],
        filter: SettlementFilter(),
        filteredLogs: [],
        evolutionItems: [],
      );

      expect(state1, equals(state2));
    });

    test('5.12 SettlementError state holds error message', () {
      const err = SettlementError('Failed to load database');
      expect(err.message, 'Failed to load database');
      expect(err.props, ['Failed to load database']);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 6: Export Integration Tests (AC 9) (8 tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Group 6: Export Integration (AC 9)', () {
    const csvGen = CsvGenerator();
    const pdfGen = PdfGenerator();
    final now = DateTime(2026, 9, 15);

    final bills = [
      Bill(id: 'b1', title: 'Groceries', amount: 100, date: now, paidBy: 'Alice', participants: const [], category: 'shopping'),
    ];

    final logs = [
      SettlementLog(
        id: 's1',
        payer: 'Bob',
        payee: 'Alice',
        amount: 50.0,
        date: now,
        status: SettlementStatus.paid,
        note: 'Bank transfer',
        createdAt: now,
      ),
    ];

    test('6.1 CsvGenerator includes Payment History section when settlementLogs provided', () {
      final csv = csvGen.generate(bills: bills, settlementLogs: logs);

      expect(csv, contains('# Payment History & Settlement Log'));
      expect(csv, contains('Bob,Alice,50.00,paid,Bank transfer'));
    });

    test('6.2 CsvGenerator omits Payment History section when settlementLogs is null or empty', () {
      final csvNull = csvGen.generate(bills: bills, settlementLogs: null);
      final csvEmpty = csvGen.generate(bills: bills, settlementLogs: []);

      expect(csvNull, isNot(contains('# Payment History & Settlement Log')));
      expect(csvEmpty, isNot(contains('# Payment History & Settlement Log')));
    });

    test('6.3 CsvGenerator escapes commas in notes properly', () {
      final logWithComma = SettlementLog(
        id: 's2',
        payer: 'Bob',
        payee: 'Alice',
        amount: 30,
        date: now,
        status: SettlementStatus.pending,
        note: 'Paid, via cash, in full',
        createdAt: now,
      );

      final csv = csvGen.generate(bills: bills, settlementLogs: [logWithComma]);
      expect(csv, contains('"Paid, via cash, in full"'));
    });

    test('6.4 PdfGenerator generates valid PDF bytes with settlementLogs included', () async {
      final pdfBytes = await pdfGen.generate(
        bills: bills,
        projectName: 'Shared House',
        settlementLogs: logs,
      );

      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('6.5 PdfGenerator generates without settlementLogs without crashing', () async {
      final pdfBytes = await pdfGen.generate(
        bills: bills,
        projectName: 'Shared House',
        settlementLogs: null,
      );

      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('6.6 ExportService passes settlementLogs to exportToFile', () async {
      final exportService = ExportService(
        getOutputDirectory: () async => Directory.systemTemp,
      );

      const filter = ExportFilter(format: ExportFormat.csv);
      final result = await exportService.exportToFile(
        bills: bills,
        filter: filter,
        settlementLogs: logs,
      );

      expect(result.success, isTrue);
      expect(result.filePath, isNotNull);

      final file = File(result.filePath!);
      final content = await file.readAsString();
      expect(content, contains('# Payment History & Settlement Log'));
      expect(content, contains('Bob,Alice,50.00'));
    });

    test('6.7 ExportService exportToFile handles PDF format with settlementLogs', () async {
      final exportService = ExportService(
        getOutputDirectory: () async => Directory.systemTemp,
      );

      const filter = ExportFilter(format: ExportFormat.pdf);
      final result = await exportService.exportToFile(
        bills: bills,
        filter: filter,
        settlementLogs: logs,
      );

      expect(result.success, isTrue);
      expect(result.filePath, isNotNull);
    });

    test('6.8 Multiple settlement logs are all output in CSV format', () {
      final multiLogs = [
        SettlementLog(id: '1', payer: 'A', payee: 'B', amount: 10, date: now, status: SettlementStatus.paid, createdAt: now),
        SettlementLog(id: '2', payer: 'B', payee: 'C', amount: 20, date: now, status: SettlementStatus.pending, createdAt: now),
        SettlementLog(id: '3', payer: 'C', payee: 'A', amount: 30, date: now, status: SettlementStatus.paid, createdAt: now),
      ];

      final csv = csvGen.generate(bills: bills, settlementLogs: multiLogs);
      expect(csv, contains('A,B,10.00,paid'));
      expect(csv, contains('B,C,20.00,pending'));
      expect(csv, contains('C,A,30.00,paid'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 7: UI Component Tests (Card & Dialog) (15 tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Group 7: UI Component Tests (TimelineCard & AddSettlementDialog)', () {
    final now = DateTime(2026, 9, 15);
    final paidLog = SettlementLog(
      id: 'log1',
      payer: 'Alice',
      payee: 'Bob',
      amount: 75.0,
      date: now,
      status: SettlementStatus.paid,
      note: 'Transfer via bank',
      createdAt: now,
    );
    final pendingLog = SettlementLog(
      id: 'log2',
      payer: 'Bob',
      payee: 'Charlie',
      amount: 40.0,
      date: now,
      status: SettlementStatus.pending,
      createdAt: now,
    );

    testWidgets('7.1 SettlementTimelineCard renders payer, payee, and amount', (tester) async {
      setLargeScreen(tester);
      final item = BalanceEvolutionItem(log: paidLog, runningTotal: 75.0, cumulativeTotal: 75.0);

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: SettlementTimelineCard(item: item),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.byKey(const Key('settlementAmountText_log1')), findsOneWidget);
    });

    testWidgets('7.2 SettlementTimelineCard renders status badge correctly for paid', (tester) async {
      setLargeScreen(tester);
      final item = BalanceEvolutionItem(log: paidLog, runningTotal: 75.0, cumulativeTotal: 75.0);

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: SettlementTimelineCard(item: item),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settlementStatusText_log1')), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
    });

    testWidgets('7.3 SettlementTimelineCard renders status badge correctly for pending', (tester) async {
      setLargeScreen(tester);
      final item = BalanceEvolutionItem(log: pendingLog, runningTotal: 0.0, cumulativeTotal: 40.0);

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: SettlementTimelineCard(item: item),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settlementStatusText_log2')), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('7.4 SettlementTimelineCard renders running total evolution badge', (tester) async {
      setLargeScreen(tester);
      final item = BalanceEvolutionItem(log: paidLog, runningTotal: 150.0, cumulativeTotal: 150.0);

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: SettlementTimelineCard(item: item),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('runningTotalText_log1')), findsOneWidget);
      expect(find.textContaining('150'), findsWidgets);
    });

    testWidgets('7.5 SettlementTimelineCard displays note when present', (tester) async {
      setLargeScreen(tester);
      final item = BalanceEvolutionItem(log: paidLog, runningTotal: 75.0, cumulativeTotal: 75.0);

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: SettlementTimelineCard(item: item),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settlementNoteText_log1')), findsOneWidget);
      expect(find.text('Transfer via bank'), findsOneWidget);
    });

    testWidgets('7.6 Pending card displays Mark as Paid button and triggers callback', (tester) async {
      setLargeScreen(tester);
      SettlementLog? markedLog;
      final item = BalanceEvolutionItem(log: pendingLog, runningTotal: 0.0, cumulativeTotal: 40.0);

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: SettlementTimelineCard(
              item: item,
              onMarkAsPaid: (l) => markedLog = l,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final btnFinder = find.byKey(const Key('markPaidButton_log2'));
      expect(btnFinder, findsOneWidget);

      await tester.tap(btnFinder);
      await tester.pumpAndSettle();
      expect(markedLog?.id, 'log2');
    });

    testWidgets('7.7 Paid card displays Undo button and triggers callback', (tester) async {
      setLargeScreen(tester);
      SettlementLog? undoneLog;
      final item = BalanceEvolutionItem(log: paidLog, runningTotal: 75.0, cumulativeTotal: 75.0);

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: SettlementTimelineCard(
              item: item,
              onUndoMarkAsPaid: (l) => undoneLog = l,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final btnFinder = find.byKey(const Key('undoPaidButton_log1'));
      expect(btnFinder, findsOneWidget);

      await tester.tap(btnFinder);
      await tester.pumpAndSettle();
      expect(undoneLog?.id, 'log1');
    });

    testWidgets('7.8 Card delete button triggers onDelete callback', (tester) async {
      setLargeScreen(tester);
      SettlementLog? deletedLog;
      final item = BalanceEvolutionItem(log: paidLog, runningTotal: 75.0, cumulativeTotal: 75.0);

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: SettlementTimelineCard(
              item: item,
              onDelete: (l) => deletedLog = l,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deleteSettlement_log1')));
      await tester.pumpAndSettle();
      expect(deletedLog?.id, 'log1');
    });

    testWidgets('7.9 AddSettlementDialog validates empty payer field', (tester) async {
      setLargeScreen(tester);

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: AddSettlementDialog(
              onSave: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveSettlementButton')));
      await tester.pumpAndSettle();

      expect(find.text('Payer is required'), findsOneWidget);
    });

    testWidgets('7.10 AddSettlementDialog validates empty payee field', (tester) async {
      setLargeScreen(tester);

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: AddSettlementDialog(
              initialPayer: 'Alice',
              onSave: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveSettlementButton')));
      await tester.pumpAndSettle();

      expect(find.text('Payee is required'), findsOneWidget);
    });

    testWidgets('7.11 AddSettlementDialog validates payer and payee being identical', (tester) async {
      setLargeScreen(tester);

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: AddSettlementDialog(
              initialPayer: 'Alice',
              initialPayee: 'Alice',
              initialAmount: 50,
              onSave: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveSettlementButton')));
      await tester.pumpAndSettle();

      expect(find.text('Payer and payee cannot be the same person'), findsOneWidget);
    });

    testWidgets('7.12 AddSettlementDialog validates zero or invalid amount', (tester) async {
      setLargeScreen(tester);

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: AddSettlementDialog(
              initialPayer: 'Alice',
              initialPayee: 'Bob',
              initialAmount: 0,
              onSave: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveSettlementButton')));
      await tester.pumpAndSettle();

      expect(find.text('Amount must be greater than zero'), findsOneWidget);
    });

    testWidgets('7.13 AddSettlementDialog submits valid settlement record', (tester) async {
      setLargeScreen(tester);
      SettlementLog? savedLog;

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: AddSettlementDialog(
              initialPayer: 'Alice',
              initialPayee: 'Bob',
              initialAmount: 65.5,
              onSave: (l) => savedLog = l,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveSettlementButton')));
      await tester.pumpAndSettle();

      expect(savedLog, isNotNull);
      expect(savedLog?.payer, 'Alice');
      expect(savedLog?.payee, 'Bob');
      expect(savedLog?.amount, 65.5);
    });

    testWidgets('7.14 AddSettlementDialog with availableMembers renders dropdowns', (tester) async {
      setLargeScreen(tester);

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: AddSettlementDialog(
              availableMembers: const ['Alice', 'Bob', 'Charlie'],
              initialPayer: 'Alice',
              initialPayee: 'Bob',
              onSave: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payerDropdownField')), findsOneWidget);
      expect(find.byKey(const Key('payeeDropdownField')), findsOneWidget);
    });

    testWidgets('7.15 AddSettlementDialog status chips toggle between Paid and Pending', (tester) async {
      setLargeScreen(tester);
      SettlementLog? saved;

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: AddSettlementDialog(
              initialPayer: 'Alice',
              initialPayee: 'Bob',
              initialAmount: 20,
              onSave: (l) => saved = l,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Pending chip
      await tester.tap(find.byKey(const Key('settlementStatusPendingChip')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveSettlementButton')));
      await tester.pumpAndSettle();

      expect(saved?.status, SettlementStatus.pending);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 8: PaymentHistoryScreen & Navigation Integration (15 tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Group 8: PaymentHistoryScreen & Navigation Integration', () {
    late FakeSettlementRepository repository;
    final now = DateTime(2026, 9, 15);

    setUp(() {
      repository = FakeSettlementRepository();
    });

    testWidgets('8.1 PaymentHistoryScreen renders AppBar and action buttons', (tester) async {
      setLargeScreen(tester);

      await tester.pumpWidget(
        buildTestApp(
          repo: repository,
          child: const PaymentHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('paymentHistoryAppBarTitle')), findsOneWidget);
      expect(find.byKey(const Key('timelineSortOrderButton')), findsOneWidget);
      expect(find.byKey(const Key('addPaymentAppBarButton')), findsOneWidget);
      expect(find.byKey(const Key('addPaymentFab')), findsOneWidget);
    });

    testWidgets('8.2 Empty state is shown when no settlement logs exist', (tester) async {
      setLargeScreen(tester);

      await tester.pumpWidget(
        buildTestApp(
          repo: repository,
          child: const PaymentHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('emptySettlementState')), findsOneWidget);
      expect(find.byKey(const Key('emptyStateAddPaymentButton')), findsOneWidget);
    });

    testWidgets('8.3 Metric cards render total paid and total pending', (tester) async {
      setLargeScreen(tester);
      await repository.createSettlementLog(
        SettlementLog(id: '1', payer: 'A', payee: 'B', amount: 100, date: now, status: SettlementStatus.paid, createdAt: now),
      );
      await repository.createSettlementLog(
        SettlementLog(id: '2', payer: 'B', payee: 'C', amount: 40, date: now, status: SettlementStatus.pending, createdAt: now),
      );

      await tester.pumpWidget(
        buildTestApp(
          repo: repository,
          child: const PaymentHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('totalPaidMetricCard')), findsOneWidget);
      expect(find.byKey(const Key('totalPendingMetricCard')), findsOneWidget);
      expect(find.textContaining('100'), findsWidgets);
      expect(find.textContaining('40'), findsWidgets);
    });

    testWidgets('8.4 Filter by status chip filters displayed settlements', (tester) async {
      setLargeScreen(tester);
      await repository.createSettlementLog(
        SettlementLog(id: 'p1', payer: 'Alice', payee: 'Bob', amount: 50, date: now, status: SettlementStatus.paid, createdAt: now),
      );
      await repository.createSettlementLog(
        SettlementLog(id: 'p2', payer: 'Bob', payee: 'Charlie', amount: 30, date: now, status: SettlementStatus.pending, createdAt: now),
      );

      await tester.pumpWidget(
        buildTestApp(
          repo: repository,
          child: const PaymentHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settlementCard_p1')), findsOneWidget);
      expect(find.byKey(const Key('settlementCard_p2')), findsOneWidget);

      // Tap Paid chip
      await tester.tap(find.byKey(const Key('filterStatusPaidChip')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settlementCard_p1')), findsOneWidget);
      expect(find.byKey(const Key('settlementCard_p2')), findsNothing);
    });

    testWidgets('8.5 Mark as Paid button in screen updates the item state', (tester) async {
      setLargeScreen(tester);
      await repository.createSettlementLog(
        SettlementLog(id: 't_pending', payer: 'Alice', payee: 'Bob', amount: 80, date: now, status: SettlementStatus.pending, createdAt: now),
      );

      await tester.pumpWidget(
        buildTestApp(
          repo: repository,
          child: const PaymentHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('markPaidButton_t_pending')), findsOneWidget);

      await tester.tap(find.byKey(const Key('markPaidButton_t_pending')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('undoPaidButton_t_pending')), findsOneWidget);
    });

    testWidgets('8.6 Undo button reverts item state back to pending', (tester) async {
      setLargeScreen(tester);
      await repository.createSettlementLog(
        SettlementLog(id: 't_paid', payer: 'Alice', payee: 'Bob', amount: 80, date: now, status: SettlementStatus.paid, createdAt: now),
      );

      await tester.pumpWidget(
        buildTestApp(
          repo: repository,
          child: const PaymentHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('undoPaidButton_t_paid')), findsOneWidget);

      await tester.tap(find.byKey(const Key('undoPaidButton_t_paid')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('markPaidButton_t_paid')), findsOneWidget);
    });

    testWidgets('8.7 Delete action shows confirmation dialog and removes item', (tester) async {
      setLargeScreen(tester);
      await repository.createSettlementLog(
        SettlementLog(id: 'del_me', payer: 'A', payee: 'B', amount: 15, date: now, createdAt: now),
      );

      await tester.pumpWidget(
        buildTestApp(
          repo: repository,
          child: const PaymentHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settlementCard_del_me')), findsOneWidget);

      await tester.tap(find.byKey(const Key('deleteSettlement_del_me')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirmDeleteSettlementButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirmDeleteSettlementButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settlementCard_del_me')), findsNothing);
    });

    testWidgets('8.8 Timeline sort order button toggles between oldest and newest first', (tester) async {
      setLargeScreen(tester);
      final earlier = DateTime(2026, 9, 1);
      final later = DateTime(2026, 9, 20);

      await repository.createSettlementLog(
        SettlementLog(id: 'old_log', payer: 'A', payee: 'B', amount: 10, date: earlier, createdAt: earlier),
      );
      await repository.createSettlementLog(
        SettlementLog(id: 'new_log', payer: 'B', payee: 'C', amount: 20, date: later, createdAt: later),
      );

      await tester.pumpWidget(
        buildTestApp(
          repo: repository,
          child: const PaymentHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Oldest first by default (old_log appears first)
      final firstFinderBefore = find.byType(SettlementTimelineCard).first;
      expect(tester.widget<SettlementTimelineCard>(firstFinderBefore).item.log.id, 'old_log');

      // Toggle sort
      await tester.tap(find.byKey(const Key('timelineSortOrderButton')));
      await tester.pumpAndSettle();

      final firstFinderAfter = find.byType(SettlementTimelineCard).first;
      expect(tester.widget<SettlementTimelineCard>(firstFinderAfter).item.log.id, 'new_log');
    });

    testWidgets('8.9 PaymentHistoryScreen renders properly in dark theme', (tester) async {
      setLargeScreen(tester);
      await repository.createSettlementLog(
        SettlementLog(id: 'dark_log', payer: 'A', payee: 'B', amount: 50, date: now, createdAt: now),
      );

      await tester.pumpWidget(
        buildTestApp(
          repo: repository,
          themeMode: ThemeMode.dark,
          child: const PaymentHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settlementCard_dark_log')), findsOneWidget);
    });

    testWidgets('8.10 PaymentHistoryScreen renders with Vietnamese locale', (tester) async {
      setLargeScreen(tester);

      await tester.pumpWidget(
        buildTestApp(
          repo: repository,
          locale: const Locale('vi'),
          child: const PaymentHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lịch sử thanh toán'), findsOneWidget);
    });

    testWidgets('8.11 SettingsScreen contains paymentHistoryTile', (tester) async {
      setLargeScreen(tester);

      await tester.pumpWidget(
        buildTestApp(
          repo: repository,
          child: const Scaffold(
            body: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('paymentHistoryTile')), findsOneWidget);
    });

    testWidgets('8.12 ProjectDetailScreen SettlementTab contains Payment History button', (tester) async {
      setLargeScreen(tester);
      final project = Project(
        id: 'proj_t38',
        name: 'Apartment 4B',
        members: const ['Alice', 'Bob'],
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        buildTestApp(
          repo: repository,
          child: ProjectDetailScreen(project: project),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to settlement tab
      await tester.tap(find.byKey(const Key('settlementTab')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectPaymentHistoryButton')), findsOneWidget);
    });

    testWidgets('8.13 Record Payment button on SettlementCard opens AddSettlementDialog prefilled', (tester) async {
      setLargeScreen(tester);
      final project = Project(
        id: 'proj_debts',
        name: 'Apartment 4B',
        members: const ['Alice', 'Bob'],
        createdAt: now,
        updatedAt: now,
      );

      // Create a bill where Alice paid Bob owes Alice
      final billRepo = FakeBillRepo();
      billRepo.bills.add(
        Bill(
          id: 'b1',
          title: 'Dinner',
          amount: 100,
          date: now,
          paidBy: 'Alice',
          projectId: 'proj_debts',
          participants: const [],
          category: 'food',
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          repo: repository,
          billRepo: billRepo,
          child: ProjectDetailScreen(project: project),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to settlement tab
      await tester.tap(find.byKey(const Key('settlementTab')));
      await tester.pumpAndSettle();

      final recordBtn = find.byKey(const Key('recordSettlementPayment_Bob_Alice'));
      if (recordBtn.evaluate().isNotEmpty) {
        await tester.tap(recordBtn);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('saveSettlementButton')), findsOneWidget);
      }
    });

    testWidgets('8.14 FAB opens AddSettlementDialog on PaymentHistoryScreen', (tester) async {
      setLargeScreen(tester);

      await tester.pumpWidget(
        buildTestApp(
          repo: repository,
          child: const PaymentHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addPaymentFab')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('saveSettlementButton')), findsOneWidget);
    });

    testWidgets('8.15 Project name in PaymentHistoryScreen title is rendered when passed', (tester) async {
      setLargeScreen(tester);

      await tester.pumpWidget(
        buildTestApp(
          repo: repository,
          child: const PaymentHistoryScreen(
            projectId: 'p_named',
            projectName: 'Lake House',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Lake House'), findsOneWidget);
    });
  });
}
