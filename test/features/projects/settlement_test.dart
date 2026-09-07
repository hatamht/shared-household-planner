import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project_statistics.dart';
import 'package:shared_household_planner/features/projects/domain/entities/settlement_item.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/calculate_settlement_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/project_detail_screen.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';

// ─────────────────────────────────────────────
// Fake BillRepository
// ─────────────────────────────────────────────
class FakeBillRepository implements BillRepository {
  final List<Bill> _bills;
  FakeBillRepository(this._bills);

  @override
  Future<Either<Failure, Bill>> create(Bill bill) async => Right(bill);

  @override
  Future<Either<Failure, List<Bill>>> getAll() async =>
      Right(List.from(_bills));

  @override
  Future<Either<Failure, Bill>> getById(String billId) async =>
      Left(const LocalFailure('not impl'));

  @override
  Future<Either<Failure, Bill>> update(Bill bill) async => Right(bill);

  @override
  Future<Either<Failure, void>> delete(String billId) async =>
      const Right(null);

  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(
      String projectId) async {
    final filtered = _bills.where((b) => b.projectId == projectId).toList();
    return Right(filtered);
  }
}

// ─────────────────────────────────────────────
// Fake ProjectRepository
// ─────────────────────────────────────────────
class FakeProjectRepository implements ProjectRepository {
  @override
  Future<Either<Failure, List<Project>>> getAll() async => const Right([]);
  @override
  Future<Either<Failure, Project>> create(Project p) async => Right(p);
  @override
  Future<Either<Failure, Project>> getById(String id) async =>
      Left(const LocalFailure('not impl'));
  @override
  Future<Either<Failure, Project>> update(Project p) async => Right(p);
  @override
  Future<Either<Failure, void>> delete(String id) async => const Right(null);
}

// ─────────────────────────────────────────────
// TestAppLocalizations
// ─────────────────────────────────────────────
class TestAppLocalizations extends AppLocalizations {
  TestAppLocalizations() : super(const Locale('en'));

  static const Map<String, String> _strings = {
    'bills_tab': 'Bills',
    'settlement_tab': 'Settlement',
    'statistics_tab': 'Statistics',
    'settlement': 'Settlement',
    'owes': 'owes',
    'paid_by_label': 'Paid by',
    'no_settlement_needed': 'Everyone is settled up! 🎉',
    'top_payer': 'Top Payer',
    'top_debtor': 'Owes the Most',
    'net_balance': 'Net Balance',
    'total_expense': 'Total Expense',
    'all_settled': 'All settled',
    'project_bills': 'Project Bills',
    'per_person': 'per person',
    'no_bills_in_project': 'No bills linked to this project yet',
    'total_spent': 'Total Spent',
    'error': 'Error',
    'loading': 'Loading...',
  };

  @override
  String translate(String key) => _strings[key] ?? key;
}

class TestAppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const TestAppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async =>
      TestAppLocalizations();
  @override
  bool shouldReload(TestAppLocalizationsDelegate old) => false;
}

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────
final _date = DateTime(2026, 9, 7);

Project makeProject({
  String id = 'proj-1',
  String name = 'Trip',
  List<String> members = const ['An', 'Binh', 'Chi'],
}) =>
    Project(id: id, name: name, members: members,
        createdAt: _date, updatedAt: _date);

Bill makeBill({
  required String id,
  required String projectId,
  required String paidBy,
  required double amount,
  required List<String> participantNames,
}) {
  final perPerson = amount / participantNames.length;
  return Bill(
    id: id,
    title: 'Bill $id',
    amount: amount,
    category: 'food',
    date: _date,
    paidBy: paidBy,
    participants: participantNames
        .map((n) => BillParticipant(
              participantId: 'p_${id}_$n',
              name: n,
              amount: perPerson,
            ))
        .toList(),
    projectId: projectId,
  );
}

Widget buildTestApp({
  required Widget child,
  required BillRepository billRepository,
  ProjectBloc? projectBloc,
}) {
  projectBloc ??= ProjectBloc(
    createProjectUseCase:
        CreateProjectUseCase(FakeProjectRepository()),
    getAllProjectsUseCase:
        GetAllProjectsUseCase(FakeProjectRepository()),
    updateProjectUseCase:
        UpdateProjectUseCase(FakeProjectRepository()),
    deleteProjectUseCase:
        DeleteProjectUseCase(FakeProjectRepository()),
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider()),
    ],
    child: MultiRepositoryProvider(
      providers: [
        RepositoryProvider<BillRepository>.value(value: billRepository),
      ],
      child: BlocProvider<ProjectBloc>.value(
        value: projectBloc,
        child: MaterialApp(
          localizationsDelegates: const [
            TestAppLocalizationsDelegate(),
          ],
          supportedLocales: const [Locale('en')],
          home: child,
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────
// TESTS
// ─────────────────────────────────────────────
void main() {
  const usecase = CalculateSettlementUseCase();

  // ── Group 1: SettlementItem entity ────────────
  group('SettlementItem entity', () {
    test('SettlementItem stores from/to/amount', () {
      const item = SettlementItem(from: 'Binh', to: 'An', amount: 500000);
      expect(item.from, 'Binh');
      expect(item.to, 'An');
      expect(item.amount, 500000);
    });

    test('SettlementItem equality', () {
      const a = SettlementItem(from: 'X', to: 'Y', amount: 100);
      const b = SettlementItem(from: 'X', to: 'Y', amount: 100);
      expect(a, equals(b));
    });
  });

  // ── Group 2: ProjectStatistics entity ─────────
  group('ProjectStatistics entity', () {
    test('isAllSettled true when no settlements', () {
      const stats = ProjectStatistics(
        totalPaidPerPerson: {},
        netBalancePerPerson: {},
        settlements: [],
        totalExpense: 0,
      );
      expect(stats.isAllSettled, isTrue);
    });

    test('isAllSettled false when settlements exist', () {
      const stats = ProjectStatistics(
        totalPaidPerPerson: {},
        netBalancePerPerson: {},
        settlements: [
          SettlementItem(from: 'A', to: 'B', amount: 100),
        ],
        totalExpense: 100,
      );
      expect(stats.isAllSettled, isFalse);
    });
  });

  // ── Group 3: CalculateSettlementUseCase Unit Tests ──
  group('CalculateSettlementUseCase - unit tests', () {
    test('Empty bills → zero expense, no settlements', () async {
      final project = makeProject(members: ['An', 'Binh']);
      final result = await usecase(
        CalculateSettlementParams(project: project, bills: []),
      );
      result.fold(
        (f) => fail('Expected success'),
        (stats) {
          expect(stats.totalExpense, 0);
          expect(stats.settlements, isEmpty);
          expect(stats.isAllSettled, isTrue);
        },
      );
    });

    test('1-person project, any bills → no settlement needed', () async {
      final project = makeProject(members: ['An']);
      final bills = [
        makeBill(id: 'b1', projectId: 'proj-1', paidBy: 'An',
            amount: 500000, participantNames: ['An']),
      ];
      final result = await usecase(
        CalculateSettlementParams(project: project, bills: bills),
      );
      result.fold(
        (f) => fail('Expected success'),
        (stats) {
          expect(stats.settlements, isEmpty);
          expect(stats.totalExpense, 500000);
        },
      );
    });

    test('2 people, one pays all → other owes half', () async {
      final project = makeProject(members: ['An', 'Binh']);
      final bills = [
        makeBill(id: 'b1', projectId: 'proj-1', paidBy: 'An',
            amount: 1000000, participantNames: ['An', 'Binh']),
      ];
      final result = await usecase(
        CalculateSettlementParams(project: project, bills: bills),
      );
      result.fold(
        (f) => fail('Expected success'),
        (stats) {
          expect(stats.totalExpense, 1000000);
          expect(stats.settlements.length, 1);
          expect(stats.settlements.first.from, 'Binh');
          expect(stats.settlements.first.to, 'An');
          expect(stats.settlements.first.amount, 500000);
        },
      );
    });

    test('Spec example: [An=3M, Binh=1.5M, Chi=0.5M] 3-person project',
        () async {
      // Total = 5M, per person = 5/3 ≈ 1.667M
      // net An   = 3M - 1.667M = +1.333M (creditor)
      // net Binh = 1.5M - 1.667M = -0.167M (debtor)
      // net Chi  = 0.5M - 1.667M = -1.167M (debtor)
      final project = makeProject(members: ['An', 'Binh', 'Chi']);
      final bills = [
        makeBill(id: 'b1', projectId: 'proj-1', paidBy: 'An',
            amount: 3000000, participantNames: ['An', 'Binh', 'Chi']),
        makeBill(id: 'b2', projectId: 'proj-1', paidBy: 'Binh',
            amount: 1500000, participantNames: ['An', 'Binh', 'Chi']),
        makeBill(id: 'b3', projectId: 'proj-1', paidBy: 'Chi',
            amount: 500000, participantNames: ['An', 'Binh', 'Chi']),
      ];
      final result = await usecase(
        CalculateSettlementParams(project: project, bills: bills),
      );
      result.fold(
        (f) => fail('Expected success'),
        (stats) {
          expect(stats.totalExpense, 5000000);
          // An is the creditor
          expect(stats.netBalancePerPerson['An']!, greaterThan(0));
          // Binh and Chi are debtors
          expect(stats.netBalancePerPerson['Binh']!, lessThan(0));
          expect(stats.netBalancePerPerson['Chi']!, lessThan(0));
          // Both should pay An
          final toAn =
              stats.settlements.where((s) => s.to == 'An').toList();
          expect(toAn.length, 2);
          // Total repaid should equal An's positive net balance
          final totalRepaid =
              toAn.fold<double>(0, (sum, s) => sum + s.amount);
          expect(totalRepaid,
              closeTo(stats.netBalancePerPerson['An']!, 10));
        },
      );
    });

    test('All paid equally → no settlements', () async {
      final project = makeProject(members: ['An', 'Binh', 'Chi']);
      // Each pays 1M → total 3M ÷ 3 = 1M each → net = 0
      final bills = [
        makeBill(id: 'b1', projectId: 'proj-1', paidBy: 'An',
            amount: 1000000, participantNames: ['An', 'Binh', 'Chi']),
        makeBill(id: 'b2', projectId: 'proj-1', paidBy: 'Binh',
            amount: 1000000, participantNames: ['An', 'Binh', 'Chi']),
        makeBill(id: 'b3', projectId: 'proj-1', paidBy: 'Chi',
            amount: 1000000, participantNames: ['An', 'Binh', 'Chi']),
      ];
      final result = await usecase(
        CalculateSettlementParams(project: project, bills: bills),
      );
      result.fold(
        (f) => fail('Expected success'),
        (stats) {
          expect(stats.settlements, isEmpty);
          expect(stats.isAllSettled, isTrue);
        },
      );
    });

    test('Multiple bills same payer → aggregated', () async {
      final project = makeProject(members: ['An', 'Binh']);
      final bills = [
        makeBill(id: 'b1', projectId: 'proj-1', paidBy: 'An',
            amount: 600000, participantNames: ['An', 'Binh']),
        makeBill(id: 'b2', projectId: 'proj-1', paidBy: 'An',
            amount: 400000, participantNames: ['An', 'Binh']),
      ];
      // An paid total 1M, Binh paid 0 → Binh owes An 500k
      final result = await usecase(
        CalculateSettlementParams(project: project, bills: bills),
      );
      result.fold(
        (f) => fail('Expected success'),
        (stats) {
          expect(stats.totalPaidPerPerson['An'], 1000000);
          expect(stats.settlements.length, 1);
          expect(stats.settlements.first.from, 'Binh');
          expect(stats.settlements.first.amount, 500000);
        },
      );
    });

    test('topPayer is the member who paid most', () async {
      final project = makeProject(members: ['An', 'Binh', 'Chi']);
      final bills = [
        makeBill(id: 'b1', projectId: 'proj-1', paidBy: 'An',
            amount: 3000000, participantNames: ['An', 'Binh', 'Chi']),
        makeBill(id: 'b2', projectId: 'proj-1', paidBy: 'Binh',
            amount: 500000, participantNames: ['An', 'Binh', 'Chi']),
      ];
      final result = await usecase(
        CalculateSettlementParams(project: project, bills: bills),
      );
      result.fold(
        (f) => fail('Expected success'),
        (stats) {
          expect(stats.topPayer, 'An');
        },
      );
    });

    test('topDebtor is the member with most negative net', () async {
      final project = makeProject(members: ['An', 'Binh', 'Chi']);
      final bills = [
        makeBill(id: 'b1', projectId: 'proj-1', paidBy: 'An',
            amount: 3000000, participantNames: ['An', 'Binh', 'Chi']),
      ];
      final result = await usecase(
        CalculateSettlementParams(project: project, bills: bills),
      );
      result.fold(
        (f) => fail('Expected success'),
        (stats) {
          // Chi paid nothing, so has same debt as Binh (1M each)
          // But Binh paid 0, Chi paid 0 → both owe 1M → either could be topDebtor
          expect(stats.topDebtor, isNotNull);
          expect(['Binh', 'Chi'], contains(stats.topDebtor));
        },
      );
    });

    test('Bills not in project are ignored', () async {
      final project = makeProject(members: ['An', 'Binh']);
      final bills = [
        makeBill(id: 'b1', projectId: 'proj-1', paidBy: 'An',
            amount: 1000000, participantNames: ['An', 'Binh']),
        makeBill(id: 'b2', projectId: 'OTHER-PROJECT', paidBy: 'Binh',
            amount: 9999999, participantNames: ['An', 'Binh']),
      ];
      final result = await usecase(
        CalculateSettlementParams(project: project, bills: bills),
      );
      result.fold(
        (f) => fail('Expected success'),
        (stats) {
          expect(stats.totalExpense, 1000000); // only proj-1 bill
          expect(stats.settlements.first.from, 'Binh');
        },
      );
    });

    test('Uneven splits: participant list subset of members', () async {
      // An and Binh in a 3-person project, Chi not involved in this bill
      final project = makeProject(members: ['An', 'Binh', 'Chi']);
      final bills = [
        makeBill(id: 'b1', projectId: 'proj-1', paidBy: 'An',
            amount: 400000, participantNames: ['An', 'Binh']),
        // Chi only in this bill
        makeBill(id: 'b2', projectId: 'proj-1', paidBy: 'Binh',
            amount: 300000, participantNames: ['Binh', 'Chi']),
      ];
      final result = await usecase(
        CalculateSettlementParams(project: project, bills: bills),
      );
      result.fold(
        (f) => fail('Expected success'),
        (stats) {
          expect(stats.totalExpense, 700000);
          // An paid 400k, owed 200k → net +200k
          expect(stats.netBalancePerPerson['An']!, closeTo(200000, 1));
          // Binh paid 300k, owed 200k+150k=350k → net -50k
          expect(stats.netBalancePerPerson['Binh']!, closeTo(-50000, 1));
          // Chi paid 0, owed 150k → net -150k
          expect(stats.netBalancePerPerson['Chi']!, closeTo(-150000, 1));
        },
      );
    });
  });

  // ── Group 4: Widget tests for ProjectDetailScreen ──
  group('ProjectDetailScreen Widget Tests', () {
    testWidgets('Shows 3 tabs: Bills, Settlement, Statistics', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = makeProject();
      final repo = FakeBillRepository([]);

      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: project),
        billRepository: repo,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('billsTab')), findsOneWidget);
      expect(find.byKey(const Key('settlementTab')), findsOneWidget);
      expect(find.byKey(const Key('statisticsTab')), findsOneWidget);
    });

    testWidgets('Bills tab shows empty message when no bills', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = makeProject();
      final repo = FakeBillRepository([]);

      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: project),
        billRepository: repo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No bills linked to this project yet'), findsOneWidget);
    });

    testWidgets('Bills tab lists project bills', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = makeProject();
      final bill = makeBill(
          id: 'b1', projectId: 'proj-1', paidBy: 'An',
          amount: 300000, participantNames: ['An', 'Binh', 'Chi']);
      final repo = FakeBillRepository([bill]);

      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: project),
        billRepository: repo,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('billItem_b1')), findsOneWidget);
    });

    testWidgets('Settlement tab shows "all settled" when no bills', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = makeProject();
      final repo = FakeBillRepository([]);

      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: project),
        billRepository: repo,
      ));
      await tester.pumpAndSettle();

      // Tap Settlement tab
      await tester.tap(find.byKey(const Key('settlementTab')));
      await tester.pumpAndSettle();

      expect(find.text('Everyone is settled up! 🎉'), findsOneWidget);
    });

    testWidgets('Settlement tab shows debts when bills exist', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = makeProject(members: ['An', 'Binh', 'Chi']);
      // An pays everything → Binh and Chi owe An
      final bills = [
        makeBill(id: 'b1', projectId: 'proj-1', paidBy: 'An',
            amount: 3000000, participantNames: ['An', 'Binh', 'Chi']),
      ];
      final repo = FakeBillRepository(bills);

      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: project),
        billRepository: repo,
      ));
      await tester.pumpAndSettle();

      // Tap Settlement tab
      await tester.tap(find.byKey(const Key('settlementTab')));
      await tester.pumpAndSettle();

      // Should show settlement cards (Binh and Chi owe An)
      expect(find.byKey(const Key('settlement_Binh_An')), findsOneWidget);
      expect(find.byKey(const Key('settlement_Chi_An')), findsOneWidget);
    });

    testWidgets('Statistics tab shows total expense summary', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = makeProject(members: ['An', 'Binh']);
      final bills = [
        makeBill(id: 'b1', projectId: 'proj-1', paidBy: 'An',
            amount: 2000000, participantNames: ['An', 'Binh']),
      ];
      final repo = FakeBillRepository(bills);

      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: project),
        billRepository: repo,
      ));
      await tester.pumpAndSettle();

      // Tap Statistics tab
      await tester.tap(find.byKey(const Key('statisticsTab')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('summaryCard')), findsOneWidget);
      expect(find.text('Total Expense'), findsWidgets);
    });

    testWidgets('Statistics tab shows top payer row', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = makeProject(members: ['An', 'Binh', 'Chi']);
      final bills = [
        makeBill(id: 'b1', projectId: 'proj-1', paidBy: 'An',
            amount: 3000000, participantNames: ['An', 'Binh', 'Chi']),
      ];
      final repo = FakeBillRepository(bills);

      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: project),
        billRepository: repo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('statisticsTab')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('topPayerRow')), findsOneWidget);
    });
  });
}
