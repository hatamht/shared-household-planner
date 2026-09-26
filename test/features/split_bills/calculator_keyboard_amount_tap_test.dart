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

class _TestLoc extends AppLocalizations {
  final String code;
  _TestLoc(this.code) : super(Locale(code));

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
    'bill_name': 'Bill Name',
    'bill_name_hint': 'What is this bill for?',
    'payer': 'Payer',
    'payer_hint': 'Who paid?',
  };

  @override
  String translate(String key) => _en[key] ?? key;
}

class _TestLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestLocDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => _TestLoc('en');
  @override
  bool shouldReload(_TestLocDelegate old) => false;
}

Widget buildTestApp({
  required Widget child,
  FakeBillRepo? billRepo,
  FakeProjRepo? projRepo,
}) {
  final bRepo = billRepo ?? FakeBillRepo();
  final pRepo = projRepo ??
      FakeProjRepo([
        Project(
          id: 'proj-1',
          name: 'Home',
          members: const ['Alice', 'Bob'],
          currency: 'VND',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>(
        create: (_) => LanguageProvider(),
      ),
      BlocProvider<ProjectBloc>(
        create: (_) => ProjectBloc(
          getAllProjectsUseCase: GetAllProjectsUseCase(pRepo),
          getProjectByIdUseCase: GetProjectByIdUseCase(pRepo),
          createProjectUseCase: CreateProjectUseCase(pRepo),
          updateProjectUseCase: UpdateProjectUseCase(pRepo),
          deleteProjectUseCase: DeleteProjectUseCase(pRepo),
        ),
      ),
      BlocProvider<BillsBloc>(
        create: (_) => BillsBloc(
          getBillsUseCase: GetBillsUseCase(bRepo),
          addBillUseCase: AddBillUseCase(bRepo),
        ),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        _TestLocDelegate(),
      ],
      home: Builder(
        builder: (ctx) => child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shared-62: Direct Custom Calculator Keyboard on Amount Input', () {
    testWidgets('1. Compact mode: compactAmountField has readOnly=true and showCursor=true', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(initialCompactMode: true),
      ));
      await tester.pumpAndSettle();

      final amountFieldFinder = find.byKey(const Key('compactAmountField'));
      expect(amountFieldFinder, findsOneWidget);

      final textField = tester.widget<TextField>(amountFieldFinder);
      expect(textField.readOnly, isTrue, reason: 'Must be readOnly to suppress OS virtual keyboard');
      expect(textField.showCursor, isTrue, reason: 'Must show blinking cursor');
    });

    testWidgets('2. Compact mode: Tapping compactAmountField opens CalculatorKeyboard directly', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(initialCompactMode: true),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorKeyboard), findsNothing);

      await tester.tap(find.byKey(const Key('compactAmountField')));
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorKeyboard), findsOneWidget);
    });

    testWidgets('3. Compact mode: Tapping compactAmountContainer opens CalculatorKeyboard', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(initialCompactMode: true),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('compactAmountContainer')), findsOneWidget);
      expect(find.byType(CalculatorKeyboard), findsNothing);

      await tester.tap(find.byKey(const Key('compactAmountContainer')));
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorKeyboard), findsOneWidget);
    });

    testWidgets('4. Compact mode: Tapping compactDescriptionField closes CalculatorKeyboard', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(initialCompactMode: true),
      ));
      await tester.pumpAndSettle();

      // Open calculator
      await tester.tap(find.byKey(const Key('compactAmountContainer')));
      await tester.pumpAndSettle();
      expect(find.byType(CalculatorKeyboard), findsOneWidget);

      // Tap description field
      await tester.tap(find.byKey(const Key('compactDescriptionField')));
      await tester.pumpAndSettle();
      expect(find.byType(CalculatorKeyboard), findsNothing);
    });

    testWidgets('5. Full mode: amountField & fullAmountField have readOnly=true and showCursor=true', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(initialCompactMode: false),
      ));
      await tester.pumpAndSettle();

      final fullFieldFinder = find.byKey(const Key('fullAmountField'));
      expect(fullFieldFinder, findsOneWidget);

      final amountFieldFinder = find.byKey(const Key('amountField'));
      expect(amountFieldFinder, findsOneWidget);

      final textField = tester.widget<TextField>(amountFieldFinder);
      expect(textField.readOnly, isTrue, reason: 'Full mode must be readOnly');
      expect(textField.showCursor, isTrue, reason: 'Full mode must show cursor');
    });

    testWidgets('6. Full mode: Tapping amountField opens CalculatorKeyboard directly', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(initialCompactMode: false),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorKeyboard), findsNothing);

      await tester.tap(find.byKey(const Key('amountField')));
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorKeyboard), findsOneWidget);
    });

    testWidgets('7. Full mode: Tapping fullAmountContainer opens CalculatorKeyboard', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(initialCompactMode: false),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fullAmountContainer')), findsOneWidget);
      expect(find.byType(CalculatorKeyboard), findsNothing);

      await tester.tap(find.byKey(const Key('fullAmountContainer')));
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorKeyboard), findsOneWidget);
    });

    testWidgets('8. Full mode: Tapping titleField closes CalculatorKeyboard', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(initialCompactMode: false),
      ));
      await tester.pumpAndSettle();

      // Open calculator
      await tester.tap(find.byKey(const Key('fullAmountContainer')));
      await tester.pumpAndSettle();
      expect(find.byType(CalculatorKeyboard), findsOneWidget);

      // Tap title field
      await tester.tap(find.byKey(const Key('titleField')));
      await tester.pumpAndSettle();
      expect(find.byType(CalculatorKeyboard), findsNothing);
    });

    testWidgets('9. Full mode: Tapping payerField closes CalculatorKeyboard', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(initialCompactMode: false),
      ));
      await tester.pumpAndSettle();

      // Open calculator
      await tester.tap(find.byKey(const Key('fullAmountContainer')));
      await tester.pumpAndSettle();
      expect(find.byType(CalculatorKeyboard), findsOneWidget);

      // Tap payer field
      await tester.tap(find.byKey(const Key('payerField')));
      await tester.pumpAndSettle();
      expect(find.byType(CalculatorKeyboard), findsNothing);
    });

    testWidgets('10. Toggle calculator buttons work in both modes', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Compact mode
      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(initialCompactMode: true),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorKeyboard), findsNothing);
      await tester.tap(find.byKey(const Key('toggleCalculatorButton')));
      await tester.pumpAndSettle();
      expect(find.byType(CalculatorKeyboard), findsOneWidget);

      await tester.tap(find.byKey(const Key('toggleCalculatorButton')));
      await tester.pumpAndSettle();
      expect(find.byType(CalculatorKeyboard), findsNothing);
    });

    testWidgets('11. Full mode toggle button toggles calculator keyboard', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(initialCompactMode: false),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorKeyboard), findsNothing);
      await tester.tap(find.byKey(const Key('fullToggleCalculatorButton')));
      await tester.pumpAndSettle();
      expect(find.byType(CalculatorKeyboard), findsOneWidget);

      await tester.tap(find.byKey(const Key('fullToggleCalculatorButton')));
      await tester.pumpAndSettle();
      expect(find.byType(CalculatorKeyboard), findsNothing);
    });

    testWidgets('12. Arithmetic input and calculation works with custom keypad buttons', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(initialCompactMode: true),
      ));
      await tester.pumpAndSettle();

      // Open calculator via amount container tap
      await tester.tap(find.byKey(const Key('compactAmountContainer')));
      await tester.pumpAndSettle();

      // Tap 5, *, 2, 0
      await tester.tap(find.byKey(const Key('calc_key_5')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('calc_key_multiply')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('calc_key_2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('calc_key_0')));
      await tester.pump();

      // Expect preview '= 100' both in compactAmountCalcPreview and on calculator keyboard
      final previewWidget = tester.widget<Text>(find.byKey(const Key('compactAmountCalcPreview')));
      expect(previewWidget.data, equals('= 100'));

      // Tap '=' evaluates to '100'
      await tester.tap(find.byKey(const Key('calc_key_equals')));
      await tester.pump();

      final amountField = tester.widget<TextField>(find.byKey(const Key('compactAmountField')));
      expect(amountField.controller!.text, equals('100'));
    });

    testWidgets('13. Compact mode: Tapping Done key evaluates and hides CalculatorKeyboard', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(initialCompactMode: true),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactAmountContainer')));
      await tester.pumpAndSettle();
      expect(find.byType(CalculatorKeyboard), findsOneWidget);

      await tester.tap(find.byKey(const Key('calc_key_5')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('calc_key_multiply')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('calc_key_6')));
      await tester.pump();

      // Tap Done
      await tester.tap(find.byKey(const Key('calc_key_done')));
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorKeyboard), findsNothing);
      final amountField = tester.widget<TextField>(find.byKey(const Key('compactAmountField')));
      expect(amountField.controller!.text, equals('30'));
    });

    testWidgets('14. Full mode: Tapping Done key evaluates and hides CalculatorKeyboard', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(initialCompactMode: false),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fullAmountContainer')));
      await tester.pumpAndSettle();
      expect(find.byType(CalculatorKeyboard), findsOneWidget);

      await tester.tap(find.byKey(const Key('calc_key_2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('calc_key_0')));
      await tester.pump();

      // Tap Done
      await tester.tap(find.byKey(const Key('calc_key_done')));
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorKeyboard), findsNothing);
      final amountField = tester.widget<TextField>(find.byKey(const Key('amountField')));
      expect(amountField.controller!.text, equals('20'));
    });
  });
}
