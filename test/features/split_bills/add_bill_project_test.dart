import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/usecases/usecase.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/data/models/bill_model.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/add_bill_screen.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_project_by_id_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';

// ─────────────────────────────────────────────
// Fake BillRepository (matches BillRepository interface)
// ─────────────────────────────────────────────
class FakeBillRepository implements BillRepository {
  final List<Bill> _bills = [];

  @override
  Future<Either<Failure, Bill>> create(Bill bill) async {
    _bills.add(bill);
    return Right(bill);
  }

  @override
  Future<Either<Failure, List<Bill>>> getAll() async =>
      Right(List.from(_bills));

  @override
  Future<Either<Failure, Bill>> getById(String billId) async {
    final b = _bills.firstWhere((b) => b.id == billId,
        orElse: () => throw Exception('Not found'));
    return Right(b);
  }

  @override
  Future<Either<Failure, Bill>> update(Bill bill) async => Right(bill);

  @override
  Future<Either<Failure, void>> delete(String billId) async {
    _bills.removeWhere((b) => b.id == billId);
    return const Right(null);
  }
}

// ─────────────────────────────────────────────
// Fake ProjectRepository
// ─────────────────────────────────────────────
class FakeProjectRepository implements ProjectRepository {
  final List<Project> _projects;
  FakeProjectRepository(this._projects);

  @override
  Future<Either<Failure, List<Project>>> getAll() async =>
      Right(List.from(_projects));

  @override
  Future<Either<Failure, Project>> create(Project project) async =>
      Right(project);

  @override
  Future<Either<Failure, Project>> getById(String id) async {
    final p = _projects.firstWhere((p) => p.id == id,
        orElse: () => throw Exception('Not found'));
    return Right(p);
  }

  @override
  Future<Either<Failure, Project>> update(Project project) async =>
      Right(project);

  @override
  Future<Either<Failure, void>> delete(String id) async =>
      const Right(null);
}

// ─────────────────────────────────────────────
// TestAppLocalizations
// ─────────────────────────────────────────────
class TestAppLocalizations extends AppLocalizations {
  TestAppLocalizations() : super(const Locale('en'));

  static const Map<String, String> _strings = {
    'add_bill': 'Add Bill',
    'bill_name': 'Bill Name',
    'bill_name_example': 'e.g., Lunch',
    'amount': 'Amount',
    'category': 'Category',
    'payer': 'Payer',
    'payer_hint': 'Who paid?',
    'participants': 'Participants',
    'participant_name': 'Participant Name',
    'enter_name': 'Enter name',
    'add': 'Add',
    'save_bill': 'Save Bill',
    'bill_name_required': 'Bill name is required',
    'amount_required': 'Amount is required',
    'amount_must_be_positive': 'Amount must be positive',
    'category_required': 'Category is required',
    'payer_required': 'Payer is required',
    'min_2_participants': 'At least 2 participants required',
    'select_project': 'Select Project (Optional)',
    'no_project': 'No Project',
    'project_members_loaded': 'Project members loaded',
    'project_no_members': 'This project has no members. Please add members first.',
    'select_participants': 'Select Participants',
    'tap_to_toggle': 'Tap to select/deselect',
    'bill_linked_to_project': 'Bill linked to project',
    'category_food': 'Food',
    'category_transport': 'Transport',
    'category_entertainment': 'Entertainment',
    'category_utilities': 'Utilities',
    'category_shopping': 'Shopping',
    'category_health': 'Health',
    'category_other': 'Other',
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
final _testDate = DateTime(2026, 9, 7);

Project makeProject({
  String id = 'proj-1',
  String name = 'Da Nang Trip',
  List<String> members = const ['An', 'Binh', 'Chi'],
}) =>
    Project(
      id: id,
      name: name,
      members: members,
      createdAt: _testDate,
      updatedAt: _testDate,
    );

Widget buildTestApp({
  required Widget child,
  required BillsBloc billsBloc,
  required ProjectBloc projectBloc,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>(
        create: (_) => LanguageProvider(),
      ),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<BillsBloc>.value(value: billsBloc),
        BlocProvider<ProjectBloc>.value(value: projectBloc),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          TestAppLocalizationsDelegate(),
        ],
        supportedLocales: const [Locale('en')],
        home: child,
      ),
    ),
  );
}

BillsBloc makeBillsBloc() {
  final repo = FakeBillRepository();
  return BillsBloc(
    getBillsUseCase: GetBillsUseCase(repo),
    addBillUseCase: AddBillUseCase(repo),
  );
}

ProjectBloc makeProjectBloc(List<Project> projects) {
  final repo = FakeProjectRepository(projects);
  return ProjectBloc(
    createProjectUseCase: CreateProjectUseCase(repo),
    getAllProjectsUseCase: GetAllProjectsUseCase(repo),
    updateProjectUseCase: UpdateProjectUseCase(repo),
    deleteProjectUseCase: DeleteProjectUseCase(repo),
  );
}

// ─────────────────────────────────────────────
// TESTS
// ─────────────────────────────────────────────
void main() {
  // ── Group 1: Bill entity projectId field ──
  group('Bill Entity - projectId field', () {
    test('Bill can be created without projectId', () {
      final bill = Bill(
        id: 'b1',
        title: 'Lunch',
        amount: 300000,
        category: 'food',
        date: _testDate,
        paidBy: 'An',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'An', amount: 150000),
          BillParticipant(participantId: 'p2', name: 'Binh', amount: 150000),
        ],
      );
      expect(bill.projectId, isNull);
    });

    test('Bill can be created with projectId', () {
      final bill = Bill(
        id: 'b1',
        title: 'Dinner',
        amount: 600000,
        category: 'food',
        date: _testDate,
        paidBy: 'An',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'An', amount: 200000),
          BillParticipant(participantId: 'p2', name: 'Binh', amount: 200000),
          BillParticipant(participantId: 'p3', name: 'Chi', amount: 200000),
        ],
        projectId: 'proj-1',
      );
      expect(bill.projectId, 'proj-1');
    });

    test('Bill equality considers projectId', () {
      final b1 = Bill(
        id: 'b1', title: 'Lunch', amount: 100,
        category: 'food', date: _testDate,
        paidBy: 'An',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'An', amount: 50),
          BillParticipant(participantId: 'p2', name: 'Binh', amount: 50),
        ],
        projectId: 'proj-1',
      );
      final b2 = b1; // same reference → equal
      expect(b1, equals(b2));
    });

    test('Bills with different projectId are not equal', () {
      const participants = [
        BillParticipant(participantId: 'p1', name: 'An', amount: 50),
        BillParticipant(participantId: 'p2', name: 'Binh', amount: 50),
      ];
      final b1 = Bill(
        id: 'b1', title: 'Lunch', amount: 100,
        category: 'food', date: _testDate,
        paidBy: 'An', participants: participants,
        projectId: 'proj-1',
      );
      final b2 = Bill(
        id: 'b1', title: 'Lunch', amount: 100,
        category: 'food', date: _testDate,
        paidBy: 'An', participants: participants,
        projectId: 'proj-2',
      );
      expect(b1, isNot(equals(b2)));
    });
  });

  // ── Group 2: BillModel serialization ──
  group('BillModel - projectId serialization', () {
    test('BillModel.fromJson handles projectId', () {
      final json = {
        'id': 'b1',
        'title': 'Trip dinner',
        'amount': 300000.0,
        'category': 'food',
        'date': _testDate.toIso8601String(),
        'paidBy': 'An',
        'participants': [
          {'participantId': 'p1', 'name': 'An', 'amount': 150000.0},
          {'participantId': 'p2', 'name': 'Binh', 'amount': 150000.0},
        ],
        'projectId': 'proj-1',
      };
      final model = BillModel.fromJson(json);
      expect(model.projectId, 'proj-1');
    });

    test('BillModel.fromJson handles null projectId', () {
      final json = {
        'id': 'b1',
        'title': 'Lunch',
        'amount': 100000.0,
        'category': 'food',
        'date': _testDate.toIso8601String(),
        'paidBy': 'An',
        'participants': [
          {'participantId': 'p1', 'name': 'An', 'amount': 50000.0},
          {'participantId': 'p2', 'name': 'Binh', 'amount': 50000.0},
        ],
      };
      final model = BillModel.fromJson(json);
      expect(model.projectId, isNull);
    });

    test('BillModel.toJson includes projectId when set', () {
      final bill = Bill(
        id: 'b1', title: 'Dinner', amount: 300000,
        category: 'food', date: _testDate,
        paidBy: 'An',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'An', amount: 150000),
          BillParticipant(participantId: 'p2', name: 'Binh', amount: 150000),
        ],
        projectId: 'proj-42',
      );
      final model = BillModel.fromEntity(bill);
      final json = model.toJson();
      expect(json['projectId'], 'proj-42');
    });

    test('BillModel.toJson omits projectId when null', () {
      final bill = Bill(
        id: 'b1', title: 'Lunch', amount: 100,
        category: 'food', date: _testDate,
        paidBy: 'An',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'An', amount: 50),
          BillParticipant(participantId: 'p2', name: 'Binh', amount: 50),
        ],
      );
      final json = BillModel.fromEntity(bill).toJson();
      expect(json.containsKey('projectId'), isFalse);
    });

    test('BillModel.fromEntity copies projectId', () {
      final bill = Bill(
        id: 'b1', title: 'Taxi', amount: 50000,
        category: 'transport', date: _testDate,
        paidBy: 'Binh',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'An', amount: 25000),
          BillParticipant(participantId: 'p2', name: 'Binh', amount: 25000),
        ],
        projectId: 'proj-trip',
      );
      final model = BillModel.fromEntity(bill);
      expect(model.projectId, 'proj-trip');
    });
  });

  // ── Group 3: Project entity for dropdown ──
  group('Project - members for auto-fill', () {
    test('Project exposes members list', () {
      final p = makeProject(members: ['An', 'Binh', 'Chi']);
      expect(p.members, ['An', 'Binh', 'Chi']);
    });

    test('Project with empty members list is valid', () {
      final p = makeProject(members: []);
      expect(p.members, isEmpty);
    });

    test('Multiple projects have independent member lists', () {
      final p1 = makeProject(id: 'p1', members: ['An', 'Binh']);
      final p2 = makeProject(id: 'p2', name: 'Hue Trip', members: ['Chi', 'Dung']);
      expect(p1.members, ['An', 'Binh']);
      expect(p2.members, ['Chi', 'Dung']);
    });
  });

  // ── Group 4: Widget tests ──────────────────
  group('AddBillScreen Widget Tests', () {
    testWidgets('Shows project dropdown at top', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billsBloc = makeBillsBloc();
      final projectBloc = makeProjectBloc([makeProject()]);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        billsBloc: billsBloc,
        projectBloc: projectBloc,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectDropdown')), findsOneWidget);

      billsBloc.close();
      projectBloc.close();
    });

    testWidgets('AddBillScreen shows all main fields', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billsBloc = makeBillsBloc();
      final projectBloc = makeProjectBloc([]);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        billsBloc: billsBloc,
        projectBloc: projectBloc,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Bill Name'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Payer'), findsOneWidget);
      expect(find.text('Participants'), findsOneWidget);

      billsBloc.close();
      projectBloc.close();
    });

    testWidgets('When project selected, member chips appear', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = makeProject(members: ['An', 'Binh', 'Chi']);
      final billsBloc = makeBillsBloc();
      final projectBloc = makeProjectBloc([project]);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        billsBloc: billsBloc,
        projectBloc: projectBloc,
      ));
      await tester.pumpAndSettle();

      // Open dropdown
      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();

      // Select the project "Da Nang Trip"
      await tester.tap(find.text('Da Nang Trip').last);
      await tester.pumpAndSettle();

      // Member chips should appear
      expect(find.byKey(const Key('member_chip_An')), findsOneWidget);
      expect(find.byKey(const Key('member_chip_Binh')), findsOneWidget);
      expect(find.byKey(const Key('member_chip_Chi')), findsOneWidget);

      billsBloc.close();
      projectBloc.close();
    });

    testWidgets('Member chips are pre-selected when project chosen', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = makeProject(members: ['An', 'Binh']);
      final billsBloc = makeBillsBloc();
      final projectBloc = makeProjectBloc([project]);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        billsBloc: billsBloc,
        projectBloc: projectBloc,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Da Nang Trip').last);
      await tester.pumpAndSettle();

      // FilterChip selected state
      final anChip = tester.widget<FilterChip>(
        find.byKey(const Key('member_chip_An')),
      );
      expect(anChip.selected, isTrue);

      billsBloc.close();
      projectBloc.close();
    });

    testWidgets('Tapping member chip toggles deselect', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = makeProject(members: ['An', 'Binh', 'Chi']);
      final billsBloc = makeBillsBloc();
      final projectBloc = makeProjectBloc([project]);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        billsBloc: billsBloc,
        projectBloc: projectBloc,
      ));
      await tester.pumpAndSettle();

      // Select project
      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Da Nang Trip').last);
      await tester.pumpAndSettle();

      // Deselect 'Chi'
      await tester.tap(find.byKey(const Key('member_chip_Chi')));
      await tester.pumpAndSettle();

      final chiChip = tester.widget<FilterChip>(
        find.byKey(const Key('member_chip_Chi')),
      );
      expect(chiChip.selected, isFalse);

      billsBloc.close();
      projectBloc.close();
    });

    testWidgets('Without project, shows manual participant input', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billsBloc = makeBillsBloc();
      final projectBloc = makeProjectBloc([]);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        billsBloc: billsBloc,
        projectBloc: projectBloc,
      ));
      await tester.pumpAndSettle();

      // Manual input field visible
      expect(find.widgetWithText(TextField, 'Participant Name'),
          findsOneWidget);

      billsBloc.close();
      projectBloc.close();
    });

    testWidgets('Edge case: project with 0 members shows warning', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final emptyProject = makeProject(
        id: 'proj-empty',
        name: 'Empty Project',
        members: [],
      );
      final billsBloc = makeBillsBloc();
      final projectBloc = makeProjectBloc([emptyProject]);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        billsBloc: billsBloc,
        projectBloc: projectBloc,
      ));
      await tester.pumpAndSettle();

      // Select empty project
      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Empty Project').last);
      await tester.pumpAndSettle();

      // Warning text visible (may appear in UI and/or SnackBar)
      expect(
        find.text('This project has no members. Please add members first.'),
        findsWidgets,
      );

      billsBloc.close();
      projectBloc.close();
    });

    testWidgets('Save button visible on screen', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billsBloc = makeBillsBloc();
      final projectBloc = makeProjectBloc([]);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        billsBloc: billsBloc,
        projectBloc: projectBloc,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('saveProjectButton')), findsOneWidget);

      billsBloc.close();
      projectBloc.close();
    });

    testWidgets('Selecting project pre-fills payer with first member', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = makeProject(members: ['An', 'Binh', 'Chi']);
      final billsBloc = makeBillsBloc();
      final projectBloc = makeProjectBloc([project]);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        billsBloc: billsBloc,
        projectBloc: projectBloc,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Da Nang Trip').last);
      await tester.pumpAndSettle();

      // Payer should be pre-filled with first member 'An'
      final payerField = tester.widget<TextField>(
        find.byKey(const Key('payerField')),
      );
      expect(payerField.controller!.text, 'An');

      billsBloc.close();
      projectBloc.close();
    });
  });
}
