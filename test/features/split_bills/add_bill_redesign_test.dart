import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';

import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/category_icon.dart';
import 'package:shared_household_planner/features/split_bills/data/models/bill_model.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/add_bill_screen.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project_settings.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';

// ─────────────────────────────────────────────
// Test Fake Repositories
// ─────────────────────────────────────────────
class FakeBillRepository implements BillRepository {
  final List<Bill> savedBills = [];

  @override
  Future<Either<Failure, Bill>> create(Bill bill) async {
    savedBills.add(bill);
    return Right(bill);
  }

  @override
  Future<Either<Failure, List<Bill>>> getAll() async => Right(List.from(savedBills));

  @override
  Future<Either<Failure, Bill>> getById(String billId) async =>
      Right(savedBills.firstWhere((b) => b.id == billId));

  @override
  Future<Either<Failure, Bill>> update(Bill bill) async => Right(bill);

  @override
  Future<Either<Failure, void>> delete(String billId) async {
    savedBills.removeWhere((b) => b.id == billId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(String projectId) async {
    return Right(savedBills.where((b) => b.projectId == projectId).toList());
  }
}

class FakeProjectRepository implements ProjectRepository {
  final List<Project> _projects;
  FakeProjectRepository(this._projects);

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
    'expense': 'Expense',
    'income': 'Income',
    'transfer': 'Transfer',
    'title': 'Title',
    'icon': 'Icon',
    'image': 'Image',
    'currency': 'Currency',
    'paid_by': 'Paid By',
    'when': 'When',
    'split': 'Split',
    'gallery': 'Gallery',
    'camera': 'Camera',
    'remove_image': 'Remove Image',
    'select_date': 'Select Date',
    'each_pays': 'Each pays',
    'category_restaurant': 'Restaurant',
    'category_transport': 'Transport',
    'category_shopping': 'Shopping',
    'category_health': 'Health',
    'category_entertainment': 'Entertainment',
    'category_travel': 'Travel',
    'category_utilities': 'Utilities',
    'category_education': 'Education',
    'category_party': 'Party',
    'category_office': 'Office',
    'category_pet': 'Pet',
    'category_sport': 'Sport',
  };

  @override
  String translate(String key) => _strings[key] ?? key;
}

class TestAppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const TestAppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => TestAppLocalizations();
  @override
  bool shouldReload(TestAppLocalizationsDelegate old) => false;
}

final _testDate = DateTime(2026, 9, 8);

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
      ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
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

void main() {
  // ════════════════════════════════════════════════════════════
  // 1. Domain & Model Tests (CategoryIconItem & Currency)
  // ════════════════════════════════════════════════════════════
  group('1. CategoryIconItem & Default Categories', () {
    test('defaultCategoryIcons has at least 12 categories', () {
      expect(defaultCategoryIcons.length, greaterThanOrEqualTo(12));
    });

    test('All categories have non-empty id, icon, and nameKey', () {
      for (final cat in defaultCategoryIcons) {
        expect(cat.id.isNotEmpty, isTrue);
        expect(cat.icon.isNotEmpty, isTrue);
        expect(cat.nameKey.isNotEmpty, isTrue);
      }
    });

    test('Includes Restaurant with 🍽️', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'restaurant');
      expect(item.icon, '🍽️');
    });

    test('Includes Transport with 🚕', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'transport');
      expect(item.icon, '🚕');
    });

    test('Includes Shopping with 🛍️', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'shopping');
      expect(item.icon, '🛍️');
    });

    test('Includes Health with 💊', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'health');
      expect(item.icon, '💊');
    });

    test('Includes Entertainment with 🎬', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'entertainment');
      expect(item.icon, '🎬');
    });

    test('Includes Travel with ✈️', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'travel');
      expect(item.icon, '✈️');
    });

    test('Includes Utilities with 🏠', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'utilities');
      expect(item.icon, '🏠');
    });

    test('Includes Education with 📚', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'education');
      expect(item.icon, '📚');
    });

    test('Includes Party with 🎉', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'party');
      expect(item.icon, '🎉');
    });

    test('Includes Office with 💼', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'office');
      expect(item.icon, '💼');
    });

    test('Includes Pet with 🐕', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'pet');
      expect(item.icon, '🐕');
    });

    test('Includes Sport with ⚽', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'sport');
      expect(item.icon, '⚽');
    });

    test('CategoryIconItem equality works correctly', () {
      const a = CategoryIconItem(id: 'food', icon: '🍽️', nameKey: 'food_key');
      const b = CategoryIconItem(id: 'food', icon: '🍽️', nameKey: 'food_key');
      expect(a, equals(b));
    });
  });

  group('2. ProjectSettings & Currencies', () {
    test('ProjectSettings defaults to VND', () {
      const settings = ProjectSettings();
      expect(settings.defaultCurrency, 'VND');
    });

    test('ProjectSettings contains 7 available currencies', () {
      const settings = ProjectSettings();
      expect(settings.availableCurrencies, containsAll(['VND', 'USD', 'EUR', 'GBP', 'JPY', 'SGD', 'THB']));
    });

    test('Currency symbols map contains correct symbols', () {
      expect(currencySymbols['VND'], '₫');
      expect(currencySymbols['USD'], '\$');
      expect(currencySymbols['EUR'], '€');
      expect(currencySymbols['GBP'], '£');
      expect(currencySymbols['JPY'], '¥');
      expect(currencySymbols['SGD'], 'S\$');
      expect(currencySymbols['THB'], '฿');
    });

    test('ProjectSettings equality holds', () {
      const s1 = ProjectSettings();
      const s2 = ProjectSettings();
      expect(s1, equals(s2));
    });

    test('ProjectSettings custom values work', () {
      const s = ProjectSettings(defaultCurrency: 'USD', availableCurrencies: ['USD', 'EUR']);
      expect(s.defaultCurrency, 'USD');
      expect(s.availableCurrencies, ['USD', 'EUR']);
    });
  });

  // ════════════════════════════════════════════════════════════
  // 2. Bill & BillModel Entity / Data Layer Tests
  // ════════════════════════════════════════════════════════════
  group('3. Bill Entity with categoryIcon, currency, imagePath', () {
    test('Bill entity stores new fields', () {
      final bill = Bill(
        id: 'b1',
        title: 'Dinner',
        amount: 250000,
        category: 'restaurant',
        date: _testDate,
        paidBy: 'An',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'An', amount: 125000),
          BillParticipant(participantId: 'p2', name: 'Binh', amount: 125000),
        ],
        categoryIcon: '🍽️',
        currency: 'VND',
        imagePath: '/path/to/receipt.jpg',
      );

      expect(bill.categoryIcon, '🍽️');
      expect(bill.currency, 'VND');
      expect(bill.imagePath, '/path/to/receipt.jpg');
    });

    test('Bill entity allows null for optional fields', () {
      final bill = Bill(
        id: 'b2',
        title: 'Lunch',
        amount: 100000,
        category: 'food',
        date: _testDate,
        paidBy: 'An',
        participants: const [],
      );

      expect(bill.categoryIcon, isNull);
      expect(bill.currency, isNull);
      expect(bill.imagePath, isNull);
    });

    test('Bill equality compares categoryIcon, currency, and imagePath', () {
      final b1 = Bill(
        id: 'b1',
        title: 'Taxi',
        amount: 50000,
        category: 'transport',
        date: _testDate,
        paidBy: 'An',
        participants: const [],
        categoryIcon: '🚕',
        currency: 'USD',
        imagePath: 'img1.png',
      );
      final b2 = Bill(
        id: 'b1',
        title: 'Taxi',
        amount: 50000,
        category: 'transport',
        date: _testDate,
        paidBy: 'An',
        participants: const [],
        categoryIcon: '🚕',
        currency: 'USD',
        imagePath: 'img1.png',
      );
      final b3 = Bill(
        id: 'b1',
        title: 'Taxi',
        amount: 50000,
        category: 'transport',
        date: _testDate,
        paidBy: 'An',
        participants: const [],
        categoryIcon: '🚕',
        currency: 'EUR',
        imagePath: 'img1.png',
      );

      expect(b1, equals(b2));
      expect(b1, isNot(equals(b3)));
    });
  });

  group('4. BillModel Serialization with new fields', () {
    test('BillModel.fromJson parses categoryIcon, currency, imagePath', () {
      final json = {
        'id': 'b1',
        'title': 'Coffee',
        'amount': 45000.0,
        'category': 'restaurant',
        'date': _testDate.toIso8601String(),
        'paidBy': 'Chi',
        'participants': [
          {'participantId': 'p1', 'name': 'Chi', 'amount': 45000.0}
        ],
        'categoryIcon': '☕',
        'currency': 'VND',
        'imagePath': '/images/coffee.jpg',
      };

      final model = BillModel.fromJson(json);
      expect(model.categoryIcon, '☕');
      expect(model.currency, 'VND');
      expect(model.imagePath, '/images/coffee.jpg');
    });

    test('BillModel.fromJson defaults currency to VND if null', () {
      final json = {
        'id': 'b2',
        'title': 'Snack',
        'amount': 20000.0,
        'category': 'shopping',
        'date': _testDate.toIso8601String(),
        'paidBy': 'An',
        'participants': [],
      };

      final model = BillModel.fromJson(json);
      expect(model.currency, 'VND');
      expect(model.categoryIcon, isNull);
      expect(model.imagePath, isNull);
    });

    test('BillModel.toJson includes new fields when present', () {
      final bill = Bill(
        id: 'b1',
        title: 'Dinner',
        amount: 500000,
        category: 'restaurant',
        date: _testDate,
        paidBy: 'An',
        participants: const [],
        categoryIcon: '🍽️',
        currency: 'USD',
        imagePath: '/receipt.png',
      );

      final model = BillModel.fromEntity(bill);
      final json = model.toJson();

      expect(json['categoryIcon'], '🍽️');
      expect(json['currency'], 'USD');
      expect(json['imagePath'], '/receipt.png');
    });

    test('BillModel.toJson omits null fields', () {
      final bill = Bill(
        id: 'b1',
        title: 'Dinner',
        amount: 500000,
        category: 'restaurant',
        date: _testDate,
        paidBy: 'An',
        participants: const [],
      );

      final model = BillModel.fromEntity(bill);
      final json = model.toJson();

      expect(json.containsKey('categoryIcon'), isFalse);
      expect(json.containsKey('imagePath'), isFalse);
    });

    test('BillModel.fromEntity copies all fields', () {
      final bill = Bill(
        id: 'b1',
        title: 'Flight',
        amount: 2000000,
        category: 'travel',
        date: _testDate,
        paidBy: 'Binh',
        participants: const [],
        projectId: 'p-danang',
        categoryIcon: '✈️',
        currency: 'EUR',
        imagePath: '/ticket.jpg',
      );

      final model = BillModel.fromEntity(bill);
      expect(model.categoryIcon, '✈️');
      expect(model.currency, 'EUR');
      expect(model.imagePath, '/ticket.jpg');
      expect(model.projectId, 'p-danang');
    });
  });

  // ════════════════════════════════════════════════════════════
  // 3. Widget Tests: Redesigned AddBillScreen UI & Interactivity
  // ════════════════════════════════════════════════════════════
  group('5. AddBillScreen Redesign UI Layout', () {
    testWidgets('Displays all sections in required order', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepository();
      final billsBloc = BillsBloc(
        getBillsUseCase: GetBillsUseCase(billRepo),
        addBillUseCase: AddBillUseCase(billRepo),
      );
      final projectBloc = ProjectBloc(
        createProjectUseCase: CreateProjectUseCase(FakeProjectRepository([])),
        getAllProjectsUseCase: GetAllProjectsUseCase(FakeProjectRepository([])),
        updateProjectUseCase: UpdateProjectUseCase(FakeProjectRepository([])),
        deleteProjectUseCase: DeleteProjectUseCase(FakeProjectRepository([])),
      );

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        billsBloc: billsBloc,
        projectBloc: projectBloc,
      ));
      await tester.pumpAndSettle();

      // 1. Title + Icon Badge
      expect(find.byKey(const Key('selectedCategoryIconBadge')), findsOneWidget);
      expect(find.text('Bill Name'), findsOneWidget);

      // 2. Icon Category Selector
      expect(find.byKey(const Key('category_icon_restaurant')), findsOneWidget);
      expect(find.byKey(const Key('category_icon_transport')), findsOneWidget);

      // 3. Image upload buttons
      expect(find.byKey(const Key('pickGalleryButton')), findsOneWidget);
      expect(find.byKey(const Key('takeCameraButton')), findsOneWidget);

      // 4. Amount + Currency
      expect(find.text('Amount'), findsOneWidget);
      expect(find.byKey(const Key('currencyDropdown')), findsOneWidget);

      // 5. Paid By
      expect(find.byKey(const Key('payerField')), findsOneWidget);

      // 6. When / Date
      expect(find.byKey(const Key('datePickerButton')), findsOneWidget);

      // 7. Split & Save Button
      expect(find.text('Split'), findsOneWidget);
      expect(find.byKey(const Key('saveProjectButton')), findsOneWidget);

      billsBloc.close();
      projectBloc.close();
    });
  });

  group('6. Category Selection & Icon Badge', () {
    testWidgets('Tapping a category updates selectedCategoryItem and icon badge', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepository();
      final billsBloc = BillsBloc(
        getBillsUseCase: GetBillsUseCase(billRepo),
        addBillUseCase: AddBillUseCase(billRepo),
      );
      final projectBloc = ProjectBloc(
        createProjectUseCase: CreateProjectUseCase(FakeProjectRepository([])),
        getAllProjectsUseCase: GetAllProjectsUseCase(FakeProjectRepository([])),
        updateProjectUseCase: UpdateProjectUseCase(FakeProjectRepository([])),
        deleteProjectUseCase: DeleteProjectUseCase(FakeProjectRepository([])),
      );

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        billsBloc: billsBloc,
        projectBloc: projectBloc,
      ));
      await tester.pumpAndSettle();

      // Initially restaurant 🍽️ is selected
      expect(find.descendant(
        of: find.byKey(const Key('selectedCategoryIconBadge')),
        matching: find.text('🍽️'),
      ), findsOneWidget);

      // Tap Transport 🚕
      await tester.tap(find.byKey(const Key('category_icon_transport')));
      await tester.pumpAndSettle();

      // Now badge shows 🚕
      expect(find.descendant(
        of: find.byKey(const Key('selectedCategoryIconBadge')),
        matching: find.text('🚕'),
      ), findsOneWidget);

      billsBloc.close();
      projectBloc.close();
    });

    testWidgets('Tapping multiple categories updates icon badge sequentially', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepository();
      final billsBloc = BillsBloc(
        getBillsUseCase: GetBillsUseCase(billRepo),
        addBillUseCase: AddBillUseCase(billRepo),
      );
      final projectBloc = ProjectBloc(
        createProjectUseCase: CreateProjectUseCase(FakeProjectRepository([])),
        getAllProjectsUseCase: GetAllProjectsUseCase(FakeProjectRepository([])),
        updateProjectUseCase: UpdateProjectUseCase(FakeProjectRepository([])),
        deleteProjectUseCase: DeleteProjectUseCase(FakeProjectRepository([])),
      );

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        billsBloc: billsBloc,
        projectBloc: projectBloc,
      ));
      await tester.pumpAndSettle();

      // Tap Shopping 🛍️
      await tester.tap(find.byKey(const Key('category_icon_shopping')));
      await tester.pumpAndSettle();
      expect(find.descendant(
        of: find.byKey(const Key('selectedCategoryIconBadge')),
        matching: find.text('🛍️'),
      ), findsOneWidget);

      // Tap Health 💊
      await tester.tap(find.byKey(const Key('category_icon_health')));
      await tester.pumpAndSettle();
      expect(find.descendant(
        of: find.byKey(const Key('selectedCategoryIconBadge')),
        matching: find.text('💊'),
      ), findsOneWidget);

      billsBloc.close();
      projectBloc.close();
    });
  });

  group('7. Image Upload & Removal', () {
    testWidgets('Shows image preview when image is selected via onPickImage', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepository();
      final billsBloc = BillsBloc(
        getBillsUseCase: GetBillsUseCase(billRepo),
        addBillUseCase: AddBillUseCase(billRepo),
      );
      final projectBloc = ProjectBloc(
        createProjectUseCase: CreateProjectUseCase(FakeProjectRepository([])),
        getAllProjectsUseCase: GetAllProjectsUseCase(FakeProjectRepository([])),
        updateProjectUseCase: UpdateProjectUseCase(FakeProjectRepository([])),
        deleteProjectUseCase: DeleteProjectUseCase(FakeProjectRepository([])),
      );

      await tester.pumpWidget(buildTestApp(
        child: AddBillScreen(
          onPickImage: (source) async => '/path/to/mock_gallery_image.jpg',
        ),
        billsBloc: billsBloc,
        projectBloc: projectBloc,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('imagePreview')), findsNothing);

      // Tap pick from gallery
      await tester.tap(find.byKey(const Key('pickGalleryButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('imagePreview')), findsOneWidget);
      expect(find.byKey(const Key('removeImageButton')), findsOneWidget);

      billsBloc.close();
      projectBloc.close();
    });

    testWidgets('Tapping remove image clears thumbnail preview', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepository();
      final billsBloc = BillsBloc(
        getBillsUseCase: GetBillsUseCase(billRepo),
        addBillUseCase: AddBillUseCase(billRepo),
      );
      final projectBloc = ProjectBloc(
        createProjectUseCase: CreateProjectUseCase(FakeProjectRepository([])),
        getAllProjectsUseCase: GetAllProjectsUseCase(FakeProjectRepository([])),
        updateProjectUseCase: UpdateProjectUseCase(FakeProjectRepository([])),
        deleteProjectUseCase: DeleteProjectUseCase(FakeProjectRepository([])),
      );

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(
          initialImagePath: '/path/to/preloaded_receipt.jpg',
        ),
        billsBloc: billsBloc,
        projectBloc: projectBloc,
      ));
      await tester.pumpAndSettle();

      // Preview initially visible
      expect(find.byKey(const Key('imagePreview')), findsOneWidget);

      // Tap remove image
      await tester.tap(find.byKey(const Key('removeImageButton')));
      await tester.pumpAndSettle();

      // Preview gone
      expect(find.byKey(const Key('imagePreview')), findsNothing);

      billsBloc.close();
      projectBloc.close();
    });

    testWidgets('Camera button works via onPickImage', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepository();
      final billsBloc = BillsBloc(
        getBillsUseCase: GetBillsUseCase(billRepo),
        addBillUseCase: AddBillUseCase(billRepo),
      );
      final projectBloc = ProjectBloc(
        createProjectUseCase: CreateProjectUseCase(FakeProjectRepository([])),
        getAllProjectsUseCase: GetAllProjectsUseCase(FakeProjectRepository([])),
        updateProjectUseCase: UpdateProjectUseCase(FakeProjectRepository([])),
        deleteProjectUseCase: DeleteProjectUseCase(FakeProjectRepository([])),
      );

      await tester.pumpWidget(buildTestApp(
        child: AddBillScreen(
          onPickImage: (source) async => '/path/to/camera_shot.jpg',
        ),
        billsBloc: billsBloc,
        projectBloc: projectBloc,
      ));
      await tester.pumpAndSettle();

      // Tap camera
      await tester.tap(find.byKey(const Key('takeCameraButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('imagePreview')), findsOneWidget);

      billsBloc.close();
      projectBloc.close();
    });
  });

  group('8. Currency Selector & Dynamic Symbol', () {
    testWidgets('Amount field shows dynamic currency symbol when currency changes', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepository();
      final billsBloc = BillsBloc(
        getBillsUseCase: GetBillsUseCase(billRepo),
        addBillUseCase: AddBillUseCase(billRepo),
      );
      final projectBloc = ProjectBloc(
        createProjectUseCase: CreateProjectUseCase(FakeProjectRepository([])),
        getAllProjectsUseCase: GetAllProjectsUseCase(FakeProjectRepository([])),
        updateProjectUseCase: UpdateProjectUseCase(FakeProjectRepository([])),
        deleteProjectUseCase: DeleteProjectUseCase(FakeProjectRepository([])),
      );

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        billsBloc: billsBloc,
        projectBloc: projectBloc,
      ));
      await tester.pumpAndSettle();

      // Default is VND (₫)
      expect(find.text('₫'), findsWidgets);

      // Open currency dropdown
      await tester.tap(find.byKey(const Key('currencyDropdown')));
      await tester.pumpAndSettle();

      // Select USD ($)
      await tester.tap(find.text('USD (\$)').last);
      await tester.pumpAndSettle();

      // Now amount field shows $
      expect(find.text('\$'), findsWidgets);

      billsBloc.close();
      projectBloc.close();
    });

    testWidgets('Loads available currencies from custom ProjectSettings', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepository();
      final billsBloc = BillsBloc(
        getBillsUseCase: GetBillsUseCase(billRepo),
        addBillUseCase: AddBillUseCase(billRepo),
      );
      final projectBloc = ProjectBloc(
        createProjectUseCase: CreateProjectUseCase(FakeProjectRepository([])),
        getAllProjectsUseCase: GetAllProjectsUseCase(FakeProjectRepository([])),
        updateProjectUseCase: UpdateProjectUseCase(FakeProjectRepository([])),
        deleteProjectUseCase: DeleteProjectUseCase(FakeProjectRepository([])),
      );

      const customSettings = ProjectSettings(
        defaultCurrency: 'EUR',
        availableCurrencies: ['EUR', 'GBP'],
      );

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(projectSettings: customSettings),
        billsBloc: billsBloc,
        projectBloc: projectBloc,
      ));
      await tester.pumpAndSettle();

      expect(find.text('€'), findsWidgets);

      await tester.tap(find.byKey(const Key('currencyDropdown')));
      await tester.pumpAndSettle();

      expect(find.text('EUR (€)'), findsWidgets);
      expect(find.text('GBP (£)'), findsWidgets);

      billsBloc.close();
      projectBloc.close();
    });
  });

  group('9. Real-time Split Recalculation', () {
    testWidgets('Recalculates per person amount when total amount changes', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = makeProject(members: ['An', 'Binh']);
      final billRepo = FakeBillRepository();
      final billsBloc = BillsBloc(
        getBillsUseCase: GetBillsUseCase(billRepo),
        addBillUseCase: AddBillUseCase(billRepo),
      );
      final projectBloc = ProjectBloc(
        createProjectUseCase: CreateProjectUseCase(FakeProjectRepository([project])),
        getAllProjectsUseCase: GetAllProjectsUseCase(FakeProjectRepository([project])),
        updateProjectUseCase: UpdateProjectUseCase(FakeProjectRepository([project])),
        deleteProjectUseCase: DeleteProjectUseCase(FakeProjectRepository([project])),
      );

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        billsBloc: billsBloc,
        projectBloc: projectBloc,
      ));
      await tester.pumpAndSettle();

      // Select Project
      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Da Nang Trip').last);
      await tester.pumpAndSettle();

      // Enter amount 200000
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '200000');
      await tester.pumpAndSettle();

      // 200000 / 2 members = 100000 each
      expect(find.byKey(const Key('realtimeSplitText')), findsOneWidget);
      expect(find.textContaining('100000'), findsWidgets);

      // Change amount to 600000
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '600000');
      await tester.pumpAndSettle();

      // 600000 / 2 = 300000 each
      expect(find.textContaining('300000'), findsWidgets);

      billsBloc.close();
      projectBloc.close();
    });

    testWidgets('Recalculates per person amount when participant is deselected', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = makeProject(members: ['An', 'Binh', 'Chi']);
      final billRepo = FakeBillRepository();
      final billsBloc = BillsBloc(
        getBillsUseCase: GetBillsUseCase(billRepo),
        addBillUseCase: AddBillUseCase(billRepo),
      );
      final projectBloc = ProjectBloc(
        createProjectUseCase: CreateProjectUseCase(FakeProjectRepository([project])),
        getAllProjectsUseCase: GetAllProjectsUseCase(FakeProjectRepository([project])),
        updateProjectUseCase: UpdateProjectUseCase(FakeProjectRepository([project])),
        deleteProjectUseCase: DeleteProjectUseCase(FakeProjectRepository([project])),
      );

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        billsBloc: billsBloc,
        projectBloc: projectBloc,
      ));
      await tester.pumpAndSettle();

      // Select Project
      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Da Nang Trip').last);
      await tester.pumpAndSettle();

      // Amount: 300000 (with 3 members: An, Binh, Chi -> 100000 each)
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '300000');
      await tester.pumpAndSettle();
      expect(find.textContaining('100000'), findsWidgets);

      // Deselect 'Chi' -> 2 members remaining (300000 / 2 = 150000 each)
      await tester.tap(find.byKey(const Key('member_chip_Chi')));
      await tester.pumpAndSettle();
      expect(find.textContaining('150000'), findsWidgets);

      billsBloc.close();
      projectBloc.close();
    });
  });

  group('10. Save Bill End-to-End Persistence', () {
    testWidgets('Saves bill with categoryIcon, currency, imagePath and project link', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = makeProject(members: ['An', 'Binh']);
      final billRepo = FakeBillRepository();
      final billsBloc = BillsBloc(
        getBillsUseCase: GetBillsUseCase(billRepo),
        addBillUseCase: AddBillUseCase(billRepo),
      );
      final projectBloc = ProjectBloc(
        createProjectUseCase: CreateProjectUseCase(FakeProjectRepository([project])),
        getAllProjectsUseCase: GetAllProjectsUseCase(FakeProjectRepository([project])),
        updateProjectUseCase: UpdateProjectUseCase(FakeProjectRepository([project])),
        deleteProjectUseCase: DeleteProjectUseCase(FakeProjectRepository([project])),
      );

      await tester.pumpWidget(buildTestApp(
        child: AddBillScreen(
          onPickImage: (_) async => '/images/lunch_bill.jpg',
        ),
        billsBloc: billsBloc,
        projectBloc: projectBloc,
      ));
      await tester.pumpAndSettle();

      // 1. Enter title
      await tester.enterText(find.widgetWithText(TextField, 'Bill Name'), 'Seafood Lunch');

      // 2. Choose Category: Transport (to test custom category selection)
      await tester.tap(find.byKey(const Key('category_icon_transport')));
      await tester.pumpAndSettle();

      // 3. Pick image
      await tester.tap(find.byKey(const Key('pickGalleryButton')));
      await tester.pumpAndSettle();

      // 4. Enter amount
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '500000');

      // 5. Select Currency USD
      await tester.tap(find.byKey(const Key('currencyDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('USD (\$)').last);
      await tester.pumpAndSettle();

      // 6. Select Project
      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Da Nang Trip').last);
      await tester.pumpAndSettle();

      // 7. Tap save
      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      // Verify saved bill in repository
      expect(billRepo.savedBills.length, 1);
      final saved = billRepo.savedBills.first;

      expect(saved.title, 'Seafood Lunch');
      expect(saved.amount, 500000.0);
      expect(saved.category, 'transport');
      expect(saved.categoryIcon, '🚕');
      expect(saved.currency, 'USD');
      expect(saved.imagePath, '/images/lunch_bill.jpg');
      expect(saved.projectId, 'proj-1');
      expect(saved.participants.length, 2);

      billsBloc.close();
      projectBloc.close();
    });

    testWidgets('Validation error prevents save when title is empty', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepository();
      final billsBloc = BillsBloc(
        getBillsUseCase: GetBillsUseCase(billRepo),
        addBillUseCase: AddBillUseCase(billRepo),
      );
      final projectBloc = ProjectBloc(
        createProjectUseCase: CreateProjectUseCase(FakeProjectRepository([])),
        getAllProjectsUseCase: GetAllProjectsUseCase(FakeProjectRepository([])),
        updateProjectUseCase: UpdateProjectUseCase(FakeProjectRepository([])),
        deleteProjectUseCase: DeleteProjectUseCase(FakeProjectRepository([])),
      );

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        billsBloc: billsBloc,
        projectBloc: projectBloc,
      ));
      await tester.pumpAndSettle();

      // Tap Save with empty form
      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(find.text('Bill name is required'), findsOneWidget);
      expect(billRepo.savedBills, isEmpty);

      billsBloc.close();
      projectBloc.close();
    });

    testWidgets('Validation error prevents save when amount <= 0', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepository();
      final billsBloc = BillsBloc(
        getBillsUseCase: GetBillsUseCase(billRepo),
        addBillUseCase: AddBillUseCase(billRepo),
      );
      final projectBloc = ProjectBloc(
        createProjectUseCase: CreateProjectUseCase(FakeProjectRepository([])),
        getAllProjectsUseCase: GetAllProjectsUseCase(FakeProjectRepository([])),
        updateProjectUseCase: UpdateProjectUseCase(FakeProjectRepository([])),
        deleteProjectUseCase: DeleteProjectUseCase(FakeProjectRepository([])),
      );

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        billsBloc: billsBloc,
        projectBloc: projectBloc,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Bill Name'), 'Lunch');
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '0');

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(find.text('Amount must be positive'), findsOneWidget);
      expect(billRepo.savedBills, isEmpty);

      billsBloc.close();
      projectBloc.close();
    });
  });
}
