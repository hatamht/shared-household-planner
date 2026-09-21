import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_filter.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/bills_list_screen.dart';
import 'package:shared_household_planner/features/split_bills/presentation/widgets/bill_card.dart';
import 'package:shared_household_planner/features/split_bills/presentation/widgets/stats_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test Helpers & Mock Repositories
// ─────────────────────────────────────────────────────────────────────────────

Bill createBill({
  required String id,
  required String title,
  required double amount,
  required String category,
  required DateTime date,
  required String paidBy,
  String? projectId,
  List<String> participantNames = const ['Alice', 'Bob'],
}) {
  return Bill(
    id: id,
    title: title,
    amount: amount,
    category: category,
    date: date,
    paidBy: paidBy,
    projectId: projectId,
    participants: participantNames
        .map((name) => BillParticipant(
              participantId: 'p_$name',
              name: name,
              amount: amount / participantNames.length,
            ))
        .toList(),
  );
}

Project createProject({
  required String id,
  required String name,
  int colorIndex = 0,
  int iconIndex = 0,
  String currency = 'VND',
}) {
  return Project(
    id: id,
    name: name,
    members: const ['Alice', 'Bob'],
    colorIndex: colorIndex,
    iconIndex: iconIndex,
    currency: currency,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

class _FakeBillRepo extends Fake implements BillRepository {
  List<Bill> bills = [];

  @override
  Future<Either<Failure, List<Bill>>> getAll() async => Right(bills);

  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(String projectId) async {
    return Right(bills.where((b) => b.projectId == projectId).toList());
  }

  @override
  Future<Either<Failure, Bill>> create(Bill bill) async {
    bills.add(bill);
    return Right(bill);
  }
}

class _FakeProjectRepo extends Fake implements ProjectRepository {
  List<Project> projects = [];

  @override
  Future<Either<Failure, List<Project>>> getAll() async => Right(projects);

  @override
  Future<Either<Failure, List<Project>>> getAllProjects() async => Right(projects);

  @override
  Future<Either<Failure, Project>> create(Project project) async {
    projects.add(project);
    return Right(project);
  }

  @override
  Future<Either<Failure, Project>> createProject(Project project) async {
    projects.add(project);
    return Right(project);
  }

  @override
  Future<Either<Failure, Project>> update(Project project) async {
    final idx = projects.indexWhere((p) => p.id == project.id);
    if (idx >= 0) projects[idx] = project;
    return Right(project);
  }

  @override
  Future<Either<Failure, Project>> updateProject(Project project) async {
    final idx = projects.indexWhere((p) => p.id == project.id);
    if (idx >= 0) projects[idx] = project;
    return Right(project);
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    projects.removeWhere((p) => p.id == id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteProject(String id) async {
    projects.removeWhere((p) => p.id == id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, Project>> getById(String id) async {
    return Right(projects.firstWhere((p) => p.id == id));
  }

  @override
  Future<Either<Failure, Project?>> getProjectById(String id) async {
    try {
      return Right(projects.firstWhere((p) => p.id == id));
    } catch (_) {
      return const Right(null);
    }
  }
}

class _TestLoc extends AppLocalizations {
  final Locale loc;
  _TestLoc(this.loc) : super(loc);

  static const _en = {
    'bills': 'Bills',
    'no_bills': 'No bills found',
    'no_matching_bills': 'No matching bills found',
    'clear_all_filters': 'Clear all filters',
    'group_by_project': 'Group by Project',
    'group_by_date': 'Group by Date',
    'all_projects': 'All Projects',
    'general_expenses': 'General Expenses',
    'filter_by_project': 'Filter by Project',
    'project_expense_total': 'Total',
    'no_bills_in_project': 'No expenses in this project',
    'bill_count_singular': '1 bill',
    'bill_count_plural': 'bills',
    'category_Home': 'Home',
    'category_Travel': 'Travel',
    'category_Food': 'Food',
    'participants': 'participants',
    'search_bills': 'Search bills',
    'error': 'Error',
  };

  static const _vi = {
    'bills': 'Hóa đơn',
    'no_bills': 'Không có hóa đơn nào',
    'no_matching_bills': 'Không tìm thấy hóa đơn phù hợp',
    'clear_all_filters': 'Xóa tất cả bộ lọc',
    'group_by_project': 'Nhóm theo Dự án',
    'group_by_date': 'Nhóm theo Ngày',
    'all_projects': 'Tất cả dự án',
    'general_expenses': 'Chi tiêu chung',
    'filter_by_project': 'Lọc theo Dự án',
    'project_expense_total': 'Tổng',
    'no_bills_in_project': 'Không có chi tiêu nào trong dự án này',
    'bill_count_singular': '1 hóa đơn',
    'bill_count_plural': 'hóa đơn',
    'category_Home': 'Nhà cửa',
    'category_Travel': 'Du lịch',
    'category_Food': 'Ăn uống',
    'participants': 'người tham gia',
    'search_bills': 'Tìm kiếm hóa đơn',
    'error': 'Lỗi',
  };

  @override
  String translate(String key) {
    if (loc.languageCode == 'vi') return _vi[key] ?? key;
    return _en[key] ?? key;
  }
}

class _TestLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestLocDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => _TestLoc(locale);
  @override
  bool shouldReload(_TestLocDelegate old) => false;
}

Widget buildTestWidget({
  required List<Bill> bills,
  List<Project> projects = const [],
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
  BillFilter? initialFilter,
  BillGroupingMode initialGroupingMode = BillGroupingMode.project,
}) {
  final billRepo = _FakeBillRepo()..bills = List.from(bills);
  final billsBloc = BillsBloc(
    getBillsUseCase: GetBillsUseCase(billRepo),
    addBillUseCase: AddBillUseCase(billRepo),
  );

  final projectRepo = _FakeProjectRepo()..projects = List.from(projects);
  final projectBloc = ProjectBloc(
    createProjectUseCase: CreateProjectUseCase(projectRepo),
    getAllProjectsUseCase: GetAllProjectsUseCase(projectRepo),
    updateProjectUseCase: UpdateProjectUseCase(projectRepo),
    deleteProjectUseCase: DeleteProjectUseCase(projectRepo),
  )..add(const GetAllProjects());

  return MultiBlocProvider(
    providers: [
      BlocProvider<BillsBloc>.value(value: billsBloc),
      BlocProvider<ProjectBloc>.value(value: projectBloc),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('vi')],
      localizationsDelegates: const [
        _TestLocDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeMode,
      home: BillsListScreen(
        initialFilter: initialFilter,
        initialGroupingMode: initialGroupingMode,
      ),
    ),
  );
}

void setLargeSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests Suite: Group & Filter Bills by Project (t58)
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  final projectA = createProject(id: 'proj_1', name: 'Apartment Renovation', colorIndex: 1, iconIndex: 0);
  final projectB = createProject(id: 'proj_2', name: 'Summer Trip', colorIndex: 2, iconIndex: 1);

  final billA1 = createBill(
    id: 'b1',
    title: 'Paint & Brushes',
    amount: 150.0,
    category: 'Home',
    date: DateTime(2026, 9, 10),
    paidBy: 'Alice',
    projectId: 'proj_1',
  );
  final billA2 = createBill(
    id: 'b2',
    title: 'Floor Tiles',
    amount: 350.0,
    category: 'Home',
    date: DateTime(2026, 9, 12),
    paidBy: 'Bob',
    projectId: 'proj_1',
  );
  final billB1 = createBill(
    id: 'b3',
    title: 'Hotel Booking',
    amount: 500.0,
    category: 'Travel',
    date: DateTime(2026, 9, 15),
    paidBy: 'Alice',
    projectId: 'proj_2',
  );
  final billGeneral = createBill(
    id: 'b4',
    title: 'Weekly Groceries',
    amount: 80.0,
    category: 'Food',
    date: DateTime(2026, 9, 18),
    paidBy: 'Bob',
    projectId: null,
  );

  final allTestBills = [billA1, billA2, billB1, billGeneral];
  final allTestProjects = [projectA, projectB];

  group('BillFilter entity - Project Filtering Logic', () {
    test('1. null or "all" selectedProjectId matches all bills', () {
      const filterNull = BillFilter(selectedProjectId: null);
      expect(filterNull.matches(billA1), isTrue);
      expect(filterNull.matches(billGeneral), isTrue);

      const filterAll = BillFilter(selectedProjectId: 'all');
      expect(filterAll.matches(billA1), isTrue);
      expect(filterAll.matches(billGeneral), isTrue);
    });

    test('2. specific selectedProjectId matches only bills with that projectId', () {
      const filterProj1 = BillFilter(selectedProjectId: 'proj_1');
      expect(filterProj1.matches(billA1), isTrue);
      expect(filterProj1.matches(billA2), isTrue);
      expect(filterProj1.matches(billB1), isFalse);
      expect(filterProj1.matches(billGeneral), isFalse);
    });

    test('3. "none" or "general" matches unassigned bills only', () {
      const filterNone = BillFilter(selectedProjectId: 'none');
      expect(filterNone.matches(billGeneral), isTrue);
      expect(filterNone.matches(billA1), isFalse);
      expect(filterNone.matches(billB1), isFalse);

      const filterGeneral = BillFilter(selectedProjectId: 'general');
      expect(filterGeneral.matches(billGeneral), isTrue);
      expect(filterGeneral.matches(billA1), isFalse);
    });

    test('4. isActive reflects selectedProjectId', () {
      expect(const BillFilter(selectedProjectId: null).isActive, isFalse);
      expect(const BillFilter(selectedProjectId: 'all').isActive, isFalse);
      expect(const BillFilter(selectedProjectId: '').isActive, isFalse);
      expect(const BillFilter(selectedProjectId: 'proj_1').isActive, isTrue);
      expect(const BillFilter(selectedProjectId: 'none').isActive, isTrue);
      expect(const BillFilter(selectedProjectId: 'general').isActive, isTrue);
    });

    test('5. activeFilterCount and nonTextFilterCount include selectedProjectId', () {
      const filter = BillFilter(selectedProjectId: 'proj_1');
      expect(filter.activeFilterCount, 1);
      expect(filter.nonTextFilterCount, 1);

      final combined = filter.copyWith(searchQuery: 'Paint', selectedCategories: {'Home'});
      expect(combined.activeFilterCount, 3);
      expect(combined.nonTextFilterCount, 2);
    });

    test('6. copyWith handles selectedProjectId and clearProject', () {
      const initial = BillFilter(selectedProjectId: 'proj_1');
      final updated = initial.copyWith(selectedProjectId: 'proj_2');
      expect(updated.selectedProjectId, 'proj_2');

      final cleared = updated.copyWith(clearProject: true);
      expect(cleared.selectedProjectId, isNull);
    });

    test('7. JSON serialization preserves selectedProjectId', () {
      const original = BillFilter(selectedProjectId: 'proj_1');
      final jsonMap = original.toJson();
      expect(jsonMap['selectedProjectId'], 'proj_1');

      final restored = BillFilter.fromJson(jsonMap);
      expect(restored.selectedProjectId, 'proj_1');
    });
  });

  group('BillsListScreen - Project Grouping & Section Headers', () {
    testWidgets('8. Groups bills by Project by default with dedicated headers', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(
        bills: allTestBills,
        projects: allTestProjects,
      ));
      await tester.pumpAndSettle();

      // Headers for projects
      expect(find.byKey(const Key('projectSectionHeader_proj_1')), findsOneWidget);
      expect(find.byKey(const Key('projectSectionHeader_proj_2')), findsOneWidget);
      expect(find.byKey(const Key('projectSectionHeader_general')), findsOneWidget);

      expect(find.text('Apartment Renovation'), findsWidgets);
      expect(find.text('Summer Trip'), findsWidgets);
      expect(find.text('General Expenses'), findsWidgets);
    });

    testWidgets('9. Project section header displays Project Name, Bill count, and Total amount', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(
        bills: allTestBills,
        projects: allTestProjects,
      ));
      await tester.pumpAndSettle();

      // Proj 1 has 2 bills: 150 + 350 = 500
      expect(find.text('2 bills'), findsOneWidget);
      expect(find.text('Total'), findsWidgets);
      expect(find.text('500đ'), findsWidgets);

      // Proj 2 has 1 bill: 500
      expect(find.text('1 bill'), findsWidgets);
    });

    testWidgets('10. Bills without project are grouped under General Expenses', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(
        bills: allTestBills,
        projects: allTestProjects,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectSectionHeader_none')), findsOneWidget);
      expect(find.text('Weekly Groceries'), findsOneWidget);
    });

    testWidgets('11. Each BillCard renders project badge with icon and name', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(
        bills: allTestBills,
        projects: allTestProjects,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectBadge_b1')), findsOneWidget);
      expect(find.byKey(const Key('projectBadge_b2')), findsOneWidget);
      expect(find.byKey(const Key('projectBadge_b3')), findsOneWidget);
      expect(find.byKey(const Key('projectBadge_b4')), findsOneWidget);
    });
  });

  group('BillsListScreen - Project Filter Chips Bar', () {
    testWidgets('12. Renders All Projects, Project, and General Expenses chips', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(
        bills: allTestBills,
        projects: allTestProjects,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectFilterChipsBar')), findsOneWidget);
      expect(find.byKey(const Key('projectFilterChip_all')), findsOneWidget);
      expect(find.byKey(const Key('projectFilterChip_proj_1')), findsOneWidget);
      expect(find.byKey(const Key('projectFilterChip_proj_2')), findsOneWidget);
      expect(find.byKey(const Key('projectFilterChip_none')), findsOneWidget);
    });

    testWidgets('13. Tapping a project chip filters list to only that project', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(
        bills: allTestBills,
        projects: allTestProjects,
      ));
      await tester.pumpAndSettle();

      // Tap Apartment Renovation chip
      await tester.tap(find.byKey(const Key('projectFilterChip_proj_1')));
      await tester.pumpAndSettle();

      expect(find.text('Paint & Brushes'), findsOneWidget);
      expect(find.text('Floor Tiles'), findsOneWidget);
      expect(find.text('Hotel Booking'), findsNothing);
      expect(find.text('Weekly Groceries'), findsNothing);
    });

    testWidgets('14. Tapping General Expenses chip filters list to unassigned bills', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(
        bills: allTestBills,
        projects: allTestProjects,
      ));
      await tester.pumpAndSettle();

      // Tap General Expenses chip
      await tester.tap(find.byKey(const Key('projectFilterChip_none')));
      await tester.pumpAndSettle();

      expect(find.text('Weekly Groceries'), findsOneWidget);
      expect(find.text('Paint & Brushes'), findsNothing);
      expect(find.text('Floor Tiles'), findsNothing);
      expect(find.text('Hotel Booking'), findsNothing);
    });

    testWidgets('15. Tapping All Projects chip restores all bills', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(
        bills: allTestBills,
        projects: allTestProjects,
      ));
      await tester.pumpAndSettle();

      // Filter by proj_1
      await tester.tap(find.byKey(const Key('projectFilterChip_proj_1')));
      await tester.pumpAndSettle();
      expect(find.text('Hotel Booking'), findsNothing);

      // Tap All Projects
      await tester.tap(find.byKey(const Key('projectFilterChip_all')));
      await tester.pumpAndSettle();

      expect(find.text('Paint & Brushes'), findsOneWidget);
      expect(find.text('Floor Tiles'), findsOneWidget);
      expect(find.text('Hotel Booking'), findsOneWidget);
      expect(find.text('Weekly Groceries'), findsOneWidget);
    });

    testWidgets('16. Tapping an already selected chip toggles it off', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(
        bills: allTestBills,
        projects: allTestProjects,
      ));
      await tester.pumpAndSettle();

      // Select proj_2
      await tester.tap(find.byKey(const Key('projectFilterChip_proj_2')));
      await tester.pumpAndSettle();
      expect(find.text('Hotel Booking'), findsOneWidget);
      expect(find.text('Paint & Brushes'), findsNothing);

      // Tap proj_2 again to deselect
      await tester.tap(find.byKey(const Key('projectFilterChip_proj_2')));
      await tester.pumpAndSettle();

      expect(find.text('Paint & Brushes'), findsOneWidget);
      expect(find.text('Hotel Booking'), findsOneWidget);
    });
  });

  group('BillsListScreen - Grouping Mode Toggle', () {
    testWidgets('17. Grouping mode toggle buttons exist with correct keys', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(
        bills: allTestBills,
        projects: allTestProjects,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('groupByProjectToggle')), findsOneWidget);
      expect(find.byKey(const Key('groupByDateToggle')), findsOneWidget);
    });

    testWidgets('18. Switching to Group by Date renders month headers and StatsCard', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(
        bills: allTestBills,
        projects: allTestProjects,
      ));
      await tester.pumpAndSettle();

      // Initially in Project grouping mode: no StatsCard
      expect(find.byType(StatsCard), findsNothing);

      // Tap Group by Date toggle
      await tester.tap(find.byKey(const Key('groupByDateToggle')));
      await tester.pumpAndSettle();

      // In Date grouping mode: StatsCard is rendered
      expect(find.byType(StatsCard), findsOneWidget);
      expect(find.text('Sep 2026'), findsOneWidget);

      // Bills are still rendered
      expect(find.text('Paint & Brushes'), findsOneWidget);
      expect(find.text('Floor Tiles'), findsOneWidget);
      expect(find.text('Hotel Booking'), findsOneWidget);
      expect(find.text('Weekly Groceries'), findsOneWidget);
    });

    testWidgets('19. Switching back to Group by Project restores section headers', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(
        bills: allTestBills,
        projects: allTestProjects,
      ));
      await tester.pumpAndSettle();

      // Switch to Date
      await tester.tap(find.byKey(const Key('groupByDateToggle')));
      await tester.pumpAndSettle();
      expect(find.byType(StatsCard), findsOneWidget);

      // Switch back to Project
      await tester.tap(find.byKey(const Key('groupByProjectToggle')));
      await tester.pumpAndSettle();

      expect(find.byType(StatsCard), findsNothing);
      expect(find.byKey(const Key('projectSectionHeader_proj_1')), findsOneWidget);
    });
  });

  group('BillsListScreen - Empty State & Edge Cases', () {
    testWidgets('20. Empty state is shown when filter yields no bills', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(
        bills: allTestBills,
        projects: allTestProjects,
      ));
      await tester.pumpAndSettle();

      // Search non-existent
      await tester.enterText(find.byKey(const Key('searchBillsTextField')), 'NonExistentXYZ');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('noMatchingBillsEmptyState')), findsOneWidget);
      expect(find.byKey(const Key('clearFiltersEmptyStateButton')), findsOneWidget);
    });

    testWidgets('21. Clearing filters from empty state restores project groups', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(
        bills: allTestBills,
        projects: allTestProjects,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('searchBillsTextField')), 'NonExistentXYZ');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('noMatchingBillsEmptyState')), findsOneWidget);

      await tester.tap(find.byKey(const Key('clearFiltersEmptyStateButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('noMatchingBillsEmptyState')), findsNothing);
      expect(find.byKey(const Key('projectSectionHeader_proj_1')), findsOneWidget);
    });

    testWidgets('22. Empty bills list renders standard no bills message', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(
        bills: [],
        projects: allTestProjects,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No bills found'), findsOneWidget);
    });
  });

  group('BillsListScreen - Localization & Theming', () {
    testWidgets('23. Vietnamese locale displays Vietnamese labels and headers', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(
        bills: allTestBills,
        projects: allTestProjects,
        locale: const Locale('vi'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tất cả dự án'), findsOneWidget);
      expect(find.text('Chi tiêu chung'), findsWidgets);
      expect(find.text('Nhóm theo Dự án'), findsOneWidget);
      expect(find.text('Nhóm theo Ngày'), findsOneWidget);
      expect(find.text('Tổng'), findsWidgets);
      expect(find.text('500đ'), findsWidgets);
    });

    testWidgets('24. Dark theme renders correctly without overflow', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(
        bills: allTestBills,
        projects: allTestProjects,
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectSectionHeader_proj_1')), findsOneWidget);
      expect(find.byKey(const Key('projectFilterChipsBar')), findsOneWidget);
    });

    testWidgets('25. Light theme renders correctly without overflow', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(
        bills: allTestBills,
        projects: allTestProjects,
        themeMode: ThemeMode.light,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectSectionHeader_proj_1')), findsOneWidget);
      expect(find.byKey(const Key('projectFilterChipsBar')), findsOneWidget);
    });
  });
}
