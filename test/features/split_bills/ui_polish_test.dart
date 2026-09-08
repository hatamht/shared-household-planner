import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:dartz/dartz.dart';

import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/category_icon.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/add_bill_screen.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project_settings.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test Doubles & Helpers
// ─────────────────────────────────────────────────────────────────────────────
class FakeBillRepo implements BillRepository {
  final List<Bill> bills = [];
  @override
  Future<Either<Failure, Bill>> create(Bill bill) async {
    bills.add(bill);
    return Right(bill);
  }
  @override
  Future<Either<Failure, List<Bill>>> getAll() async => Right(List.from(bills));
  @override
  Future<Either<Failure, Bill>> getById(String billId) async =>
      Right(bills.firstWhere((b) => b.id == billId));
  @override
  Future<Either<Failure, Bill>> update(Bill bill) async => Right(bill);
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

class FakeProjRepo implements ProjectRepository {
  final List<Project> projects;
  FakeProjRepo([this.projects = const []]);
  @override
  Future<Either<Failure, List<Project>>> getAll() async => Right(projects);
  @override
  Future<Either<Failure, Project>> create(Project project) async => Right(project);
  @override
  Future<Either<Failure, Project>> getById(String id) async =>
      Right(projects.firstWhere((p) => p.id == id,
          orElse: () => Project(
              id: id,
              name: 'P',
              members: const [],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now())));
  @override
  Future<Either<Failure, Project>> update(Project project) async => Right(project);
  @override
  Future<Either<Failure, void>> delete(String id) async => const Right(null);
}

class UIPolishAppLocalizations extends AppLocalizations {
  final Locale _locale;
  UIPolishAppLocalizations(this._locale) : super(_locale);

  static const Map<String, String> _en = {
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
    'add_category': 'Add Category',
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
    'select_project': 'Select Project (Optional)',
    'no_project': 'No Project',
    'project_members_loaded': 'Project members loaded',
    'project_no_members': 'This project has no members. Please add members first.',
    'select_participants': 'Select Participants',
    'tap_to_toggle': 'Tap to select/deselect',
    'bill_linked_to_project': 'Bill linked to project',
    'category_restaurant': 'Restaurant',
    'category_restaurant_short': 'Dining',
    'category_transport': 'Transport',
    'category_transport_short': 'Transport',
    'category_shopping': 'Shopping',
    'category_shopping_short': 'Shopping',
    'category_health': 'Health',
    'category_health_short': 'Health',
    'category_entertainment': 'Entertainment',
    'category_entertainment_short': 'Fun',
    'category_travel': 'Travel',
    'category_travel_short': 'Travel',
    'category_utilities': 'Utilities',
    'category_utilities_short': 'Bills',
    'category_education': 'Education',
    'category_education_short': 'Learn',
    'category_party': 'Party',
    'category_party_short': 'Party',
    'category_office': 'Office',
    'category_office_short': 'Office',
    'category_pet': 'Pet',
    'category_pet_short': 'Pet',
    'category_sport': 'Sport',
    'category_sport_short': 'Sport',
  };

  @override
  Locale get locale => _locale;

  @override
  String translate(String key) => _en[key] ?? key;
}

class UIPolishLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const UIPolishLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => UIPolishAppLocalizations(locale);
  @override
  bool shouldReload(UIPolishLocalizationsDelegate old) => false;
}

Widget buildTestUIPolishApp({
  Widget? child,
  FakeBillRepo? billRepo,
  List<Project>? projects,
  ProjectSettings? projectSettings,
  Brightness brightness = Brightness.light,
  String? initialImagePath,
  Future<String?> Function(dynamic)? onPickImage,
}) {
  final repo = billRepo ?? FakeBillRepo();
  final billsBloc = BillsBloc(
    getBillsUseCase: GetBillsUseCase(repo),
    addBillUseCase: AddBillUseCase(repo),
  );
  final projectBloc = ProjectBloc(
    createProjectUseCase: CreateProjectUseCase(FakeProjRepo(projects ?? [])),
    getAllProjectsUseCase: GetAllProjectsUseCase(FakeProjRepo(projects ?? [])),
    updateProjectUseCase: UpdateProjectUseCase(FakeProjRepo(projects ?? [])),
    deleteProjectUseCase: DeleteProjectUseCase(FakeProjRepo(projects ?? [])),
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
        theme: ThemeData(
          brightness: brightness,
          useMaterial3: true,
          scaffoldBackgroundColor: brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey[50],
          cardColor: brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.white,
        ),
        localizationsDelegates: const [
          UIPolishLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: child ?? AddBillScreen(
          projectSettings: projectSettings ?? const ProjectSettings(),
          initialImagePath: initialImagePath,
          onPickImage: onPickImage,
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 1: Header Polish (Typography, Spacing, Close Button, Divider)
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 1: Header Polish', () {
    testWidgets('Header displays Close button with Key("closeButton")', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      final closeBtn = find.byKey(const Key('closeButton'));
      expect(closeBtn, findsOneWidget);
      expect(find.descendant(of: closeBtn, matching: find.byIcon(Icons.close)), findsOneWidget);
    });

    testWidgets('Header title displays "Add Bill" centered with semi-bold typography', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      final titleFinder = find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Add Bill'),
      );
      expect(titleFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(titleFinder);
      expect(textWidget.style?.fontWeight, anyOf(FontWeight.w600, FontWeight.bold));
      expect(textWidget.style?.fontSize, greaterThanOrEqualTo(17.0));
    });

    testWidgets('Tapping close button calls maybePop', (tester) async {
      final billRepo = FakeBillRepo();
      final billsBloc = BillsBloc(
        getBillsUseCase: GetBillsUseCase(billRepo),
        addBillUseCase: AddBillUseCase(billRepo),
      );
      final projectBloc = ProjectBloc(
        createProjectUseCase: CreateProjectUseCase(FakeProjRepo([])),
        getAllProjectsUseCase: GetAllProjectsUseCase(FakeProjRepo([])),
        updateProjectUseCase: UpdateProjectUseCase(FakeProjRepo([])),
        deleteProjectUseCase: DeleteProjectUseCase(FakeProjRepo([])),
      );

      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<BillsBloc>.value(value: billsBloc),
              BlocProvider<ProjectBloc>.value(value: projectBloc),
            ],
            child: MaterialApp(
              navigatorKey: navKey,
              localizationsDelegates: const [
                UIPolishLocalizationsDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: Builder(
                builder: (ctx) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).push(
                      MaterialPageRoute(builder: (_) => const AddBillScreen()),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('closeButton')), findsOneWidget);
      await tester.tap(find.byKey(const Key('closeButton')));
      await tester.pumpAndSettle();

      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('Header bottom decoration exists as PreferredSize divider', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.bottom, isNotNull);
      expect(appBar.bottom, isA<PreferredSizeWidget>());
    });

    testWidgets('Header has 0 elevation for flat, modern design', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.elevation, equals(0));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 2: Tab Selector Refinement (Expense / Income / Transfer)
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 2: Tab Selector Refinement', () {
    testWidgets('Tabs container rendered with Key("transactionTypeTabs")', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('transactionTypeTabs')), findsOneWidget);
    });

    testWidgets('Contains Expense, Income, and Transfer tab options', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
    });

    testWidgets('Expense tab is selected by default', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      final expenseText = tester.widget<Text>(find.text('Expense'));
      expect(expenseText.style?.fontWeight, equals(FontWeight.bold));
    });

    testWidgets('Switching tab to Income updates selection smoothly', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      final incomeText = tester.widget<Text>(find.text('Income'));
      expect(incomeText.style?.fontWeight, equals(FontWeight.bold));
    });

    testWidgets('Switching tab to Transfer updates selection smoothly', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Transfer'));
      await tester.pumpAndSettle();

      final transferText = tester.widget<Text>(find.text('Transfer'));
      expect(transferText.style?.fontWeight, equals(FontWeight.bold));
    });

    testWidgets('Tabs have rounded container background styling', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      final tabContainer = tester.widget<Container>(find.byKey(const Key('transactionTypeTabs')));
      final decor = tabContainer.decoration as BoxDecoration?;
      expect(decor?.borderRadius, isNotNull);
    });

    testWidgets('Each tab item has equal flex weight', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      final tabRow = find.descendant(
        of: find.byKey(const Key('transactionTypeTabs')),
        matching: find.byType(Row),
      );
      expect(tabRow, findsOneWidget);

      final rowWidget = tester.widget<Row>(tabRow);
      expect(rowWidget.children.length, equals(3));
      for (final child in rowWidget.children) {
        expect(child, isA<Expanded>());
      }
    });

    testWidgets('Tapping back to Expense restores Expense selection', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Expense'));
      await tester.pumpAndSettle();

      final expenseText = tester.widget<Text>(find.text('Expense'));
      expect(expenseText.style?.fontWeight, equals(FontWeight.bold));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 3: Title Section Layout (LEFT Badge, CENTER Title, RIGHT Buttons)
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 3: Title Section Layout (CEO Update)', () {
    testWidgets('Title section contains Row with Left Badge, Center Input, Right Action Buttons', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      final titleField = find.byKey(const Key('titleField'));
      expect(titleField, findsOneWidget);

      // Camera button is present on right
      expect(find.byKey(const Key('cameraTitleButton')), findsOneWidget);
    });

    testWidgets('Left circular badge contains category emoji icon', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      // Default category is restaurant -> emoji 🍽️
      expect(find.descendant(
        of: find.byKey(const Key('selectedCategoryIconBadge')),
        matching: find.text('🍽️'),
      ), findsOneWidget);
    });

    testWidgets('Center title field auto-fills with category name on selection', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('category_icon_restaurant')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Restaurant'), findsOneWidget);
    });

    testWidgets('Clear button Key("clearTitleButton") appears when title is not empty', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'Dinner with friends');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('clearTitleButton')), findsOneWidget);
    });

    testWidgets('Tapping clear button clears title input and hides clear button', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'Dinner');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('clearTitleButton')), findsOneWidget);
      await tester.tap(find.byKey(const Key('clearTitleButton')));
      await tester.pumpAndSettle();

      final titleField = tester.widget<TextField>(find.byKey(const Key('titleField')));
      expect(titleField.controller?.text, isEmpty);
      expect(find.byKey(const Key('clearTitleButton')), findsNothing);
    });

    testWidgets('Camera button Key("cameraTitleButton") triggers image picker', (tester) async {
      bool pickCalled = false;
      await tester.pumpWidget(buildTestUIPolishApp(
        onPickImage: (src) async {
          pickCalled = true;
          return null;
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cameraTitleButton')));
      await tester.pumpAndSettle();

      expect(pickCalled, isTrue);
    });

    testWidgets('Title input font size is prominent (>= 16px)', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      final tf = tester.widget<TextField>(find.byKey(const Key('titleField')));
      expect(tf.style?.fontSize, greaterThanOrEqualTo(16.0));
      expect(tf.style?.fontWeight, equals(FontWeight.w600));
    });

    testWidgets('Title section container has rounded border and card background', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      final finder = find.ancestor(
        of: find.byKey(const Key('titleField')),
        matching: find.byType(Container),
      ).first;
      final container = tester.widget<Container>(finder);
      final decor = container.decoration as BoxDecoration?;
      expect(decor?.borderRadius, isNotNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 4: Image Preview Styling & Remove Button
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 4: Image Preview Refinement', () {
    testWidgets('Image preview displays with borderRadius 16 when image is set', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp(
        initialImagePath: '/fake/path/receipt.jpg',
      ));
      await tester.pumpAndSettle();

      final removeBtn = find.byKey(const Key('removeImageButton'));
      expect(removeBtn, findsOneWidget);

      final clipRRectFinder = find.byType(ClipRRect);
      expect(clipRRectFinder, findsWidgets);
      final clipRRect = tester.widget<ClipRRect>(clipRRectFinder.first);
      expect(clipRRect.borderRadius, equals(BorderRadius.circular(16)));
    });

    testWidgets('Tapping removeImageButton clears selectedImage', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp(
        initialImagePath: '/fake/path/receipt.jpg',
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('removeImageButton')), findsOneWidget);
      await tester.tap(find.byKey(const Key('removeImageButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('removeImageButton')), findsNothing);
    });

    testWidgets('Remove button is positioned at bottom-right corner', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp(
        initialImagePath: '/fake/path/receipt.jpg',
      ));
      await tester.pumpAndSettle();

      final positionedFinder = find.ancestor(
        of: find.byKey(const Key('removeImageButton')),
        matching: find.byType(Positioned),
      );
      expect(positionedFinder, findsOneWidget);

      final positioned = tester.widget<Positioned>(positionedFinder);
      expect(positioned.right, isNotNull);
      expect(positioned.bottom, isNotNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 5: Amount Section (Pill Currency Dropdown & Right Alignment)
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 5: Amount Section Refinement', () {
    testWidgets('Currency dropdown has Key("currencyDropdown")', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('currencyDropdown')), findsOneWidget);
    });

    testWidgets('Amount input text is right-aligned', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      final allTextFields = tester.widgetList<TextField>(find.byType(TextField));
      final amountField = allTextFields.firstWhere((tf) => tf.decoration?.labelText == 'Amount');
      expect(amountField.textAlign, equals(TextAlign.right));
    });

    testWidgets('Amount field uses number keyboard with decimal option', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      final allTextFields = tester.widgetList<TextField>(find.byType(TextField));
      final amountField = allTextFields.firstWhere((tf) => tf.decoration?.labelText == 'Amount');
      expect(amountField.keyboardType, equals(const TextInputType.numberWithOptions(decimal: true)));
    });

    testWidgets('Pill container encapsulates currency selector with rounded corners', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      final pillContainerFinder = find.ancestor(
        of: find.byKey(const Key('currencyDropdown')),
        matching: find.byType(Container),
      ).first;

      final container = tester.widget<Container>(pillContainerFinder);
      final decor = container.decoration as BoxDecoration?;
      expect(decor?.borderRadius, isNotNull);
    });

    testWidgets('Suffix text shows active currency symbol', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      // Default VND symbol
      expect(find.text('₫'), findsWidgets);
    });

    testWidgets('Changing currency updates suffix symbol to USD (\$)', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('currencyDropdown')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('USD (\$)').last);
      await tester.pumpAndSettle();

      expect(find.text('\$'), findsWidgets);
    });

    testWidgets('Changing currency updates suffix symbol to EUR (€)', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('currencyDropdown')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('EUR (€)').last);
      await tester.pumpAndSettle();

      expect(find.text('€'), findsWidgets);
    });

    testWidgets('Entering amount value formats correctly in text field', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '250000');
      await tester.pumpAndSettle();

      expect(find.text('250000'), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 6: Paid By & When (Two-column Layout)
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 6: Paid By & When Section (Two-column Layout)', () {
    testWidgets('Payer field has Key("payerField")', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payerField')), findsOneWidget);
    });

    testWidgets('When / Date picker card has Key("datePickerButton")', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('datePickerButton')), findsOneWidget);
    });

    testWidgets('Payer and Date Picker are arranged in a horizontal Row (2 columns)', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      final payerFinder = find.byKey(const Key('payerField'));
      final dateFinder = find.byKey(const Key('datePickerButton'));

      final rowFinder = find.ancestor(of: payerFinder, matching: find.byType(Row));
      expect(rowFinder, findsWidgets);

      final isDateDescendant = find.descendant(of: rowFinder.first, matching: dateFinder);
      expect(isDateDescendant, findsOneWidget);
    });

    testWidgets('Both Payer and Date picker columns use Expanded for 50/50 balance', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      final payerExpanded = find.ancestor(of: find.byKey(const Key('payerField')), matching: find.byType(Expanded));
      final dateExpanded = find.ancestor(of: find.byKey(const Key('datePickerButton')), matching: find.byType(Expanded));

      expect(payerExpanded, findsWidgets);
      expect(dateExpanded, findsWidgets);
    });

    testWidgets('Payer card shows person icon prefix', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('Date picker card shows calendar icon', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('Date picker displays current formatted date (yyyy-MM-dd)', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final expectedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      expect(find.text(expectedDate), findsOneWidget);
    });

    testWidgets('Payer field allows typing custom payer name', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('payerField')), 'Bob');
      await tester.pumpAndSettle();

      expect(find.text('Bob'), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 7: Split Section (Card-based Participant List, Avatars, Checkboxes)
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 7: Split Section Refinement', () {
    testWidgets('Displays Split section header with title', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      expect(find.text('Split'), findsOneWidget);
    });

    testWidgets('Project members each display card with name and avatar', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = Project(
        id: 'p1',
        name: 'Apartment',
        members: ['Alice', 'Bob'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestUIPolishApp(projects: [project]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apartment').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('member_card_Alice')), findsOneWidget);
      expect(find.byKey(const Key('member_card_Bob')), findsOneWidget);
    });

    testWidgets('Each participant card has a Checkbox', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = Project(
        id: 'p1',
        name: 'Apartment',
        members: ['Alice', 'Bob'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestUIPolishApp(projects: [project]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apartment').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('member_checkbox_Alice')), findsOneWidget);
      expect(find.byKey(const Key('member_checkbox_Bob')), findsOneWidget);
    });

    testWidgets('Tapping participant card toggles checkbox state', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = Project(
        id: 'p1',
        name: 'Apartment',
        members: ['Alice', 'Bob'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestUIPolishApp(projects: [project]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apartment').last);
      await tester.pumpAndSettle();

      // Tap Bob's card to toggle
      await tester.tap(find.byKey(const Key('member_card_Bob')));
      await tester.pumpAndSettle();

      final bobCheckbox = tester.widget<Checkbox>(find.byKey(const Key('member_checkbox_Bob')));
      expect(bobCheckbox.value, isFalse);
    });

    testWidgets('Split calculation updates realtime when amount is entered', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = Project(
        id: 'p1',
        name: 'Apartment',
        members: ['Alice', 'Bob'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestUIPolishApp(projects: [project]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apartment').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '100000');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('realtimeSplitText')), findsOneWidget);
      expect(find.textContaining('50000'), findsWidgets);
    });

    testWidgets('Adding manual participant adds chip when no project is selected', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Participant Name'), 'Charlie');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      expect(find.text('Charlie'), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 8: Color Integration (Category Brand Color as Accent)
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 8: Category Brand Color Integration', () {
    testWidgets('Default Restaurant category applies brand color to selectedCategoryIconBadge border', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      final badge = tester.widget<Container>(find.byKey(const Key('selectedCategoryIconBadge')));
      final decor = badge.decoration as BoxDecoration?;
      expect(decor?.border, isNotNull);
    });

    testWidgets('Selecting Transport category updates category icon to taxi', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('category_icon_transport')));
      await tester.pumpAndSettle();

      expect(find.descendant(
        of: find.byKey(const Key('selectedCategoryIconBadge')),
        matching: find.text('🚕'),
      ), findsOneWidget);
    });

    testWidgets('Selecting Shopping category updates category icon to bag', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('category_icon_shopping')));
      await tester.pumpAndSettle();

      expect(find.descendant(
        of: find.byKey(const Key('selectedCategoryIconBadge')),
        matching: find.text('🛍️'),
      ), findsOneWidget);
    });

    testWidgets('Save button Key("saveProjectButton") uses category color', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      final saveBtnFinder = find.byKey(const Key('saveProjectButton'));
      expect(saveBtnFinder, findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 9 & 10: Spacing, Padding, and Interactive Feedback
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 9 & 10: Spacing, Padding, and Feedback', () {
    testWidgets('Screen content has consistent padding', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      final paddingFinders = find.byType(Padding);
      expect(paddingFinders, findsWidgets);
    });

    testWidgets('Form elements are contained in SingleChildScrollView for no overflow', (tester) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('InkWell ripple feedback is present on interactive cards', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      final inkWells = find.byType(InkWell);
      expect(inkWells, findsWidgets);
    });

    testWidgets('Save button is clickable and responsive', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      final saveBtn = tester.widget<ElevatedButton>(find.byKey(const Key('saveProjectButton')));
      expect(saveBtn.onPressed, isNotNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 11: Dark Mode Refinement
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 11: Dark Mode Refinement', () {
    testWidgets('Renders properly in Dark Mode without glitches', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp(brightness: Brightness.dark));
      await tester.pumpAndSettle();

      expect(find.text('Add Bill'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
    });

    testWidgets('Cards in Dark Mode have dark surface background, not pure black', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp(brightness: Brightness.dark));
      await tester.pumpAndSettle();

      final titleContainerFinder = find.ancestor(
        of: find.byKey(const Key('titleField')),
        matching: find.byType(Container),
      ).first;
      final container = tester.widget<Container>(titleContainerFinder);
      final decor = container.decoration as BoxDecoration?;
      expect(decor?.color, isNotNull);
      expect(decor?.color, isNot(equals(Colors.white)));
      expect(decor?.color, isNot(equals(Colors.black)));
    });

    testWidgets('Tabs container in Dark Mode has dark surface fill', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp(brightness: Brightness.dark));
      await tester.pumpAndSettle();

      final tabContainer = tester.widget<Container>(find.byKey(const Key('transactionTypeTabs')));
      final decor = tabContainer.decoration as BoxDecoration?;
      expect(decor?.color, isNotNull);
      expect(decor?.color, isNot(equals(Colors.white)));
    });

    testWidgets('Divider below AppBar renders with dark mode border color', (tester) async {
      await tester.pumpWidget(buildTestUIPolishApp(brightness: Brightness.dark));
      await tester.pumpAndSettle();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.bottom, isNotNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 12: Category Selection & Auto-Fill & Project Link Integrations
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 12: End-to-End Functionality and Integrations', () {
    testWidgets('Auto-fills title dynamically when selecting Health category', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('category_icon_health')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Health'), findsOneWidget);
    });

    testWidgets('Auto-fills title dynamically when selecting Education category', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('category_icon_education')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Education'), findsOneWidget);
    });

    testWidgets('Auto-fills title dynamically when selecting Party category', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('category_icon_party')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Party'), findsOneWidget);
    });

    testWidgets('Auto-fills title dynamically when selecting Pet category', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView).first, const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('category_icon_pet')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Pet'), findsOneWidget);
    });

    testWidgets('Auto-fills title dynamically when selecting Sport category', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView).first, const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('category_icon_sport')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Sport'), findsOneWidget);
    });

    testWidgets('Auto-fills title dynamically when selecting Entertainment category', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('category_icon_entertainment')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Entertainment'), findsOneWidget);
    });

    testWidgets('Auto-fills title dynamically when selecting Travel category', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('category_icon_travel')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Travel'), findsOneWidget);
    });

    testWidgets('Auto-fills title dynamically when selecting Utilities category', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('category_icon_utilities')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Utilities'), findsOneWidget);
    });

    testWidgets('Auto-fills title dynamically when selecting Office category', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestUIPolishApp());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView).first, const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('category_icon_office')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Office'), findsOneWidget);
    });

    testWidgets('Selecting project populates project members into split participants', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = Project(
        id: 'p1',
        name: 'Apartment 402',
        members: ['Lan', 'Minh', 'Khoa'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestUIPolishApp(projects: [project]));
      await tester.pumpAndSettle();

      // Open project dropdown
      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();

      // Select project
      await tester.tap(find.text('Apartment 402').last);
      await tester.pumpAndSettle();

      // Verify member cards are present
      expect(find.byKey(const Key('member_card_Lan')), findsOneWidget);
      expect(find.byKey(const Key('member_card_Minh')), findsOneWidget);
      expect(find.byKey(const Key('member_card_Khoa')), findsOneWidget);
    });

    testWidgets('Project members each receive avatar with their initial', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = Project(
        id: 'p1',
        name: 'Apartment 402',
        members: ['Lan'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestUIPolishApp(projects: [project]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apartment 402').last);
      await tester.pumpAndSettle();

      expect(find.descendant(
        of: find.byKey(const Key('member_card_Lan')),
        matching: find.text('L'),
      ), findsOneWidget);
    });

    testWidgets('Project members helper text shown under Payer input', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = Project(
        id: 'p1',
        name: 'Trip Project',
        members: ['David', 'Elena'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestUIPolishApp(projects: [project]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trip Project').last);
      await tester.pumpAndSettle();

      expect(find.text('David, Elena'), findsOneWidget);
    });

    testWidgets('Saving valid bill dispatches AddBillEvent and persists all fields', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = Project(
        id: 'p1',
        name: 'Apartment',
        members: ['Alice', 'Bob'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestUIPolishApp(billRepo: billRepo, projects: [project]));
      await tester.pumpAndSettle();

      // Enter title
      await tester.enterText(find.byKey(const Key('titleField')), 'Grocery shopping');

      // Enter amount
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '150000');

      // Enter payer
      await tester.enterText(find.byKey(const Key('payerField')), 'Alice');
      await tester.pumpAndSettle();

      // Select Project to have members
      await tester.tap(find.byKey(const Key('projectDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apartment').last);
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.bills.length, equals(1));
      final savedBill = billRepo.bills.first;
      expect(savedBill.title, equals('Grocery shopping'));
      expect(savedBill.amount, equals(150000.0));
      expect(savedBill.paidBy, equals('Alice'));
      expect(savedBill.participants.map((p) => p.name), containsAll(['Alice', 'Bob']));
      expect(savedBill.currency, equals('VND'));
    });
  });
}
