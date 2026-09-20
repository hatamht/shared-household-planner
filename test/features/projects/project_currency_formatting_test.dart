import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/features/projects/data/models/project_model.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_project_by_id_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/create_project_screen.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/project_detail_screen.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/project_screen.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/add_bill_screen.dart';

class FakeBillRepo implements BillRepository {
  final List<Bill> bills = [];
  FakeBillRepo([List<Bill>? initial]) {
    if (initial != null) bills.addAll(initial);
  }

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

class FakeProjRepo implements ProjectRepository {
  final List<Project> projects = [];
  FakeProjRepo([List<Project>? initial]) {
    if (initial != null) projects.addAll(initial);
  }

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
    final idx = projects.indexWhere((item) => item.id == p.id);
    if (idx != -1) projects[idx] = p;
    return Right(p);
  }
  @override
  Future<Either<Failure, void>> delete(String id) async {
    projects.removeWhere((p) => p.id == id);
    return const Right(null);
  }
}

class _TestLoc extends AppLocalizations {
  final String code;
  _TestLoc(this.code) : super(Locale(code));

  static const Map<String, String> _dict = {
    'projects': 'Projects',
    'create_project': 'Create Project',
    'edit_project': 'Edit Project',
    'project_name': 'Project Name',
    'project_description': 'Description',
    'project_currency': 'Project Currency',
    'select_currency': 'Select project currency',
    'bills_tab': 'Bills',
    'settlement_tab': 'Settlement',
    'statistics_tab': 'Statistics',
    'add_expense_button': 'Add Expense',
    'create_first_bill': 'Create Expense',
    'paid_by_label': 'Paid by',
    'no_settlement_needed': 'Everyone is settled up! 🎉',
    'payment_history': 'Payment History',
    'settlement': 'Settlement',
    'total_expense': 'Total Expense',
    'top_payer': 'Top Payer',
    'top_debtor': 'Top Debtor',
    'total_spent': 'Total Spent',
    'per_person': 'per person',
    'error': 'Error',
    'amount': 'Amount',
    'save': 'Save',
    'save_bill': 'Save Bill',
    'restaurant': 'Restaurant',
    'currency': 'Currency',
    'all_projects': 'All Projects',
    'no_projects_yet': 'No projects yet',
    'search_projects': 'Search projects...',
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
  FakeBillRepo? billRepo,
  FakeProjRepo? projRepo,
  List<Project>? projects,
}) {
  final bRepo = billRepo ?? FakeBillRepo();
  final billsBloc = BillsBloc(
    getBillsUseCase: GetBillsUseCase(bRepo),
    addBillUseCase: AddBillUseCase(bRepo),
  );

  final pRepo = projRepo ?? FakeProjRepo(projects ?? [
    Project(
      id: 'proj-1',
      name: 'Da Nang Trip',
      members: const ['An', 'Binh'],
      createdAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 1),
    ),
  ]);

  final projectBloc = ProjectBloc(
    getAllProjectsUseCase: GetAllProjectsUseCase(pRepo),
    createProjectUseCase: CreateProjectUseCase(pRepo),
    getProjectByIdUseCase: GetProjectByIdUseCase(pRepo),
    updateProjectUseCase: UpdateProjectUseCase(pRepo),
    deleteProjectUseCase: DeleteProjectUseCase(pRepo),
  )..emit(ProjectLoaded(projects: pRepo.projects));

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
      RepositoryProvider<BillRepository>.value(value: bRepo),
      RepositoryProvider<ProjectRepository>.value(value: pRepo),
      BlocProvider<BillsBloc>.value(value: billsBloc),
      BlocProvider<ProjectBloc>.value(value: projectBloc),
    ],
    child: MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      localizationsDelegates: const [
        _TestLocDelegate(),
      ],
      supportedLocales: const [Locale('en'), Locale('vi')],
      home: child,
    ),
  );
}

void main() {
  group('NumberFormat & Amount Representation (No k / M abbreviations)', () {
    final formatter = NumberFormat('#,##0.##', 'en_US');

    test('0 formats to 0', () {
      expect(formatter.format(0), '0');
    });

    test('52000 formats to 52,000 without k', () {
      final formatted = formatter.format(52000);
      expect(formatted, '52,000');
      expect(formatted.contains('k'), isFalse);
    });

    test('600000 formats to 600,000 without k', () {
      final formatted = formatter.format(600000);
      expect(formatted, '600,000');
      expect(formatted.contains('k'), isFalse);
    });

    test('1500000 formats to 1,500,000 without M', () {
      final formatted = formatter.format(1500000);
      expect(formatted, '1,500,000');
      expect(formatted.contains('M'), isFalse);
    });

    test('12345678 formats to 12,345,678 with thousand separators', () {
      expect(formatter.format(12345678), '12,345,678');
    });

    test('fractional amounts format correctly', () {
      expect(formatter.format(1234.56), '1,234.56');
    });
  });

  group('Project Entity & Model Currency Tests', () {
    test('Project entity defaults currency to VND and symbol to ₫', () {
      final project = Project(
        id: 'p1',
        name: 'Test Project',
        members: const ['m1'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(project.currency, 'VND');
      expect(project.currencySymbol, '₫');
    });

    test('Project entity supports USD, EUR, JPY, GBP symbols', () {
      final usd = Project(
        id: 'p_usd',
        name: 'US Project',
        currency: 'USD',
        members: const ['m1'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(usd.currency, 'USD');
      expect(usd.currencySymbol, '\$');

      final eur = Project(
        id: 'p_eur',
        name: 'EU Project',
        currency: 'EUR',
        members: const ['m1'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(eur.currency, 'EUR');
      expect(eur.currencySymbol, '€');

      final jpy = Project(
        id: 'p_jpy',
        name: 'Japan Project',
        currency: 'JPY',
        members: const ['m1'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(jpy.currency, 'JPY');
      expect(jpy.currencySymbol, '¥');

      final gbp = Project(
        id: 'p_gbp',
        name: 'UK Project',
        currency: 'GBP',
        members: const ['m1'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(gbp.currency, 'GBP');
      expect(gbp.currencySymbol, '£');
    });

    test('Project fallback for unmapped currency symbol returns code itself', () {
      final custom = Project(
        id: 'p_cad',
        name: 'Canada Project',
        currency: 'CAD',
        members: const ['m1'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(custom.currencySymbol, 'CAD');
    });

    test('ProjectModel serialization and deserialization preserves currency', () {
      final model = ProjectModel(
        id: 'p_model',
        name: 'Model Project',
        currency: 'USD',
        members: const ['m1'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final json = model.toJson();
      expect(json['currency'], 'USD');

      final fromJson = ProjectModel.fromJson(json);
      expect(fromJson.currency, 'USD');
      expect(fromJson.currencySymbol, '\$');
    });

    test('ProjectModel SQLite map serialization and deserialization', () {
      final model = ProjectModel(
        id: 'p_sqlite',
        name: 'SQLite Project',
        currency: 'EUR',
        members: const ['m1'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final map = model.toSqliteMap();
      expect(map['currency'], 'EUR');

      final fromMap = ProjectModel.fromJson(map);
      expect(fromMap.currency, 'EUR');
      expect(fromMap.currencySymbol, '€');
    });

    test('ProjectModel backward compatibility: missing currency defaults to VND', () {
      final legacyJson = {
        'id': 'legacy_1',
        'name': 'Old Project',
        'members': ['m1'],
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      };

      final model = ProjectModel.fromJson(legacyJson);
      expect(model.currency, 'VND');
      expect(model.currencySymbol, '₫');
    });

    test('Project copyWith updates currency correctly', () {
      final original = Project(
        id: 'p_copy',
        name: 'Copy',
        currency: 'VND',
        members: const ['m1'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final updated = original.copyWith(currency: 'GBP');
      expect(updated.currency, 'GBP');
      expect(updated.currencySymbol, '£');
    });

    test('Project fromEntity retains currency value', () {
      final entity = Project(
        id: 'p_from_e',
        name: 'Entity',
        currency: 'JPY',
        members: const ['m1'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final model = ProjectModel.fromEntity(entity);
      expect(model.currency, 'JPY');
      expect(model.currencySymbol, '¥');
    });
  });

  group('CreateProjectScreen Currency Picker Tests', () {
    testWidgets('Displays currency picker with all supported currencies and VND selected by default', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(child: const CreateProjectScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectCurrencyPicker')), findsOneWidget);
      expect(find.byKey(const Key('currencyOption_VND')), findsOneWidget);
      expect(find.byKey(const Key('currencyOption_USD')), findsOneWidget);
      expect(find.byKey(const Key('currencyOption_EUR')), findsOneWidget);
      expect(find.byKey(const Key('currencyOption_JPY')), findsOneWidget);
      expect(find.byKey(const Key('currencyOption_GBP')), findsOneWidget);

      final vndChip = tester.widget<ChoiceChip>(find.byKey(const Key('currencyOption_VND')));
      expect(vndChip.selected, isTrue);

      final usdChip = tester.widget<ChoiceChip>(find.byKey(const Key('currencyOption_USD')));
      expect(usdChip.selected, isFalse);
    });

    testWidgets('Tapping USD chip selects USD in CreateProjectScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(child: const CreateProjectScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('currencyOption_USD')));
      await tester.pumpAndSettle();

      final usdChip = tester.widget<ChoiceChip>(find.byKey(const Key('currencyOption_USD')));
      expect(usdChip.selected, isTrue);

      final vndChip = tester.widget<ChoiceChip>(find.byKey(const Key('currencyOption_VND')));
      expect(vndChip.selected, isFalse);
    });

    testWidgets('Editing existing project pre-selects existing currency', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final existingProject = Project(
        id: 'p_edit',
        name: 'Tokyo Trip',
        currency: 'JPY',
        members: const ['m1'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(buildTestApp(child: CreateProjectScreen(project: existingProject)));
      await tester.pumpAndSettle();

      final jpyChip = tester.widget<ChoiceChip>(find.byKey(const Key('currencyOption_JPY')));
      expect(jpyChip.selected, isTrue);
    });
  });

  group('ProjectScreen Currency Badge Tests', () {
    testWidgets('Displays currency badge with code and symbol on project card', (tester) async {
      final project = Project(
        id: 'proj_usd',
        name: 'US Trip',
        currency: 'USD',
        members: const ['m1'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(buildTestApp(
        child: const ProjectScreen(),
        projects: [project],
      ));
      await tester.pumpAndSettle();

      final badgeFinder = find.byKey(Key('projectCurrencyBadge_${project.id}'));
      expect(badgeFinder, findsOneWidget);
      expect(find.text('USD (\$)'), findsOneWidget);
    });

    testWidgets('Displays VND badge for default project', (tester) async {
      final project = Project(
        id: 'proj_vnd',
        name: 'Home Household',
        currency: 'VND',
        members: const ['m1'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(buildTestApp(
        child: const ProjectScreen(),
        projects: [project],
      ));
      await tester.pumpAndSettle();

      final badgeFinder = find.byKey(Key('projectCurrencyBadge_${project.id}'));
      expect(badgeFinder, findsOneWidget);
      expect(find.text('VND (₫)'), findsOneWidget);
    });

    testWidgets('Displays EUR badge for EUR project', (tester) async {
      final project = Project(
        id: 'proj_eur',
        name: 'Paris Vacation',
        currency: 'EUR',
        members: const ['m1'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(buildTestApp(
        child: const ProjectScreen(),
        projects: [project],
      ));
      await tester.pumpAndSettle();

      final badgeFinder = find.byKey(Key('projectCurrencyBadge_${project.id}'));
      expect(badgeFinder, findsOneWidget);
      expect(find.text('EUR (€)'), findsOneWidget);
    });
  });

  group('ProjectDetailScreen Full Amount Formatting & Currency Symbol Tests', () {
    testWidgets('52,000 displays with thousand separators and no 52k abbreviations in VND project', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = Project(
        id: 'p_format_vnd',
        name: 'VND Household',
        currency: 'VND',
        members: const ['m1', 'm2'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final bill = Bill(
        id: 'b1',
        projectId: 'p_format_vnd',
        title: 'Grocery',
        amount: 52000,
        paidBy: 'm1',
        date: DateTime(2026, 1, 1),
        category: 'restaurant',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'm1', amount: 26000),
          BillParticipant(participantId: 'p2', name: 'm2', amount: 26000),
        ],
      );

      final billRepo = FakeBillRepo([bill]);

      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: project),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      // Ensure 52k or 52K is NOT displayed anywhere
      expect(find.textContaining('52k'), findsNothing);
      expect(find.textContaining('52K'), findsNothing);

      // Verify formatted with separator 52,000₫
      expect(find.text('52,000₫'), findsWidgets);
    });

    testWidgets('600,000 displays as 600,000\$ in USD project', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = Project(
        id: 'p_format_usd',
        name: 'USD Household',
        currency: 'USD',
        members: const ['m1', 'm2'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final bill = Bill(
        id: 'b_usd_1',
        projectId: 'p_format_usd',
        title: 'Tech Gadget',
        amount: 600000,
        paidBy: 'm1',
        date: DateTime(2026, 1, 1),
        category: 'restaurant',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'm1', amount: 300000),
          BillParticipant(participantId: 'p2', name: 'm2', amount: 300000),
        ],
      );

      final billRepo = FakeBillRepo([bill]);

      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: project),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      // No 600k abbreviation
      expect(find.textContaining('600k'), findsNothing);
      expect(find.textContaining('600K'), findsNothing);

      // Displays USD symbol $ and 600,000$
      expect(find.text('600,000\$'), findsWidgets);
    });

    testWidgets('Settlement items display project currency symbol', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = Project(
        id: 'p_settle_eur',
        name: 'EUR Trip',
        currency: 'EUR',
        members: const ['m1', 'm2'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final bill = Bill(
        id: 'b_eur_1',
        projectId: 'p_settle_eur',
        title: 'Dinner',
        amount: 100000,
        paidBy: 'm1',
        date: DateTime(2026, 1, 1),
        category: 'restaurant',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'm1', amount: 50000),
          BillParticipant(participantId: 'p2', name: 'm2', amount: 50000),
        ],
      );

      final billRepo = FakeBillRepo([bill]);

      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: project),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      // Switch to settlement tab
      await tester.tap(find.text('Settlement'));
      await tester.pumpAndSettle();

      // Check settlement card displays 50,000€
      expect(find.text('50,000€'), findsWidgets);
    });

    testWidgets('AddBillScreen initializes with passed initialCurrency', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(initialCurrency: 'GBP'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('GBP'), findsWidgets);
    });

    testWidgets('Statistics tab displays project currency symbol and formatted amount', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = Project(
        id: 'p_stats_jpy',
        name: 'Tokyo Trip',
        currency: 'JPY',
        members: const ['m1', 'm2'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final bill = Bill(
        id: 'b_jpy_1',
        projectId: 'p_stats_jpy',
        title: 'Shinkansen',
        amount: 32000,
        paidBy: 'm1',
        date: DateTime(2026, 1, 1),
        category: 'restaurant',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'm1', amount: 16000),
          BillParticipant(participantId: 'p2', name: 'm2', amount: 16000),
        ],
      );

      final billRepo = FakeBillRepo([bill]);

      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: project),
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      // Switch to statistics tab
      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();

      expect(find.text('32,000¥'), findsWidgets);
    });
  });
}
