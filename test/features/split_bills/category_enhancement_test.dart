import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:dartz/dartz.dart';

import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/category_entity.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/category_icon.dart';
import 'package:shared_household_planner/features/split_bills/data/models/bill_model.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/add_bill_screen.dart';
import 'package:shared_household_planner/features/split_bills/presentation/widgets/add_category_bottom_sheet.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';

// ─────────────────────────────────────────────
// Test Fakes & Localizations
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
    'save_bill': 'Save Bill',
    'bill_name_required': 'Bill name is required',
    'amount_required': 'Amount is required',
    'amount_must_be_positive': 'Amount must be positive',
    'payer_required': 'Payer is required',
    'min_2_participants': 'At least 2 participants required',
    'select_project': 'Select Project (Optional)',
    'no_project': 'No Project',
    'project_no_members': 'This project has no members. Please add members first.',
    'tap_to_toggle': 'Tap to select/deselect',
    'title': 'Title',
    'icon': 'Icon',
    'image': 'Image',
    'currency': 'Currency',
    'when': 'When',
    'split': 'Split',
    'gallery': 'Gallery',
    'camera': 'Camera',
    'remove_image': 'Remove Image',
    'each_pays': 'Each pays',
    'color': 'Color',
    'suggestions': 'Suggestions',
    'add_category': 'Add Category',
    'category_name': 'Category Name',
    'category_name_required': 'Category name is required',
    'category_already_exists': 'Category already exists',
    'save_category': 'Save Category',
    'popular_suggestions': 'Popular Suggestions',
    'choose_color': 'Choose Color',
    'choose_icon': 'Choose Icon',
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

Widget buildTestApp({
  required Widget child,
  BillsBloc? billsBloc,
  ProjectBloc? projectBloc,
}) {
  billsBloc ??= BillsBloc(
    getBillsUseCase: GetBillsUseCase(FakeBillRepository()),
    addBillUseCase: AddBillUseCase(FakeBillRepository()),
  );
  projectBloc ??= ProjectBloc(
    createProjectUseCase: CreateProjectUseCase(FakeProjectRepository([])),
    getAllProjectsUseCase: GetAllProjectsUseCase(FakeProjectRepository([])),
    updateProjectUseCase: UpdateProjectUseCase(FakeProjectRepository([])),
    deleteProjectUseCase: DeleteProjectUseCase(FakeProjectRepository([])),
  );

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
  final testDate = DateTime(2026, 9, 8);

  // ════════════════════════════════════════════════════════════
  // 1. Color Mapping & Presets Unit Tests
  // ════════════════════════════════════════════════════════════
  group('1. Category Color Mapping & Presets', () {
    test('Restaurant has Red brand color (#F44336)', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'restaurant');
      expect(item.colorHex, '#F44336');
      expect(item.color, const Color(0xFFF44336));
    });

    test('Transport has Blue brand color (#2196F3)', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'transport');
      expect(item.colorHex, '#2196F3');
      expect(item.color, const Color(0xFF2196F3));
    });

    test('Shopping has Green brand color (#4CAF50)', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'shopping');
      expect(item.colorHex, '#4CAF50');
      expect(item.color, const Color(0xFF4CAF50));
    });

    test('Health has Pink brand color (#E91E63)', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'health');
      expect(item.colorHex, '#E91E63');
      expect(item.color, const Color(0xFFE91E63));
    });

    test('Entertainment has Purple brand color (#9C27B0)', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'entertainment');
      expect(item.colorHex, '#9C27B0');
      expect(item.color, const Color(0xFF9C27B0));
    });

    test('Travel has Orange brand color (#FF9800)', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'travel');
      expect(item.colorHex, '#FF9800');
      expect(item.color, const Color(0xFFFF9800));
    });

    test('Utilities has Gray brand color (#9E9E9E)', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'utilities');
      expect(item.colorHex, '#9E9E9E');
      expect(item.color, const Color(0xFF9E9E9E));
    });

    test('Education has Indigo brand color (#3F51B5)', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'education');
      expect(item.colorHex, '#3F51B5');
      expect(item.color, const Color(0xFF3F51B5));
    });

    test('Party has Magenta brand color (#E040FB)', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'party');
      expect(item.colorHex, '#E040FB');
      expect(item.color, const Color(0xFFE040FB));
    });

    test('Office has Yellow/Amber brand color (#FFC107)', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'office');
      expect(item.colorHex, '#FFC107');
      expect(item.color, const Color(0xFFFFC107));
    });

    test('Pet has Brown brand color (#795548)', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'pet');
      expect(item.colorHex, '#795548');
      expect(item.color, const Color(0xFF795548));
    });

    test('Sport has Cyan brand color (#00BCD4)', () {
      final item = defaultCategoryIcons.firstWhere((c) => c.id == 'sport');
      expect(item.colorHex, '#00BCD4');
      expect(item.color, const Color(0xFF00BCD4));
    });

    test('presetCategoryColors contains at least 12 colors', () {
      expect(presetCategoryColors.length, greaterThanOrEqualTo(12));
    });

    test('suggestedCategoryIcons contains at least 20 Material icons', () {
      expect(suggestedCategoryIcons.length, greaterThanOrEqualTo(20));
      expect(suggestedCategoryIcons, containsAll([
        Icons.restaurant,
        Icons.local_taxi,
        Icons.shopping_bag,
        Icons.health_and_safety,
        Icons.local_movies,
        Icons.flight,
        Icons.home,
        Icons.school,
        Icons.cake,
        Icons.work,
        Icons.pets,
        Icons.sports_basketball,
      ]));
    });

    test('popularCategorySuggestions contains 8 popular presets with icons & colors', () {
      expect(popularCategorySuggestions.length, 8);
      final ids = popularCategorySuggestions.map((s) => s.id).toList();
      expect(ids, containsAll([
        'restaurant',
        'transport',
        'shopping',
        'health',
        'entertainment',
        'travel',
        'party',
        'sport',
      ]));
    });

    test('colorFromHex parses 6-digit and 8-digit hex', () {
      expect(colorFromHex('#FF0000'), const Color(0xFFFF0000));
      expect(colorFromHex('FF0000'), const Color(0xFFFF0000));
      expect(colorFromHex('#80FF0000'), const Color(0x80FF0000));
      expect(colorFromHex('invalid'), const Color(0xFF9E9E9E));
    });

    test('colorToHex formats Color to #RRGGBB', () {
      expect(colorToHex(const Color(0xFFFF0000)), '#FF0000');
      expect(colorToHex(const Color(0xFF00FF00)), '#00FF00');
    });
  });

  // ════════════════════════════════════════════════════════════
  // 2. Backward Compatibility & Entity Serialization
  // ════════════════════════════════════════════════════════════
  group('2. Backward Compatibility & Category Entity', () {
    test('Bill without categoryColor falls back to mapped category color', () {
      final bill = Bill(
        id: 'b1',
        title: 'Taxi',
        amount: 50000,
        category: 'transport',
        date: testDate,
        paidBy: 'An',
        participants: const [],
      );

      expect(bill.categoryColor, isNull);
      // Fallback is Transport Blue #2196F3
      expect(bill.effectiveCategoryColor, '#2196F3');
    });

    test('Bill with explicit categoryColor uses provided color', () {
      final bill = Bill(
        id: 'b1',
        title: 'Dinner',
        amount: 150000,
        category: 'restaurant',
        date: testDate,
        paidBy: 'Binh',
        participants: const [],
        categoryColor: '#E040FB',
      );

      expect(bill.categoryColor, '#E040FB');
      expect(bill.effectiveCategoryColor, '#E040FB');
    });

    test('BillModel fromJson parses categoryColor', () {
      final json = {
        'id': 'b1',
        'title': 'Coffee',
        'amount': 30000.0,
        'category': 'restaurant',
        'date': testDate.toIso8601String(),
        'paidBy': 'Chi',
        'participants': [],
        'categoryColor': '#FF9800',
      };

      final model = BillModel.fromJson(json);
      expect(model.categoryColor, '#FF9800');
      expect(model.effectiveCategoryColor, '#FF9800');
    });

    test('BillModel toJson includes categoryColor when present', () {
      final bill = Bill(
        id: 'b1',
        title: 'Coffee',
        amount: 30000,
        category: 'restaurant',
        date: testDate,
        paidBy: 'Chi',
        participants: const [],
        categoryColor: '#00BCD4',
      );

      final model = BillModel.fromEntity(bill);
      final json = model.toJson();
      expect(json['categoryColor'], '#00BCD4');
    });

    test('CategoryEntity serializes to and from Json', () {
      const entity = CategoryEntity(
        id: 'custom_cafe',
        name: 'Cafe & Tea',
        icon: '☕',
        colorHex: '#795548',
        iconCodePoint: 58745,
      );

      final json = entity.toJson();
      expect(json['id'], 'custom_cafe');
      expect(json['name'], 'Cafe & Tea');
      expect(json['icon'], '☕');
      expect(json['colorHex'], '#795548');
      expect(json['iconCodePoint'], 58745);

      final fromJson = CategoryEntity.fromJson(json);
      expect(fromJson, equals(entity));
      expect(fromJson.color, const Color(0xFF795548));
    });
  });

  // ════════════════════════════════════════════════════════════
  // 3. AddCategoryBottomSheet Widget Tests
  // ════════════════════════════════════════════════════════════
  group('3. AddCategoryBottomSheet UI & Interaction', () {
    testWidgets('Renders all sections: header, suggestions, name, icon picker, color palette, save', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const Scaffold(
          body: AddCategoryBottomSheet(existingCategories: defaultCategoryIcons),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Add Category'), findsOneWidget);
      expect(find.byKey(const Key('cancelCategoryButton')), findsOneWidget);
      expect(find.text('Suggestions'), findsOneWidget);
      expect(find.byKey(const Key('newCategoryNameField')), findsOneWidget);
      expect(find.text('Choose Icon'), findsOneWidget);
      expect(find.text('Choose Color'), findsOneWidget);
      expect(find.byKey(const Key('saveCategoryButton')), findsOneWidget);
    });

    testWidgets('Tapping a suggestion chip auto-populates category name, icon, and color', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const Scaffold(
          body: AddCategoryBottomSheet(existingCategories: []),
        ),
      ));
      await tester.pumpAndSettle();

      // Tap suggestion "Restaurant"
      await tester.tap(find.byKey(const Key('suggestion_restaurant')));
      await tester.pumpAndSettle();

      // Name field is populated
      expect(find.widgetWithText(TextField, 'Restaurant'), findsOneWidget);
      // Emoji preview updated to 🍽️
      expect(find.text('🍽️'), findsWidgets);
    });

    testWidgets('Validation error when category name is empty', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const Scaffold(
          body: AddCategoryBottomSheet(existingCategories: []),
        ),
      ));
      await tester.pumpAndSettle();

      // Tap Save without entering name
      await tester.tap(find.byKey(const Key('saveCategoryButton')));
      await tester.pumpAndSettle();

      expect(find.text('Category name is required'), findsOneWidget);
    });

    testWidgets('Validation error when category name already exists', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const Scaffold(
          body: AddCategoryBottomSheet(existingCategories: defaultCategoryIcons),
        ),
      ));
      await tester.pumpAndSettle();

      // Enter 'restaurant' (which exists in defaultCategoryIcons)
      await tester.enterText(find.byKey(const Key('newCategoryNameField')), 'restaurant');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveCategoryButton')));
      await tester.pumpAndSettle();

      expect(find.text('Category already exists'), findsOneWidget);
    });

    testWidgets('Selecting custom color swatch updates active color', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const Scaffold(
          body: AddCategoryBottomSheet(existingCategories: []),
        ),
      ));
      await tester.pumpAndSettle();

      // Tap Green swatch #4CAF50
      await tester.tap(find.byKey(const Key('color_swatch_#4CAF50')));
      await tester.pumpAndSettle();

      // Checkmark icon appears in the selected swatch
      expect(find.descendant(
        of: find.byKey(const Key('color_swatch_#4CAF50')),
        matching: find.byIcon(Icons.check),
      ), findsOneWidget);
    });
  });

  // ════════════════════════════════════════════════════════════
  // 4. AddBillScreen Category Color Enhancement & Flow Tests
  // ════════════════════════════════════════════════════════════
  group('4. AddBillScreen Category Enhancement & Persistence', () {
    testWidgets('Selected category badge displays category brand color', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
      ));
      await tester.pumpAndSettle();

      // Badge exists
      final badgeFinder = find.byKey(const Key('selectedCategoryIconBadge'));
      expect(badgeFinder, findsOneWidget);

      final Container container = tester.widget(badgeFinder);
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      // Default restaurant is Red
      expect(decoration.border?.top.color, const Color(0xFFF44336));
    });

    testWidgets('Tapping category chip updates badge border to that category color', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
      ));
      await tester.pumpAndSettle();

      // Tap Transport 🚕 (Blue)
      await tester.tap(find.byKey(const Key('category_icon_transport')));
      await tester.pumpAndSettle();

      final badgeFinder = find.byKey(const Key('selectedCategoryIconBadge'));
      final Container container = tester.widget(badgeFinder);
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      expect(decoration.border?.top.color, const Color(0xFF2196F3));
    });

    testWidgets('Add category button (+) exists in category header', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('addCategoryButton')), findsOneWidget);
      expect(find.text('Add Category'), findsOneWidget);
    });

    testWidgets('Saves bill with categoryColor persisted correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepository();
      final billsBloc = BillsBloc(
        getBillsUseCase: GetBillsUseCase(billRepo),
        addBillUseCase: AddBillUseCase(billRepo),
      );

      final project = Project(
        id: 'proj-beach',
        name: 'Beach Trip',
        members: const ['An', 'Binh'],
        createdAt: testDate,
        updatedAt: testDate,
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

      // 1. Title
      await tester.enterText(find.widgetWithText(TextField, 'Bill Name'), 'Hotel booking');

      // 2. Category: Shopping (Green #4CAF50)
      await tester.tap(find.byKey(const Key('category_icon_shopping')));
      await tester.pumpAndSettle();

      // 3. Amount
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '1200000');

      // 4. Select Project
      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Beach Trip').last);
      await tester.pumpAndSettle();

      // 5. Save
      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      // Verify saved bill in repository
      expect(billRepo.savedBills.length, 1);
      final saved = billRepo.savedBills.first;
      expect(saved.title, 'Hotel booking');
      expect(saved.category, 'shopping');
      expect(saved.categoryIcon, '🛍️');
      expect(saved.categoryColor, '#4CAF50');
      expect(saved.effectiveCategoryColor, '#4CAF50');

      billsBloc.close();
      projectBloc.close();
    });
  });
}
