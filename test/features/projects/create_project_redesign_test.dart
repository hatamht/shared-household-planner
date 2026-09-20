import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_project_by_id_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/create_project_screen.dart';

// ─── Fake Repository ────────────────────────────────────────────────────────
class FakeProjectRepository implements ProjectRepository {
  final List<Project> _projects;
  FakeProjectRepository([this._projects = const []]);

  @override
  Future<Either<Failure, List<Project>>> getAll() async => Right(List.from(_projects));
  @override
  Future<Either<Failure, Project>> create(Project project) async => Right(project);
  @override
  Future<Either<Failure, Project>> getById(String id) async =>
      Right(_projects.firstWhere((p) => p.id == id));
  @override
  Future<Either<Failure, Project>> update(Project project) async => Right(project);
  @override
  Future<Either<Failure, void>> delete(String id) async => const Right(null);
}

// ─── Localizations Test Helper ──────────────────────────────────────────────
class _RedesignTestLoc extends AppLocalizations {
  final String langCode;
  _RedesignTestLoc(this.langCode) : super(Locale(langCode));

  static const Map<String, String> _en = {
    'create_project': 'Create Project',
    'edit_project': 'Edit Project',
    'project_name': 'Project Name',
    'project_name_example': 'e.g., Trip to Da Nang, Home Renovation',
    'project_name_required': 'Project name is required',
    'project_name_duplicate': 'Project name already exists',
    'description': 'Description',
    'description_example': 'e.g., Summer vacation 2026',
    'project_icon': 'Project Icon',
    'project_color': 'Theme Color',
    'members': 'Members',
    'add_member': 'Add Member',
    'member_name': 'Member Name',
    'enter_name': 'Enter member name',
    'min_1_member': 'At least 1 member is required',
    'member_already_exists': 'Member already exists',
    'initial_member_hint': 'You (initial member)',
    'save': 'Save',
    'cancel': 'Cancel',
  };

  static const Map<String, String> _vi = {
    'create_project': 'Tạo dự án',
    'edit_project': 'Chỉnh sửa dự án',
    'project_name': 'Tên dự án',
    'project_name_example': 'VD: Chuyến đi Đà Nẵng, Mua sắm nhà',
    'project_name_required': 'Tên dự án không được trống',
    'project_name_duplicate': 'Tên dự án đã tồn tại',
    'description': 'Mô tả',
    'description_example': 'VD: Chuyến đi hè 2026',
    'project_icon': 'Biểu tượng dự án',
    'project_color': 'Màu chủ đề',
    'members': 'Thành viên',
    'add_member': 'Thêm thành viên',
    'member_name': 'Tên thành viên',
    'enter_name': 'Nhập tên thành viên',
    'min_1_member': 'Cần ít nhất 1 thành viên',
    'member_already_exists': 'Thành viên đã tồn tại',
    'initial_member_hint': 'Bạn (thành viên ban đầu)',
    'save': 'Lưu',
    'cancel': 'Hủy',
  };

  @override
  String translate(String key) {
    if (langCode == 'vi') return _vi[key] ?? key;
    return _en[key] ?? key;
  }
}

class _RedesignTestLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  final String langCode;
  const _RedesignTestLocDelegate([this.langCode = 'en']);

  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => _RedesignTestLoc(langCode);
  @override
  bool shouldReload(_RedesignTestLocDelegate old) => false;
}

Widget buildTestScreen({
  Project? project,
  List<Project> existingProjects = const [],
  ProjectBloc? customBloc,
  String language = 'en',
  ThemeData? theme,
}) {
  final repo = FakeProjectRepository(existingProjects);
  final bloc = customBloc ??
      ProjectBloc(
        createProjectUseCase: CreateProjectUseCase(repo),
        getAllProjectsUseCase: GetAllProjectsUseCase(repo),
        getProjectByIdUseCase: GetProjectByIdUseCase(repo),
        updateProjectUseCase: UpdateProjectUseCase(repo),
        deleteProjectUseCase: DeleteProjectUseCase(repo),
      );

  if (existingProjects.isNotEmpty && customBloc == null) {
    bloc.emit(ProjectLoaded(projects: existingProjects));
  }

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
    ],
    child: BlocProvider<ProjectBloc>.value(
      value: bloc,
      child: MaterialApp(
        theme: theme ?? ThemeData.light(useMaterial3: true),
        localizationsDelegates: [_RedesignTestLocDelegate(language)],
        supportedLocales: const [Locale('en'), Locale('vi')],
        home: CreateProjectScreen(project: project),
      ),
    ),
  );
}

Future<void> pumpScreen(
  WidgetTester tester, {
  Project? project,
  List<Project> existingProjects = const [],
  ProjectBloc? customBloc,
  String language = 'en',
  ThemeData? theme,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(buildTestScreen(
    project: project,
    existingProjects: existingProjects,
    customBloc: customBloc,
    language: language,
    theme: theme,
  ));
  if (settle) {
    await tester.pumpAndSettle();
  }
}

final _sampleDate = DateTime(2026, 9, 20);

Project _makeProject({
  String id = 'proj-1',
  String name = 'Da Nang Trip',
  String? description = 'Summer holidays',
  List<String> members = const ['Alice', 'Bob'],
}) {
  return Project(
    id: id,
    name: name,
    description: description,
    members: members,
    createdAt: _sampleDate,
    updatedAt: _sampleDate,
  );
}

void main() {
  group('AC 1. Header & MD3 AppBar', () {
    testWidgets('1.1 AppBar displays title "Create Project" in create mode', (tester) async {
      await pumpScreen(tester, );
      expect(find.text('Create Project'), findsOneWidget);
    });

    testWidgets('1.2 AppBar displays title "Edit Project" in edit mode', (tester) async {
      final p = _makeProject();
      await pumpScreen(tester, project: p);
      expect(find.text('Edit Project'), findsOneWidget);
    });

    testWidgets('1.3 AppBar has flexibleSpace with gradient decoration', (tester) async {
      await pumpScreen(tester, );
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.flexibleSpace, isNotNull);
    });

    testWidgets('1.4 AppBar foregroundColor is white', (tester) async {
      await pumpScreen(tester, );
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.foregroundColor, equals(Colors.white));
    });

    testWidgets('1.5 Avatar preview container is displayed at top center', (tester) async {
      await pumpScreen(tester, );
      expect(find.byKey(const Key('projectAvatarPreview')), findsOneWidget);
    });
  });

  group('AC 2. Project Name Input', () {
    testWidgets('2.1 Project name textfield exists with Key("projectNameField")', (tester) async {
      await pumpScreen(tester, );
      expect(find.byKey(const Key('projectNameField')), findsOneWidget);
    });

    testWidgets('2.2 Project name field displays prefix icon', (tester) async {
      await pumpScreen(tester, );
      expect(find.byIcon(Icons.business_rounded), findsOneWidget);
    });

    testWidgets('2.3 Project name label is displayed', (tester) async {
      await pumpScreen(tester, );
      expect(find.text('Project Name'), findsOneWidget);
    });

    testWidgets('2.4 Pre-fills existing project name in edit mode', (tester) async {
      final p = _makeProject(name: 'House Renovation');
      await pumpScreen(tester, project: p);
      final field = tester.widget<TextFormField>(find.byKey(const Key('projectNameField')));
      expect(field.controller?.text, equals('House Renovation'));
    });

    testWidgets('2.5 Allows typing project name', (tester) async {
      await pumpScreen(tester, );
      await tester.enterText(find.byKey(const Key('projectNameField')), 'Japan Travel');
      expect(find.text('Japan Travel'), findsOneWidget);
    });
  });

  group('AC 3. Project Description Input', () {
    testWidgets('3.1 Project description textfield exists with Key("projectDescriptionField")', (tester) async {
      await pumpScreen(tester, );
      expect(find.byKey(const Key('projectDescriptionField')), findsOneWidget);
    });

    testWidgets('3.2 Description field has minLines of 3', (tester) async {
      await pumpScreen(tester, );
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('projectDescriptionField')),
          matching: find.byType(TextField),
        ),
      );
      expect(field.minLines, equals(3));
    });

    testWidgets('3.3 Description field has character counter (maxLength: 200)', (tester) async {
      await pumpScreen(tester, );
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('projectDescriptionField')),
          matching: find.byType(TextField),
        ),
      );
      expect(field.maxLength, equals(200));
    });

    testWidgets('3.4 Pre-fills description in edit mode', (tester) async {
      final p = _makeProject(description: 'Special trip');
      await pumpScreen(tester, project: p);
      final field = tester.widget<TextFormField>(find.byKey(const Key('projectDescriptionField')));
      expect(field.controller?.text, equals('Special trip'));
    });

    testWidgets('3.5 Allows entering multi-line description text', (tester) async {
      await pumpScreen(tester, );
      await tester.enterText(find.byKey(const Key('projectDescriptionField')), 'Line 1\nLine 2\nLine 3');
      expect(find.text('Line 1\nLine 2\nLine 3'), findsOneWidget);
    });
  });

  group('AC 4. Avatar & Icon Picker', () {
    testWidgets('4.1 Icon picker container exists with Key("projectIconPicker")', (tester) async {
      await pumpScreen(tester, );
      expect(find.byKey(const Key('projectIconPicker')), findsOneWidget);
    });

    testWidgets('4.2 Icon picker presents 8 icon options', (tester) async {
      await pumpScreen(tester, );
      for (int i = 0; i < 8; i++) {
        expect(find.byKey(Key('projectIconOption_$i')), findsOneWidget);
      }
    });

    testWidgets('4.3 Tapping icon option 1 (home) updates avatar preview', (tester) async {
      await pumpScreen(tester, );
      await tester.tap(find.byKey(const Key('projectIconOption_1')));
      await tester.pumpAndSettle();
      final preview = find.descendant(
        of: find.byKey(const Key('projectAvatarPreview')),
        matching: find.byIcon(Icons.home_rounded),
      );
      expect(preview, findsOneWidget);
    });

    testWidgets('4.4 Tapping icon option 2 (flight) updates avatar preview', (tester) async {
      await pumpScreen(tester, );
      await tester.tap(find.byKey(const Key('projectIconOption_2')));
      await tester.pumpAndSettle();
      final preview = find.descendant(
        of: find.byKey(const Key('projectAvatarPreview')),
        matching: find.byIcon(Icons.flight_takeoff_rounded),
      );
      expect(preview, findsOneWidget);
    });

    testWidgets('4.5 Tapping icon option 3 (restaurant) updates preview', (tester) async {
      await pumpScreen(tester, );
      await tester.tap(find.byKey(const Key('projectIconOption_3')));
      await tester.pumpAndSettle();
      final preview = find.descendant(
        of: find.byKey(const Key('projectAvatarPreview')),
        matching: find.byIcon(Icons.restaurant_rounded),
      );
      expect(preview, findsOneWidget);
    });

    testWidgets('4.6 Tapping icon option 4 (celebration) updates preview', (tester) async {
      await pumpScreen(tester, );
      await tester.tap(find.byKey(const Key('projectIconOption_4')));
      await tester.pumpAndSettle();
      final preview = find.descendant(
        of: find.byKey(const Key('projectAvatarPreview')),
        matching: find.byIcon(Icons.celebration_rounded),
      );
      expect(preview, findsOneWidget);
    });

    testWidgets('4.7 Tapping icon option 5 (school) updates preview', (tester) async {
      await pumpScreen(tester, );
      await tester.tap(find.byKey(const Key('projectIconOption_5')));
      await tester.pumpAndSettle();
      final preview = find.descendant(
        of: find.byKey(const Key('projectAvatarPreview')),
        matching: find.byIcon(Icons.school_rounded),
      );
      expect(preview, findsOneWidget);
    });

    testWidgets('4.8 Tapping icon option 6 (work) updates preview', (tester) async {
      await pumpScreen(tester, );
      await tester.tap(find.byKey(const Key('projectIconOption_6')));
      await tester.pumpAndSettle();
      final preview = find.descendant(
        of: find.byKey(const Key('projectAvatarPreview')),
        matching: find.byIcon(Icons.work_rounded),
      );
      expect(preview, findsOneWidget);
    });

    testWidgets('4.9 Tapping icon option 7 (shopping) updates preview', (tester) async {
      await pumpScreen(tester, );
      await tester.tap(find.byKey(const Key('projectIconOption_7')));
      await tester.pumpAndSettle();
      final preview = find.descendant(
        of: find.byKey(const Key('projectAvatarPreview')),
        matching: find.byIcon(Icons.shopping_bag_rounded),
      );
      expect(preview, findsOneWidget);
    });
  });

  group('AC 5. Color Theme Picker', () {
    testWidgets('5.1 Color picker container exists with Key("projectColorPicker")', (tester) async {
      await pumpScreen(tester, );
      expect(find.byKey(const Key('projectColorPicker')), findsOneWidget);
    });

    testWidgets('5.2 Color picker presents 6 color options', (tester) async {
      await pumpScreen(tester, );
      for (int i = 0; i < 6; i++) {
        expect(find.byKey(Key('colorChip_$i')), findsOneWidget);
      }
    });

    testWidgets('5.3 Selected color chip displays checkmark icon', (tester) async {
      await pumpScreen(tester, );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('5.4 Tapping color chip 1 (teal) updates active color and checkmark', (tester) async {
      await pumpScreen(tester, );
      await tester.tap(find.byKey(const Key('colorChip_1')));
      await tester.pumpAndSettle();
      final chip1Check = find.descendant(
        of: find.byKey(const Key('colorChip_1')),
        matching: find.byIcon(Icons.check),
      );
      expect(chip1Check, findsOneWidget);
    });

    testWidgets('5.5 Tapping color chip 2 (deep orange) selects it', (tester) async {
      await pumpScreen(tester, );
      await tester.tap(find.byKey(const Key('colorChip_2')));
      await tester.pumpAndSettle();
      final check = find.descendant(
        of: find.byKey(const Key('colorChip_2')),
        matching: find.byIcon(Icons.check),
      );
      expect(check, findsOneWidget);
    });

    testWidgets('5.6 Tapping color chip 3 (amber) selects it', (tester) async {
      await pumpScreen(tester, );
      await tester.tap(find.byKey(const Key('colorChip_3')));
      await tester.pumpAndSettle();
      final check = find.descendant(
        of: find.byKey(const Key('colorChip_3')),
        matching: find.byIcon(Icons.check),
      );
      expect(check, findsOneWidget);
    });

    testWidgets('5.7 Tapping color chip 4 (purple) selects it', (tester) async {
      await pumpScreen(tester, );
      await tester.tap(find.byKey(const Key('colorChip_4')));
      await tester.pumpAndSettle();
      final check = find.descendant(
        of: find.byKey(const Key('colorChip_4')),
        matching: find.byIcon(Icons.check),
      );
      expect(check, findsOneWidget);
    });

    testWidgets('5.8 Tapping color chip 5 (blue) selects it', (tester) async {
      await pumpScreen(tester, );
      await tester.tap(find.byKey(const Key('colorChip_5')));
      await tester.pumpAndSettle();
      final check = find.descendant(
        of: find.byKey(const Key('colorChip_5')),
        matching: find.byIcon(Icons.check),
      );
      expect(check, findsOneWidget);
    });
  });

  group('AC 6. Members Management & Preview', () {
    testWidgets('6.1 Member input and add button exist', (tester) async {
      await pumpScreen(tester, );
      expect(find.byKey(const Key('memberNameField')), findsOneWidget);
      expect(find.byKey(const Key('addMemberButton')), findsOneWidget);
    });

    testWidgets('6.2 Adding a member displays member chip and increases count', (tester) async {
      await pumpScreen(tester, );
      await tester.enterText(find.byKey(const Key('memberNameField')), 'David');
      await tester.tap(find.byKey(const Key('addMemberButton')));
      await tester.pumpAndSettle();
      expect(find.text('David'), findsOneWidget);
      expect(find.byKey(const Key('memberChip_0')), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // member count badge
    });

    testWidgets('6.3 Adding duplicate member displays duplicate warning', (tester) async {
      await pumpScreen(tester, );
      await tester.enterText(find.byKey(const Key('memberNameField')), 'Alice');
      await tester.tap(find.byKey(const Key('addMemberButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('memberNameField')), 'Alice');
      await tester.tap(find.byKey(const Key('addMemberButton')));
      await tester.pumpAndSettle();

      expect(find.text('Member already exists'), findsOneWidget);
    });

    testWidgets('6.4 Submitting textfield adds member via keyboard', (tester) async {
      await pumpScreen(tester, );
      await tester.enterText(find.byKey(const Key('memberNameField')), 'Emma');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Emma'), findsOneWidget);
    });

    testWidgets('6.5 Removing member chip deletes it and decreases count', (tester) async {
      await pumpScreen(tester, );
      await tester.enterText(find.byKey(const Key('memberNameField')), 'Frank');
      await tester.tap(find.byKey(const Key('addMemberButton')));
      await tester.pumpAndSettle();
      expect(find.text('Frank'), findsOneWidget);

      final deleteIcon = find.descendant(
        of: find.byKey(const Key('memberChip_0')),
        matching: find.byIcon(Icons.close),
      );
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      expect(find.text('Frank'), findsNothing);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('6.6 Empty member list displays initial member hint', (tester) async {
      await pumpScreen(tester, );
      expect(find.text('You (initial member)'), findsOneWidget);
    });

    testWidgets('6.7 Edit mode pre-fills existing members as chips', (tester) async {
      final p = _makeProject(members: ['Alice', 'Bob', 'Charlie']);
      await pumpScreen(tester, project: p);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });

  group('AC 7. Save Button & Loading State', () {
    testWidgets('7.1 Save button exists with Key("saveProjectButton")', (tester) async {
      await pumpScreen(tester, );
      expect(find.byKey(const Key('saveProjectButton')), findsOneWidget);
    });

    testWidgets('7.2 Save button is elevated and full-width', (tester) async {
      await pumpScreen(tester, );
      final button = tester.widget<ElevatedButton>(find.byKey(const Key('saveProjectButton')));
      expect(button, isNotNull);
    });

    testWidgets('7.3 Loading state shows CircularProgressIndicator during ProjectLoading', (tester) async {
      final repo = FakeProjectRepository();
      final bloc = ProjectBloc(
        createProjectUseCase: CreateProjectUseCase(repo),
        getAllProjectsUseCase: GetAllProjectsUseCase(repo),
        getProjectByIdUseCase: GetProjectByIdUseCase(repo),
        updateProjectUseCase: UpdateProjectUseCase(repo),
        deleteProjectUseCase: DeleteProjectUseCase(repo),
      );
      bloc.emit(const ProjectLoading());

      await pumpScreen(tester, customBloc: bloc, settle: false);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('AC 8. Cancel Button', () {
    testWidgets('8.1 Cancel button exists with Key("cancelProjectButton")', (tester) async {
      await pumpScreen(tester, );
      expect(find.byKey(const Key('cancelProjectButton')), findsOneWidget);
    });

    testWidgets('8.2 Cancel button has text "Cancel"', (tester) async {
      await pumpScreen(tester, );
      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  group('AC 9. Single-Column Scrollable Layout', () {
    testWidgets('9.1 Uses SingleChildScrollView for scrollable form', (tester) async {
      await pumpScreen(tester, );
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('9.2 SingleChildScrollView has horizontal padding of 20', (tester) async {
      await pumpScreen(tester, );
      final scrollView = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
      expect(scrollView.padding, equals(const EdgeInsets.symmetric(horizontal: 20, vertical: 16)));
    });
  });

  group('AC 10. Form Validation', () {
    testWidgets('10.1 Empty project name shows "Project name is required"', (tester) async {
      await pumpScreen(tester, );
      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();
      expect(find.text('Project name is required'), findsOneWidget);
    });

    testWidgets('10.2 Project with no members shows "At least 1 member is required"', (tester) async {
      await pumpScreen(tester, );
      await tester.enterText(find.byKey(const Key('projectNameField')), 'My Project');
      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();
      expect(find.text('At least 1 member is required'), findsOneWidget);
    });

    testWidgets('10.3 Duplicate project name shows "Project name already exists"', (tester) async {
      final existing = [_makeProject(name: 'House Share')];
      await pumpScreen(tester, existingProjects: existing);

      await tester.enterText(find.byKey(const Key('projectNameField')), 'House Share');
      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(find.text('Project name already exists'), findsOneWidget);
    });

    testWidgets('10.4 Duplicate name check is case-insensitive', (tester) async {
      final existing = [_makeProject(name: 'House Share')];
      await pumpScreen(tester, existingProjects: existing);

      await tester.enterText(find.byKey(const Key('projectNameField')), 'house share');
      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(find.text('Project name already exists'), findsOneWidget);
    });

    testWidgets('10.5 Editing project with same name does not trigger duplicate error', (tester) async {
      final project = _makeProject(id: 'proj-1', name: 'House Share');
      final existing = [project];
      await pumpScreen(tester, project: project, existingProjects: existing);

      // Tap save in edit mode
      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(find.text('Project name already exists'), findsNothing);
    });

    testWidgets('10.6 Valid form dispatches CreateProject and succeeds', (tester) async {
      await pumpScreen(tester, );

      await tester.enterText(find.byKey(const Key('projectNameField')), 'New Journey');
      await tester.enterText(find.byKey(const Key('memberNameField')), 'Sarah');
      await tester.tap(find.byKey(const Key('addMemberButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();
      expect(find.text('Project name is required'), findsNothing);
      expect(find.text('At least 1 member is required'), findsNothing);
    });
  });

  group('AC 11. Dark & Light Theme Support', () {
    testWidgets('11.1 Renders properly in dark theme', (tester) async {
      await pumpScreen(tester, theme: ThemeData.dark(useMaterial3: true));
      expect(find.byType(CreateProjectScreen), findsOneWidget);
      expect(find.byKey(const Key('projectNameField')), findsOneWidget);
    });

    testWidgets('11.2 Renders properly in light theme', (tester) async {
      await pumpScreen(tester, theme: ThemeData.light(useMaterial3: true));
      expect(find.byType(CreateProjectScreen), findsOneWidget);
      expect(find.byKey(const Key('projectNameField')), findsOneWidget);
    });
  });

  group('AC 12. EN / VI Internationalization', () {
    testWidgets('12.1 Vietnamese localization displays "Tạo dự án" on AppBar', (tester) async {
      await pumpScreen(tester, language: 'vi');
      expect(find.text('Tạo dự án'), findsOneWidget);
    });

    testWidgets('12.2 Vietnamese localization displays "Tên dự án"', (tester) async {
      await pumpScreen(tester, language: 'vi');
      expect(find.text('Tên dự án'), findsOneWidget);
    });

    testWidgets('12.3 Vietnamese localization displays "Mô tả"', (tester) async {
      await pumpScreen(tester, language: 'vi');
      expect(find.text('Mô tả'), findsOneWidget);
    });

    testWidgets('12.4 Vietnamese localization displays "Thành viên"', (tester) async {
      await pumpScreen(tester, language: 'vi');
      expect(find.text('Thành viên'), findsOneWidget);
    });

    testWidgets('12.5 Vietnamese localization displays "Lưu"', (tester) async {
      await pumpScreen(tester, language: 'vi');
      expect(find.text('Lưu'), findsOneWidget);
    });

    testWidgets('12.6 Vietnamese localization displays "Hủy"', (tester) async {
      await pumpScreen(tester, language: 'vi');
      expect(find.text('Hủy'), findsOneWidget);
    });

    testWidgets('12.7 Vietnamese validation shows "Tên dự án không được trống"', (tester) async {
      await pumpScreen(tester, language: 'vi');
      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();
      expect(find.text('Tên dự án không được trống'), findsOneWidget);
    });

    testWidgets('12.8 Vietnamese validation shows "Cần ít nhất 1 thành viên"', (tester) async {
      await pumpScreen(tester, language: 'vi');
      await tester.enterText(find.byKey(const Key('projectNameField')), 'Dự án mới');
      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();
      expect(find.text('Cần ít nhất 1 thành viên'), findsOneWidget);
    });

    testWidgets('12.9 Vietnamese validation shows "Tên dự án đã tồn tại"', (tester) async {
      final existing = [_makeProject(name: 'Nhà chung')];
      await pumpScreen(tester, existingProjects: existing, language: 'vi');
      await tester.enterText(find.byKey(const Key('projectNameField')), 'Nhà chung');
      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();
      expect(find.text('Tên dự án đã tồn tại'), findsOneWidget);
    });
  });
}
