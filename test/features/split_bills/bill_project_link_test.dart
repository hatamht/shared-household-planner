import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:dartz/dartz.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/usecases/usecase.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/data/models/bill_model.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/add_bill_screen.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/bill_detail_screen.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/fast_add_bill_screen.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project_settings.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_project_by_id_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/calculate_settlement_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/features/templates/presentation/bloc/bill_templates_bloc.dart';
import 'package:shared_household_planner/features/templates/domain/entities/bill_template.dart';
import 'package:shared_household_planner/features/templates/domain/repositories/bill_template_repository.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/get_templates_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/create_template_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/update_template_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/delete_template_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/toggle_favorite_template_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/record_template_usage_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/get_suggested_templates_usecase.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';

// ─────────────────────────────────────────────
// In-Memory BillRepository
// ─────────────────────────────────────────────
class MockBillRepository implements BillRepository {
  final List<Bill> bills;
  MockBillRepository([List<Bill>? initial]) : bills = initial ?? [];

  Bill? lastCreatedBill;
  Bill? lastUpdatedBill;
  String? lastDeletedId;

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
    lastDeletedId = billId;
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(String projectId) async {
    final filtered = bills.where((b) => b.projectId == projectId).toList();
    return Right(filtered);
  }
}

// ─────────────────────────────────────────────
// In-Memory ProjectRepository
// ─────────────────────────────────────────────
class MockProjectRepository implements ProjectRepository {
  final List<Project> projects;
  MockProjectRepository([List<Project>? initial]) : projects = initial ?? [];

  @override
  Future<Either<Failure, List<Project>>> getAll() async =>
      Right(List.from(projects));

  @override
  Future<Either<Failure, Project>> create(Project project) async {
    projects.add(project);
    return Right(project);
  }

  @override
  Future<Either<Failure, Project>> getById(String id) async {
    final p = projects.firstWhere((p) => p.id == id,
        orElse: () => throw Exception('Not found'));
    return Right(p);
  }

  @override
  Future<Either<Failure, Project>> update(Project project) async {
    final idx = projects.indexWhere((p) => p.id == project.id);
    if (idx != -1) projects[idx] = project;
    return Right(project);
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    projects.removeWhere((p) => p.id == id);
    return const Right(null);
  }
}

// ─────────────────────────────────────────────
// Mock BillTemplateRepository
// ─────────────────────────────────────────────
class MockBillTemplateRepository implements BillTemplateRepository {
  final List<BillTemplate> templates = [];
  BillTemplate? lastCreated;

  @override
  Future<Either<Failure, List<BillTemplate>>> getTemplates({String? projectId}) async =>
      Right(List.from(templates));

  @override
  Future<Either<Failure, BillTemplate>> getTemplateById(String id) async =>
      Right(templates.firstWhere((t) => t.id == id));

  @override
  Future<Either<Failure, BillTemplate>> createTemplate(BillTemplate template) async {
    templates.add(template);
    lastCreated = template;
    return Right(template);
  }

  @override
  Future<Either<Failure, BillTemplate>> updateTemplate(BillTemplate template) async {
    final idx = templates.indexWhere((t) => t.id == template.id);
    if (idx != -1) templates[idx] = template;
    return Right(template);
  }

  @override
  Future<Either<Failure, void>> deleteTemplate(String id) async {
    templates.removeWhere((t) => t.id == id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, BillTemplate>> toggleFavorite(String id) async {
    final idx = templates.indexWhere((t) => t.id == id);
    final t = templates[idx];
    final updated = t.copyWith(isFavorite: !t.isFavorite);
    templates[idx] = updated;
    return Right(updated);
  }

  @override
  Future<Either<Failure, BillTemplate>> toggleFavoriteTemplate(String id) =>
      toggleFavorite(id);

  @override
  Future<Either<Failure, List<BillTemplate>>> getFavoriteTemplates({String? projectId}) async =>
      Right(templates.where((t) => t.isFavorite).toList());

  @override
  Future<Either<Failure, void>> recordTemplateUsage(String id) async {
    final idx = templates.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final t = templates[idx];
      templates[idx] = t.copyWith(usageCount: t.usageCount + 1, lastUsedAt: DateTime.now());
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<BillTemplate>>> getSuggestedTemplates({String? projectId, int limit = 3}) async =>
      Right(templates.take(limit).toList());

  @override
  Future<Either<Failure, List<BillTemplate>>> getFrequentlyUsedTemplates({int limit = 5}) async =>
      Right(templates.take(limit).toList());
}

// ─────────────────────────────────────────────
// Localization for testing
// ─────────────────────────────────────────────
class TestLocalizations extends AppLocalizations {
  TestLocalizations() : super(const Locale('en'));

  static const Map<String, String> _strings = {
    'add_bill': 'Add Bill',
    'edit_bill': 'Edit Bill',
    'bill_name': 'Bill Name',
    'amount': 'Amount',
    'category': 'Category',
    'category_food': 'Food',
    'category_transport': 'Transport',
    'category_other': 'Other',
    'payer': 'Payer',
    'payer_hint': 'Who paid?',
    'participants': 'Participants',
    'participant_name': 'Participant Name',
    'enter_name': 'Enter name',
    'add': 'Add',
    'save_bill': 'Save Bill',
    'select_project': 'Select Project (Optional)',
    'no_project': 'No Project',
    'project': 'Project',
    'linked_project': 'Linked Project',
    'bill_detail': 'Bill Detail',
    'total_amount': 'Total Amount',
    'paid_by': 'Paid by',
    'paid_by_label': 'Paid by',
    'split_breakdown': 'Split Breakdown',
    'split_mode': 'Split Mode',
    'split_mode_equal': 'Split Equally',
    'split_mode_percentage': 'Percentage',
    'split_mode_shares': 'Shares',
    'split_mode_custom': 'Custom',
    'save_as_template': 'Save as Template',
    'template_saved_success': 'Saved as template!',
    'project_no_members': 'This project has no members. Please add members first.',
    'today': 'Today',
    'fast_split_equal_label': 'Paid by you and split equally',
    'fast_description_hint': 'What was this for?',
    'more': 'More',
    'you': 'You',
    'description': 'Description',
  };

  @override
  String translate(String key) => _strings[key] ?? key;
}

class TestLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const TestLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => TestLocalizations();
  @override
  bool shouldReload(TestLocalizationsDelegate old) => false;
}

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────
final _dt = DateTime(2026, 9, 17);

Project makeProject({
  String id = 'proj-1',
  String name = 'Household Trip',
  List<String> members = const ['Alice', 'Bob', 'Charlie'],
}) =>
    Project(
      id: id,
      name: name,
      members: members,
      createdAt: _dt,
      updatedAt: _dt,
    );

Bill makeBill({
  String id = 'bill-1',
  String title = 'Grocery Shopping',
  double amount = 150000,
  String? projectId = 'proj-1',
  String paidBy = 'Alice',
  List<String> participants = const ['Alice', 'Bob', 'Charlie'],
  String splitMode = 'equal',
}) {
  final perPerson = amount / (participants.isEmpty ? 1 : participants.length);
  return Bill(
    id: id,
    title: title,
    amount: amount,
    category: 'food',
    date: _dt,
    paidBy: paidBy,
    projectId: projectId,
    splitMode: splitMode,
    participants: participants
        .map((p) => BillParticipant(
              participantId: 'part-$p',
              name: p,
              amount: perPerson,
            ))
        .toList(),
  );
}

Widget buildTestApp({
  required Widget child,
  MockBillRepository? billRepo,
  MockProjectRepository? projectRepo,
  MockBillTemplateRepository? templateRepo,
  ThemeMode themeMode = ThemeMode.light,
}) {
  final bRepo = billRepo ?? MockBillRepository();
  final pRepo = projectRepo ?? MockProjectRepository();
  final tRepo = templateRepo ?? MockBillTemplateRepository();

  final billsBloc = BillsBloc(
    getBillsUseCase: GetBillsUseCase(bRepo),
    addBillUseCase: AddBillUseCase(bRepo),
  );

  final projectBloc = ProjectBloc(
    createProjectUseCase: CreateProjectUseCase(pRepo),
    getAllProjectsUseCase: GetAllProjectsUseCase(pRepo),
    updateProjectUseCase: UpdateProjectUseCase(pRepo),
    deleteProjectUseCase: DeleteProjectUseCase(pRepo),
  );

  final templatesBloc = BillTemplatesBloc(
    getTemplatesUseCase: GetTemplatesUseCase(tRepo),
    createTemplateUseCase: CreateTemplateUseCase(tRepo),
    updateTemplateUseCase: UpdateTemplateUseCase(tRepo),
    deleteTemplateUseCase: DeleteTemplateUseCase(tRepo),
    toggleFavoriteTemplateUseCase: ToggleFavoriteTemplateUseCase(tRepo),
    recordTemplateUsageUseCase: RecordTemplateUsageUseCase(tRepo),
    getSuggestedTemplatesUseCase: GetSuggestedTemplatesUseCase(tRepo),
  );

  return MultiProvider(
    providers: [
      RepositoryProvider<BillRepository>.value(value: bRepo),
      RepositoryProvider<ProjectRepository>.value(value: pRepo),
      ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<BillsBloc>.value(value: billsBloc),
        BlocProvider<ProjectBloc>.value(value: projectBloc),
        BlocProvider<BillTemplatesBloc>.value(value: templatesBloc),
      ],
      child: MaterialApp(
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        localizationsDelegates: const [
          TestLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: () {
          if (child is AddBillScreen && child.initialCompactMode == null) {
            return AddBillScreen(
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
          return child;
        }(),
      ),
    ),
  );
}

// ─────────────────────────────────────────────
// TEST SUITE (50+ TESTS)
// ─────────────────────────────────────────────
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('en', null);
  });
  // ───────────────────────────────────────────
  // Group 1: Bill Entity & Model Linking (10 tests)
  // ───────────────────────────────────────────
  group('1. Bill Entity & Model Project Linking', () {
    test('1.1 Bill entity retains projectId when set', () {
      final bill = makeBill(projectId: 'proj-123');
      expect(bill.projectId, 'proj-123');
    });

    test('1.2 Bill entity allows null projectId', () {
      final bill = makeBill(projectId: null);
      expect(bill.projectId, isNull);
    });

    test('1.3 Bill copyWith retains existing projectId when not specified', () {
      final bill = makeBill(projectId: 'proj-123');
      final updated = bill.copyWith(title: 'New Title');
      expect(updated.projectId, 'proj-123');
      expect(updated.title, 'New Title');
    });

    test('1.4 Bill copyWith can update projectId to another project', () {
      final bill = makeBill(projectId: 'proj-1');
      final updated = bill.copyWith(projectId: 'proj-2');
      expect(updated.projectId, 'proj-2');
    });

    test('1.5 Bill copyWith can clear projectId to null using clearProjectId', () {
      final bill = makeBill(projectId: 'proj-1');
      final updated = bill.copyWith(clearProjectId: true);
      expect(updated.projectId, isNull);
    });

    test('1.6 BillModel fromJson correctly parses projectId', () {
      final json = {
        'id': 'b1',
        'title': 'Dinner',
        'amount': 200000.0,
        'category': 'food',
        'date': _dt.toIso8601String(),
        'paidBy': 'Alice',
        'participants': [],
        'projectId': 'proj-abc',
      };
      final model = BillModel.fromJson(json);
      expect(model.projectId, 'proj-abc');
    });

    test('1.7 BillModel fromJson correctly handles missing/null projectId', () {
      final json = {
        'id': 'b1',
        'title': 'Dinner',
        'amount': 200000.0,
        'category': 'food',
        'date': _dt.toIso8601String(),
        'paidBy': 'Alice',
        'participants': [],
        'projectId': null,
      };
      final model = BillModel.fromJson(json);
      expect(model.projectId, isNull);
    });

    test('1.8 BillModel toJson includes projectId when non-null', () {
      final model = BillModel(
        id: 'b1',
        title: 'Dinner',
        amount: 200000.0,
        category: 'food',
        date: _dt,
        paidBy: 'Alice',
        participants: const [],
        projectId: 'proj-xyz',
      );
      final json = model.toJson();
      expect(json['projectId'], 'proj-xyz');
    });

    test('1.9 BillModel toJson omits projectId when null', () {
      final model = BillModel(
        id: 'b1',
        title: 'Dinner',
        amount: 200000.0,
        category: 'food',
        date: _dt,
        paidBy: 'Alice',
        participants: const [],
        projectId: null,
      );
      final json = model.toJson();
      expect(json.containsKey('projectId'), isFalse);
    });

    test('1.10 BillModel.fromEntity preserves projectId', () {
      final bill = makeBill(projectId: 'proj-special');
      final model = BillModel.fromEntity(bill);
      expect(model.projectId, 'proj-special');
    });
  });

  // ───────────────────────────────────────────
  // Group 2: Repository & Isolation (10 tests)
  // ───────────────────────────────────────────
  group('2. Repository & DataSource Project Isolation', () {
    test('2.1 Adding bill with projectId saves to repository', () async {
      final repo = MockBillRepository();
      final bill = makeBill(id: 'b1', projectId: 'p1');
      await repo.create(bill);
      expect(repo.bills.first.projectId, 'p1');
    });

    test('2.2 Adding bill without projectId saves with null projectId', () async {
      final repo = MockBillRepository();
      final bill = makeBill(id: 'b2', projectId: null);
      await repo.create(bill);
      expect(repo.bills.first.projectId, isNull);
    });

    test('2.3 getBillsByProjectId returns only matching bills', () async {
      final repo = MockBillRepository([
        makeBill(id: 'b1', projectId: 'p1'),
        makeBill(id: 'b2', projectId: 'p1'),
        makeBill(id: 'b3', projectId: 'p2'),
        makeBill(id: 'b4', projectId: null),
      ]);
      final result = await repo.getBillsByProjectId('p1');
      expect(result.isRight(), isTrue);
      final bills = result.getOrElse(() => []);
      expect(bills.length, 2);
      expect(bills.map((b) => b.id), containsAll(['b1', 'b2']));
    });

    test('2.4 getBillsByProjectId returns empty list if no bills match', () async {
      final repo = MockBillRepository([
        makeBill(id: 'b1', projectId: 'p1'),
        makeBill(id: 'b2', projectId: null),
      ]);
      final result = await repo.getBillsByProjectId('p3');
      final bills = result.getOrElse(() => []);
      expect(bills, isEmpty);
    });

    test('2.5 Updating bill properties preserves projectId', () async {
      final repo = MockBillRepository([makeBill(id: 'b1', amount: 100000, projectId: 'p1')]);
      final updated = repo.bills.first.copyWith(amount: 250000);
      await repo.update(updated);
      final fetched = (await repo.getById('b1')).getOrElse(() => throw Exception());
      expect(fetched.amount, 250000);
      expect(fetched.projectId, 'p1');
    });

    test('2.6 Updating bill projectId reassigns project', () async {
      final repo = MockBillRepository([makeBill(id: 'b1', projectId: 'p1')]);
      final updated = repo.bills.first.copyWith(projectId: 'p2');
      await repo.update(updated);
      final p1Bills = (await repo.getBillsByProjectId('p1')).getOrElse(() => []);
      final p2Bills = (await repo.getBillsByProjectId('p2')).getOrElse(() => []);
      expect(p1Bills, isEmpty);
      expect(p2Bills.length, 1);
      expect(p2Bills.first.id, 'b1');
    });

    test('2.7 Unlinking bill removes it from project queries but keeps in getAll', () async {
      final repo = MockBillRepository([makeBill(id: 'b1', projectId: 'p1')]);
      final unlinked = repo.bills.first.copyWith(clearProjectId: true);
      await repo.update(unlinked);
      final p1Bills = (await repo.getBillsByProjectId('p1')).getOrElse(() => []);
      final allBills = (await repo.getAll()).getOrElse(() => []);
      expect(p1Bills, isEmpty);
      expect(allBills.length, 1);
      expect(allBills.first.id, 'b1');
    });

    test('2.8 Deleting bill removes it from that project', () async {
      final repo = MockBillRepository([
        makeBill(id: 'b1', projectId: 'p1'),
        makeBill(id: 'b2', projectId: 'p1'),
      ]);
      await repo.delete('b1');
      final p1Bills = (await repo.getBillsByProjectId('p1')).getOrElse(() => []);
      expect(p1Bills.length, 1);
      expect(p1Bills.first.id, 'b2');
    });

    test('2.9 Deleting bill in project A does not affect project B bills', () async {
      final repo = MockBillRepository([
        makeBill(id: 'b1', projectId: 'p1'),
        makeBill(id: 'b2', projectId: 'p2'),
      ]);
      await repo.delete('b1');
      final p2Bills = (await repo.getBillsByProjectId('p2')).getOrElse(() => []);
      expect(p2Bills.length, 1);
      expect(p2Bills.first.id, 'b2');
    });

    test('2.10 Deleting bill does not affect unlinked bills', () async {
      final repo = MockBillRepository([
        makeBill(id: 'b1', projectId: 'p1'),
        makeBill(id: 'b2', projectId: null),
      ]);
      await repo.delete('b1');
      final all = (await repo.getAll()).getOrElse(() => []);
      expect(all.length, 1);
      expect(all.first.id, 'b2');
    });
  });

  // ───────────────────────────────────────────
  // Group 3: Settlement Calculation Isolation (10 tests)
  // ───────────────────────────────────────────
  group('3. Settlement Calculation Project Isolation', () {
    const calculator = CalculateSettlementUseCase();
    final project1 = makeProject(id: 'p1', members: ['Alice', 'Bob']);
    final project2 = makeProject(id: 'p2', members: ['Charlie', 'Dave']);

    test('3.1 Settlement calculation with 0 bills yields 0 totalExpense', () async {
      final res = await calculator(CalculateSettlementParams(project: project1, bills: []));
      expect(res.isRight(), isTrue);
      final stats = res.getOrElse(() => throw Exception());
      expect(stats.totalExpense, 0.0);
      expect(stats.settlements, isEmpty);
    });

    test('3.2 Settlement calculation uses only bills matching project.id', () async {
      final bills = [
        makeBill(id: 'b1', projectId: 'p1', amount: 100000, paidBy: 'Alice', participants: ['Alice', 'Bob']),
        makeBill(id: 'b2', projectId: 'p2', amount: 999999, paidBy: 'Charlie', participants: ['Charlie', 'Dave']),
      ];
      final res = await calculator(CalculateSettlementParams(project: project1, bills: bills));
      final stats = res.getOrElse(() => throw Exception());
      expect(stats.totalExpense, 100000.0);
    });

    test('3.3 Bills without projectId are excluded from project settlement', () async {
      final bills = [
        makeBill(id: 'b1', projectId: 'p1', amount: 50000, paidBy: 'Alice', participants: ['Alice', 'Bob']),
        makeBill(id: 'b2', projectId: null, amount: 80000, paidBy: 'Alice', participants: ['Alice', 'Bob']),
      ];
      final res = await calculator(CalculateSettlementParams(project: project1, bills: bills));
      final stats = res.getOrElse(() => throw Exception());
      expect(stats.totalExpense, 50000.0);
    });

    test('3.4 Correct debt minimization for single bill in project', () async {
      final bills = [
        makeBill(id: 'b1', projectId: 'p1', amount: 200000, paidBy: 'Alice', participants: ['Alice', 'Bob']),
      ];
      final res = await calculator(CalculateSettlementParams(project: project1, bills: bills));
      final stats = res.getOrElse(() => throw Exception());
      expect(stats.settlements.length, 1);
      final s = stats.settlements.first;
      expect(s.from, 'Bob');
      expect(s.to, 'Alice');
      expect(s.amount, 100000.0);
    });

    test('3.5 Multiple bills in project accumulate balances correctly', () async {
      final bills = [
        makeBill(id: 'b1', projectId: 'p1', amount: 100000, paidBy: 'Alice', participants: ['Alice', 'Bob']),
        makeBill(id: 'b2', projectId: 'p1', amount: 100000, paidBy: 'Bob', participants: ['Alice', 'Bob']),
      ];
      final res = await calculator(CalculateSettlementParams(project: project1, bills: bills));
      final stats = res.getOrElse(() => throw Exception());
      expect(stats.totalExpense, 200000.0);
      expect(stats.settlements, isEmpty); // Fully balanced
    });

    test('3.6 Project with 3 members computes triangular debt minimization', () async {
      final trip = makeProject(id: 'trip', members: ['A', 'B', 'C']);
      final bills = [
        makeBill(id: 'b1', projectId: 'trip', amount: 300000, paidBy: 'A', participants: ['A', 'B', 'C']),
      ];
      final res = await calculator(CalculateSettlementParams(project: trip, bills: bills));
      final stats = res.getOrElse(() => throw Exception());
      expect(stats.settlements.length, 2);
      expect(stats.settlements.any((s) => s.from == 'B' && s.to == 'A' && s.amount == 100000.0), isTrue);
      expect(stats.settlements.any((s) => s.from == 'C' && s.to == 'A' && s.amount == 100000.0), isTrue);
    });

    test('3.7 Non-participating members in a bill do not owe for that bill', () async {
      final trip = makeProject(id: 'trip', members: ['A', 'B', 'C']);
      final bills = [
        makeBill(id: 'b1', projectId: 'trip', amount: 100000, paidBy: 'A', participants: ['A', 'B']),
      ];
      final res = await calculator(CalculateSettlementParams(project: trip, bills: bills));
      final stats = res.getOrElse(() => throw Exception());
      expect(stats.settlements.length, 1);
      expect(stats.settlements.first.from, 'B');
      expect(stats.settlements.first.to, 'A');
      expect(stats.settlements.first.amount, 50000.0);
    });

    test('3.8 Top payer is identified from project bills only', () async {
      final bills = [
        makeBill(id: 'b1', projectId: 'p1', amount: 100000, paidBy: 'Alice', participants: ['Alice', 'Bob']),
        makeBill(id: 'b2', projectId: 'p2', amount: 9999999, paidBy: 'Dave', participants: ['Charlie', 'Dave']),
      ];
      final res = await calculator(CalculateSettlementParams(project: project1, bills: bills));
      final stats = res.getOrElse(() => throw Exception());
      expect(stats.topPayer, 'Alice');
    });

    test('3.9 Top debtor is identified from project bills only', () async {
      final bills = [
        makeBill(id: 'b1', projectId: 'p1', amount: 100000, paidBy: 'Alice', participants: ['Alice', 'Bob']),
      ];
      final res = await calculator(CalculateSettlementParams(project: project1, bills: bills));
      final stats = res.getOrElse(() => throw Exception());
      expect(stats.topDebtor, 'Bob');
    });

    test('3.10 Independent project settlements do not bleed into each other', () async {
      final bills = [
        makeBill(id: 'b1', projectId: 'p1', amount: 200000, paidBy: 'Alice', participants: ['Alice', 'Bob']),
        makeBill(id: 'b2', projectId: 'p2', amount: 300000, paidBy: 'Charlie', participants: ['Charlie', 'Dave']),
      ];
      final res1 = await calculator(CalculateSettlementParams(project: project1, bills: bills));
      final res2 = await calculator(CalculateSettlementParams(project: project2, bills: bills));
      expect(res1.getOrElse(() => throw Exception()).totalExpense, 200000.0);
      expect(res2.getOrElse(() => throw Exception()).totalExpense, 300000.0);
    });
  });

  // ───────────────────────────────────────────
  // Group 4: AddBillScreen Project Linking (15 tests)
  // ───────────────────────────────────────────
  group('4. AddBillScreen Project Linking & Pre-selection', () {
    testWidgets('4.1 Pre-selects project when widget.projectId is passed', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = makeProject(id: 'p1', name: 'Summer Trip');
      final projectRepo = MockProjectRepository([project]);
      final billRepo = MockBillRepository();

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(projectId: 'p1'),
        projectRepo: projectRepo,
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Summer Trip'), findsWidgets);
    });

    testWidgets('4.2 Pre-selects project members when widget.projectId is passed', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = makeProject(id: 'p1', members: ['Alice', 'Bob', 'Charlie']);
      final projectRepo = MockProjectRepository([project]);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(projectId: 'p1'),
        projectRepo: projectRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('member_card_Alice')), findsOneWidget);
      expect(find.byKey(const Key('member_card_Bob')), findsOneWidget);
      expect(find.byKey(const Key('member_card_Charlie')), findsOneWidget);
    });

    testWidgets('4.3 Pre-fills payer with first project member when widget.projectId passed', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = makeProject(id: 'p1', members: ['Alice', 'Bob']);
      final projectRepo = MockProjectRepository([project]);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(projectId: 'p1'),
        projectRepo: projectRepo,
      ));
      await tester.pumpAndSettle();

      final payerField = tester.widget<TextField>(find.byKey(const Key('payerField')));
      expect(payerField.controller!.text, 'Alice');
    });

    testWidgets('4.4 Creating bill with widget.projectId saves bill with that projectId', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = makeProject(id: 'p1', name: 'Summer Trip', members: ['Alice', 'Bob']);
      final projectRepo = MockProjectRepository([project]);
      final billRepo = MockBillRepository();

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(projectId: 'p1'),
        projectRepo: projectRepo,
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'Beach Tickets');
      tester.widget<TextField>(find.byKey(const Key('amountField'))).controller!.text = '120000';
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.lastCreatedBill, isNotNull);
      expect(billRepo.lastCreatedBill!.projectId, 'p1');
      expect(billRepo.lastCreatedBill!.title, 'Beach Tickets');
    });

    testWidgets('4.5 Creating bill selecting project from dropdown saves with selected projectId', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = makeProject(id: 'proj-custom', name: 'Weekend BBQ', members: ['Alice', 'Bob']);
      final projectRepo = MockProjectRepository([project]);
      final billRepo = MockBillRepository();

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        projectRepo: projectRepo,
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      // Select project from dropdown
      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weekend BBQ').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'Steak');
      tester.widget<TextField>(find.byKey(const Key('amountField'))).controller!.text = '500000';
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.lastCreatedBill, isNotNull);
      expect(billRepo.lastCreatedBill!.projectId, 'proj-custom');
    });

    testWidgets('4.6 Creating bill without selecting project saves with null projectId', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = MockBillRepository();

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'Coffee');
      tester.widget<TextField>(find.byKey(const Key('amountField'))).controller!.text = '50000';
      await tester.enterText(find.byKey(const Key('payerField')), 'Me');

      // Add manual participants
      await tester.enterText(find.byKey(const Key('participantNameField')), 'Me');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('participantNameField')), 'Friend');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.lastCreatedBill, isNotNull);
      expect(billRepo.lastCreatedBill!.projectId, isNull);
    });

    testWidgets('4.7 Editing bill pre-selects project in dropdown from billToEdit.projectId', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = makeProject(id: 'proj-edit', name: 'Cabin Retreat');
      final bill = makeBill(id: 'b1', projectId: 'proj-edit');
      final projectRepo = MockProjectRepository([project]);

      await tester.pumpWidget(buildTestApp(
        child: AddBillScreen(billToEdit: bill),
        projectRepo: projectRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Cabin Retreat'), findsWidgets);
    });

    testWidgets('4.8 Editing bill keeps projectId unchanged when saving without touching project dropdown', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = makeProject(id: 'proj-keep', name: 'Ski Trip');
      final bill = makeBill(id: 'b-keep', title: 'Ski Rental', amount: 300000, projectId: 'proj-keep');
      final projectRepo = MockProjectRepository([project]);
      final billRepo = MockBillRepository([bill]);

      await tester.pumpWidget(buildTestApp(
        child: AddBillScreen(billToEdit: bill),
        projectRepo: projectRepo,
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      // Change title only
      await tester.enterText(find.byKey(const Key('titleField')), 'Ski Rental Premium');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.lastUpdatedBill, isNotNull);
      expect(billRepo.lastUpdatedBill!.id, 'b-keep');
      expect(billRepo.lastUpdatedBill!.title, 'Ski Rental Premium');
      expect(billRepo.lastUpdatedBill!.projectId, 'proj-keep'); // MUST NOT reset to null!
    });

    testWidgets('4.9 Editing bill allows switching to a different project', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject(id: 'p1', name: 'Project One', members: ['Alice', 'Bob']);
      final p2 = makeProject(id: 'p2', name: 'Project Two', members: ['Alice', 'Bob', 'Charlie']);
      final bill = makeBill(id: 'b-switch', projectId: 'p1');
      final projectRepo = MockProjectRepository([p1, p2]);
      final billRepo = MockBillRepository([bill]);

      await tester.pumpWidget(buildTestApp(
        child: AddBillScreen(billToEdit: bill),
        projectRepo: projectRepo,
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      // Switch to Project Two
      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Project Two').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.lastUpdatedBill, isNotNull);
      expect(billRepo.lastUpdatedBill!.projectId, 'p2');
    });

    testWidgets('4.10 Editing bill allows unlinking project (selecting "No Project")', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject(id: 'p1', name: 'Project One', members: ['Alice', 'Bob']);
      final bill = makeBill(id: 'b-unlink', projectId: 'p1', participants: ['Alice', 'Bob']);
      final projectRepo = MockProjectRepository([p1]);
      final billRepo = MockBillRepository([bill]);

      await tester.pumpWidget(buildTestApp(
        child: AddBillScreen(billToEdit: bill),
        projectRepo: projectRepo,
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      // Switch to No Project
      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No Project').last);
      await tester.pumpAndSettle();

      // Ensure manual participants are present for validation if needed
      if (find.byKey(const Key('participantNameField')).evaluate().isNotEmpty) {
        await tester.enterText(find.byKey(const Key('participantNameField')), 'Alice');
        await tester.tap(find.byKey(const Key('addParticipantButton')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('participantNameField')), 'Bob');
        await tester.tap(find.byKey(const Key('addParticipantButton')));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.lastUpdatedBill, isNotNull);
      expect(billRepo.lastUpdatedBill!.projectId, isNull);
    });

    testWidgets('4.11 Saving as template preserves projectId from pre-selected project', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject(id: 'p-tpl', name: 'Monthly Rent', members: ['Alice', 'Bob']);
      final projectRepo = MockProjectRepository([p1]);
      final templateRepo = MockBillTemplateRepository();

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(projectId: 'p-tpl'),
        projectRepo: projectRepo,
        templateRepo: templateRepo,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'Rent Oct');
      tester.widget<TextField>(find.byKey(const Key('amountField'))).controller!.text = '5000000';
      await tester.pumpAndSettle();

      // Tap save as template
      await tester.tap(find.byKey(const Key('saveAsTemplateButton')));
      await tester.pumpAndSettle();

      expect(templateRepo.lastCreated, isNotNull);
      expect(templateRepo.lastCreated!.projectId, 'p-tpl');
    });

    testWidgets('4.12 Editing unlinked bill and choosing project links that project', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject(id: 'p-new', name: 'New House', members: ['Alice', 'Bob']);
      final unlinkedBill = makeBill(id: 'b-unlinked', projectId: null);
      final projectRepo = MockProjectRepository([p1]);
      final billRepo = MockBillRepository([unlinkedBill]);

      await tester.pumpWidget(buildTestApp(
        child: AddBillScreen(billToEdit: unlinkedBill),
        projectRepo: projectRepo,
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      // Select project from dropdown
      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New House').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.lastUpdatedBill, isNotNull);
      expect(billRepo.lastUpdatedBill!.projectId, 'p-new');
    });

    testWidgets('4.13 Pre-selected project with empty members shows warning snackbar', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pEmpty = makeProject(id: 'p-empty', name: 'Ghost Project', members: []);
      final projectRepo = MockProjectRepository([pEmpty]);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        projectRepo: projectRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ghost Project').last);
      await tester.pumpAndSettle();

      expect(find.text('This project has no members. Please add members first.'), findsWidgets);
    });

    testWidgets('4.14 Tapping member card deselects participant in project bill', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final p1 = makeProject(id: 'p1', members: ['Alice', 'Bob', 'Charlie']);
      final projectRepo = MockProjectRepository([p1]);
      final billRepo = MockBillRepository();

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(projectId: 'p1'),
        projectRepo: projectRepo,
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      // Deselect Charlie
      await tester.tap(find.byKey(const Key('member_card_Charlie')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'Lunch');
      tester.widget<TextField>(find.byKey(const Key('amountField'))).controller!.text = '200000';
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.lastCreatedBill, isNotNull);
      final participantNames = billRepo.lastCreatedBill!.participants.map((p) => p.name).toList();
      expect(participantNames, containsAll(['Alice', 'Bob']));
      expect(participantNames, isNot(contains('Charlie')));
    });

    testWidgets('4.15 Editing bill preserves custom split mode and projectId', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = makeProject(id: 'p-custom', members: ['Alice', 'Bob']);
      final bill = makeBill(
        id: 'b-custom',
        projectId: 'p-custom',
        splitMode: 'percentage',
        amount: 100000,
        participants: ['Alice', 'Bob'],
      );
      final projectRepo = MockProjectRepository([project]);
      final billRepo = MockBillRepository([bill]);

      await tester.pumpWidget(buildTestApp(
        child: AddBillScreen(billToEdit: bill),
        projectRepo: projectRepo,
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.lastUpdatedBill, isNotNull);
      expect(billRepo.lastUpdatedBill!.projectId, 'p-custom');
      expect(billRepo.lastUpdatedBill!.splitMode, 'percentage');
    });
  });

  // ───────────────────────────────────────────
  // Group 5: BillDetailScreen Project Association (10 tests)
  // ───────────────────────────────────────────
  group('5. BillDetailScreen Project Association Display', () {
    testWidgets('5.1 Shows billDetailProject badge when bill has projectId', (tester) async {
      final bill = makeBill(projectId: 'proj-vacation');
      await tester.pumpWidget(buildTestApp(
        child: BillDetailScreen(bill: bill),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('billDetailProject')), findsOneWidget);
      expect(find.byKey(const Key('billDetailProjectName')), findsOneWidget);
    });

    testWidgets('5.2 Hides billDetailProject badge when bill has null projectId', (tester) async {
      final bill = makeBill(projectId: null);
      await tester.pumpWidget(buildTestApp(
        child: BillDetailScreen(bill: bill),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('billDetailProject')), findsNothing);
      expect(find.byKey(const Key('billDetailProjectName')), findsNothing);
    });

    testWidgets('5.3 Hides billDetailProject badge when bill has empty projectId', (tester) async {
      final bill = makeBill(projectId: '');
      await tester.pumpWidget(buildTestApp(
        child: BillDetailScreen(bill: bill),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('billDetailProject')), findsNothing);
    });

    testWidgets('5.4 Displays explicit projectName when provided in constructor', (tester) async {
      final bill = makeBill(projectId: 'p123');
      await tester.pumpWidget(buildTestApp(
        child: BillDetailScreen(bill: bill, projectName: 'Da Nang Summer'),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Da Nang Summer'), findsOneWidget);
    });

    testWidgets('5.5 Resolves projectName from ProjectBloc when available', (tester) async {
      final project = makeProject(id: 'p-bloc', name: 'Secret Mission');
      final projectRepo = MockProjectRepository([project]);
      final bill = makeBill(projectId: 'p-bloc');

      await tester.pumpWidget(buildTestApp(
        child: BillDetailScreen(bill: bill),
        projectRepo: projectRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Secret Mission'), findsOneWidget);
    });

    testWidgets('5.6 Falls back to bill.projectId when ProjectBloc does not have the project', (tester) async {
      final projectRepo = MockProjectRepository([]);
      final bill = makeBill(projectId: 'orphan-project-id');

      await tester.pumpWidget(buildTestApp(
        child: BillDetailScreen(bill: bill),
        projectRepo: projectRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('orphan-project-id'), findsOneWidget);
    });

    testWidgets('5.7 Edit button in BillDetailScreen navigates to AddBillScreen with billToEdit and projectId', (tester) async {
      final bill = makeBill(id: 'b-edit-nav', title: 'Museum Entry', projectId: 'p-museum');
      await tester.pumpWidget(buildTestApp(
        child: BillDetailScreen(bill: bill),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('billDetailEditButton')));
      await tester.pumpAndSettle();

      expect(find.byType(AddBillScreen), findsOneWidget);
      final addBillScreen = tester.widget<AddBillScreen>(find.byType(AddBillScreen));
      expect(addBillScreen.billToEdit?.id, 'b-edit-nav');
      expect(addBillScreen.projectId, 'p-museum');
    });

    testWidgets('5.8 Bottom edit button also navigates to AddBillScreen with projectId', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final bill = makeBill(id: 'b-bot-nav', title: 'Museum Entry', projectId: 'p-museum');
      await tester.pumpWidget(buildTestApp(
        child: BillDetailScreen(bill: bill),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('billDetailBottomEditButton')));
      await tester.pumpAndSettle();

      expect(find.byType(AddBillScreen), findsOneWidget);
      final addBillScreen = tester.widget<AddBillScreen>(find.byType(AddBillScreen));
      expect(addBillScreen.projectId, 'p-museum');
    });

    testWidgets('5.9 Save template from BillDetailScreen includes bill.projectId', (tester) async {
      final templateRepo = MockBillTemplateRepository();
      final bill = makeBill(projectId: 'proj-tpl-save');

      await tester.pumpWidget(buildTestApp(
        child: BillDetailScreen(bill: bill),
        templateRepo: templateRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('billDetailSaveTemplateButton')));
      await tester.pumpAndSettle();

      expect(templateRepo.lastCreated, isNotNull);
      expect(templateRepo.lastCreated!.projectId, 'proj-tpl-save');
    });

    testWidgets('5.10 BillDetailScreen renders project badge properly in Dark Theme', (tester) async {
      final bill = makeBill(projectId: 'p-dark');
      await tester.pumpWidget(buildTestApp(
        themeMode: ThemeMode.dark,
        child: BillDetailScreen(bill: bill),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('billDetailProject')), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────
  // Group 6: FastAddBillScreen Project Support (5 tests)
  // ───────────────────────────────────────────
  group('6. FastAddBillScreen Project Support', () {
    testWidgets('6.1 FastAddBillScreen with projectId saves bill with projectId', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = MockBillRepository();
      await tester.pumpWidget(buildTestApp(
        child: const FastAddBillScreen(
          projectId: 'fast-proj',
          projectMembers: ['Alice', 'Bob'],
        ),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('fastAmountField')), '150000');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fastSaveButton')));
      await tester.pumpAndSettle();

      expect(billRepo.lastCreatedBill, isNotNull);
      expect(billRepo.lastCreatedBill!.projectId, 'fast-proj');
    });

    testWidgets('6.2 FastAddBillScreen without projectId saves bill with null projectId', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = MockBillRepository();
      await tester.pumpWidget(buildTestApp(
        child: const FastAddBillScreen(
          projectMembers: ['Alice', 'Bob'],
        ),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('fastAmountField')), '75000');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fastSaveButton')));
      await tester.pumpAndSettle();

      expect(billRepo.lastCreatedBill, isNotNull);
      expect(billRepo.lastCreatedBill!.projectId, isNull);
    });

    testWidgets('6.3 FastAddBillScreen pre-selects all projectMembers', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = MockBillRepository();
      await tester.pumpWidget(buildTestApp(
        child: const FastAddBillScreen(
          projectId: 'p-test',
          projectMembers: ['Alice', 'Bob', 'Charlie'],
        ),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('fastAmountField')), '300000');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fastSaveButton')));
      await tester.pumpAndSettle();

      final parts = billRepo.lastCreatedBill!.participants.map((p) => p.name).toList();
      expect(parts, containsAll(['Alice', 'Bob', 'Charlie']));
    });

    testWidgets('6.4 FastAddBillScreen pre-fills paidBy with currentUser when provided', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = MockBillRepository();
      await tester.pumpWidget(buildTestApp(
        child: const FastAddBillScreen(
          projectId: 'p-test',
          currentUser: 'Bob',
          projectMembers: ['Alice', 'Bob'],
        ),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('fastAmountField')), '50000');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fastSaveButton')));
      await tester.pumpAndSettle();

      expect(billRepo.lastCreatedBill!.paidBy, 'Bob');
    });

    testWidgets('6.5 FastAddBillScreen falls back to first project member when currentUser is null', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = MockBillRepository();
      await tester.pumpWidget(buildTestApp(
        child: const FastAddBillScreen(
          projectId: 'p-test',
          projectMembers: ['Alice', 'Bob'],
        ),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('fastAmountField')), '50000');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fastSaveButton')));
      await tester.pumpAndSettle();

      expect(billRepo.lastCreatedBill!.paidBy, 'Alice');
    });
  });
}
