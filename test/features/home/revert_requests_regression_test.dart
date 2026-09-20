import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartz/dartz.dart';

import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/core/theme/app_theme.dart';
import 'package:shared_household_planner/features/home/presentation/pages/home_screen.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_project_by_id_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/project_detail_screen.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/bills_list_screen.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/add_bill_screen.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/bill_detail_screen.dart';
import 'package:shared_household_planner/features/statistics/presentation/pages/statistics_screen.dart';
import 'package:shared_household_planner/features/settings/presentation/pages/settings_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fakes & Mocks
// ─────────────────────────────────────────────────────────────────────────────

class FakeProjectRepo implements ProjectRepository {
  List<Project> list = [];
  bool deleteCalled = false;

  FakeProjectRepo([List<Project>? initial]) : list = initial != null ? List.from(initial) : [];

  @override
  Future<Either<Failure, Project>> create(Project project) async {
    list.add(project);
    return Right(project);
  }

  @override
  Future<Either<Failure, List<Project>>> getAll() async => Right(list);

  @override
  Future<Either<Failure, Project>> getById(String id) async {
    final p = list.firstWhere((e) => e.id == id, orElse: () => throw Exception('not found'));
    return Right(p);
  }

  @override
  Future<Either<Failure, Project>> update(Project project) async {
    final idx = list.indexWhere((p) => p.id == project.id);
    if (idx >= 0) list[idx] = project;
    return Right(project);
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    deleteCalled = true;
    list.removeWhere((e) => e.id == id);
    return const Right(null);
  }
}

class FakeBillRepo implements BillRepository {
  List<Bill> list = [];

  FakeBillRepo([List<Bill>? initial]) : list = initial != null ? List.from(initial) : [];

  @override
  Future<Either<Failure, Bill>> create(Bill bill) async {
    list.add(bill);
    return Right(bill);
  }

  @override
  Future<Either<Failure, List<Bill>>> getAll() async => Right(list);

  @override
  Future<Either<Failure, Bill>> getById(String billId) async => Right(list.firstWhere((b) => b.id == billId));

  @override
  Future<Either<Failure, Bill>> update(Bill bill) async {
    final idx = list.indexWhere((b) => b.id == bill.id);
    if (idx >= 0) list[idx] = bill;
    return Right(bill);
  }

  @override
  Future<Either<Failure, void>> delete(String billId) async {
    list.removeWhere((b) => b.id == billId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(String projectId) async {
    return Right(list.where((b) => b.projectId == projectId).toList());
  }
}

class TestLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  final String lang;
  const TestLocDelegate([this.lang = 'en']);

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async => _MockLoc(Locale(lang));

  @override
  bool shouldReload(TestLocDelegate old) => false;
}

class _MockLoc extends AppLocalizations {
  _MockLoc(super.locale);

  static const _en = <String, String>{
    'app_name': 'Shared Household Planner',
    'projects': 'Projects',
    'requests': 'Requests',
    'settings': 'Settings',
    'profile': 'Profile',
    'statistics': 'Statistics',
    'statistics_charts': 'Statistics & Charts',
    'no_stats_data': 'No expense data for this period',
    'split_bills': 'Split Bills',
    'all_projects': 'All Projects',
    'overview': 'Overview',
    'no_projects': 'No projects yet',
    'create_first_project_prompt': 'Create your first project to start tracking shared expenses!',
    'add_project': 'Add Project',
    'create_project': 'Create Project',
    'edit_project': 'Edit Project',
    'leave_project': 'Leave Project',
    'delete_project': 'Delete Project',
    'delete_project_confirm': 'Are you sure you want to delete this project?',
    'delete': 'Delete',
    'cancel': 'Cancel',
    'total_members': 'Total Members',
    'total_bills_count': 'Total Bills',
    'total_spent': 'Total Spent',
    'preferences': 'Preferences',
    'language': 'Language',
    'english': 'English',
    'vietnamese': 'Vietnamese',
    'theme': 'Theme',
    'light_mode': 'Light',
    'dark_mode': 'Dark',
    'theme_light': 'Light Theme',
    'theme_dark': 'Dark Theme',
    'theme_settings': 'Theme Settings',
    'loading': 'Loading...',
    'error': 'Error',
    'members': 'Members',
    'bills': 'Bills',
    'bills_tab': 'Bills',
    'settlement_tab': 'Settlement',
    'statistics_tab': 'Statistics',
    'no_bills': 'No bills yet',
    'search_bills': 'Search bills...',
    'filter': 'Filter',
    'add_bill': 'Add Bill',
    'title': 'Title',
    'amount': 'Amount',
    'save': 'Save',
    'save_bill': 'Save Bill',
    'bill_details': 'Bill Details',
    'bill_name_required': 'Bill name is required',
    'split_mode': 'Split Mode',
    'equal': 'Equal',
    'percentage': 'Percentage',
    'shares': 'Shares',
    'custom': 'Custom',
    'split_mode_equal': 'Equal',
    'split_mode_percentage': 'Percentage',
    'split_mode_shares': 'Shares',
    'split_mode_custom': 'Custom',
  };

  @override
  String translate(String key) => _en[key] ?? key;
}

Project sampleProject({
  String id = 'p1',
  String name = 'Main Home',
  List<String>? members,
  String? description,
}) {
  return Project(
    id: id,
    name: name,
    members: members ?? ['Alice', 'Bob'],
    description: description,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Bill sampleBill({
  String id = 'b1',
  String title = 'Groceries',
  double amount = 50.0,
  String? projectId = 'p1',
}) {
  return Bill(
    id: id,
    title: title,
    amount: amount,
    category: 'Groceries',
    date: DateTime(2026, 1, 2),
    paidBy: 'Alice',
    participants: const [
      BillParticipant(participantId: 'p1', name: 'Alice', amount: 25.0),
      BillParticipant(participantId: 'p2', name: 'Bob', amount: 25.0),
    ],
    projectId: projectId,
  );
}

Widget buildTestApp({
  List<Project>? initialProjects,
  List<Bill>? initialBills,
  Widget? child,
  ThemeProvider? themeProvider,
  LanguageProvider? langProvider,
}) {
  final pRepo = FakeProjectRepo(initialProjects);
  final bRepo = FakeBillRepo(initialBills);

  final pBloc = ProjectBloc(
    createProjectUseCase: CreateProjectUseCase(pRepo),
    getAllProjectsUseCase: GetAllProjectsUseCase(pRepo),
    getProjectByIdUseCase: GetProjectByIdUseCase(pRepo),
    updateProjectUseCase: UpdateProjectUseCase(pRepo),
    deleteProjectUseCase: DeleteProjectUseCase(pRepo),
  );
  if (initialProjects != null && initialProjects.isNotEmpty) {
    pBloc.emit(ProjectLoaded(projects: initialProjects));
  } else {
    pBloc.emit(const ProjectLoaded(projects: []));
  }

  final bBloc = BillsBloc(
    getBillsUseCase: GetBillsUseCase(bRepo),
    addBillUseCase: AddBillUseCase(bRepo),
  );
  if (initialBills != null && initialBills.isNotEmpty) {
    bBloc.emit(BillsLoaded(bills: initialBills));
  } else {
    bBloc.emit(const BillsLoaded(bills: []));
  }

  Widget effectiveChild = child ?? const HomeScreen();
  if (effectiveChild is AddBillScreen && effectiveChild.initialCompactMode == null) {
    effectiveChild = AddBillScreen(
      key: effectiveChild.key,
      billToEdit: effectiveChild.billToEdit,
      projectId: effectiveChild.projectId,
      requireProject: effectiveChild.requireProject,
      projectSettings: effectiveChild.projectSettings,
      template: effectiveChild.template,
      initialImagePath: effectiveChild.initialImagePath,
      initialImagePaths: effectiveChild.initialImagePaths,
      onPickImage: effectiveChild.onPickImage,
      onPickMultipleImages: effectiveChild.onPickMultipleImages,
      projectName: effectiveChild.projectName,
      initialCompactMode: false,
    );
  }

  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<ProjectRepository>.value(value: pRepo),
      RepositoryProvider<BillRepository>.value(value: bRepo),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<ProjectBloc>.value(value: pBloc),
        BlocProvider<BillsBloc>.value(value: bBloc),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(
            value: themeProvider ?? ThemeProvider(),
          ),
          ChangeNotifierProvider<LanguageProvider>.value(
            value: langProvider ?? LanguageProvider(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            TestLocDelegate('en'),
          ],
          routes: {
            '/bills': (_) => const Scaffold(body: BillsListScreen()),
            '/projects': (_) => const HomeScreen(),
          },
          home: effectiveChild,
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en', null);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Group 1: Navigation & Tabs Revert Verification (12 tests)
  // ───────────────────────────────────────────────────────────────────────────
  group('1. Navigation & Tabs Revert Verification', () {
    testWidgets('1.1 HomeScreen renders exactly 4 bottom navigation items', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final nav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(nav.items.length, 4);
    });

    testWidgets('1.2 Tab 0 default is Projects overview', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('statsSummaryCard')), findsOneWidget);
    });

    testWidgets('1.3 Tab 1 directly renders BillsListScreen', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Requests')); // Tab 1 label in bottom nav
      await tester.pumpAndSettle();

      expect(find.byType(BillsListScreen), findsOneWidget);
    });

    testWidgets('1.4 Tab 1 has NO requestsTabSegmentedButton', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('requestsTabSegmentedButton')), findsNothing);
    });

    testWidgets('1.5 Tab 1 has NO request list screen embedded', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('requestListScreen')), findsNothing);
    });

    testWidgets('1.6 Tab 2 switches view to StatisticsScreen', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();

      expect(find.byType(StatisticsScreen), findsOneWidget);
    });

    testWidgets('1.7 Tab 3 switches view to SettingsScreen', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('1.8 FAB on Tab 0 has key addProjectButton', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('addProjectButton')), findsOneWidget);
    });

    testWidgets('1.9 FAB on Tab 1 exists and no request FAB', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('1.10 No addRequestFab exists on Tab 1', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('addRequestFab')), findsNothing);
    });

    testWidgets('1.11 FAB is hidden on Tab 2 (Statistics)', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('1.12 FAB is hidden on Tab 3 (Settings)', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Group 2: Project Card Revert Verification (10 tests)
  // ───────────────────────────────────────────────────────────────────────────
  group('2. Project Card Revert Verification', () {
    testWidgets('2.1 Project card has NO projectRequestBadge', (tester) async {
      final p1 = sampleProject(id: 'p1', name: 'Alpha House');
      await tester.pumpWidget(buildTestApp(initialProjects: [p1]));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectRequestBadge_p1')), findsNothing);
    });

    testWidgets('2.2 Project card has NO projectRequestCount', (tester) async {
      final p1 = sampleProject(id: 'p1', name: 'Alpha House');
      await tester.pumpWidget(buildTestApp(initialProjects: [p1]));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectRequestCount_p1')), findsNothing);
    });

    testWidgets('2.3 Project card displays clean statsText', (tester) async {
      final p1 = sampleProject(id: 'p1', name: 'Alpha House');
      await tester.pumpWidget(buildTestApp(initialProjects: [p1]));
      await tester.pumpAndSettle();

      expect(find.text('2 members, 0 bills, €0.00 total'), findsOneWidget);
    });

    testWidgets('2.4 Project context menu has NO viewProjectRequests option', (tester) async {
      final p1 = sampleProject(id: 'p1', name: 'Alpha House');
      await tester.pumpWidget(buildTestApp(initialProjects: [p1]));
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('projectCard_p1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('viewProjectRequests_p1')), findsNothing);
    });

    testWidgets('2.5 Project context menu retains Edit Project', (tester) async {
      final p1 = sampleProject(id: 'p1', name: 'Alpha House');
      await tester.pumpWidget(buildTestApp(initialProjects: [p1]));
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('projectCard_p1')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Project'), findsOneWidget);
    });

    testWidgets('2.6 Project context menu retains Leave Project', (tester) async {
      final p1 = sampleProject(id: 'p1', name: 'Alpha House');
      await tester.pumpWidget(buildTestApp(initialProjects: [p1]));
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('projectCard_p1')));
      await tester.pumpAndSettle();

      expect(find.text('Leave Project'), findsOneWidget);
    });

    testWidgets('2.7 Project context menu retains Delete Project', (tester) async {
      final p1 = sampleProject(id: 'p1', name: 'Alpha House');
      await tester.pumpWidget(buildTestApp(initialProjects: [p1]));
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('projectCard_p1')));
      await tester.pumpAndSettle();

      expect(find.text('Delete Project'), findsOneWidget);
    });

    testWidgets('2.8 ProjectDetailScreen has NO projectRequestsButton', (tester) async {
      final p1 = sampleProject(id: 'p1', name: 'Alpha House');
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: p1),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectRequestsButton')), findsNothing);
    });

    testWidgets('2.9 ProjectDetailScreen displays project name in AppBar', (tester) async {
      final p1 = sampleProject(id: 'p1', name: 'Alpha House');
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: p1),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Alpha House'), findsWidgets);
    });

    testWidgets('2.10 ProjectDetailScreen shows tabs Bills, Settlement, Statistics', (tester) async {
      final p1 = sampleProject(id: 'p1', name: 'Alpha House');
      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: p1),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('billsTab')), findsOneWidget);
      expect(find.byKey(const Key('settlementTab')), findsOneWidget);
      expect(find.byKey(const Key('statisticsTab')), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Group 3: Core Features Continuity - Projects & Dashboard (10 tests)
  // ───────────────────────────────────────────────────────────────────────────
  group('3. Core Features Continuity - Projects & Dashboard', () {
    testWidgets('3.1 Shows empty state when no projects exist', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: []));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('emptyStateAddProjectButton')), findsOneWidget);
    });

    testWidgets('3.2 Overview card displays correct project count', (tester) async {
      final projs = [sampleProject(id: 'p1'), sampleProject(id: 'p2')];
      await tester.pumpWidget(buildTestApp(initialProjects: projs));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsWidgets);
    });

    testWidgets('3.3 Overview card displays total spent accurately', (tester) async {
      final p1 = sampleProject(id: 'p1');
      final b1 = sampleBill(id: 'b1', amount: 100.0, projectId: 'p1');
      await tester.pumpWidget(buildTestApp(initialProjects: [p1], initialBills: [b1]));
      await tester.pumpAndSettle();

      expect(find.text('€100.00'), findsWidgets);
    });

    testWidgets('3.4 Quick action button Projects exists', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectsButton')), findsOneWidget);
    });

    testWidgets('3.5 Quick action button Split Bills exists', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('splitBillsButton')), findsOneWidget);
    });

    testWidgets('3.6 Tapping Split Bills quick action switches to Tab 1', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('splitBillsButton')));
      await tester.pumpAndSettle();

      expect(find.byType(BillsListScreen), findsOneWidget);
    });

    testWidgets('3.7 All Projects section title is displayed', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('All Projects'), findsOneWidget);
    });

    testWidgets('3.8 Pull to refresh indicator exists', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pullToRefresh')), findsOneWidget);
    });

    testWidgets('3.9 Swipe to delete on project card shows delete dialog', (tester) async {
      final p1 = sampleProject(id: 'p1', name: 'Alpha');
      await tester.pumpWidget(buildTestApp(initialProjects: [p1]));
      await tester.pumpAndSettle();

      await tester.drag(find.byKey(const Key('dismissible_p1')), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('Delete Project'), findsOneWidget);
    });

    testWidgets('3.10 Cancel button in delete dialog keeps project', (tester) async {
      final p1 = sampleProject(id: 'p1', name: 'Alpha');
      await tester.pumpWidget(buildTestApp(initialProjects: [p1]));
      await tester.pumpAndSettle();

      await tester.drag(find.byKey(const Key('dismissible_p1')), const Offset(-400, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Group 4: Core Features Continuity - Bills & AddBill (10 tests)
  // ───────────────────────────────────────────────────────────────────────────
  group('4. Core Features Continuity - Bills & AddBill', () {
    testWidgets('4.1 BillsListScreen renders empty state when no bills', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const Scaffold(body: BillsListScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No bills yet'), findsOneWidget);
    });

    testWidgets('4.2 BillsListScreen renders bill card when bills exist', (tester) async {
      final b1 = sampleBill(id: 'b1', title: 'Dinner party');
      await tester.pumpWidget(buildTestApp(
        initialBills: [b1],
        child: const Scaffold(body: BillsListScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Dinner party'), findsOneWidget);
    });

    testWidgets('4.3 AddBillScreen renders form fields', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('titleField')), findsOneWidget);
      expect(find.byKey(const Key('amountField')), findsOneWidget);
    });

    testWidgets('4.4 AddBillScreen shows validation error on empty submit', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(find.text('Bill name is required'), findsOneWidget);
    });

    testWidgets('4.5 AddBillScreen supports Equal split mode', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('splitModeRadio_equal')), findsOneWidget);
      expect(find.text('Equal'), findsWidgets);
    });

    testWidgets('4.6 AddBillScreen supports Percentage split mode', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('splitModeRadio_percentage')), findsOneWidget);
      expect(find.text('Percentage'), findsWidgets);
    });

    testWidgets('4.7 AddBillScreen supports Shares split mode', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('splitModeRadio_shares')), findsOneWidget);
      expect(find.text('Shares'), findsWidgets);
    });

    testWidgets('4.8 AddBillScreen supports Custom split mode', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('splitModeRadio_custom')), findsOneWidget);
      expect(find.text('Custom'), findsWidgets);
    });

    testWidgets('4.9 BillDetailScreen displays bill information', (tester) async {
      final b1 = sampleBill(id: 'b1', title: 'Supermarket Run', amount: 85.0);
      await tester.pumpWidget(buildTestApp(
        child: BillDetailScreen(bill: b1),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Supermarket Run'), findsOneWidget);
      expect(find.textContaining('85'), findsWidgets);
    });

    testWidgets('4.10 BillDetailScreen shows participant breakdown', (tester) async {
      final b1 = sampleBill(id: 'b1', title: 'Trip snacks', amount: 50.0);
      await tester.pumpWidget(buildTestApp(
        child: BillDetailScreen(bill: b1),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsWidgets);
      expect(find.text('Bob'), findsWidgets);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Group 5: Settings & Theme/Localization Continuity (10 tests)
  // ───────────────────────────────────────────────────────────────────────────
  group('5. Settings & Theme/Localization Continuity', () {
    testWidgets('5.1 SettingsScreen renders Theme Settings', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const Scaffold(body: SettingsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Theme Settings'), findsOneWidget);
    });

    testWidgets('5.2 SettingsScreen renders Language selection', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const Scaffold(body: SettingsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('preferencesCard')), findsOneWidget);
      expect(find.byKey(const Key('settingsEnglishTile')), findsOneWidget);
    });

    testWidgets('5.3 Shows Light Theme and Dark Theme radio options', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const Scaffold(body: SettingsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Light Theme'), findsOneWidget);
      expect(find.text('Dark Theme'), findsOneWidget);
    });

    testWidgets('5.4 Shows English and Vietnamese language options', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const Scaffold(body: SettingsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settingsEnglishTile')), findsOneWidget);
      expect(find.byKey(const Key('settingsVietnameseTile')), findsOneWidget);
    });

    testWidgets('5.5 Tapping Dark Theme radio activates dark theme', (tester) async {
      final tp = ThemeProvider();
      await tester.pumpWidget(buildTestApp(
        themeProvider: tp,
        child: const Scaffold(body: SettingsScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark Theme'));
      await tester.pumpAndSettle();

      expect(tp.isDarkMode, isTrue);
    });

    testWidgets('5.6 Tapping Light Theme radio activates light theme', (tester) async {
      final tp = ThemeProvider();
      tp.setDarkMode(true);
      await tester.pumpWidget(buildTestApp(
        themeProvider: tp,
        child: const Scaffold(body: SettingsScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Light Theme'));
      await tester.pumpAndSettle();

      expect(tp.isDarkMode, isFalse);
    });

    testWidgets('5.7 Tapping Vietnamese radio activates Vietnamese locale', (tester) async {
      final lp = LanguageProvider();
      await tester.pumpWidget(buildTestApp(
        langProvider: lp,
        child: const Scaffold(body: SettingsScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settingsVietnameseTile')));
      await tester.pumpAndSettle();

      expect(lp.currentLocale.languageCode, 'vi');
    });

    testWidgets('5.8 Tapping English radio activates English locale', (tester) async {
      final lp = LanguageProvider();
      await lp.setLanguage('vi');
      await tester.pumpWidget(buildTestApp(
        langProvider: lp,
        child: const Scaffold(body: SettingsScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settingsEnglishTile')));
      await tester.pumpAndSettle();

      expect(lp.currentLocale.languageCode, 'en');
    });

    testWidgets('5.9 App title in AppBar reflects app_name translation', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Shared Household Planner'), findsOneWidget);
    });

    testWidgets('5.10 Theme toggle button exists in AppBar', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('themeToggleButton')), findsOneWidget);
    });
  });
}
