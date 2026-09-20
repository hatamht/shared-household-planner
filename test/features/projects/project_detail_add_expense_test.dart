import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project_settings.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_project_by_id_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/project_detail_screen.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/add_bill_screen.dart';

// ── Fake BillRepository ───────────────────────────────────────────────────────
class FakeBillRepo implements BillRepository {
  final List<Bill> bills = [];

  FakeBillRepo([List<Bill>? initial]) {
    if (initial != null) bills.addAll(initial);
  }

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
  Future<Either<Failure, void>> delete(String id) async {
    bills.removeWhere((b) => b.id == id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(String projectId) async =>
      Right(bills.where((b) => b.projectId == projectId).toList());
}

// ── Fake ProjectRepository ────────────────────────────────────────────────────
class FakeProjRepo implements ProjectRepository {
  final List<Project> _projects;
  FakeProjRepo([this._projects = const []]);

  @override
  Future<Either<Failure, List<Project>>> getAll() async => Right(List.from(_projects));
  @override
  Future<Either<Failure, Project>> create(Project p) async => Right(p);
  @override
  Future<Either<Failure, Project>> getById(String id) async =>
      Right(_projects.firstWhere((p) => p.id == id));
  @override
  Future<Either<Failure, Project>> update(Project p) async => Right(p);
  @override
  Future<Either<Failure, void>> delete(String id) async => const Right(null);
}

// ── Test Localization ─────────────────────────────────────────────────────────
class _TestDetailLoc extends AppLocalizations {
  final String code;
  _TestDetailLoc(this.code) : super(Locale(code));

  static const Map<String, String> _en = {
    'bills_tab': 'Bills',
    'settlement_tab': 'Settlement',
    'statistics_tab': 'Statistics',
    'no_bills_in_project': 'No bills linked to this project yet',
    'add_expense_button': 'Add Expense',
    'create_first_bill': 'Create Expense',
    'paid_by_label': 'Paid by',
    'no_settlement_needed': 'Everyone is settled up! 🎉',
    'payment_history': 'Payment History',
    'settlement': 'Settlement',
    'total_expense': 'Total Expense',
    'top_payer': 'Top Payer',
    'top_debtor': 'Top Debtor',
    'total_spent': 'Total Spent',
    'per_person': 'per person',
    'error': 'Error',
    'amount': 'Amount',
    'save': 'Save',
    'save_bill': 'Save Bill',
    'restaurant': 'Restaurant',
    'no_project_selected': 'No Project Selected',
    'select_project': 'Select Project',
  };

  static const Map<String, String> _vi = {
    'bills_tab': 'Chi tiêu',
    'settlement_tab': 'Thanh toán',
    'statistics_tab': 'Thống kê',
    'no_bills_in_project': 'Chưa có chi tiêu nào trong dự án này',
    'add_expense_button': 'Tạo yêu cầu chi tiêu',
    'create_first_bill': 'Tạo chi tiêu',
    'paid_by_label': 'Người trả',
    'no_settlement_needed': 'Đã thanh toán hết! 🎉',
    'payment_history': 'Lịch sử thanh toán',
    'settlement': 'Quyết toán',
    'total_expense': 'Tổng chi tiêu',
    'top_payer': 'Chi nhiều nhất',
    'top_debtor': 'Nợ nhiều nhất',
    'total_spent': 'Tổng đã chi',
    'per_person': 'mỗi người',
    'error': 'Lỗi',
    'amount': 'Số tiền',
    'save': 'Lưu',
    'save_bill': 'Lưu hóa đơn',
    'restaurant': 'Nhà hàng',
    'no_project_selected': 'Chưa chọn dự án',
    'select_project': 'Chọn dự án',
  };

  @override
  String translate(String key) {
    if (code == 'vi') return _vi[key] ?? key;
    return _en[key] ?? key;
  }
}

class _TestDetailLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  final String code;
  const _TestDetailLocDelegate([this.code = 'en']);

  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => _TestDetailLoc(code);
  @override
  bool shouldReload(_TestDetailLocDelegate old) => false;
}

Widget buildTestApp({
  required Widget child,
  String language = 'en',
  ThemeData? theme,
  FakeBillRepo? billRepo,
  List<Project>? projects,
}) {
  final bRepo = billRepo ?? FakeBillRepo();
  final billsBloc = BillsBloc(
    getBillsUseCase: GetBillsUseCase(bRepo),
    addBillUseCase: AddBillUseCase(bRepo),
  );

  final pList = projects ??
      [
        Project(
          id: 'proj-1',
          name: 'Da Nang Trip',
          members: const ['An', 'Binh', 'Chi'],
          createdAt: DateTime(2026, 9, 1),
          updatedAt: DateTime(2026, 9, 1),
        ),
      ];
  final projRepo = FakeProjRepo(pList);
  final projectBloc = ProjectBloc(
    getAllProjectsUseCase: GetAllProjectsUseCase(projRepo),
    createProjectUseCase: CreateProjectUseCase(projRepo),
    getProjectByIdUseCase: GetProjectByIdUseCase(projRepo),
    updateProjectUseCase: UpdateProjectUseCase(projRepo),
    deleteProjectUseCase: DeleteProjectUseCase(projRepo),
  )..emit(ProjectLoaded(projects: pList));

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
      RepositoryProvider<BillRepository>.value(value: bRepo),
      BlocProvider<BillsBloc>.value(value: billsBloc),
      BlocProvider<ProjectBloc>.value(value: projectBloc),
    ],
    child: MaterialApp(
      theme: theme ?? ThemeData.light(useMaterial3: true),
      localizationsDelegates: [
        _TestDetailLocDelegate(language),
      ],
      supportedLocales: const [Locale('en'), Locale('vi')],
      home: child,
    ),
  );
}

void main() {
  final sampleProject = Project(
    id: 'proj-1',
    name: 'Da Nang Trip',
    members: const ['An', 'Binh', 'Chi'],
    createdAt: DateTime(2026, 9, 1),
    updatedAt: DateTime(2026, 9, 1),
  );

  final sampleBill = Bill(
    id: 'b1',
    projectId: 'proj-1',
    title: 'Dinner at Beach',
    amount: 600000,
    paidBy: 'An',
    date: DateTime(2026, 9, 15),
    category: 'restaurant',
    participants: const [
      BillParticipant(participantId: 'p1', name: 'An', amount: 200000),
      BillParticipant(participantId: 'p2', name: 'Binh', amount: 200000),
      BillParticipant(participantId: 'p3', name: 'Chi', amount: 200000),
    ],
  );

  group('Shared-51: ProjectDetailScreen Add Expense Button & Navigation Tests', () {
    // ── AC 1 & 2: Button Visibility & Key ──
    testWidgets('1. FloatingActionButton is present with Key("addExpenseFromProjectButton")', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: sampleProject),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('addExpenseFromProjectButton')), findsOneWidget);
    });

    testWidgets('2. FAB displays "Add Expense" label in English', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: sampleProject),
        language: 'en',
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Add Expense'), findsOneWidget);
    });

    testWidgets('3. FAB displays "Tạo yêu cầu chi tiêu" label in Vietnamese', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: sampleProject),
        language: 'vi',
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tạo yêu cầu chi tiêu'), findsOneWidget);
    });

    testWidgets('4. FAB is accessible when switching to SettlementTab and StatisticsTab', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: sampleProject),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      // Bills tab
      expect(find.byKey(const Key('addExpenseFromProjectButton')), findsOneWidget);

      // Tap Settlement tab
      await tester.tap(find.byKey(const Key('settlementTab')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('addExpenseFromProjectButton')), findsOneWidget);

      // Tap Statistics tab
      await tester.tap(find.byKey(const Key('statisticsTab')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('addExpenseFromProjectButton')), findsOneWidget);
    });

    // ── AC 6: Empty State in Bills Tab ──
    testWidgets('5. Empty state in Bills tab displays inline button with Key("emptyStateAddExpenseButton")', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo(); // empty
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: sampleProject),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('emptyStateAddExpenseButton')), findsOneWidget);
      expect(find.byKey(const Key('inlineAddBillButton')), findsOneWidget);
    });

    testWidgets('6. Empty state inline button displays "Create Expense" in English', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: sampleProject),
        language: 'en',
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Create Expense'), findsOneWidget);
    });

    testWidgets('7. Empty state inline button displays "Tạo chi tiêu" in Vietnamese', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: sampleProject),
        language: 'vi',
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tạo chi tiêu'), findsOneWidget);
    });

    testWidgets('8. When bills are present, empty state inline button is not shown but FAB remains', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo([sampleBill]);
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: sampleProject),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('emptyStateAddExpenseButton')), findsNothing);
      expect(find.byKey(const Key('addExpenseFromProjectButton')), findsOneWidget);
      expect(find.text('Dinner at Beach'), findsOneWidget);
    });

    // ── AC 8: Theme Support ──
    testWidgets('9. FAB and empty state button render cleanly in Light Mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: sampleProject),
        theme: ThemeData.light(useMaterial3: true),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('addExpenseFromProjectButton')), findsOneWidget);
      expect(find.byKey(const Key('emptyStateAddExpenseButton')), findsOneWidget);
    });

    testWidgets('10. FAB and empty state button render cleanly in Dark Mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: sampleProject),
        theme: ThemeData.dark(useMaterial3: true),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('addExpenseFromProjectButton')), findsOneWidget);
      expect(find.byKey(const Key('emptyStateAddExpenseButton')), findsOneWidget);
    });

    // ── AC 3: Navigation & Parameter Passing ──
    testWidgets('11. Tapping FAB navigates to AddBillScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: sampleProject),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addExpenseFromProjectButton')));
      await tester.pumpAndSettle();

      expect(find.byType(AddBillScreen), findsOneWidget);
    });

    testWidgets('12. Tapping empty state inline button navigates to AddBillScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: sampleProject),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('emptyStateAddExpenseButton')));
      await tester.pumpAndSettle();

      expect(find.byType(AddBillScreen), findsOneWidget);
    });

    testWidgets('13. AddBillScreen receives correct projectId and projectName', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: sampleProject),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addExpenseFromProjectButton')));
      await tester.pumpAndSettle();

      final addBill = tester.widget<AddBillScreen>(find.byType(AddBillScreen));
      expect(addBill.projectId, equals('proj-1'));
      expect(addBill.projectName, equals('Da Nang Trip'));
    });

    testWidgets('14. AddBillScreen receives projectSettings with project.members', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: sampleProject),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addExpenseFromProjectButton')));
      await tester.pumpAndSettle();

      final addBill = tester.widget<AddBillScreen>(find.byType(AddBillScreen));
      expect(addBill.projectSettings.members, equals(['An', 'Binh', 'Chi']));
    });

    // ── AC 4: Current Project Pre-selected ──
    testWidgets('15. AddBillScreen opens with the current project pre-selected in header', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: sampleProject),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addExpenseFromProjectButton')));
      await tester.pumpAndSettle();

      // Selected project name widget should display 'Da Nang Trip'
      expect(find.byKey(const Key('selectedProjectName')), findsOneWidget);
      final textWidget = tester.widget<Text>(find.byKey(const Key('selectedProjectName')));
      expect(textWidget.data, equals('Da Nang Trip'));
    });

    // ── AC 5: Pre-filled Participants & Payer ──
    testWidgets('16. AddBillScreen pre-fills payer field with the first project member', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: sampleProject),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addExpenseFromProjectButton')));
      await tester.pumpAndSettle();

      // Payer field should be pre-filled with 'An'
      final state = tester.state<AddBillScreenState>(find.byType(AddBillScreen));
      expect(state.paidByController.text, equals('An'));
    });

    testWidgets('17. AddBillScreen pre-fills project members in state.projectMembers', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: sampleProject),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addExpenseFromProjectButton')));
      await tester.pumpAndSettle();

      final state = tester.state<AddBillScreenState>(find.byType(AddBillScreen));
      expect(state.projectMembers, equals(['An', 'Binh', 'Chi']));
      expect(state.selectedParticipants, containsAll(['An', 'Binh', 'Chi']));
    });

    // ── AC 7: Data Refresh ──
    testWidgets('18. ProjectDetailScreenState.refreshData() reloads bills and statistics', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: sampleProject),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      // Initially empty
      expect(find.text('No bills linked to this project yet'), findsOneWidget);

      // Now add a bill directly into repo
      await billRepo.create(sampleBill);

      // Call refreshData on screen state
      final detailState = tester.state<ProjectDetailScreenState>(find.byType(ProjectDetailScreen));
      detailState.refreshData();
      await tester.pumpAndSettle();

      // Should now show the bill!
      expect(find.text('Dinner at Beach'), findsOneWidget);
      expect(find.text('No bills linked to this project yet'), findsNothing);
    });

    testWidgets('19. Returning from AddBillScreen (pop) triggers data refresh', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: sampleProject),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      // Tap FAB to open AddBillScreen
      await tester.tap(find.byKey(const Key('addExpenseFromProjectButton')));
      await tester.pumpAndSettle();
      expect(find.byType(AddBillScreen), findsOneWidget);

      // Add a bill into repo while AddBillScreen is active
      await billRepo.create(sampleBill);

      // Pop AddBillScreen (e.g. back or after save)
      final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
      navigator.pop();
      await tester.pumpAndSettle();

      // Back on ProjectDetailScreen, it should have refreshed and display the new bill
      expect(find.byType(ProjectDetailScreen), findsOneWidget);
      expect(find.text('Dinner at Beach'), findsOneWidget);
    });

    testWidgets('20. Data refresh updates statistics tab with new total expense', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: sampleProject),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      // Open AddBillScreen
      await tester.tap(find.byKey(const Key('addExpenseFromProjectButton')));
      await tester.pumpAndSettle();

      // Add bill to repo
      await billRepo.create(sampleBill); // 600,000đ

      // Pop
      final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
      navigator.pop();
      await tester.pumpAndSettle();

      // Switch to Statistics tab
      await tester.tap(find.byKey(const Key('statisticsTab')));
      await tester.pumpAndSettle();

      // Summary card should show 600k
      expect(find.byKey(const Key('summaryCard')), findsOneWidget);
      expect(find.descendant(
        of: find.byKey(const Key('summaryCard')),
        matching: find.text('600kđ'),
      ), findsOneWidget);
    });

    // ── Edge Cases ──
    testWidgets('21. Project with single member pre-fills only that 1 member', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final soloProject = Project(
        id: 'proj-solo',
        name: 'Solo Trip',
        members: const ['SoloDev'],
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      );
      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: soloProject),
        projects: [soloProject],
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addExpenseFromProjectButton')));
      await tester.pumpAndSettle();

      final state = tester.state<AddBillScreenState>(find.byType(AddBillScreen));
      expect(state.projectMembers, equals(['SoloDev']));
      expect(state.paidByController.text, equals('SoloDev'));
    });

    testWidgets('22. Project with 5 members pre-fills all 5 members', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final bigProject = Project(
        id: 'proj-big',
        name: 'Family Gathering',
        members: const ['Mom', 'Dad', 'Son', 'Daughter', 'Dog'],
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      );
      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: bigProject),
        projects: [bigProject],
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addExpenseFromProjectButton')));
      await tester.pumpAndSettle();

      final state = tester.state<AddBillScreenState>(find.byType(AddBillScreen));
      expect(state.projectMembers, equals(['Mom', 'Dad', 'Son', 'Daughter', 'Dog']));
      expect(state.paidByController.text, equals('Mom'));
    });
  });
}
