import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/core/theme/app_theme.dart';
import 'package:shared_household_planner/features/home/presentation/pages/home_screen.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/services/last_active_project_service.dart';
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

class FakeProjectRepo implements ProjectRepository {
  List<Project> list = [];
  bool deleteCalled = false;

  @override
  Future<Either<Failure, Project>> create(Project project) async {
    list.add(project);
    return Right(project);
  }

  @override
  Future<Either<Failure, List<Project>>> getAll() async => Right(List.from(list));

  @override
  Future<Either<Failure, Project>> getById(String id) async {
    final p = list.where((e) => e.id == id).firstOrNull;
    if (p == null) {
      return const Left(LocalFailure('Project not found'));
    }
    return Right(p);
  }

  @override
  Future<Either<Failure, Project>> update(Project project) async {
    final idx = list.indexWhere((p) => p.id == project.id);
    if (idx != -1) list[idx] = project;
    return Right(project);
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    deleteCalled = true;
    list.removeWhere((p) => p.id == id);
    return const Right(null);
  }
}

class FakeBillRepo implements BillRepository {
  List<Bill> list = [];

  @override
  Future<Either<Failure, Bill>> create(Bill bill) async {
    list.add(bill);
    return Right(bill);
  }

  @override
  Future<Either<Failure, List<Bill>>> getAll() async => Right(List.from(list));

  @override
  Future<Either<Failure, Bill>> getById(String id) async {
    return Right(list.firstWhere((b) => b.id == id));
  }

  @override
  Future<Either<Failure, Bill>> update(Bill bill) async {
    final idx = list.indexWhere((b) => b.id == bill.id);
    if (idx != -1) list[idx] = bill;
    return Right(bill);
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    list.removeWhere((b) => b.id == id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(String projectId) async {
    return Right(list.where((b) => b.projectId == projectId).toList());
  }
}

class _TestLoc extends AppLocalizations {
  final String code;
  _TestLoc(this.code) : super(Locale(code));

  static const _dict = {
    'app_name': 'Shared Household Planner',
    'projects': 'Projects',
    'split_bills': 'Split Bills',
    'bills_tab': 'Bills',
    'settlement_tab': 'Settlement',
    'statistics_tab': 'Statistics',
    'add_expense_button': 'Add Expense',
    'save_bill': 'Save Bill',
    'last_active_project': 'Last Active Project',
    'auto_restoring_project': 'Restoring last project...',
    'overview': 'Overview',
    'all_projects': 'All Projects',
    'no_projects': 'No projects yet',
    'total_spent': 'Total Spent',
    'delete_project': 'Delete Project',
    'delete_project_confirm': 'Are you sure?',
    'delete': 'Delete',
    'cancel': 'Cancel',
    'edit_project': 'Edit Project',
  };

  @override
  String translate(String key) => _dict[key] ?? key;
}

class _TestLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestLocDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => _TestLoc(locale.languageCode);
  @override
  bool shouldReload(_TestLocDelegate old) => false;
}

Widget buildTestApp({
  required Widget child,
  List<Project> initialProjects = const [],
  List<Bill> initialBills = const [],
  ThemeData? theme,
  FakeProjectRepo? projectRepo,
  FakeBillRepo? billRepo,
}) {
  final pRepo = projectRepo ?? (FakeProjectRepo()..list = List.from(initialProjects));
  final bRepo = billRepo ?? (FakeBillRepo()..list = List.from(initialBills));

  final projectBloc = ProjectBloc(
    createProjectUseCase: CreateProjectUseCase(pRepo),
    getAllProjectsUseCase: GetAllProjectsUseCase(pRepo),
    getProjectByIdUseCase: GetProjectByIdUseCase(pRepo),
    updateProjectUseCase: UpdateProjectUseCase(pRepo),
    deleteProjectUseCase: DeleteProjectUseCase(pRepo),
  )..emit(ProjectLoaded(projects: pRepo.list));

  final billsBloc = BillsBloc(
    getBillsUseCase: GetBillsUseCase(bRepo),
    addBillUseCase: AddBillUseCase(bRepo),
  )..emit(BillsLoaded(bills: bRepo.list));

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
      RepositoryProvider<ProjectRepository>.value(value: pRepo),
      RepositoryProvider<BillRepository>.value(value: bRepo),
      BlocProvider<ProjectBloc>.value(value: projectBloc),
      BlocProvider<BillsBloc>.value(value: billsBloc),
    ],
    child: MaterialApp(
      theme: theme ?? ThemeData.light(useMaterial3: true),
      localizationsDelegates: const [_TestLocDelegate()],
      supportedLocales: const [Locale('en'), Locale('vi')],
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LastActiveProjectService.resetMemoryProjectId();
  });

  tearDown(() {
    LastActiveProjectService.resetMemoryProjectId();
  });

  group('LastActiveProjectService Unit Tests', () {
    test('1. prefKey constant matches last_active_project_id', () {
      expect(LastActiveProjectService.prefKey, 'last_active_project_id');
    });

    test('2. setLastActiveProjectId persists to SharedPreferences and memory', () async {
      SharedPreferences.setMockInitialValues({});
      final service = LastActiveProjectService.instance;

      await service.setLastActiveProjectId('proj-alpha');

      expect(LastActiveProjectService.currentProjectId, 'proj-alpha');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_active_project_id'), 'proj-alpha');
    });

    test('3. getLastActiveProjectId reads from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'last_active_project_id': 'proj-beta'});
      final service = LastActiveProjectService.instance;

      final result = await service.getLastActiveProjectId();
      expect(result, 'proj-beta');
      expect(LastActiveProjectService.currentProjectId, 'proj-beta');
    });

    test('4. getLastActiveProjectId returns null when no value stored', () async {
      SharedPreferences.setMockInitialValues({});
      final service = LastActiveProjectService.instance;

      final result = await service.getLastActiveProjectId();
      expect(result, isNull);
    });

    test('5. clearLastActiveProjectId removes stored value and resets memory', () async {
      SharedPreferences.setMockInitialValues({'last_active_project_id': 'proj-gamma'});
      final service = LastActiveProjectService.instance;

      await service.clearLastActiveProjectId();

      expect(LastActiveProjectService.currentProjectId, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_active_project_id'), isNull);
    });

    test('6. setMemoryProjectId and resetMemoryProjectId update state directly', () {
      LastActiveProjectService.setMemoryProjectId('mem-1');
      expect(LastActiveProjectService.currentProjectId, 'mem-1');

      LastActiveProjectService.resetMemoryProjectId();
      expect(LastActiveProjectService.currentProjectId, isNull);
    });

    test('7. onProjectDeleted clears ID if matching deleted project', () async {
      SharedPreferences.setMockInitialValues({'last_active_project_id': 'proj-delete'});
      final service = LastActiveProjectService.instance;

      await service.onProjectDeleted('proj-delete');

      final result = await service.getLastActiveProjectId();
      expect(result, isNull);
    });

    test('8. onProjectDeleted retains ID if deleting a different project', () async {
      SharedPreferences.setMockInitialValues({'last_active_project_id': 'proj-keep'});
      final service = LastActiveProjectService.instance;

      await service.onProjectDeleted('proj-other');

      final result = await service.getLastActiveProjectId();
      expect(result, 'proj-keep');
    });
  });

  group('ProjectDetailScreen & AddBillScreen State Saving Tests', () {
    testWidgets('9. Opening ProjectDetailScreen automatically persists last_active_project_id', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final project = Project(
        id: 'proj-open-test',
        name: 'Opening Test Project',
        members: const ['User1'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: project),
      ));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_active_project_id'), 'proj-open-test');
      expect(LastActiveProjectService.currentProjectId, 'proj-open-test');
    });

    testWidgets('10. Saving bill with project in AddBillScreen persists last_active_project_id', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({});
      final project = Project(
        id: 'proj-bill-save',
        name: 'Trip Project',
        members: const ['Alice', 'Bob'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(buildTestApp(
        initialProjects: [project],
        child: AddBillScreen(
          projectId: project.id,
          projectName: project.name,
          initialCompactMode: false,
        ),
      ));
      await tester.pumpAndSettle();

      // Enter title and amount, then save
      await tester.enterText(find.byKey(const Key('titleField')), 'Dinner');
      tester.widget<TextField>(find.byKey(const Key('amountField'))).controller!.text = '100000';
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveBillButton')));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_active_project_id'), 'proj-bill-save');
    });
  });

  group('ProjectBloc Deletion & Update State Management Tests', () {
    test('11. Deleting active project via ProjectBloc clears last_active_project_id', () async {
      SharedPreferences.setMockInitialValues({'last_active_project_id': 'proj-to-delete'});
      final pRepo = FakeProjectRepo()..list = [
        Project(
          id: 'proj-to-delete',
          name: 'Delete Me',
          members: const ['A'],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];

      final bloc = ProjectBloc(
        createProjectUseCase: CreateProjectUseCase(pRepo),
        getAllProjectsUseCase: GetAllProjectsUseCase(pRepo),
        getProjectByIdUseCase: GetProjectByIdUseCase(pRepo),
        updateProjectUseCase: UpdateProjectUseCase(pRepo),
        deleteProjectUseCase: DeleteProjectUseCase(pRepo),
      );

      bloc.add(const DeleteProject('proj-to-delete'));
      await bloc.stream.firstWhere((s) => s is ProjectLoaded);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_active_project_id'), isNull);
      await bloc.close();
    });

    test('12. Updating project via ProjectBloc maintains last_active_project_id', () async {
      SharedPreferences.setMockInitialValues({'last_active_project_id': 'proj-update'});
      final original = Project(
        id: 'proj-update',
        name: 'Old Name',
        members: const ['A'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final pRepo = FakeProjectRepo()..list = [original];

      final bloc = ProjectBloc(
        createProjectUseCase: CreateProjectUseCase(pRepo),
        getAllProjectsUseCase: GetAllProjectsUseCase(pRepo),
        getProjectByIdUseCase: GetProjectByIdUseCase(pRepo),
        updateProjectUseCase: UpdateProjectUseCase(pRepo),
        deleteProjectUseCase: DeleteProjectUseCase(pRepo),
      );

      final updated = original.copyWith(name: 'New Name');
      bloc.add(UpdateProject(updated));
      await Future.delayed(const Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_active_project_id'), 'proj-update');
      await bloc.close();
    });
  });

  group('HomeScreen Auto-Restore Navigation & Fallback Tests', () {
    testWidgets('13. Automatically navigates to ProjectDetailScreen when valid last_active_project_id exists', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'last_active_project_id': 'proj-restore-1'});

      final project = Project(
        id: 'proj-restore-1',
        name: 'Auto Restored Trip',
        members: const ['Alice', 'Bob'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(buildTestApp(
        initialProjects: [project],
        child: const HomeScreen(),
      ));
      await tester.pumpAndSettle();

      // Verify ProjectDetailScreen is rendered with project title
      expect(find.byType(ProjectDetailScreen), findsOneWidget);
      expect(find.text('Auto Restored Trip'), findsWidgets);
    });

    testWidgets('14. Pressing Back on auto-restored ProjectDetailScreen cleanly returns to HomeScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'last_active_project_id': 'proj-back-test'});

      final project = Project(
        id: 'proj-back-test',
        name: 'Back Test Project',
        members: const ['Alice'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(buildTestApp(
        initialProjects: [project],
        child: const HomeScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ProjectDetailScreen), findsOneWidget);

      // Tap back button
      final backButton = find.byType(BackButton);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Verify HomeScreen is now visible and ProjectDetailScreen is popped
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(ProjectDetailScreen), findsNothing);
    });

    testWidgets('15. Starts on HomeScreen safely when last_active_project_id is null', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final project = Project(
        id: 'proj-null-id',
        name: 'Null Test Project',
        members: const ['Alice'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(buildTestApp(
        initialProjects: [project],
        child: const HomeScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(ProjectDetailScreen), findsNothing);
    });

    testWidgets('16. Falls back to HomeScreen and clears ID when project is deleted/not found', (tester) async {
      SharedPreferences.setMockInitialValues({'last_active_project_id': 'proj-non-existent'});

      final project = Project(
        id: 'proj-other-existing',
        name: 'Other Project',
        members: const ['Alice'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(buildTestApp(
        initialProjects: [project],
        child: const HomeScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(ProjectDetailScreen), findsNothing);

      // Verify cleared from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_active_project_id'), isNull);
    });

    testWidgets('17. Auto-restore functions cleanly under Dark Theme', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'last_active_project_id': 'proj-dark-theme'});

      final project = Project(
        id: 'proj-dark-theme',
        name: 'Dark Mode Project',
        members: const ['Alice'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(buildTestApp(
        theme: ThemeData.dark(useMaterial3: true),
        initialProjects: [project],
        child: const HomeScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ProjectDetailScreen), findsOneWidget);
      expect(find.text('Dark Mode Project'), findsWidgets);
    });

    testWidgets('18. autoRestoreLastProject: false disables auto-navigation', (tester) async {
      SharedPreferences.setMockInitialValues({'last_active_project_id': 'proj-disabled'});

      final project = Project(
        id: 'proj-disabled',
        name: 'Disabled Auto Restore Project',
        members: const ['Alice'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(buildTestApp(
        initialProjects: [project],
        child: const HomeScreen(autoRestoreLastProject: false),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(ProjectDetailScreen), findsNothing);
    });
  });
}
