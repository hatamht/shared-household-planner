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
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/bills_list_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test Helpers & Mocks
// ─────────────────────────────────────────────────────────────────────────────

Bill createBill({
  required String id,
  required String title,
  required double amount,
  required String category,
  required DateTime date,
  required String paidBy,
  String? projectId,
  String splitMode = 'equal',
  List<String> images = const [],
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
    splitMode: splitMode,
    imagePaths: images,
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
}) {
  return Project(
    id: id,
    name: name,
    members: const ['Alice', 'Bob'],
    colorIndex: colorIndex,
    iconIndex: iconIndex,
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
  Future<Either<Failure, Project>> create(Project project) async {
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
  Future<Either<Failure, void>> delete(String id) async {
    projects.removeWhere((p) => p.id == id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, Project>> getById(String id) async {
    return Right(projects.firstWhere((p) => p.id == id));
  }
}

class _AccordionTestLoc extends AppLocalizations {
  final Locale loc;
  _AccordionTestLoc(this.loc) : super(loc);

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
    'expand_all': 'Expand All',
    'collapse_all': 'Collapse All',
    'tap_to_expand': 'Tap to expand',
    'tap_to_collapse': 'Tap to collapse',
    'category_Home': 'Home',
    'category_Food': 'Food',
    'category_Utilities': 'Utilities',
    'participants': 'participants',
    'bill_detail': 'Bill Details',
    'save_as_template': 'Save as Template',
    'edit_bill': 'Edit Bill',
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
    'project_expense_total': 'Tổng cộng',
    'no_bills_in_project': 'Chưa có chi tiêu trong dự án này',
    'bill_count_singular': '1 hóa đơn',
    'bill_count_plural': 'hóa đơn',
    'expand_all': 'Mở rộng tất cả',
    'collapse_all': 'Thu gọn tất cả',
    'tap_to_expand': 'Chạm để mở rộng',
    'tap_to_collapse': 'Chạm để thu gọn',
    'category_Home': 'Nhà cửa',
    'category_Food': 'Ăn uống',
    'category_Utilities': 'Hóa đơn',
    'participants': 'người tham gia',
    'bill_detail': 'Chi tiết hóa đơn',
    'save_as_template': 'Lưu làm mẫu',
    'edit_bill': 'Sửa hóa đơn',
  };

  @override
  String translate(String key) {
    if (loc.languageCode == 'vi') return _vi[key] ?? key;
    return _en[key] ?? key;
  }
}

class _AccordionTestLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AccordionTestLocDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => _AccordionTestLoc(locale);
  @override
  bool shouldReload(_AccordionTestLocDelegate old) => false;
}

Widget buildTestWidget({
  required List<Bill> bills,
  List<Project> projects = const [],
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
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
        _AccordionTestLocDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeMode,
      home: const BillsListScreen(),
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
// Tests: Animated Expand/Collapse & BillCard Polish (t59)
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  final projectA = createProject(id: 'proj_A', name: 'Apartment Upgrade', colorIndex: 1, iconIndex: 0);
  final projectB = createProject(id: 'proj_B', name: 'Long Long Long Long Extended Project Name Tag', colorIndex: 3, iconIndex: 2);

  final billA1 = createBill(
    id: 'bA1',
    title: 'New Sofa',
    amount: 14000.0,
    category: 'Home',
    date: DateTime(2026, 9, 1),
    paidBy: 'Alice',
    projectId: 'proj_A',
  );
  final billA2 = createBill(
    id: 'bA2',
    title: 'Paint Rollers',
    amount: 100000000.0,
    category: 'Home',
    date: DateTime(2026, 9, 2),
    paidBy: 'Bob',
    projectId: 'proj_A',
  );
  final billB1 = createBill(
    id: 'bB1',
    title: 'Trip Snacks',
    amount: 450000.0,
    category: 'Food',
    date: DateTime(2026, 9, 5),
    paidBy: 'Alice',
    projectId: 'proj_B',
    splitMode: 'percent',
  );
  final billGeneral = createBill(
    id: 'bGen',
    title: 'Internet Bill',
    amount: 250000.0,
    category: 'Utilities',
    date: DateTime(2026, 9, 8),
    paidBy: 'Bob',
    projectId: null,
  );

  final allBills = [billA1, billA2, billB1, billGeneral];
  final allProjects = [projectA, projectB];

  group('AC 1 & 2: Animated Expand/Collapse on Section Header Tap', () {
    testWidgets('1. All project sections are initially expanded by default', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(bills: allBills, projects: allProjects));
      await tester.pumpAndSettle();

      expect(find.text('New Sofa'), findsOneWidget);
      expect(find.text('Paint Rollers'), findsOneWidget);
      expect(find.text('Trip Snacks'), findsOneWidget);
      expect(find.text('Internet Bill'), findsOneWidget);
    });

    testWidgets('2. Section header has rotating chevron arrow with projectChevron key', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(bills: allBills, projects: allProjects));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectChevron_proj_A')), findsOneWidget);
      expect(find.byKey(const Key('projectChevron_proj_B')), findsOneWidget);
      expect(find.byKey(const Key('projectChevron_general')), findsOneWidget);
    });

    testWidgets('3. Tapping Section Header collapses its bills list with AnimatedSize', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(bills: allBills, projects: allProjects));
      await tester.pumpAndSettle();

      expect(find.text('New Sofa'), findsOneWidget);

      // Tap header for proj_A to collapse
      await tester.tap(find.byKey(const Key('projectSectionHeader_proj_A')));
      // Advance by 100ms: animation in progress
      await tester.pump(const Duration(milliseconds: 100));
      // Settle animation (completes 300ms easeInOut)
      await tester.pumpAndSettle();

      // proj_A bills are collapsed
      expect(find.text('New Sofa'), findsNothing);
      expect(find.text('Paint Rollers'), findsNothing);

      // Other sections remain expanded
      expect(find.text('Trip Snacks'), findsOneWidget);
      expect(find.text('Internet Bill'), findsOneWidget);
    });

    testWidgets('4. Tapping collapsed Section Header expands it back with smooth animation', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(bills: allBills, projects: allProjects));
      await tester.pumpAndSettle();

      // Collapse proj_A
      await tester.tap(find.byKey(const Key('projectSectionHeader_proj_A')));
      await tester.pumpAndSettle();
      expect(find.text('New Sofa'), findsNothing);

      // Tap again to expand
      await tester.tap(find.byKey(const Key('projectSectionHeader_proj_A')));
      await tester.pumpAndSettle();

      expect(find.text('New Sofa'), findsOneWidget);
      expect(find.text('Paint Rollers'), findsOneWidget);
    });

    testWidgets('5. Tapping General Expenses section header collapses and expands unassigned bills', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(bills: allBills, projects: allProjects));
      await tester.pumpAndSettle();

      expect(find.text('Internet Bill'), findsOneWidget);

      // Tap General Expenses header
      await tester.tap(find.byKey(const Key('projectSectionHeader_general')));
      await tester.pumpAndSettle();
      expect(find.text('Internet Bill'), findsNothing);

      // Tap again to expand
      await tester.tap(find.byKey(const Key('projectSectionHeader_general')));
      await tester.pumpAndSettle();
      expect(find.text('Internet Bill'), findsOneWidget);
    });
  });

  group('AC 3: Expand All & Collapse All Quick Toggle', () {
    testWidgets('6. Quick toggle button exists with expandCollapseAllButton key', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(bills: allBills, projects: allProjects));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('expandCollapseAllButton')), findsOneWidget);
      expect(find.byKey(const Key('collapseAllButton')), findsOneWidget);
      expect(find.text('Collapse All'), findsOneWidget);
    });

    testWidgets('7. Tapping Collapse All collapses all sections at once', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(bills: allBills, projects: allProjects));
      await tester.pumpAndSettle();

      // Tap Collapse All
      await tester.tap(find.byKey(const Key('expandCollapseAllButton')));
      await tester.pumpAndSettle();

      // All bills are hidden
      expect(find.text('New Sofa'), findsNothing);
      expect(find.text('Paint Rollers'), findsNothing);
      expect(find.text('Trip Snacks'), findsNothing);
      expect(find.text('Internet Bill'), findsNothing);

      // Button updates label and key to Expand All
      expect(find.byKey(const Key('expandAllButton')), findsOneWidget);
      expect(find.text('Expand All'), findsOneWidget);
    });

    testWidgets('8. Tapping Expand All restores all bill lists', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(bills: allBills, projects: allProjects));
      await tester.pumpAndSettle();

      // Collapse all
      await tester.tap(find.byKey(const Key('expandCollapseAllButton')));
      await tester.pumpAndSettle();
      expect(find.text('New Sofa'), findsNothing);

      // Expand all
      await tester.tap(find.byKey(const Key('expandCollapseAllButton')));
      await tester.pumpAndSettle();

      expect(find.text('New Sofa'), findsOneWidget);
      expect(find.text('Paint Rollers'), findsOneWidget);
      expect(find.text('Trip Snacks'), findsOneWidget);
      expect(find.text('Internet Bill'), findsOneWidget);
    });
  });

  group('AC 4 & 5: BillCard Overflow Fix & Amount Formatting', () {
    testWidgets('9. Formats amounts with thousand separators (e.g. 100,000,000 đ and 14,000 đ)', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(bills: allBills, projects: allProjects));
      await tester.pumpAndSettle();

      // 14000 formatted with thousand separators
      expect(find.text('14,000 đ'), findsOneWidget);
      // 100000000 formatted with thousand separators
      expect(find.text('100,000,000 đ'), findsOneWidget);
      // 450000 formatted with thousand separators
      expect(find.text('450,000 đ'), findsOneWidget);
      // 250000 formatted with thousand separators
      expect(find.text('250,000 đ'), findsOneWidget);
    });

    testWidgets('10. Renders BillCard without RenderFlex bottom overflow on standard mobile viewport', (tester) async {
      // Standard mobile portrait size 390x844 (iPhone 14)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget(bills: [billA2], projects: [projectA]));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Paint Rollers'), findsOneWidget);
      expect(find.text('100,000,000 đ'), findsOneWidget);
    });

    testWidgets('11. BillCard with splitMode, receipt, and projectBadge renders cleanly without overflow', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget(bills: [billB1], projects: [projectB]));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('splitModeChip_bB1')), findsOneWidget);
      expect(find.byKey(const Key('projectBadge_bB1')), findsOneWidget);
    });
  });

  group('AC 6: Long Project Name Graceful Wrapping & Truncation', () {
    testWidgets('12. BillCard with long project name does not overflow horizontally', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget(bills: [billB1], projects: [projectB]));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('projectBadge_bB1')), findsOneWidget);
    });

    testWidgets('13. Project badge restricts text width with ellipsis truncation', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(bills: [billB1], projects: [projectB]));
      await tester.pumpAndSettle();

      final badgeFinder = find.byKey(const Key('projectBadge_bB1'));
      expect(badgeFinder, findsOneWidget);

      final constrainedBox = find.descendant(
        of: badgeFinder,
        matching: find.byType(ConstrainedBox),
      );
      expect(constrainedBox, findsOneWidget);
    });
  });

  group('AC 8: Theming & Ink Ripple Feedback', () {
    testWidgets('14. Section header provides InkWell with projectSectionHeaderInk key', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(bills: allBills, projects: allProjects));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectSectionHeaderInk_proj_A')), findsOneWidget);
      expect(find.byKey(const Key('projectSectionHeaderInk_proj_B')), findsOneWidget);
      expect(find.byKey(const Key('projectSectionHeaderInk_general')), findsOneWidget);
    });

    testWidgets('15. Dark theme renders expand/collapse headers without overflow', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(
        bills: allBills,
        projects: allProjects,
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('projectSectionHeader_proj_A')), findsOneWidget);
    });

    testWidgets('16. Light theme renders expand/collapse headers without overflow', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(
        bills: allBills,
        projects: allProjects,
        themeMode: ThemeMode.light,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('projectSectionHeader_proj_A')), findsOneWidget);
    });
  });

  group('AC 9: Localization (Vietnamese & English)', () {
    testWidgets('17. Vietnamese locale renders "Mở rộng tất cả" and "Thu gọn tất cả"', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(
        bills: allBills,
        projects: allProjects,
        locale: const Locale('vi'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Thu gọn tất cả'), findsOneWidget);

      // Tap to collapse all
      await tester.tap(find.byKey(const Key('expandCollapseAllButton')));
      await tester.pumpAndSettle();

      expect(find.text('Mở rộng tất cả'), findsOneWidget);
    });

    testWidgets('18. Vietnamese locale formats amounts properly with đ', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(
        bills: allBills,
        projects: allProjects,
        locale: const Locale('vi'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('14,000 đ'), findsOneWidget);
      expect(find.text('100,000,000 đ'), findsOneWidget);
    });
  });

  group('Edge Cases & State Preservation', () {
    testWidgets('19. Switching to Date grouping hides project accordion and quick toggle', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(bills: allBills, projects: allProjects));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('expandCollapseAllButton')), findsOneWidget);

      // Switch to date
      await tester.tap(find.byKey(const Key('groupByDateToggle')));
      await tester.pumpAndSettle();

      // Quick toggle is hidden in date grouping mode
      expect(find.byKey(const Key('expandCollapseAllButton')), findsNothing);
    });

    testWidgets('20. Switching back to Project grouping retains collapsed states', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(bills: allBills, projects: allProjects));
      await tester.pumpAndSettle();

      // Collapse proj_A
      await tester.tap(find.byKey(const Key('projectSectionHeader_proj_A')));
      await tester.pumpAndSettle();
      expect(find.text('New Sofa'), findsNothing);

      // Switch to Date
      await tester.tap(find.byKey(const Key('groupByDateToggle')));
      await tester.pumpAndSettle();

      // Switch back to Project
      await tester.tap(find.byKey(const Key('groupByProjectToggle')));
      await tester.pumpAndSettle();

      // proj_A remains collapsed
      expect(find.text('New Sofa'), findsNothing);
      expect(find.text('Trip Snacks'), findsOneWidget);
    });

    testWidgets('21. Filtering to single project keeps only that section and supports expand/collapse', (tester) async {
      setLargeSurface(tester);
      await tester.pumpWidget(buildTestWidget(bills: allBills, projects: allProjects));
      await tester.pumpAndSettle();

      // Filter by proj_A
      await tester.tap(find.byKey(const Key('projectFilterChip_proj_A')));
      await tester.pumpAndSettle();

      expect(find.text('New Sofa'), findsOneWidget);
      expect(find.text('Trip Snacks'), findsNothing);

      // Collapse proj_A
      await tester.tap(find.byKey(const Key('projectSectionHeader_proj_A')));
      await tester.pumpAndSettle();
      expect(find.text('New Sofa'), findsNothing);
    });
  });
}
