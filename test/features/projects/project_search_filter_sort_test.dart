import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/core/theme/app_theme.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_project_by_id_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/project_screen.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';

// ─── Fake Repositories ────────────────────────────────────────────────────────

class _FakeProjRepo implements ProjectRepository {
  final List<Project> projects;
  _FakeProjRepo([List<Project>? initial])
      : projects = initial != null ? List.from(initial) : [];

  @override
  Future<Either<Failure, List<Project>>> getAll() async =>
      Right(List.from(projects));

  @override
  Future<Either<Failure, Project>> create(Project p) async {
    projects.add(p);
    return Right(p);
  }

  @override
  Future<Either<Failure, Project>> getById(String id) async =>
      Right(projects.firstWhere((p) => p.id == id));

  @override
  Future<Either<Failure, Project>> update(Project p) async {
    final idx = projects.indexWhere((it) => it.id == p.id);
    if (idx != -1) projects[idx] = p;
    return Right(p);
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    projects.removeWhere((it) => it.id == id);
    return const Right(null);
  }
}

class _FakeBillRepo implements BillRepository {
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
  Future<Either<Failure, void>> delete(String id) async {
    bills.removeWhere((b) => b.id == id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(
          String projectId) async =>
      Right(bills.where((b) => b.projectId == projectId).toList());
}

// ─── Test Localizations ───────────────────────────────────────────────────────

class _TestLoc extends AppLocalizations {
  _TestLoc() : super(const Locale('en'));

  static const Map<String, String> _dict = {
    'projects': 'Projects',
    'no_projects': 'No Projects',
    'search_projects': 'Search projects...',
    'filter_all': 'All',
    'filter_family_home': 'Family/Home',
    'filter_travel': 'Travel',
    'filter_food_dining': 'Food/Dining',
    'filter_event': 'Event',
    'filter_work': 'Work',
    'filter_school': 'School',
    'filter_shopping': 'Shopping',
    'filter_by_category': 'Filter by Category',
    'filter_by_currency': 'Filter by Currency',
    'sort_projects': 'Sort Projects',
    'sort_newest': 'Newest',
    'sort_oldest': 'Oldest',
    'sort_name_az': 'Name A→Z',
    'sort_name_za': 'Name Z→A',
    'sort_members': 'Member Count',
    'active_filters': 'Active filters',
    'clear_filters': 'Clear filters',
    'no_matching_projects': 'No matching projects found',
    'no_matching_projects_hint': 'Try adjusting your search or filters',
    'reset_filters': 'Reset filters',
    'members': 'Members',
    'create_project': 'Create Project',
    'edit_project': 'Edit Project',
    'delete_project': 'Delete Project',
    'delete_project_confirm': 'Confirm delete?',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'error': 'Error',
  };

  @override
  String translate(String key) => _dict[key] ?? key;
}

class _TestLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestLocDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async => _TestLoc();

  @override
  bool shouldReload(_TestLocDelegate old) => false;
}

// ─── Test Helper ─────────────────────────────────────────────────────────────

Widget _buildTestApp({List<Project>? projects, bool darkMode = false}) {
  final pRepo = _FakeProjRepo(projects ?? []);
  final bRepo = _FakeBillRepo();

  final projectBloc = ProjectBloc(
    getAllProjectsUseCase: GetAllProjectsUseCase(pRepo),
    createProjectUseCase: CreateProjectUseCase(pRepo),
    getProjectByIdUseCase: GetProjectByIdUseCase(pRepo),
    updateProjectUseCase: UpdateProjectUseCase(pRepo),
    deleteProjectUseCase: DeleteProjectUseCase(pRepo),
  )..emit(ProjectLoaded(projects: pRepo.projects));

  final billsBloc = BillsBloc(
    getBillsUseCase: GetBillsUseCase(bRepo),
    addBillUseCase: AddBillUseCase(bRepo),
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
      RepositoryProvider<BillRepository>.value(value: bRepo),
      BlocProvider<BillsBloc>.value(value: billsBloc),
      BlocProvider<ProjectBloc>.value(value: projectBloc),
    ],
    child: MaterialApp(
      theme: darkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      localizationsDelegates: const [_TestLocDelegate()],
      supportedLocales: const [Locale('en'), Locale('vi')],
      home: const ProjectScreen(),
    ),
  );
}

// Sample test data
final _testDate = DateTime(2026, 1, 1);
final _olderDate = DateTime(2025, 6, 1);
final _newerDate = DateTime(2026, 9, 1);

Project _makeProject({
  required String id,
  required String name,
  String? description,
  List<String> members = const ['Alice'],
  int iconIndex = 0,
  int colorIndex = 0,
  String currency = 'VND',
  DateTime? createdAt,
  DateTime? updatedAt,
}) =>
    Project(
      id: id,
      name: name,
      description: description,
      members: members,
      iconIndex: iconIndex,
      colorIndex: colorIndex,
      currency: currency,
      createdAt: createdAt ?? _testDate,
      updatedAt: updatedAt ?? _testDate,
    );

void main() {
  group('AC 1: Search Bar – Realtime Filtering', () {
    testWidgets('1.1 Search bar renders with correct placeholder', (tester) async {
      await tester.pumpWidget(_buildTestApp(projects: []));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projectSearchField')), findsOneWidget);
      final textField = tester.widget<TextField>(find.byKey(const Key('projectSearchField')));
      expect(textField.decoration?.hintText, 'Search projects...');
    });

    testWidgets('1.2 Typing in search bar filters projects by name', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [
        _makeProject(id: 'p1', name: 'Apartment Rent'),
        _makeProject(id: 'p2', name: 'Travel to Bali'),
        _makeProject(id: 'p3', name: 'Family Dinner'),
      ];
      await tester.pumpWidget(_buildTestApp(projects: projects));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('projectSearchField')), 'Bali');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectItem_p2')), findsOneWidget);
      expect(find.byKey(const Key('projectItem_p1')), findsNothing);
      expect(find.byKey(const Key('projectItem_p3')), findsNothing);
    });

    testWidgets('1.3 Search filters by member name', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [
        _makeProject(id: 'p1', name: 'Project A', members: ['John', 'Mary']),
        _makeProject(id: 'p2', name: 'Project B', members: ['Alice', 'Bob']),
      ];
      await tester.pumpWidget(_buildTestApp(projects: projects));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('projectSearchField')), 'John');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectItem_p1')), findsOneWidget);
      expect(find.byKey(const Key('projectItem_p2')), findsNothing);
    });

    testWidgets('1.4 Search filters by description', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [
        _makeProject(id: 'p1', name: 'Project A', description: 'Weekend camping trip'),
        _makeProject(id: 'p2', name: 'Project B', description: 'City tour'),
      ];
      await tester.pumpWidget(_buildTestApp(projects: projects));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('projectSearchField')), 'camping');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectItem_p1')), findsOneWidget);
      expect(find.byKey(const Key('projectItem_p2')), findsNothing);
    });

    testWidgets('1.5 Search is case-insensitive', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [
        _makeProject(id: 'p1', name: 'Shopping List'),
        _makeProject(id: 'p2', name: 'Rent Payment'),
      ];
      await tester.pumpWidget(_buildTestApp(projects: projects));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('projectSearchField')), 'SHOPPING');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectItem_p1')), findsOneWidget);
      expect(find.byKey(const Key('projectItem_p2')), findsNothing);
    });

    testWidgets('1.6 Clear search button appears when query is non-empty', (tester) async {
      await tester.pumpWidget(_buildTestApp(projects: []));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('clearSearchButton')), findsNothing);
      await tester.enterText(find.byKey(const Key('projectSearchField')), 'test');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('clearSearchButton')), findsOneWidget);
    });

    testWidgets('1.7 Tapping clear button resets search query', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [
        _makeProject(id: 'p1', name: 'Home Project'),
        _makeProject(id: 'p2', name: 'Work Project'),
      ];
      await tester.pumpWidget(_buildTestApp(projects: projects));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('projectSearchField')), 'Home');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projectItem_p2')), findsNothing);

      await tester.tap(find.byKey(const Key('clearSearchButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projectItem_p1')), findsOneWidget);
      expect(find.byKey(const Key('projectItem_p2')), findsOneWidget);
    });
  });

  group('AC 2: Category Filter Chips', () {
    testWidgets('2.1 Category filter chips render', (tester) async {
      await tester.pumpWidget(_buildTestApp(projects: []));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('categoryFilterList')), findsOneWidget);
      expect(find.byKey(const Key('categoryChip_0')), findsOneWidget); // All
      expect(find.byKey(const Key('categoryChip_1')), findsOneWidget); // Family/Home
    });

    testWidgets('2.2 Selecting category chip filters projects by iconIndex', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [
        _makeProject(id: 'home_p', name: 'Home', iconIndex: 1), // home_rounded -> family/home
        _makeProject(id: 'travel_p', name: 'Trip', iconIndex: 2), // flight_takeoff -> travel
      ];
      await tester.pumpWidget(_buildTestApp(projects: projects));
      await tester.pumpAndSettle();

      // Tap "Travel" chip (index 2)
      await tester.tap(find.byKey(const Key('categoryChip_2')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectItem_travel_p')), findsOneWidget);
      expect(find.byKey(const Key('projectItem_home_p')), findsNothing);
    });

    testWidgets('2.3 All category chip shows all projects', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [
        _makeProject(id: 'p1', name: 'Home', iconIndex: 1),
        _makeProject(id: 'p2', name: 'Trip', iconIndex: 2),
        _makeProject(id: 'p3', name: 'Dinner', iconIndex: 3),
      ];
      await tester.pumpWidget(_buildTestApp(projects: projects));
      await tester.pumpAndSettle();

      // Filter to Travel first
      await tester.tap(find.byKey(const Key('categoryChip_2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projectItem_p1')), findsNothing);

      // Then select All
      await tester.tap(find.byKey(const Key('categoryChip_0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projectItem_p1')), findsOneWidget);
      expect(find.byKey(const Key('projectItem_p2')), findsOneWidget);
      expect(find.byKey(const Key('projectItem_p3')), findsOneWidget);
    });

    testWidgets('2.4 Family/Home filter maps iconIndex 0 and 1', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [
        _makeProject(id: 'apt', name: 'Apartment', iconIndex: 0),
        _makeProject(id: 'hm', name: 'House', iconIndex: 1),
        _makeProject(id: 'trv', name: 'Travel', iconIndex: 2),
      ];
      await tester.pumpWidget(_buildTestApp(projects: projects));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('categoryChip_1'))); // Family/Home
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectItem_apt')), findsOneWidget);
      expect(find.byKey(const Key('projectItem_hm')), findsOneWidget);
      expect(find.byKey(const Key('projectItem_trv')), findsNothing);
    });
  });

  group('AC 3: Currency Filter Chips', () {
    testWidgets('3.1 Currency filter row hidden when only one currency', (tester) async {
      await tester.pumpWidget(_buildTestApp(projects: [
        _makeProject(id: 'p1', name: 'A', currency: 'VND'),
      ]));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('currencyFilterList')), findsNothing);
    });

    testWidgets('3.2 Currency filter row visible with multiple currencies', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(projects: [
        _makeProject(id: 'p1', name: 'VND Project', currency: 'VND'),
        _makeProject(id: 'p2', name: 'USD Project', currency: 'USD'),
      ]));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('currencyFilterList')), findsOneWidget);
    });

    testWidgets('3.3 Selecting currency chip filters projects', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [
        _makeProject(id: 'vnd_p', name: 'VND Project', currency: 'VND'),
        _makeProject(id: 'usd_p', name: 'USD Project', currency: 'USD'),
      ];
      await tester.pumpWidget(_buildTestApp(projects: projects));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('currencyChip_USD')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectItem_usd_p')), findsOneWidget);
      expect(find.byKey(const Key('projectItem_vnd_p')), findsNothing);
    });

    testWidgets('3.4 Selecting All currency chip restores all projects', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [
        _makeProject(id: 'vnd_p', name: 'VND Project', currency: 'VND'),
        _makeProject(id: 'usd_p', name: 'USD Project', currency: 'USD'),
      ];
      await tester.pumpWidget(_buildTestApp(projects: projects));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('currencyChip_USD')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projectItem_vnd_p')), findsNothing);

      await tester.tap(find.byKey(const Key('currencyChip_all')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projectItem_vnd_p')), findsOneWidget);
      expect(find.byKey(const Key('projectItem_usd_p')), findsOneWidget);
    });
  });

  group('AC 4: Sort Options', () {
    testWidgets('4.1 Sort button opens bottom sheet', (tester) async {
      await tester.pumpWidget(_buildTestApp(projects: []));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sortProjectsButton')));
      await tester.pumpAndSettle();
      expect(find.text('Sort Projects'), findsWidgets);
    });

    testWidgets('4.2 Default sort is Newest – most recent createdAt first', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [
        _makeProject(id: 'old_p', name: 'Old Project', createdAt: _olderDate),
        _makeProject(id: 'new_p', name: 'New Project', createdAt: _newerDate),
      ];
      await tester.pumpWidget(_buildTestApp(projects: projects));
      await tester.pumpAndSettle();

      final items = tester.widgetList(find.byWidgetPredicate(
        (w) => w is ListTile && (w.key == const Key('projectItem_old_p') ||
                                 w.key == const Key('projectItem_new_p')),
      )).toList();
      // new_p should be before old_p
      expect(items.first.key, const Key('projectItem_new_p'));
    });

    testWidgets('4.3 Sort by Oldest puts older project first', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [
        _makeProject(id: 'old_p', name: 'Old Project', createdAt: _olderDate),
        _makeProject(id: 'new_p', name: 'New Project', createdAt: _newerDate),
      ];
      await tester.pumpWidget(_buildTestApp(projects: projects));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sortProjectsButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oldest'));
      await tester.pumpAndSettle();

      final items = tester.widgetList(find.byWidgetPredicate(
        (w) => w is ListTile && (w.key == const Key('projectItem_old_p') ||
                                 w.key == const Key('projectItem_new_p')),
      )).toList();
      expect(items.first.key, const Key('projectItem_old_p'));
    });

    testWidgets('4.4 Sort Name A→Z orders alphabetically ascending', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [
        _makeProject(id: 'z_p', name: 'Zoo Trip'),
        _makeProject(id: 'a_p', name: 'Apple Fund'),
      ];
      await tester.pumpWidget(_buildTestApp(projects: projects));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sortProjectsButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Name A→Z'));
      await tester.pumpAndSettle();

      final items = tester.widgetList(find.byWidgetPredicate(
        (w) => w is ListTile && (w.key == const Key('projectItem_z_p') ||
                                 w.key == const Key('projectItem_a_p')),
      )).toList();
      expect(items.first.key, const Key('projectItem_a_p'));
    });

    testWidgets('4.5 Sort Name Z→A orders alphabetically descending', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [
        _makeProject(id: 'z_p', name: 'Zoo Trip'),
        _makeProject(id: 'a_p', name: 'Apple Fund'),
      ];
      await tester.pumpWidget(_buildTestApp(projects: projects));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sortProjectsButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Name Z→A'));
      await tester.pumpAndSettle();

      final items = tester.widgetList(find.byWidgetPredicate(
        (w) => w is ListTile && (w.key == const Key('projectItem_z_p') ||
                                 w.key == const Key('projectItem_a_p')),
      )).toList();
      expect(items.first.key, const Key('projectItem_z_p'));
    });

    testWidgets('4.6 Sort by Member Count orders by member count descending', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [
        _makeProject(id: 'solo', name: 'Solo', members: ['Alice']),
        _makeProject(id: 'team', name: 'Team', members: ['Alice', 'Bob', 'Charlie']),
      ];
      await tester.pumpWidget(_buildTestApp(projects: projects));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sortProjectsButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Member Count'));
      await tester.pumpAndSettle();

      final items = tester.widgetList(find.byWidgetPredicate(
        (w) => w is ListTile && (w.key == const Key('projectItem_solo') ||
                                 w.key == const Key('projectItem_team')),
      )).toList();
      expect(items.first.key, const Key('projectItem_team'));
    });
  });

  group('AC 5: Active Filter Indicator & Clear Filters', () {
    testWidgets('5.1 No active filter indicator when no filters set', (tester) async {
      await tester.pumpWidget(_buildTestApp(projects: [
        _makeProject(id: 'p1', name: 'Test'),
      ]));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('clearFiltersButton')), findsNothing);
    });

    testWidgets('5.2 Active filter indicator appears when search is non-empty', (tester) async {
      await tester.pumpWidget(_buildTestApp(projects: [
        _makeProject(id: 'p1', name: 'Test'),
      ]));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('projectSearchField')), 'abc');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('clearFiltersButton')), findsOneWidget);
    });

    testWidgets('5.3 Active filter indicator appears when category filter is set', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(projects: [
        _makeProject(id: 'p1', name: 'Test'),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('categoryChip_2'))); // Travel
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('clearFiltersButton')), findsOneWidget);
    });

    testWidgets('5.4 Clear filters button resets all filters', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [
        _makeProject(id: 'p1', name: 'Apple', iconIndex: 1),
        _makeProject(id: 'p2', name: 'Mango', iconIndex: 2),
      ];
      await tester.pumpWidget(_buildTestApp(projects: projects));
      await tester.pumpAndSettle();

      // Apply search filter
      await tester.enterText(find.byKey(const Key('projectSearchField')), 'Apple');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projectItem_p2')), findsNothing);

      // Clear all filters
      await tester.tap(find.byKey(const Key('clearFiltersButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectItem_p1')), findsOneWidget);
      expect(find.byKey(const Key('projectItem_p2')), findsOneWidget);
      expect(find.byKey(const Key('clearFiltersButton')), findsNothing);
    });
  });

  group('AC 6: Empty Search Result State', () {
    testWidgets('6.1 No matching state shows when search has no results', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [
        _makeProject(id: 'p1', name: 'Rent'),
      ];
      await tester.pumpWidget(_buildTestApp(projects: projects));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('projectSearchField')), 'zzz_nonexistent');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('noMatchingProjectsState')), findsOneWidget);
      expect(find.text('No matching projects found'), findsOneWidget);
    });

    testWidgets('6.2 Reset filters button in empty state restores all projects', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [
        _makeProject(id: 'p1', name: 'Rent'),
      ];
      await tester.pumpWidget(_buildTestApp(projects: projects));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('projectSearchField')), 'zzz_nonexistent');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('resetFiltersButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectItem_p1')), findsOneWidget);
      expect(find.byKey(const Key('noMatchingProjectsState')), findsNothing);
    });

    testWidgets('6.3 Original empty state shows when no projects exist at all', (tester) async {
      await tester.pumpWidget(_buildTestApp(projects: []));
      await tester.pumpAndSettle();
      expect(find.text('No Projects'), findsOneWidget);
      expect(find.byKey(const Key('noMatchingProjectsState')), findsNothing);
    });
  });

  group('AC 7: Combined Search + Filter', () {
    testWidgets('7.1 Search + category filter combined narrows results', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [
        _makeProject(id: 'trip_alice', name: 'Trip Alice', iconIndex: 2, members: ['Alice']),
        _makeProject(id: 'trip_bob', name: 'Trip Bob', iconIndex: 2, members: ['Bob']),
        _makeProject(id: 'home_alice', name: 'Home Alice', iconIndex: 1, members: ['Alice']),
      ];
      await tester.pumpWidget(_buildTestApp(projects: projects));
      await tester.pumpAndSettle();

      // Filter by Travel
      await tester.tap(find.byKey(const Key('categoryChip_2')));
      await tester.pumpAndSettle();

      // Also search for Alice
      await tester.enterText(find.byKey(const Key('projectSearchField')), 'Alice');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectItem_trip_alice')), findsOneWidget);
      expect(find.byKey(const Key('projectItem_trip_bob')), findsNothing);
      expect(find.byKey(const Key('projectItem_home_alice')), findsNothing);
    });

    testWidgets('7.2 Search + currency filter combined narrows results', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [
        _makeProject(id: 'usd_alice', name: 'USD Alice', currency: 'USD', members: ['Alice']),
        _makeProject(id: 'usd_bob', name: 'USD Bob', currency: 'USD', members: ['Bob']),
        _makeProject(id: 'vnd_alice', name: 'VND Alice', currency: 'VND', members: ['Alice']),
      ];
      await tester.pumpWidget(_buildTestApp(projects: projects));
      await tester.pumpAndSettle();

      // Filter by USD
      await tester.tap(find.byKey(const Key('currencyChip_USD')));
      await tester.pumpAndSettle();

      // Search for Alice
      await tester.enterText(find.byKey(const Key('projectSearchField')), 'Alice');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectItem_usd_alice')), findsOneWidget);
      expect(find.byKey(const Key('projectItem_usd_bob')), findsNothing);
      expect(find.byKey(const Key('projectItem_vnd_alice')), findsNothing);
    });
  });

  group('AC 8: Dark Theme Support', () {
    testWidgets('8.1 ProjectScreen renders in dark theme without errors', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [
        _makeProject(id: 'p1', name: 'Dark Project'),
      ];
      await tester.pumpWidget(_buildTestApp(projects: projects, darkMode: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectSearchField')), findsOneWidget);
      expect(find.byKey(const Key('categoryFilterList')), findsOneWidget);
      expect(find.byKey(const Key('projectItem_p1')), findsOneWidget);
    });

    testWidgets('8.2 Search and filter work in dark mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [
        _makeProject(id: 'p1', name: 'Alpha'),
        _makeProject(id: 'p2', name: 'Beta'),
      ];
      await tester.pumpWidget(_buildTestApp(projects: projects, darkMode: true));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('projectSearchField')), 'Alpha');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectItem_p1')), findsOneWidget);
      expect(find.byKey(const Key('projectItem_p2')), findsNothing);
    });
  });

  group('AC 9: Project List Backwards Compatibility', () {
    testWidgets('9.1 Existing project keys (projectItem, editProject, deleteProject) preserved', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [_makeProject(id: 'p1', name: 'Legacy Project')];
      await tester.pumpWidget(_buildTestApp(projects: projects));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectItem_p1')), findsOneWidget);
      expect(find.byKey(const Key('editProject_p1')), findsOneWidget);
      expect(find.byKey(const Key('deleteProject_p1')), findsOneWidget);
    });

    testWidgets('9.2 Add project FAB still works', (tester) async {
      await tester.pumpWidget(_buildTestApp(projects: []));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('addProjectButton')), findsOneWidget);
    });

    testWidgets('9.3 Currency badge still shows on project cards', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = [_makeProject(id: 'p1', name: 'Proj', currency: 'USD')];
      await tester.pumpWidget(_buildTestApp(projects: projects));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectCurrencyBadge_p1')), findsOneWidget);
      expect(find.byKey(const Key('projectCurrencyText_p1')), findsOneWidget);
    });
  });
}
