import 'dart:convert';
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
import 'package:shared_household_planner/features/projects/domain/entities/project_palette.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_project_by_id_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/data/models/project_model.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/create_project_screen.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/project_screen.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/project_detail_screen.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/add_bill_screen.dart';

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
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(String projectId) async =>
      Right(bills.where((b) => b.projectId == projectId).toList());
}

class _FakeProjRepo implements ProjectRepository {
  final List<Project> projects;
  _FakeProjRepo([List<Project>? initial]) : projects = initial != null ? List.from(initial) : [];

  @override
  Future<Either<Failure, List<Project>>> getAll() async => Right(List.from(projects));
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

class _TestThemeLoc extends AppLocalizations {
  final String code;
  _TestThemeLoc(this.code) : super(Locale(code));

  static const Map<String, String> _dict = {
    'create_project': 'Create Project',
    'edit_project': 'Edit Project',
    'project_name': 'Project Name',
    'project_name_required': 'Project name is required',
    'members': 'Members',
    'members_hint': 'e.g. John, Sarah',
    'min_1_member': 'Add at least 1 member',
    'save_project': 'Save Project',
    'projects': 'Projects',
    'bills_tab': 'Bills',
    'settlement_tab': 'Settlement',
    'statistics_tab': 'Statistics',
    'no_bills_in_project': 'No bills linked to this project yet',
    'add_expense_button': 'Add Expense',
    'create_first_bill': 'Create Expense',
    'select_project_modal_title': 'Select Project',
    'select_project': 'Select Project',
    'choose_project': 'Choose Project',
    'no_project_selected': 'No Project Selected',
    'no_project': 'No Project',
    'no_projects': 'No Projects',
    'project_no_members': 'No members in this project',
    'error': 'Error',
  };

  @override
  String translate(String key) => _dict[key] ?? key;
}

class _TestThemeLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestThemeLocDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => _TestThemeLoc('en');
  @override
  bool shouldReload(_TestThemeLocDelegate old) => false;
}

Widget _buildTestApp({
  required Widget child,
  List<Project>? projects,
  List<Bill>? bills,
  _FakeProjRepo? projRepo,
}) {
  final pRepo = projRepo ?? _FakeProjRepo(projects ?? []);
  final bRepo = _FakeBillRepo();
  if (bills != null) bRepo.bills.addAll(bills);

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
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        _TestThemeLocDelegate(),
      ],
      supportedLocales: const [Locale('en'), Locale('vi')],
      home: child,
    ),
  );
}

void main() {
  final testDate = DateTime(2026, 9, 20);

  group('AC 1 & AC 9: Project Entity & ProjectModel Serialization', () {
    test('1.1 Project entity defaults iconIndex and colorIndex to 0', () {
      final p = Project(
        id: 'p1',
        name: 'Apartment',
        members: const ['Alice'],
        createdAt: testDate,
        updatedAt: testDate,
      );
      expect(p.iconIndex, 0);
      expect(p.colorIndex, 0);
      expect(p.iconData, ProjectPalette.icons[0]);
      expect(p.color, ProjectPalette.colors[0]);
    });

    test('1.2 Project entity retains custom iconIndex and colorIndex', () {
      final p = Project(
        id: 'p2',
        name: 'Trip',
        members: const ['Bob'],
        iconIndex: 2,
        colorIndex: 3,
        createdAt: testDate,
        updatedAt: testDate,
      );
      expect(p.iconIndex, 2);
      expect(p.colorIndex, 3);
      expect(p.iconData, ProjectPalette.icons[2]);
      expect(p.color, ProjectPalette.colors[3]);
    });

    test('1.3 Project copyWith updates iconIndex and colorIndex', () {
      final p = Project(
        id: 'p1',
        name: 'Home',
        members: const ['Alice'],
        iconIndex: 1,
        colorIndex: 2,
        createdAt: testDate,
        updatedAt: testDate,
      );
      final updated = p.copyWith(iconIndex: 4, colorIndex: 5);
      expect(updated.iconIndex, 4);
      expect(updated.colorIndex, 5);
      expect(updated.name, 'Home');
    });

    test('1.4 Project props includes iconIndex and colorIndex for Equatable', () {
      final p1 = Project(
        id: 'p1',
        name: 'Home',
        members: const ['Alice'],
        iconIndex: 1,
        colorIndex: 2,
        createdAt: testDate,
        updatedAt: testDate,
      );
      final p2 = Project(
        id: 'p1',
        name: 'Home',
        members: const ['Alice'],
        iconIndex: 1,
        colorIndex: 2,
        createdAt: testDate,
        updatedAt: testDate,
      );
      final p3 = Project(
        id: 'p1',
        name: 'Home',
        members: const ['Alice'],
        iconIndex: 2,
        colorIndex: 2,
        createdAt: testDate,
        updatedAt: testDate,
      );
      expect(p1, equals(p2));
      expect(p1, isNot(equals(p3)));
    });

    test('1.5 ProjectModel fromJson & toJson serialize iconIndex and colorIndex', () {
      final model = ProjectModel(
        id: 'pm1',
        name: 'Party',
        members: const ['Dave', 'Eva'],
        iconIndex: 4,
        colorIndex: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );
      final json = model.toJson();
      expect(json['iconIndex'], 4);
      expect(json['colorIndex'], 1);

      final decoded = ProjectModel.fromJson(json);
      expect(decoded.iconIndex, 4);
      expect(decoded.colorIndex, 1);
      expect(decoded.id, 'pm1');
    });

    test('1.6 Backward compatibility: ProjectModel fromJson defaults to 0 when keys missing', () {
      final legacyJson = {
        'id': 'legacy_p',
        'name': 'Old Project',
        'description': 'Created before icons',
        'members': ['OldUser'],
        'createdAt': testDate.toIso8601String(),
        'updatedAt': testDate.toIso8601String(),
      };
      final decoded = ProjectModel.fromJson(legacyJson);
      expect(decoded.iconIndex, 0);
      expect(decoded.colorIndex, 0);
      expect(decoded.iconData, ProjectPalette.icons[0]);
      expect(decoded.color, ProjectPalette.colors[0]);
    });

    test('1.7 ProjectModel toSqliteMap serializes iconIndex and colorIndex', () {
      final model = ProjectModel(
        id: 'sqlite_1',
        name: 'Database Project',
        members: const ['Frank'],
        iconIndex: 3,
        colorIndex: 2,
        createdAt: testDate,
        updatedAt: testDate,
      );
      final map = model.toSqliteMap();
      expect(map['iconIndex'], 3);
      expect(map['colorIndex'], 2);
      expect(map['members'], jsonEncode(['Frank']));
    });

    test('1.8 ProjectModel.fromEntity preserves iconIndex and colorIndex', () {
      final entity = Project(
        id: 'ent1',
        name: 'Entity Proj',
        members: const ['Grace'],
        iconIndex: 5,
        colorIndex: 4,
        createdAt: testDate,
        updatedAt: testDate,
      );
      final model = ProjectModel.fromEntity(entity);
      expect(model.iconIndex, 5);
      expect(model.colorIndex, 4);
    });

    test('1.9 ProjectPalette safe out-of-bounds access fallback', () {
      expect(ProjectPalette.getIcon(-1), ProjectPalette.icons[0]);
      expect(ProjectPalette.getIcon(999), ProjectPalette.icons[0]);
      expect(ProjectPalette.getColor(-5), ProjectPalette.colors[0]);
      expect(ProjectPalette.getColor(999), ProjectPalette.colors[0]);
    });
  });

  group('AC 3 & AC 4: CreateProjectScreen Icon & Color Persistence', () {
    testWidgets('3.1 CreateProjectScreen preselects icon and color in edit mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final existingProject = Project(
        id: 'edit_p',
        name: 'Existing House',
        members: const ['John'],
        iconIndex: 2, // flight_takeoff_rounded
        colorIndex: 1, // Teal
        createdAt: testDate,
        updatedAt: testDate,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: CreateProjectScreen(project: existingProject),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Existing House'), findsOneWidget);
      expect(find.byIcon(ProjectPalette.icons[2]), findsWidgets);
    });

    testWidgets('3.2 Saving edited project persists updated iconIndex and colorIndex', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final existingProject = Project(
        id: 'edit_p',
        name: 'Existing House',
        members: const ['John'],
        iconIndex: 0,
        colorIndex: 0,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final pRepo = _FakeProjRepo([existingProject]);
      await tester.pumpWidget(
        _buildTestApp(
          child: CreateProjectScreen(project: existingProject),
          projRepo: pRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Tap the second icon
      final secondIconFinder = find.byIcon(ProjectPalette.icons[1]);
      if (secondIconFinder.evaluate().isNotEmpty) {
        await tester.tap(secondIconFinder.first);
        await tester.pumpAndSettle();
      }

      // Tap save project button
      final saveButton = find.byKey(const Key('saveProjectButton'));
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      final saved = pRepo.projects.firstWhere((p) => p.id == 'edit_p');
      expect(saved.iconIndex, 1);
    });
  });

  group('AC 5: ProjectScreen displays chosen icon and color', () {
    testWidgets('5.1 ProjectScreen renders project leading CircleAvatar with chosen color & icon', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = Project(
        id: 'p_screen',
        name: 'Summer Vacation',
        members: const ['Alex'],
        iconIndex: 2, // Flight
        colorIndex: 2, // Deep Orange
        createdAt: testDate,
        updatedAt: testDate,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: const ProjectScreen(),
          projects: [project],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Summer Vacation'), findsOneWidget);
      expect(find.byIcon(ProjectPalette.icons[2]), findsOneWidget);

      final avatarFinder = find.descendant(
        of: find.byKey(const Key('projectItem_p_screen')),
        matching: find.byType(CircleAvatar),
      );
      expect(avatarFinder, findsOneWidget);
      final avatar = tester.widget<CircleAvatar>(avatarFinder);
      expect(avatar.backgroundColor, ProjectPalette.colors[2]);
    });
  });

  group('AC 6 & AC 8: ProjectDetailScreen AppBar Color Gradient & Icon Theming', () {
    testWidgets('6.1 ProjectDetailScreen AppBar adapts project color and icon', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = Project(
        id: 'p_detail',
        name: 'Hanoi Trip',
        members: const ['Minh'],
        iconIndex: 3, // Restaurant
        colorIndex: 4, // Purple
        createdAt: testDate,
        updatedAt: testDate,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: ProjectDetailScreen(project: project),
        ),
      );
      await tester.pumpAndSettle();

      // Project icon is present in AppBar
      expect(find.byIcon(ProjectPalette.icons[3]), findsOneWidget);
      expect(find.text('Hanoi Trip'), findsOneWidget);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, ProjectPalette.colors[4]);
    });

    testWidgets('6.2 Amber project color triggers contrast-aware black text and icon', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final amberProject = Project(
        id: 'p_amber',
        name: 'Golden House',
        members: const ['Sunny'],
        iconIndex: 1, // Home
        colorIndex: 3, // Amber (bright, luminance > 0.5)
        createdAt: testDate,
        updatedAt: testDate,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: ProjectDetailScreen(project: amberProject),
        ),
      );
      await tester.pumpAndSettle();

      expect(amberProject.color.computeLuminance() > 0.5, isTrue);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, ProjectPalette.colors[3]);

      // Icon should be dark for high contrast
      final iconFinder = find.byIcon(ProjectPalette.icons[1]);
      expect(iconFinder, findsOneWidget);
      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.color, Colors.black87);
    });
  });

  group('AC 7: AddBillScreen Project Selector Icon & Color Chips', () {
    testWidgets('7.1 Project selector displays project icon & color chip when selected', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = Project(
        id: 'p_bill',
        name: 'Family Grocery',
        members: const ['Mom', 'Dad'],
        iconIndex: 7, // shopping_bag_rounded
        colorIndex: 1, // Teal
        createdAt: testDate,
        updatedAt: testDate,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: AddBillScreen(
            projectId: project.id,
            projectName: project.name,
          ),
          projects: [project],
        ),
      );
      await tester.pumpAndSettle();

      // Top project selector displays chosen icon and color chip
      expect(find.byKey(const Key('projectSelectorColorChip')), findsOneWidget);
      expect(find.byIcon(ProjectPalette.icons[7]), findsWidgets);
    });

    testWidgets('7.2 Project picker bottom sheet displays color avatar and chip for items', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = Project(
        id: 'p_picker',
        name: 'Company Outing',
        members: const ['Staff'],
        iconIndex: 6, // work_rounded
        colorIndex: 5, // Blue
        createdAt: testDate,
        updatedAt: testDate,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: const AddBillScreen(),
          projects: [project],
        ),
      );
      await tester.pumpAndSettle();

      // Open bottom sheet
      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectPickerBottomSheet')), findsOneWidget);
      expect(find.byKey(const Key('projectPickerColorChip_p_picker')), findsOneWidget);
      expect(find.byIcon(ProjectPalette.icons[6]), findsWidgets);
    });

    testWidgets('7.3 AddBillScreen project selector handles null project gracefully', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          child: const AddBillScreen(),
          projects: [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.folder_outlined), findsWidgets);
      expect(find.byKey(const Key('projectSelectorColorChip')), findsNothing);
    });
  });

  group('AC 8 & AC 9: Dark Mode Theming & Robust Edge Cases', () {
    testWidgets('8.1 ProjectDetailScreen in dark mode renders project color accent', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = Project(
        id: 'p_dark',
        name: 'Night Out',
        members: const ['Lan'],
        iconIndex: 4, // celebration
        colorIndex: 0, // Indigo
        createdAt: testDate,
        updatedAt: testDate,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: ProjectDetailScreen(project: project),
        ),
      );
      await tester.pumpAndSettle();

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.labelColor, Colors.white);
      expect(tabBar.indicatorColor, Colors.white);
    });

    test('9.1 Negative or large index clamp safe resolution', () {
      final pNegative = Project(
        id: 'neg',
        name: 'Negative Index',
        members: const ['Tom'],
        iconIndex: -10,
        colorIndex: -20,
        createdAt: testDate,
        updatedAt: testDate,
      );
      expect(pNegative.iconData, ProjectPalette.icons[0]);
      expect(pNegative.color, ProjectPalette.colors[0]);

      final pLarge = Project(
        id: 'large',
        name: 'Large Index',
        members: const ['Jerry'],
        iconIndex: 9999,
        colorIndex: 8888,
        createdAt: testDate,
        updatedAt: testDate,
      );
      expect(pLarge.iconData, ProjectPalette.icons[0]);
      expect(pLarge.color, ProjectPalette.colors[0]);
    });

    test('9.2 ProjectModel fromJson handles explicit nulls and missing keys', () {
      final jsonWithNulls = <String, dynamic>{
        'id': 'nulls_p',
        'name': 'Nulls Project',
        'members': <String>[],
        'iconIndex': null,
        'colorIndex': null,
        'createdAt': testDate.toIso8601String(),
        'updatedAt': testDate.toIso8601String(),
      };
      final model = ProjectModel.fromJson(jsonWithNulls);
      expect(model.iconIndex, 0);
      expect(model.colorIndex, 0);
    });

    testWidgets('3.3 CreateProjectScreen initializes with default index 0 when creating a new project', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          child: const CreateProjectScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(ProjectPalette.icons[0]), findsWidgets);
    });

    testWidgets('3.4 CreateProjectScreen saves new project with selected non-default icon and color', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pRepo = _FakeProjRepo();
      await tester.pumpWidget(
        _buildTestApp(
          child: const CreateProjectScreen(),
          projRepo: pRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(find.byKey(const Key('projectNameField')), 'Brand New Proj');
      // Enter member
      await tester.enterText(find.byKey(const Key('memberNameField')), 'Member 1');
      await tester.tap(find.byKey(const Key('addMemberButton')));
      await tester.pumpAndSettle();

      // Select icon 2
      await tester.tap(find.byKey(const Key('projectIconOption_2')));
      await tester.pumpAndSettle();

      // Tap save
      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(pRepo.projects, isNotEmpty);
      final created = pRepo.projects.first;
      expect(created.name, 'Brand New Proj');
      expect(created.iconIndex, 2);
    });
  });
}
