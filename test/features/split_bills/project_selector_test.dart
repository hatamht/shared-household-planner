import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project_settings.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/add_bill_screen.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/bill_detail_screen.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_project_by_id_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';

// ─────────────────────────────────────────────
// Test Localization
// ─────────────────────────────────────────────
class TestAppLocalizations extends AppLocalizations {
  TestAppLocalizations() : super(const Locale('en'));

  static final Map<String, String> _dict = {
    'add_bill': 'Add Bill',
    'edit_bill': 'Edit Bill',
    'bill_name': 'Bill Name',
    'bill_name_example': 'e.g. Dinner with friends',
    'bill_name_required': 'Please enter a bill name',
    'amount': 'Amount',
    'amount_required': 'Please enter an amount',
    'amount_must_be_positive': 'Amount must be greater than zero',
    'payer_required': 'Please select or enter who paid',
    'min_2_participants': 'Please select at least 2 participants',
    'select_project': 'Select Project',
    'no_project': 'No Project',
    'project': 'Project',
    'project_required': 'Please select a project',
    'select_project_modal_title': 'Select Project',
    'no_project_selected': 'No Project Selected',
    'choose_project': 'Choose Project',
    'project_no_members': 'This project has no members. Please add members first.',
    'tap_to_toggle': 'Tap to select/deselect',
    'participants': 'Participants',
    'participant_name': 'Participant Name',
    'split': 'Split',
    'expense': 'Expense',
    'income': 'Income',
    'transfer': 'Transfer',
    'save_bill': 'Save Bill',
    'cancel': 'Cancel',
    'paid_by': 'Paid By',
    'each_pays': 'Each pays',
    'date': 'Date',
    'notes': 'Notes',
    'category': 'Category',
    'category_restaurant': 'Restaurant',
  };

  @override
  String translate(String key) => _dict[key] ?? key;
}

class _TestLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => TestAppLocalizations();
  @override
  bool shouldReload(_TestLocalizationsDelegate old) => false;
}

// ─────────────────────────────────────────────
// Test Repositories
// ─────────────────────────────────────────────
class FakeBillRepository implements BillRepository {
  final List<Bill> bills = [];
  Bill? lastCreatedBill;
  Bill? lastUpdatedBill;

  @override
  Future<Either<Failure, Bill>> create(Bill bill) async {
    bills.add(bill);
    lastCreatedBill = bill;
    return Right(bill);
  }

  @override
  Future<Either<Failure, List<Bill>>> getAll() async => Right(List.from(bills));

  @override
  Future<Either<Failure, Bill>> getById(String billId) async {
    final b = bills.firstWhere((b) => b.id == billId,
        orElse: () => throw Exception('Not found'));
    return Right(b);
  }

  @override
  Future<Either<Failure, Bill>> update(Bill bill) async {
    final idx = bills.indexWhere((b) => b.id == bill.id);
    if (idx != -1) {
      bills[idx] = bill;
    } else {
      bills.add(bill);
    }
    lastUpdatedBill = bill;
    return Right(bill);
  }

  @override
  Future<Either<Failure, void>> delete(String billId) async {
    bills.removeWhere((b) => b.id == billId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(String projectId) async {
    return Right(bills.where((b) => b.projectId == projectId).toList());
  }
}

class FakeProjectRepository implements ProjectRepository {
  final List<Project> projects;
  FakeProjectRepository(this.projects);

  @override
  Future<Either<Failure, List<Project>>> getAll() async => Right(List.from(projects));
  @override
  Future<Either<Failure, Project>> create(Project project) async {
    projects.add(project);
    return Right(project);
  }
  @override
  Future<Either<Failure, Project>> getById(String id) async {
    return Right(projects.firstWhere((p) => p.id == id));
  }
  @override
  Future<Either<Failure, Project>> update(Project project) async => Right(project);
  @override
  Future<Either<Failure, void>> delete(String id) async => const Right(null);
}

// ─────────────────────────────────────────────
// Test Helpers
// ─────────────────────────────────────────────
Project makeProject({
  String id = 'proj-1',
  String name = 'Apartment Shared',
  List<String>? members,
}) {
  return Project(
    id: id,
    name: name,
    members: members ?? ['Alice', 'Bob', 'Charlie'],
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

BillsBloc makeBillsBloc({FakeBillRepository? repo}) {
  final r = repo ?? FakeBillRepository();
  return BillsBloc(
    getBillsUseCase: GetBillsUseCase(r),
    addBillUseCase: AddBillUseCase(r),
  );
}

ProjectBloc makeProjectBloc(List<Project> projects) {
  final repo = FakeProjectRepository(projects);
  final bloc = ProjectBloc(
    getAllProjectsUseCase: GetAllProjectsUseCase(repo),
    createProjectUseCase: CreateProjectUseCase(repo),
    getProjectByIdUseCase: GetProjectByIdUseCase(repo),
    updateProjectUseCase: UpdateProjectUseCase(repo),
    deleteProjectUseCase: DeleteProjectUseCase(repo),
  );
  bloc.add(const GetAllProjects());
  return bloc;
}

Widget buildTestApp({
  required Widget child,
  BillsBloc? billsBloc,
  ProjectBloc? projectBloc,
  FakeBillRepository? billRepo,
  Brightness brightness = Brightness.light,
}) {
  Widget effectiveChild = child;
  if (child is AddBillScreen && child.initialCompactMode == null) {
    effectiveChild = AddBillScreen(
      key: child.key,
      billToEdit: child.billToEdit,
      projectId: child.projectId,
      requireProject: child.requireProject,
      projectSettings: child.projectSettings,
      template: child.template,
      initialImagePath: child.initialImagePath,
      initialImagePaths: child.initialImagePaths,
      onPickImage: child.onPickImage,
      onPickMultipleImages: child.onPickMultipleImages,
      projectName: child.projectName,
      initialCompactMode: false,
    );
  }
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
      if (billRepo != null)
        RepositoryProvider<BillRepository>.value(value: billRepo),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<BillsBloc>.value(value: billsBloc ?? makeBillsBloc()),
        BlocProvider<ProjectBloc>.value(value: projectBloc ?? makeProjectBloc([])),
      ],
      child: MaterialApp(
        theme: ThemeData(
          brightness: brightness,
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          _TestLocalizationsDelegate(),
        ],
        supportedLocales: const [Locale('en')],
        home: effectiveChild,
      ),
    ),
  );
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('AC 1: Project Selector Placement at Top of AddBillScreen', () {
    testWidgets('1.1 Project selector container rendered with Key("projectSelector")', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject();
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectSelector')), findsOneWidget);
      pb.close();
    });

    testWidgets('1.2 Project selector button rendered with Key("projectSelectorButton")', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject();
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectSelectorButton')), findsOneWidget);
      pb.close();
    });

    testWidgets('1.3 Backward-compatible Key("projectDropdown") is present in top selector', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject();
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectDropdown')), findsOneWidget);
      pb.close();
    });

    testWidgets('1.4 Project selector is placed before Title/Description input field', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject();
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      final selectorTop = tester.getTopLeft(find.byKey(const Key('projectSelector'))).dy;
      final titleTop = tester.getTopLeft(find.byKey(const Key('titleField'))).dy;
      expect(selectorTop, lessThan(titleTop));
      pb.close();
    });

    testWidgets('1.5 Project selector is placed before Amount section', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject();
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      final selectorTop = tester.getTopLeft(find.byKey(const Key('projectSelector'))).dy;
      final amountTop = tester.getTopLeft(find.widgetWithText(TextField, 'Amount')).dy;
      expect(selectorTop, lessThan(amountTop));
      pb.close();
    });

    testWidgets('1.6 Project selector button displays folder icon', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject();
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.folder_outlined), findsWidgets);
      pb.close();
    });

    testWidgets('1.7 Project selector has choose project button text', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject();
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.text('Choose Project'), findsOneWidget);
      pb.close();
    });

    testWidgets('1.8 Project selector displays label "Select Project"', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject();
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.text('Select Project'), findsWidgets);
      pb.close();
    });

    testWidgets('1.9 Project selector is always visible even when projects is empty', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pb = makeProjectBloc([]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(requireProject: false), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectSelector')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('No Project Selected')), findsOneWidget);
      pb.close();
    });

    testWidgets('1.10 Project selector displayed if requireProject is true even with empty projects', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pb = makeProjectBloc([]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(requireProject: true), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectSelector')), findsOneWidget);
      pb.close();
    });
  });

  group('AC 2: Display Current Selected Project Name', () {
    testWidgets('2.1 Shows selected project name with Key("selectedProjectName")', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(name: 'House 101');
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('selectedProjectName')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('House 101')), findsOneWidget);
      pb.close();
    });

    testWidgets('2.2 When project changes, Key("selectedProjectName") updates immediately', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject(id: 'p1', name: 'Project Alpha');
      final p2 = makeProject(id: 'p2', name: 'Project Beta');
      final pb = makeProjectBloc([p1, p2]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('Project Alpha')), findsOneWidget);

      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Project Beta').last);
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('Project Beta')), findsOneWidget);
      pb.close();
    });

    testWidgets('2.3 Displays "No Project Selected" when no project is chosen', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pb = makeProjectBloc([]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(requireProject: true), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('No Project Selected')), findsOneWidget);
      pb.close();
    });

    testWidgets('2.4 Displays project name when explicit projectId is passed in constructor', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject(id: 'p1', name: 'Room 202');
      final p2 = makeProject(id: 'p2', name: 'Room 303');
      final pb = makeProjectBloc([p1, p2]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p2'), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('Room 303')), findsOneWidget);
      pb.close();
    });

    testWidgets('2.5 Displays project name when editing a bill with projectId', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject(id: 'p1', name: 'Da Lat Vacation');
      final pb = makeProjectBloc([p1]);
      final bill = Bill(
        id: 'b1',
        title: 'Dinner',
        amount: 200000,
        paidBy: 'Alice',
        date: DateTime.now(),
        category: 'food',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50.0),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 50.0),
        ],
        projectId: 'p1',
      );

      await tester.pumpWidget(buildTestApp(child: AddBillScreen(billToEdit: bill), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('Da Lat Vacation')), findsOneWidget);
      pb.close();
    });

    testWidgets('2.6 Selected project name has bold font weight', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(name: 'Bold Test');
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.byKey(const Key('selectedProjectName')));
      expect(textWidget.style?.fontWeight, equals(FontWeight.bold));
      pb.close();
    });

    testWidgets('2.7 Switching to No Project updates selectedProjectName', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(name: 'Trip');
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No Project').last);
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('No Project Selected')), findsOneWidget);
      pb.close();
    });

    testWidgets('2.8 Project name handles long titles gracefully with ellipsis', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final longName = 'A Very Long Project Name That Exceeds Normal Length For Testing Ellipsis';
      final p = makeProject(name: longName);
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.byKey(const Key('selectedProjectName')));
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
      pb.close();
    });

    testWidgets('2.9 Project name displays single member project name properly', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(name: 'Solo Project', members: ['Solo']);
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('Solo Project')), findsOneWidget);
      pb.close();
    });

    testWidgets('2.10 Selected project name font size is at least 14', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(name: 'Size Check');
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.byKey(const Key('selectedProjectName')));
      expect(textWidget.style?.fontSize, greaterThanOrEqualTo(14.0));
      pb.close();
    });
  });

  group('AC 3: Project Picker Modal Bottom Sheet', () {
    testWidgets('3.1 Tapping projectSelectorButton opens bottom sheet with Key("projectPickerBottomSheet")', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject();
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectPickerBottomSheet')), findsOneWidget);
      pb.close();
    });

    testWidgets('3.2 Bottom sheet shows title with Key("projectPickerTitle")', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject();
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectPickerTitle')), findsOneWidget);
      expect(find.text('Select Project'), findsWidgets);
      pb.close();
    });

    testWidgets('3.3 Bottom sheet lists all available projects', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject(id: 'p1', name: 'Apartment A');
      final p2 = makeProject(id: 'p2', name: 'Apartment B');
      final pb = makeProjectBloc([p1, p2]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectPickerItem_p1')), findsOneWidget);
      expect(find.byKey(const Key('projectPickerItem_p2')), findsOneWidget);
      pb.close();
    });

    testWidgets('3.4 Bottom sheet items have Key("projectItem_{id}")', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(id: 'p-special', name: 'Special Project');
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectItem_p-special')), findsOneWidget);
      pb.close();
    });

    testWidgets('3.5 Tapping project item in bottom sheet selects it and closes modal', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject(id: 'p1', name: 'Alpha');
      final p2 = makeProject(id: 'p2', name: 'Beta');
      final pb = makeProjectBloc([p1, p2]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectPickerItem_p2')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectPickerBottomSheet')), findsNothing);
      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('Beta')), findsOneWidget);
      pb.close();
    });

    testWidgets('3.6 Bottom sheet shows check icon for currently selected project', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject(id: 'p1', name: 'Alpha');
      final pb = makeProjectBloc([p1]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      pb.close();
    });

    testWidgets('3.7 Bottom sheet has "No Project" option with Key("projectPickerItem_none")', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject();
      final pb = makeProjectBloc([p1]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectPickerItem_none')), findsOneWidget);
      pb.close();
    });

    testWidgets('3.8 Selecting "No Project" clears selected project', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject(name: 'House');
      final pb = makeProjectBloc([p1]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectPickerItem_none')));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('No Project Selected')), findsOneWidget);
      pb.close();
    });

    testWidgets('3.9 Bottom sheet displays member count in subtitle', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject(members: ['A', 'B', 'C', 'D']);
      final pb = makeProjectBloc([p1]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();

      expect(find.text('4 members'), findsOneWidget);
      pb.close();
    });

    testWidgets('3.10 Bottom sheet close button dismisses sheet without selection change', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject(name: 'Original');
      final pb = makeProjectBloc([p1]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectPickerCloseButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectPickerBottomSheet')), findsNothing);
      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('Original')), findsOneWidget);
      pb.close();
    });

    testWidgets('3.11 Bottom sheet has drag handle bar at top', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject();
      final pb = makeProjectBloc([p1]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectPickerDragHandle')), findsOneWidget);
      pb.close();
    });

    testWidgets('3.12 Bottom sheet scrolls when there are many projects', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projects = List.generate(15, (i) => makeProject(id: 'p_$i', name: 'Project $i'));
      final pb = makeProjectBloc(projects);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectPickerItem_p_0')), findsOneWidget);
      pb.close();
    });
  });

  group('AC 4: Dynamic Member Chips Update', () {
    testWidgets('4.1 Selecting project displays member chips for only that project', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(members: ['Emma', 'Liam', 'Noah']);
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('member_chip_Emma')), findsOneWidget);
      expect(find.byKey(const Key('member_chip_Liam')), findsOneWidget);
      expect(find.byKey(const Key('member_chip_Noah')), findsOneWidget);
      expect(find.byKey(const Key('member_chip_Ghost')), findsNothing);
      pb.close();
    });

    testWidgets('4.2 Switching project updates member chips to new project members only', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject(id: 'p1', name: 'Project 1', members: ['Alpha', 'Beta']);
      final p2 = makeProject(id: 'p2', name: 'Project 2', members: ['Gamma', 'Delta']);
      final pb = makeProjectBloc([p1, p2]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('member_chip_Alpha')), findsOneWidget);
      expect(find.byKey(const Key('member_chip_Beta')), findsOneWidget);
      expect(find.byKey(const Key('member_chip_Gamma')), findsNothing);

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('projectPickerItem_p2')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('member_chip_Alpha')), findsNothing);
      expect(find.byKey(const Key('member_chip_Beta')), findsNothing);
      expect(find.byKey(const Key('member_chip_Gamma')), findsOneWidget);
      expect(find.byKey(const Key('member_chip_Delta')), findsOneWidget);
      pb.close();
    });

    testWidgets('4.3 Member chips are initially selected by default', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(members: ['User1', 'User2']);
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      final chip1 = tester.widget<FilterChip>(find.byKey(const Key('member_chip_User1')));
      final chip2 = tester.widget<FilterChip>(find.byKey(const Key('member_chip_User2')));
      expect(chip1.selected, isTrue);
      expect(chip2.selected, isTrue);
      pb.close();
    });

    testWidgets('4.4 Tapping a member chip toggles its selection', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(members: ['User1', 'User2']);
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('member_chip_User1')));
      await tester.pumpAndSettle();

      final chip1 = tester.widget<FilterChip>(find.byKey(const Key('member_chip_User1')));
      expect(chip1.selected, isFalse);
      pb.close();
    });

    testWidgets('4.5 Member cards list displays cards with Key("member_card_{name}")', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('member_card_Alice')), findsOneWidget);
      expect(find.byKey(const Key('member_card_Bob')), findsOneWidget);
      pb.close();
    });

    testWidgets('4.6 Member checkbox matches chip selection state', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(members: ['Alice']);
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      final cb = tester.widget<Checkbox>(find.byKey(const Key('member_checkbox_Alice')));
      expect(cb.value, isTrue);
      pb.close();
    });

    testWidgets('4.7 Tapping member card toggles checkbox and chip state', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('member_card_Alice')));
      await tester.pumpAndSettle();

      final cb = tester.widget<Checkbox>(find.byKey(const Key('member_checkbox_Alice')));
      final chip = tester.widget<FilterChip>(find.byKey(const Key('member_chip_Alice')));
      expect(cb.value, isFalse);
      expect(chip.selected, isFalse);
      pb.close();
    });

    testWidgets('4.8 Payer field defaults to first member of selected project', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(members: ['Zoe', 'Yan']);
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      final payerField = tester.widget<TextField>(find.byKey(const Key('payerField')));
      expect(payerField.controller?.text, equals('Zoe'));
      pb.close();
    });

    testWidgets('4.9 Empty project members shows warning message', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(members: []);
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.text('This project has no members. Please add members first.'), findsWidgets);
      pb.close();
    });

    testWidgets('4.10 Member initial avatar displays first letter uppercase', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(members: ['charlie']);
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.text('C'), findsWidgets);
      pb.close();
    });
  });

  group('AC 5: Member Filtering and Multi-Select Logic', () {
    testWidgets('5.1 Multi-select allows picking any combination of members', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(members: ['A', 'B', 'C', 'D']);
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      // Deselect B and D
      await tester.tap(find.byKey(const Key('member_chip_B')));
      await tester.tap(find.byKey(const Key('member_chip_D')));
      await tester.pumpAndSettle();

      expect(tester.widget<FilterChip>(find.byKey(const Key('member_chip_A'))).selected, isTrue);
      expect(tester.widget<FilterChip>(find.byKey(const Key('member_chip_B'))).selected, isFalse);
      expect(tester.widget<FilterChip>(find.byKey(const Key('member_chip_C'))).selected, isTrue);
      expect(tester.widget<FilterChip>(find.byKey(const Key('member_chip_D'))).selected, isFalse);
      pb.close();
    });

    testWidgets('5.2 Deselecting and re-selecting member restores selected state', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(members: ['A', 'B']);
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('member_chip_A')));
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(find.byKey(const Key('member_chip_A'))).selected, isFalse);

      await tester.tap(find.byKey(const Key('member_chip_A')));
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(find.byKey(const Key('member_chip_A'))).selected, isTrue);
      pb.close();
    });

    testWidgets('5.3 Project with 5 members renders 5 chips and 5 cards', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(members: ['M1', 'M2', 'M3', 'M4', 'M5']);
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      for (int i = 1; i <= 5; i++) {
        expect(find.byKey(Key('member_chip_M$i')), findsOneWidget);
        expect(find.byKey(Key('member_card_M$i')), findsOneWidget);
      }
      pb.close();
    });

    testWidgets('5.4 Equal split recalculates when member is deselected', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(members: ['A', 'B']);
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '100000');
      await tester.pumpAndSettle();

      expect(find.textContaining('50000'), findsWidgets);
      pb.close();
    });

    testWidgets('5.5 Deselecting all members and selecting one leaves only 1 participant', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(members: ['A', 'B']);
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('member_chip_A')));
      await tester.tap(find.byKey(const Key('member_chip_B')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('member_chip_A')));
      await tester.pumpAndSettle();

      expect(tester.widget<FilterChip>(find.byKey(const Key('member_chip_A'))).selected, isTrue);
      expect(tester.widget<FilterChip>(find.byKey(const Key('member_chip_B'))).selected, isFalse);
      pb.close();
    });

    testWidgets('5.6 Only members from currently active project exist in DOM', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject(id: 'p1', members: ['AliceInProject1']);
      final p2 = makeProject(id: 'p2', members: ['BobInProject2']);
      final pb = makeProjectBloc([p1, p2]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('member_chip_AliceInProject1')), findsOneWidget);
      expect(find.byKey(const Key('member_chip_BobInProject2')), findsNothing);
      pb.close();
    });

    testWidgets('5.7 Tapping member checkbox directly toggles participant selection', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(members: ['DirectCheck']);
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('member_checkbox_DirectCheck')));
      await tester.pumpAndSettle();

      expect(tester.widget<Checkbox>(find.byKey(const Key('member_checkbox_DirectCheck'))).value, isFalse);
      pb.close();
    });

    testWidgets('5.8 Members chips maintain alphabetical or defined order', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(members: ['First', 'Second', 'Third']);
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip)).toList();
      expect(chips.length, equals(3));
      pb.close();
    });

    testWidgets('5.9 Multiple member names are handled correctly with spaces', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(members: ['Nguyen Van A', 'Tran Thi B']);
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('member_chip_Nguyen Van A')), findsOneWidget);
      expect(find.byKey(const Key('member_chip_Tran Thi B')), findsOneWidget);
      pb.close();
    });

    testWidgets('5.10 Tap to toggle helper text is displayed above member list', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(members: ['A']);
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.text('Tap to select/deselect'), findsOneWidget);
      pb.close();
    });
  });

  group('AC 6: Default Project Persistence & Resolution', () {
    testWidgets('6.1 Defaults to first project when no saved project exists', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject(id: 'p1', name: 'First Proj');
      final p2 = makeProject(id: 'p2', name: 'Second Proj');
      final pb = makeProjectBloc([p1, p2]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('First Proj')), findsOneWidget);
      pb.close();
    });

    testWidgets('6.2 Restores last selected project from SharedPreferences', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({
        'last_selected_project_id': 'p2',
      });

      final p1 = makeProject(id: 'p1', name: 'First Proj');
      final p2 = makeProject(id: 'p2', name: 'Second Proj');
      final pb = makeProjectBloc([p1, p2]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('Second Proj')), findsOneWidget);
      pb.close();
    });

    testWidgets('6.3 Selecting a project saves its id to SharedPreferences', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject(id: 'p1', name: 'Proj 1');
      final p2 = makeProject(id: 'p2', name: 'Proj 2');
      final pb = makeProjectBloc([p1, p2]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('projectPickerItem_p2')));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_selected_project_id'), equals('p2'));
      pb.close();
    });

    testWidgets('6.4 Selecting a project via dropdown saves its id to SharedPreferences', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject(id: 'p1', name: 'Proj 1');
      final p2 = makeProject(id: 'p2', name: 'Proj 2');
      final pb = makeProjectBloc([p1, p2]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Proj 2').last);
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_selected_project_id'), equals('p2'));
      pb.close();
    });

    testWidgets('6.5 If saved project id is not found in available projects, falls back to first', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({
        'last_selected_project_id': 'non_existent_id',
      });

      final p1 = makeProject(id: 'p1', name: 'Fallback Proj');
      final pb = makeProjectBloc([p1]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('Fallback Proj')), findsOneWidget);
      pb.close();
    });

    testWidgets('6.6 Constructor widget.projectId takes precedence over SharedPreferences', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({
        'last_selected_project_id': 'p1',
      });

      final p1 = makeProject(id: 'p1', name: 'Saved Proj');
      final p2 = makeProject(id: 'p2', name: 'Constructor Proj');
      final pb = makeProjectBloc([p1, p2]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p2'), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('Constructor Proj')), findsOneWidget);
      pb.close();
    });

    testWidgets('6.7 Editing bill with projectId ignores SharedPreferences', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({
        'last_selected_project_id': 'p2',
      });

      final p1 = makeProject(id: 'p1', name: 'Bill Proj');
      final p2 = makeProject(id: 'p2', name: 'Saved Proj');
      final pb = makeProjectBloc([p1, p2]);

      final bill = Bill(
        id: 'b1',
        title: 'Rent',
        amount: 500,
        paidBy: 'Alice',
        date: DateTime.now(),
        category: 'housing',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50.0),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 50.0),
        ],
        projectId: 'p1',
      );

      await tester.pumpWidget(buildTestApp(child: AddBillScreen(billToEdit: bill), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('Bill Proj')), findsOneWidget);
      pb.close();
    });

    testWidgets('6.8 Editing bill without projectId keeps project null even if SharedPreferences exists', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({
        'last_selected_project_id': 'p1',
      });

      final p1 = makeProject(id: 'p1', name: 'Proj 1');
      final pb = makeProjectBloc([p1]);

      final bill = Bill(
        id: 'b1',
        title: 'Coffee',
        amount: 50,
        paidBy: 'Alice',
        date: DateTime.now(),
        category: 'food',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50.0),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 50.0),
        ],
        projectId: null,
      );

      await tester.pumpWidget(buildTestApp(child: AddBillScreen(billToEdit: bill), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('No Project Selected')), findsOneWidget);
      pb.close();
    });

    testWidgets('6.9 Switching projects multiple times updates SharedPreferences to final choice', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject(id: 'p1', name: 'P1');
      final p2 = makeProject(id: 'p2', name: 'P2');
      final p3 = makeProject(id: 'p3', name: 'P3');
      final pb = makeProjectBloc([p1, p2, p3]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('projectPickerItem_p2')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('projectPickerItem_p3')));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_selected_project_id'), equals('p3'));
      pb.close();
    });

    testWidgets('6.10 Persisted preference key is exactly last_selected_project_id', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(id: 'p-exact', name: 'Exact');
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('projectPickerItem_p-exact')));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('last_selected_project_id'), isTrue);
      pb.close();
    });

    testWidgets('6.11 Default project resolution handles empty project list gracefully', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pb = makeProjectBloc([]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(requireProject: false), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectSelector')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('No Project Selected')), findsOneWidget);
      pb.close();
    });

    testWidgets('6.12 ProjectBloc async load triggers default project resolution', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(id: 'p-async', name: 'Async Project');
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('Async Project')), findsOneWidget);
      pb.close();
    });
  });

  group('AC 7: Required Project Validation', () {
    testWidgets('7.1 Error snackbar with Key("projectRequiredSnackBar") shown when project is required and null', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pb = makeProjectBloc([]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(requireProject: true), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectRequiredSnackBar')), findsOneWidget);
      expect(find.text('Please select a project'), findsOneWidget);
      pb.close();
    });

    testWidgets('7.2 Cannot submit new bill if project is deselected to null when projects exist', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);
      final billRepo = FakeBillRepository();
      final bb = makeBillsBloc(repo: billRepo);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        projectBloc: pb,
        billsBloc: bb,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('projectPickerItem_none')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'Dinner');
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '100000');
      await tester.enterText(find.byKey(const Key('payerField')), 'Alice');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.bills.isEmpty, isTrue);
      expect(find.byKey(const Key('projectRequiredSnackBar')), findsOneWidget);

      pb.close();
      bb.close();
    });

    testWidgets('7.3 Form passes project validation when valid project is selected', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);
      final billRepo = FakeBillRepository();
      final bb = makeBillsBloc(repo: billRepo);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        projectBloc: pb,
        billsBloc: bb,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'Dinner');
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '100000');
      await tester.enterText(find.byKey(const Key('payerField')), 'Alice');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectRequiredSnackBar')), findsNothing);
      expect(billRepo.bills.length, equals(1));

      pb.close();
      bb.close();
    });

    testWidgets('7.4 Editing existing bill without project does not block save if requireProject is false', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pb = makeProjectBloc([]);
      final billRepo = FakeBillRepository();
      final bb = makeBillsBloc(repo: billRepo);

      final bill = Bill(
        id: 'b1',
        title: 'Snack',
        amount: 25000,
        paidBy: 'Alice',
        date: DateTime.now(),
        category: 'food',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50.0),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 50.0),
        ],
        projectId: null,
      );
      billRepo.bills.add(bill);

      await tester.pumpWidget(buildTestApp(
        child: AddBillScreen(billToEdit: bill, requireProject: false),
        projectBloc: pb,
        billsBloc: bb,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectRequiredSnackBar')), findsNothing);

      pb.close();
      bb.close();
    });

    testWidgets('7.5 SnackBar displays floating behavior', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pb = makeProjectBloc([]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(requireProject: true), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      final snackBar = tester.widget<SnackBar>(find.byKey(const Key('projectRequiredSnackBar')));
      expect(snackBar.behavior, equals(SnackBarBehavior.floating));
      pb.close();
    });

    testWidgets('7.6 Validation fails immediately before checking title/amount if project required and missing', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pb = makeProjectBloc([]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(requireProject: true), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(find.text('Please select a project'), findsOneWidget);
      expect(find.text('Please enter a bill name'), findsNothing);
      pb.close();
    });

    testWidgets('7.7 Selecting project dismisses requirement error on next save attempt', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);
      final billRepo = FakeBillRepository();
      final bb = makeBillsBloc(repo: billRepo);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(requireProject: true),
        projectBloc: pb,
        billsBloc: bb,
      ));
      await tester.pumpAndSettle();

      // Enter valid fields
      await tester.enterText(find.byKey(const Key('titleField')), 'Dinner');
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '100000');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectRequiredSnackBar')), findsNothing);
      pb.close();
      bb.close();
    });

    testWidgets('7.8 requireProject constructor defaults to false', (tester) async {
      const screen = AddBillScreen();
      expect(screen.requireProject, isFalse);
    });

    testWidgets('7.9 requireProject parameter can be explicitly set to true', (tester) async {
      const screen = AddBillScreen(requireProject: true);
      expect(screen.requireProject, isTrue);
    });

    testWidgets('7.10 Editing bill with requireProject true requires project', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pb = makeProjectBloc([]);
      final bill = Bill(
        id: 'b1',
        title: 'Snack',
        amount: 25000,
        paidBy: 'Alice',
        date: DateTime.now(),
        category: 'food',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50.0),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 50.0),
        ],
        projectId: null,
      );

      await tester.pumpWidget(buildTestApp(
        child: AddBillScreen(billToEdit: bill, requireProject: true),
        projectBloc: pb,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectRequiredSnackBar')), findsOneWidget);
      pb.close();
    });
  });

  group('AC 8: Bill Saves with Correct projectId', () {
    testWidgets('8.1 Newly created bill contains the selected project ID', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(id: 'proj-xyz', name: 'XYZ Project', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);
      final billRepo = FakeBillRepository();
      final bb = makeBillsBloc(repo: billRepo);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        projectBloc: pb,
        billsBloc: bb,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'Team Lunch');
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '300000');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.lastCreatedBill, isNotNull);
      expect(billRepo.lastCreatedBill!.projectId, equals('proj-xyz'));

      pb.close();
      bb.close();
    });

    testWidgets('8.2 Switching project before save persists the updated project ID', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject(id: 'p1', name: 'Proj 1', members: ['Alice', 'Bob']);
      final p2 = makeProject(id: 'p2', name: 'Proj 2', members: ['Charlie', 'Dave']);
      final pb = makeProjectBloc([p1, p2]);
      final billRepo = FakeBillRepository();
      final bb = makeBillsBloc(repo: billRepo);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        projectBloc: pb,
        billsBloc: bb,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('projectPickerItem_p2')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'Switch Test');
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '120000');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.lastCreatedBill!.projectId, equals('p2'));

      pb.close();
      bb.close();
    });

    testWidgets('8.3 Bill participants match the selected project members upon saving', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(members: ['Anna', 'Ben', 'Chris']);
      final pb = makeProjectBloc([p]);
      final billRepo = FakeBillRepository();
      final bb = makeBillsBloc(repo: billRepo);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        projectBloc: pb,
        billsBloc: bb,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('member_chip_Chris')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'Two Members');
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '80000');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      final saved = billRepo.lastCreatedBill!;
      final participantNames = saved.participants.map((p) => p.name).toList();
      expect(participantNames, containsAll(['Anna', 'Ben']));
      expect(participantNames, isNot(contains('Chris')));

      pb.close();
      bb.close();
    });

    testWidgets('8.4 Bill with explicit widget.projectId saves with that ID', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(id: 'explicit-p', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);
      final billRepo = FakeBillRepository();
      final bb = makeBillsBloc(repo: billRepo);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(projectId: 'explicit-p'),
        projectBloc: pb,
        billsBloc: bb,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'Explicit Project');
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '50000');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.lastCreatedBill!.projectId, equals('explicit-p'));
      pb.close();
      bb.close();
    });

    testWidgets('8.5 Editing bill preserves original projectId when unchanged', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(id: 'p-orig', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);
      final billRepo = FakeBillRepository();
      final bb = makeBillsBloc(repo: billRepo);

      final bill = Bill(
        id: 'b1',
        title: 'Original Title',
        amount: 40000,
        paidBy: 'Alice',
        date: DateTime.now(),
        category: 'food',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50.0),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 50.0),
        ],
        projectId: 'p-orig',
      );
      billRepo.bills.add(bill);

      await tester.pumpWidget(buildTestApp(
        child: AddBillScreen(billToEdit: bill),
        projectBloc: pb,
        billsBloc: bb,
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.lastUpdatedBill!.projectId, equals('p-orig'));
      pb.close();
      bb.close();
    });

    testWidgets('8.6 Editing bill and changing title updates bill with same projectId', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(id: 'p-same', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);
      final billRepo = FakeBillRepository();
      final bb = makeBillsBloc(repo: billRepo);

      final bill = Bill(
        id: 'b1',
        title: 'Old Title',
        amount: 40000,
        paidBy: 'Alice',
        date: DateTime.now(),
        category: 'food',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50.0),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 50.0),
        ],
        projectId: 'p-same',
      );
      billRepo.bills.add(bill);

      await tester.pumpWidget(buildTestApp(
        child: AddBillScreen(billToEdit: bill),
        projectBloc: pb,
        billsBloc: bb,
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'New Title');
      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.lastUpdatedBill!.title, equals('New Title'));
      expect(billRepo.lastUpdatedBill!.projectId, equals('p-same'));
      pb.close();
      bb.close();
    });

    testWidgets('8.7 Bill saves with correct amount and currency alongside projectId', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(id: 'p-fields', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);
      final billRepo = FakeBillRepository();
      final bb = makeBillsBloc(repo: billRepo);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        projectBloc: pb,
        billsBloc: bb,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'Dinner Bill');
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '250000');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      final b = billRepo.lastCreatedBill!;
      expect(b.amount, equals(250000.0));
      expect(b.projectId, equals('p-fields'));
      pb.close();
      bb.close();
    });

    testWidgets('8.8 Bill saves correct paidBy member from project', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(id: 'p-payer', members: ['Payer1', 'Payer2']);
      final pb = makeProjectBloc([p]);
      final billRepo = FakeBillRepository();
      final bb = makeBillsBloc(repo: billRepo);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        projectBloc: pb,
        billsBloc: bb,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'Bill');
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '100000');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.lastCreatedBill!.paidBy, equals('Payer1'));
      pb.close();
      bb.close();
    });
  });

  group('AC 9: Project Badge in BillDetailScreen', () {
    testWidgets('9.1 Displays Key("billDetailProject") badge when bill has projectId', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(id: 'p1', name: 'Summer Trip');
      final pb = makeProjectBloc([p]);
      final bill = Bill(
        id: 'b1',
        title: 'Flight Tickets',
        amount: 5000000,
        paidBy: 'Alice',
        date: DateTime.now(),
        category: 'travel',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50.0),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 50.0),
        ],
        projectId: 'p1',
      );

      await tester.pumpWidget(buildTestApp(
        child: BillDetailScreen(bill: bill),
        projectBloc: pb,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('billDetailProject')), findsOneWidget);
      pb.close();
    });

    testWidgets('9.2 Project badge displays Key("projectBadge") and icon Key("billProjectBadgeIcon")', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(id: 'p1', name: 'Summer Trip');
      final pb = makeProjectBloc([p]);
      final bill = Bill(
        id: 'b1',
        title: 'Flight',
        amount: 100000,
        paidBy: 'Alice',
        date: DateTime.now(),
        category: 'travel',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50.0),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 50.0),
        ],
        projectId: 'p1',
      );

      await tester.pumpWidget(buildTestApp(
        child: BillDetailScreen(bill: bill),
        projectBloc: pb,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectBadge')), findsOneWidget);
      expect(find.byKey(const Key('billProjectBadgeIcon')), findsOneWidget);
      pb.close();
    });

    testWidgets('9.3 Project badge displays resolved project name from ProjectBloc', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(id: 'p1', name: 'Da Nang Getaway');
      final pb = makeProjectBloc([p]);
      final bill = Bill(
        id: 'b1',
        title: 'Hotel',
        amount: 2000000,
        paidBy: 'Alice',
        date: DateTime.now(),
        category: 'travel',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50.0),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 50.0),
        ],
        projectId: 'p1',
      );

      await tester.pumpWidget(buildTestApp(
        child: BillDetailScreen(bill: bill),
        projectBloc: pb,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Project: Da Nang Getaway'), findsOneWidget);
      pb.close();
    });

    testWidgets('9.4 Project badge is hidden when bill has null projectId', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pb = makeProjectBloc([]);
      final bill = Bill(
        id: 'b1',
        title: 'Snack',
        amount: 20000,
        paidBy: 'Alice',
        date: DateTime.now(),
        category: 'food',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50.0),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 50.0),
        ],
        projectId: null,
      );

      await tester.pumpWidget(buildTestApp(
        child: BillDetailScreen(bill: bill),
        projectBloc: pb,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('billDetailProject')), findsNothing);
      pb.close();
    });

    testWidgets('9.5 Project badge is hidden when bill has empty projectId', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pb = makeProjectBloc([]);
      final bill = Bill(
        id: 'b1',
        title: 'Snack',
        amount: 20000,
        paidBy: 'Alice',
        date: DateTime.now(),
        category: 'food',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50.0),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 50.0),
        ],
        projectId: '',
      );

      await tester.pumpWidget(buildTestApp(
        child: BillDetailScreen(bill: bill),
        projectBloc: pb,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('billDetailProject')), findsNothing);
      pb.close();
    });

    testWidgets('9.6 Project badge has rounded corners decoration', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(id: 'p1', name: 'P1');
      final pb = makeProjectBloc([p]);
      final bill = Bill(
        id: 'b1',
        title: 'Coffee',
        amount: 30000,
        paidBy: 'Alice',
        date: DateTime.now(),
        category: 'food',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50.0),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 50.0),
        ],
        projectId: 'p1',
      );

      await tester.pumpWidget(buildTestApp(
        child: BillDetailScreen(bill: bill),
        projectBloc: pb,
      ));
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(find.byKey(const Key('billDetailProject')));
      final decor = container.decoration as BoxDecoration?;
      expect(decor?.borderRadius, isNotNull);
      pb.close();
    });

    testWidgets('9.7 Project badge shows explicit projectName parameter if provided in constructor', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pb = makeProjectBloc([]);
      final bill = Bill(
        id: 'b1',
        title: 'Dinner',
        amount: 150000,
        paidBy: 'Alice',
        date: DateTime.now(),
        category: 'food',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50.0),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 50.0),
        ],
        projectId: 'p-explicit',
      );

      await tester.pumpWidget(buildTestApp(
        child: BillDetailScreen(bill: bill, projectName: 'Explicit Passed Name'),
        projectBloc: pb,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Project: Explicit Passed Name'), findsOneWidget);
      pb.close();
    });

    testWidgets('9.8 Project badge falls back to bill.projectId when ProjectBloc does not have project', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pb = makeProjectBloc([]);
      final bill = Bill(
        id: 'b1',
        title: 'Dinner',
        amount: 150000,
        paidBy: 'Alice',
        date: DateTime.now(),
        category: 'food',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50.0),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 50.0),
        ],
        projectId: 'p-raw-id',
      );

      await tester.pumpWidget(buildTestApp(
        child: BillDetailScreen(bill: bill),
        projectBloc: pb,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Project: p-raw-id'), findsOneWidget);
      pb.close();
    });
  });

  group('AC 10: Theme, Dark Mode & Localizations', () {
    testWidgets('10.1 Project selector renders with dark theme surface in Dark Mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject();
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        projectBloc: pb,
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(find.byKey(const Key('projectSelector')));
      final decor = container.decoration as BoxDecoration?;
      expect(decor?.color, equals(const Color(0xFF242424)));
      pb.close();
    });

    testWidgets('10.2 Project selector bottom sheet renders in Dark Mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject();
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        projectBloc: pb,
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectPickerBottomSheet')), findsOneWidget);
      pb.close();
    });

    testWidgets('10.3 Project badge in BillDetailScreen renders properly in Dark Mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(id: 'p1', name: 'Dark Proj');
      final pb = makeProjectBloc([p]);
      final bill = Bill(
        id: 'b1',
        title: 'Dark Mode Test',
        amount: 50000,
        paidBy: 'Alice',
        date: DateTime.now(),
        category: 'food',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50.0),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 50.0),
        ],
        projectId: 'p1',
      );

      await tester.pumpWidget(buildTestApp(
        child: BillDetailScreen(bill: bill),
        projectBloc: pb,
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('billDetailProject')), findsOneWidget);
      pb.close();
    });

    testWidgets('10.4 Project selector renders properly in Light Mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject();
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        projectBloc: pb,
        brightness: Brightness.light,
      ));
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(find.byKey(const Key('projectSelector')));
      final decor = container.decoration as BoxDecoration?;
      expect(decor?.color, equals(Colors.white));
      pb.close();
    });

    testWidgets('10.5 Project selector button has compact visual density', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject();
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      final button = tester.widget<OutlinedButton>(find.byKey(const Key('projectSelectorButton')));
      expect(button.style?.visualDensity, equals(VisualDensity.compact));
      pb.close();
    });

    testWidgets('10.6 Project dropdown border is rounded', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject();
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButtonFormField<Project?>>(find.byKey(const Key('projectDropdown')));
      final border = dropdown.decoration.border as OutlineInputBorder?;
      expect(border?.borderRadius, equals(BorderRadius.circular(10)));
      pb.close();
    });

    testWidgets('10.7 Project selector renders cleanly with special characters in project name', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(name: 'Nhà & Bạn Bè (2026) #1');
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('Nhà & Bạn Bè (2026) #1')), findsOneWidget);
      pb.close();
    });

    testWidgets('10.8 Project bottom sheet handles project name with unicode characters', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p = makeProject(name: 'Chuyến du lịch Đà Nẵng 🏖️');
      final pb = makeProjectBloc([p]);
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();

      expect(find.text('Chuyến du lịch Đà Nẵng 🏖️'), findsWidgets);
      pb.close();
    });
  });
}
