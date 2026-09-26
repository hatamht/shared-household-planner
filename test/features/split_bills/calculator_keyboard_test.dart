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
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/services/calculator_evaluator.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/add_bill_screen.dart';
import 'package:shared_household_planner/features/split_bills/presentation/widgets/calculator_keyboard.dart';

// ─── Fakes ──────────────────────────────────────────────────────────────────
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
  Future<Either<Failure, Bill>> getById(String id) async =>
      Right(bills.firstWhere((b) => b.id == id));
  @override
  Future<Either<Failure, Bill>> update(Bill bill) async => Right(bill);
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
  final List<Project> _projects;
  FakeProjRepo([this._projects = const []]);

  @override
  Future<Either<Failure, List<Project>>> getAll() async => Right(List.from(_projects));
  @override
  Future<Either<Failure, Project>> create(Project p) async => Right(p);
  @override
  Future<Either<Failure, Project>> getById(String id) async =>
      Right(_projects.firstWhere((p) => p.id == id));
  @override
  Future<Either<Failure, Project>> update(Project p) async => Right(p);
  @override
  Future<Either<Failure, void>> delete(String id) async => const Right(null);
}

// ─── Test Localization ──────────────────────────────────────────────────────
class _CalcTestLoc extends AppLocalizations {
  final String code;
  _CalcTestLoc(this.code) : super(Locale(code));

  static const Map<String, String> _en = {
    'calculator': 'Calculator',
    'invalid_expression': 'Invalid expression',
    'clear_expression': 'Clear',
    'amount': 'Amount',
    'save': 'Save',
    'save_bill': 'Save Bill',
    'restaurant': 'Restaurant',
    'add_bill': 'Add Bill',
    'today': 'Today',
    'receipt': 'Receipt',
    'expand': 'Expand',
    'collapse': 'Collapse',
    'select_project': 'Select Project',
  };

  static const Map<String, String> _vi = {
    'calculator': 'Máy tính',
    'invalid_expression': 'Biểu thức không hợp lệ',
    'clear_expression': 'Xóa',
    'amount': 'Số tiền',
    'save': 'Lưu',
    'save_bill': 'Lưu hóa đơn',
    'restaurant': 'Nhà hàng',
    'add_bill': 'Thêm hóa đơn',
    'today': 'Hôm nay',
    'receipt': 'Hóa đơn',
    'expand': 'Mở rộng',
    'collapse': 'Thu gọn',
    'select_project': 'Chọn dự án',
  };

  @override
  String translate(String key) {
    if (code == 'vi') return _vi[key] ?? key;
    return _en[key] ?? key;
  }
}

class _CalcTestLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  final String code;
  const _CalcTestLocDelegate([this.code = 'en']);

  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => _CalcTestLoc(code);
  @override
  bool shouldReload(_CalcTestLocDelegate old) => false;
}

Widget buildTestApp({
  required Widget child,
  String language = 'en',
  ThemeData? theme,
  FakeBillRepo? billRepo,
  List<Project>? projects,
}) {
  final bRepo = billRepo ?? FakeBillRepo();
  final billsBloc = BillsBloc(
    getBillsUseCase: GetBillsUseCase(bRepo),
    addBillUseCase: AddBillUseCase(bRepo),
  );

  final pList = projects ??
      [
        Project(
          id: 'proj-1',
          name: 'Home Project',
          members: const ['Alice', 'Bob'],
          createdAt: DateTime(2026, 9, 20),
          updatedAt: DateTime(2026, 9, 20),
        ),
      ];

  final pRepo = FakeProjRepo(pList);
  final projectBloc = ProjectBloc(
    createProjectUseCase: CreateProjectUseCase(pRepo),
    getAllProjectsUseCase: GetAllProjectsUseCase(pRepo),
    getProjectByIdUseCase: GetProjectByIdUseCase(pRepo),
    updateProjectUseCase: UpdateProjectUseCase(pRepo),
    deleteProjectUseCase: DeleteProjectUseCase(pRepo),
  );
  projectBloc.emit(ProjectLoaded(projects: pList));

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
        theme: theme ?? ThemeData.light(useMaterial3: true),
        localizationsDelegates: [_CalcTestLocDelegate(language)],
        supportedLocales: const [Locale('en'), Locale('vi')],
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('AC 1-4 & 10. CalculatorEvaluator - PEMDAS & Decimals', () {
    test('1.1 Simple integer evaluation', () {
      expect(CalculatorEvaluator.evaluate('750'), equals(750.0));
    });

    test('1.2 Simple multiplication "25*30"', () {
      expect(CalculatorEvaluator.evaluate('25*30'), equals(750.0));
    });

    test('1.3 Multiplication with Unicode "×"', () {
      expect(CalculatorEvaluator.evaluate('25×30'), equals(750.0));
    });

    test('1.4 Division with "/"', () {
      expect(CalculatorEvaluator.evaluate('100/4'), equals(25.0));
    });

    test('1.5 Division with Unicode "÷"', () {
      expect(CalculatorEvaluator.evaluate('100÷4'), equals(25.0));
    });

    test('1.6 Addition and Subtraction', () {
      expect(CalculatorEvaluator.evaluate('100+50-20'), equals(130.0));
    });

    test('1.7 PEMDAS: 25 + 30 * 2 equals 85 (not 110)', () {
      expect(CalculatorEvaluator.evaluate('25 + 30 * 2'), equals(85.0));
    });

    test('1.8 PEMDAS with division: 100 - 50 / 2 equals 75', () {
      expect(CalculatorEvaluator.evaluate('100 - 50 / 2'), equals(75.0));
    });

    test('1.9 Parentheses override precedence: (25 + 30) * 2 = 110', () {
      expect(CalculatorEvaluator.evaluate('(25 + 30) * 2'), equals(110.0));
    });

    test('1.10 Decimals: 25.5 * 30 equals 765', () {
      expect(CalculatorEvaluator.evaluate('25.5 * 30'), equals(765.0));
    });

    test('1.11 Decimal addition: 12.25 + 7.75 equals 20', () {
      expect(CalculatorEvaluator.evaluate('12.25 + 7.75'), equals(20.0));
    });

    test('1.12 Incomplete expression returns null', () {
      expect(CalculatorEvaluator.evaluate('25+'), isNull);
      expect(CalculatorEvaluator.canEvaluate('25+'), isFalse);
    });

    test('1.13 Trailing operator returns null', () {
      expect(CalculatorEvaluator.evaluate('25*'), isNull);
    });

    test('1.14 Division by zero returns null', () {
      expect(CalculatorEvaluator.evaluate('100/0'), isNull);
    });

    test('1.15 Empty string returns null', () {
      expect(CalculatorEvaluator.evaluate(''), isNull);
    });

    test('1.16 hasOperator returns true for all supported operators', () {
      expect(CalculatorEvaluator.hasOperator('25+30'), isTrue);
      expect(CalculatorEvaluator.hasOperator('25-30'), isTrue);
      expect(CalculatorEvaluator.hasOperator('25*30'), isTrue);
      expect(CalculatorEvaluator.hasOperator('25×30'), isTrue);
      expect(CalculatorEvaluator.hasOperator('25/30'), isTrue);
      expect(CalculatorEvaluator.hasOperator('25÷30'), isTrue);
      expect(CalculatorEvaluator.hasOperator('25000'), isFalse);
    });

    test('1.17 formatResult formats whole numbers without decimals', () {
      expect(CalculatorEvaluator.formatResult(750.0), equals('750'));
      expect(CalculatorEvaluator.formatResult(85.0), equals('85'));
    });

    test('1.18 formatResult formats decimals cleanly', () {
      expect(CalculatorEvaluator.formatResult(25.5), equals('25.5'));
      expect(CalculatorEvaluator.formatResult(12.25), equals('12.25'));
    });
  });

  group('AC 2. CalculatorKeyboard Widget Keys', () {
    testWidgets('2.1 Keyboard renders all number keys 0-9', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(buildTestApp(
        child: CalculatorKeyboard(controller: controller),
      ));
      await tester.pumpAndSettle();

      for (int i = 0; i <= 9; i++) {
        expect(find.byKey(Key('calc_key_$i')), findsOneWidget);
      }
    });

    testWidgets('2.2 Keyboard renders math operator keys (+, -, ×, ÷, =)', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(buildTestApp(
        child: CalculatorKeyboard(controller: controller),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calc_key_add')), findsOneWidget);
      expect(find.byKey(const Key('calc_key_subtract')), findsOneWidget);
      expect(find.byKey(const Key('calc_key_multiply')), findsOneWidget);
      expect(find.byKey(const Key('calc_key_divide')), findsOneWidget);
      expect(find.byKey(const Key('calc_key_equals')), findsOneWidget);
    });

    testWidgets('2.3 Keyboard renders decimal point (.), backspace (⌫), and space', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(buildTestApp(
        child: CalculatorKeyboard(controller: controller),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calc_key_dot')), findsOneWidget);
      expect(find.byKey(const Key('calc_key_backspace')), findsOneWidget);
      expect(find.byKey(const Key('calc_key_space')), findsOneWidget);
      expect(find.byKey(const Key('calc_key_clear')), findsOneWidget);
      expect(find.byKey(const Key('calc_key_done')), findsOneWidget);
    });
  });

  group('AC 3-7. Keypad Interactions & Real-time Validation', () {
    testWidgets('3.1 Tapping number keys appends to controller', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(buildTestApp(
        child: CalculatorKeyboard(controller: controller),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('calc_key_2')));
      await tester.tap(find.byKey(const Key('calc_key_5')));
      await tester.pumpAndSettle();

      expect(controller.text, equals('25'));
    });

    testWidgets('3.2 Tapping operator keys appends operator', (tester) async {
      final controller = TextEditingController(text: '25');
      await tester.pumpWidget(buildTestApp(
        child: CalculatorKeyboard(controller: controller),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('calc_key_multiply')));
      await tester.pumpAndSettle();
      expect(controller.text, equals('25×'));
    });

    testWidgets('3.3 Tapping "=" evaluates expression and replaces controller text', (tester) async {
      final controller = TextEditingController(text: '25×30');
      await tester.pumpWidget(buildTestApp(
        child: CalculatorKeyboard(controller: controller),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('calc_key_equals')));
      await tester.pumpAndSettle();

      expect(controller.text, equals('750'));
    });

    testWidgets('3.4 Backspace removes last character', (tester) async {
      final controller = TextEditingController(text: '750');
      await tester.pumpWidget(buildTestApp(
        child: CalculatorKeyboard(controller: controller),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('calc_key_backspace')));
      await tester.pumpAndSettle();

      expect(controller.text, equals('75'));
    });

    testWidgets('3.5 Clear (C) button clears entered expression', (tester) async {
      final controller = TextEditingController(text: '25*30+100');
      await tester.pumpWidget(buildTestApp(
        child: CalculatorKeyboard(controller: controller),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('calc_key_clear')));
      await tester.pumpAndSettle();

      expect(controller.text, isEmpty);
    });

    testWidgets('3.6 Real-time preview displays calculated result', (tester) async {
      final controller = TextEditingController(text: '25×30');
      await tester.pumpWidget(buildTestApp(
        child: CalculatorKeyboard(controller: controller),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calc_result_preview')), findsOneWidget);
      expect(find.text('= 750'), findsOneWidget);
    });

    testWidgets('3.7 Visual feedback shows invalid expression error when incomplete', (tester) async {
      final controller = TextEditingController(text: '25+');
      await tester.pumpWidget(buildTestApp(
        child: CalculatorKeyboard(controller: controller),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calc_error_text')), findsOneWidget);
    });

    testWidgets('3.8 Space key appends a space', (tester) async {
      final controller = TextEditingController(text: '25');
      await tester.pumpWidget(buildTestApp(
        child: CalculatorKeyboard(controller: controller),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('calc_key_space')));
      await tester.pumpAndSettle();

      expect(controller.text, equals('25 '));
    });

    testWidgets('3.9 Decimal key appends dot', (tester) async {
      final controller = TextEditingController(text: '25');
      await tester.pumpWidget(buildTestApp(
        child: CalculatorKeyboard(controller: controller),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('calc_key_dot')));
      await tester.pumpAndSettle();

      expect(controller.text, equals('25.'));
    });
  });

  group('AC 8-9. Copy-Paste & Save with Calculated Result in AddBillScreen', () {
    testWidgets('8.1 Compact mode has toggleCalculatorButton', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(initialCompactMode: true),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('toggleCalculatorButton')), findsOneWidget);
    });

    testWidgets('8.2 Tapping toggleCalculatorButton reveals CalculatorKeyboard in compact mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(initialCompactMode: true),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calculatorKeyboard')), findsNothing);

      await tester.tap(find.byKey(const Key('toggleCalculatorButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calculatorKeyboard')), findsOneWidget);
    });

    testWidgets('8.3 Full mode has fullToggleCalculatorButton and toggles keyboard', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(initialCompactMode: false),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fullToggleCalculatorButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('fullToggleCalculatorButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calculatorKeyboard')), findsOneWidget);
    });

    testWidgets('8.4 Typing or pasting "25*30" into compactAmountField shows preview "= 750"', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(initialCompactMode: true),
      ));
      await tester.pumpAndSettle();

      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '25*30';
      await tester.pump();

      expect(find.byKey(const Key('compactAmountCalcPreview')), findsOneWidget);
      expect(find.text('= 750'), findsOneWidget);
    });

    testWidgets('8.5 Saving bill with expression "25*30" saves calculated result 750', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        billRepo: billRepo,
        child: const AddBillScreen(projectId: 'proj-1', initialCompactMode: true),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('compactDescriptionField')), 'Dinner party');
      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '25*30';
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.bills, isNotEmpty);
      expect(billRepo.bills.first.amount, equals(750.0));
    });

    testWidgets('8.6 Saving bill with PEMDAS expression "25 + 30 * 2" saves 85', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        billRepo: billRepo,
        child: const AddBillScreen(projectId: 'proj-1', initialCompactMode: true),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('compactDescriptionField')), 'Coffee & snacks');
      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '25 + 30 * 2';
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.bills, isNotEmpty);
      expect(billRepo.bills.first.amount, equals(85.0));
    });

    testWidgets('8.7 Saving bill with decimal expression "25.5 * 30" saves 765', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(
        billRepo: billRepo,
        child: const AddBillScreen(projectId: 'proj-1', initialCompactMode: true),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('compactDescriptionField')), 'Fuel bill');
      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '25.5 * 30';
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.bills, isNotEmpty);
      expect(billRepo.bills.first.amount, equals(765.0));
    });
  });

  group('AC 11-12. Theme & Internationalization', () {
    testWidgets('11.1 CalculatorKeyboard renders properly in dark theme', (tester) async {
      final controller = TextEditingController(text: '123+456');
      await tester.pumpWidget(buildTestApp(
        theme: ThemeData.dark(useMaterial3: true),
        child: CalculatorKeyboard(controller: controller),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calculatorKeyboard')), findsOneWidget);
      expect(find.byKey(const Key('calc_result_preview')), findsOneWidget);
    });

    testWidgets('11.2 CalculatorKeyboard renders properly in light theme', (tester) async {
      final controller = TextEditingController(text: '123+456');
      await tester.pumpWidget(buildTestApp(
        theme: ThemeData.light(useMaterial3: true),
        child: CalculatorKeyboard(controller: controller),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calculatorKeyboard')), findsOneWidget);
      expect(find.byKey(const Key('calc_result_preview')), findsOneWidget);
    });

    testWidgets('12.1 Vietnamese localization shows "Biểu thức không hợp lệ" on invalid syntax', (tester) async {
      final controller = TextEditingController(text: '25+');
      await tester.pumpWidget(buildTestApp(
        language: 'vi',
        child: CalculatorKeyboard(controller: controller),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Biểu thức không hợp lệ'), findsOneWidget);
    });

    testWidgets('12.2 English localization shows "Invalid expression" on invalid syntax', (tester) async {
      final controller = TextEditingController(text: '25+');
      await tester.pumpWidget(buildTestApp(
        language: 'en',
        child: CalculatorKeyboard(controller: controller),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Invalid expression'), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 13: Comma as Thousands Separator
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 13: Comma Thousands Separator & Formatting', () {
    test('13.1 formatWithCommas formats integer digits with commas', () {
      expect(CalculatorEvaluator.formatWithCommas('1000'), equals('1,000'));
      expect(CalculatorEvaluator.formatWithCommas('100000'), equals('100,000'));
      expect(CalculatorEvaluator.formatWithCommas('1000000'), equals('1,000,000'));
      expect(CalculatorEvaluator.formatWithCommas('500'), equals('500'));
    });

    test('13.2 formatWithCommas formats decimal digits correctly', () {
      expect(CalculatorEvaluator.formatWithCommas('1234.56'), equals('1,234.56'));
      expect(CalculatorEvaluator.formatWithCommas('100000.5'), equals('100,000.5'));
    });

    test('13.3 formatExpression formats numbers with operators', () {
      expect(CalculatorEvaluator.formatExpression('100000+50000'), equals('100,000+50,000'));
      expect(CalculatorEvaluator.formatExpression('1000*20'), equals('1,000*20'));
    });

    test('13.4 evaluate evaluates expressions with comma-separated numbers', () {
      expect(CalculatorEvaluator.evaluate('100,000 + 50,000'), equals(150000.0));
      expect(CalculatorEvaluator.evaluate('1,000,000 / 2'), equals(500000.0));
      expect(CalculatorEvaluator.evaluate('25,000 * 4'), equals(100000.0));
    });

    test('13.5 formatResult formats double with comma separators', () {
      expect(CalculatorEvaluator.formatResult(1000000.0), equals('1,000,000'));
      expect(CalculatorEvaluator.formatResult(100000.0), equals('100,000'));
      expect(CalculatorEvaluator.formatResult(12500.5), equals('12,500.5'));
    });

    testWidgets('13.6 Typing numbers on CalculatorKeyboard automatically formats with commas', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(buildTestApp(child: CalculatorKeyboard(controller: controller)));
      await tester.pumpAndSettle();

      for (final digit in ['1', '0', '0', '0', '0', '0']) {
        await tester.tap(find.text(digit).first);
        await tester.pumpAndSettle();
      }

      expect(controller.text, equals('100,000'));

      // Now tap '+' and '5', '0', '0', '0', '0'
      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();
      for (final digit in ['5', '0', '0', '0', '0']) {
        await tester.tap(find.text(digit).first);
        await tester.pumpAndSettle();
      }

      expect(controller.text, equals('100,000+50,000'));
      expect(find.text('= 150,000'), findsOneWidget);
    });

    testWidgets('13.7 Backspacing on formatted number updates commas correctly', (tester) async {
      final controller = TextEditingController(text: '100,000');
      await tester.pumpWidget(buildTestApp(child: CalculatorKeyboard(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('⌫'));
      await tester.pumpAndSettle();

      expect(controller.text, equals('10,000'));
    });
  });
}

