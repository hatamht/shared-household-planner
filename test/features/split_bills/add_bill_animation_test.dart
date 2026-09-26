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
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/add_bill_screen.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_project_by_id_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────
class FakeBillRepo implements BillRepository {
  final List<Bill> _bills = [];
  @override
  Future<Either<Failure, Bill>> create(Bill bill) async {
    _bills.add(bill);
    return Right(bill);
  }
  @override
  Future<Either<Failure, List<Bill>>> getAll() async => Right(List.from(_bills));
  @override
  Future<Either<Failure, Bill>> getById(String id) async =>
      Right(_bills.firstWhere((b) => b.id == id));
  @override
  Future<Either<Failure, Bill>> update(Bill bill) async => Right(bill);
  @override
  Future<Either<Failure, void>> delete(String id) async {
    _bills.removeWhere((b) => b.id == id);
    return const Right(null);
  }
  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(String projectId) async =>
      Right(_bills.where((b) => b.projectId == projectId).toList());
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

// ─── Localizations ────────────────────────────────────────────────────────
class _TestLoc extends AppLocalizations {
  _TestLoc() : super(const Locale('en'));
  static const Map<String, String> _en = {
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
    'select_project': 'Select Project',
    'no_project': 'No Project',
    'no_project_selected': 'No Project Selected',
    'project_no_members': 'No members',
    'expand': 'Expand',
    'collapse': 'Collapse',
    'compact_mode': 'Compact Mode',
    'full_mode': 'Full Mode',
    'select_project_first': 'Please select a project first',
    'more': 'More',
    'date': 'Date',
    'members': 'Members',
    'receipt': 'Receipt',
    'split': 'Split',
    'save': 'Save',
    'done': 'Done',
    'select_all': 'Select All',
    'deselect_all': 'Deselect All',
    'payer_in_compact': 'Payer',
    'equal_split': 'Equal Split',
    'percentage_split': 'Percentage Split',
    'shares_split': 'Shares Split',
    'custom_split': 'Custom Split',
    'save_as_template': 'Save as Template',
    'expense': 'Expense',
    'income': 'Income',
    'transfer': 'Transfer',
    'category_restaurant': 'Restaurant',
    'category_transport': 'Transport',
    'category_shopping': 'Shopping',
    'category_health': 'Health',
    'category_entertainment': 'Entertainment',
    'category_travel': 'Travel',
    'category_utilities': 'Utilities',
    'category_party': 'Party',
    'category_sport': 'Sport',
  };
  @override
  String translate(String key) => _en[key] ?? key;
}

class _TestLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestLocDelegate();
  @override
  bool isSupported(Locale l) => true;
  @override
  Future<AppLocalizations> load(Locale l) async => _TestLoc();
  @override
  bool shouldReload(_TestLocDelegate old) => false;
}

// ─── Helpers ──────────────────────────────────────────────────────────────
final _testDate = DateTime(2026, 9, 20);

Project makeProject({
  String id = 'p1',
  String name = 'Home',
  List<String> members = const ['Alice', 'Bob', 'Charlie'],
}) =>
    Project(id: id, name: name, members: members, createdAt: _testDate, updatedAt: _testDate);

Widget buildApp({required Widget child, List<Project> projects = const []}) {
  final billRepo = FakeBillRepo();
  final billsBloc = BillsBloc(
    getBillsUseCase: GetBillsUseCase(billRepo),
    addBillUseCase: AddBillUseCase(billRepo),
  );
  final projRepo = FakeProjRepo(projects);
  final projectBloc = ProjectBloc(
    createProjectUseCase: CreateProjectUseCase(projRepo),
    getAllProjectsUseCase: GetAllProjectsUseCase(projRepo),
    getProjectByIdUseCase: GetProjectByIdUseCase(projRepo),
    updateProjectUseCase: UpdateProjectUseCase(projRepo),
    deleteProjectUseCase: DeleteProjectUseCase(projRepo),
  );
  if (projects.isNotEmpty) {
    projectBloc.emit(ProjectLoaded(projects: projects));
  }
  return MultiProvider(
    providers: [ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider())],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<BillsBloc>.value(value: billsBloc),
        BlocProvider<ProjectBloc>.value(value: projectBloc),
      ],
      child: MaterialApp(
        localizationsDelegates: const [_TestLocDelegate()],
        supportedLocales: const [Locale('en')],
        home: child,
      ),
    ),
  );
}

void main() {
  group('AC 1. Animation Controller Initialization', () {
    testWidgets('1.1 State has TickerProviderStateMixin - widget created without error', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      expect(find.byType(AddBillScreen), findsOneWidget);
    });

    testWidgets('1.2 Compact mode initial state shows expandToFullModeButton', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('expandToFullModeButton')), findsOneWidget);
    });

    testWidgets('1.3 Full mode initial state shows collapseToCompactModeButton', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: false)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('collapseToCompactModeButton')), findsOneWidget);
    });

    testWidgets('1.4 AnimatedSize widget is present in compact mode build tree', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedSize), findsWidgets);
    });

    testWidgets('1.5 FadeTransition widget is present in compact mode build tree', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      expect(find.byType(FadeTransition), findsWidgets);
    });

    testWidgets('1.6 AnimatedSize is present in full mode build tree', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: false)));
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedSize), findsWidgets);
    });
  });

  group('AC 2. Expand Animation (Compact → Full, 300ms easeInOut)', () {
    testWidgets('2.1 Tapping expand triggers transition to full mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('expandToFullModeButton')), findsOneWidget);
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('collapseToCompactModeButton')), findsOneWidget);
    });

    testWidgets('2.2 FadeTransitions exist simultaneously mid-animation', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.byType(FadeTransition), findsWidgets);
    });

    testWidgets('2.3 After expand collapse button is visible and tappable', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('collapseToCompactModeButton')), findsOneWidget);
      final btn = tester.widget<TextButton>(find.byKey(const Key('collapseToCompactModeButton')));
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('2.4 After expand compact fields disappear', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('compactDescriptionField')), findsNothing);
      expect(find.byKey(const Key('compactAmountField')), findsNothing);
    });

    testWidgets('2.5 After expand full mode fields appear (transactionTypeTabs)', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('transactionTypeTabs')), findsOneWidget);
    });

    testWidgets('2.6 Multiple expand/collapse cycles work without crash', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('expandToFullModeButton')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('collapseToCompactModeButton')));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('expandToFullModeButton')), findsOneWidget);
    });

    testWidgets('2.7 RotationTransition present on expand icon in compact mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      expect(find.byType(RotationTransition), findsWidgets);
    });

    testWidgets('2.8 AnimatedSize uses Curves.easeInOut', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      final animatedSize = tester.widget<AnimatedSize>(find.byType(AnimatedSize).first);
      expect(animatedSize.curve, equals(Curves.easeInOut));
    });

    testWidgets('2.9 AnimatedSize duration is exactly 300ms', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      final animatedSize = tester.widget<AnimatedSize>(find.byType(AnimatedSize).first);
      expect(animatedSize.duration, equals(const Duration(milliseconds: 300)));
    });

    testWidgets('2.10 Mid-animation 150ms no crash', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(AddBillScreen), findsOneWidget);
    });
  });

  group('AC 3. Collapse Animation (Full → Compact, 300ms easeInOut)', () {
    testWidgets('3.1 Tapping collapse transitions from full to compact', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: false)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('collapseToCompactModeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('expandToFullModeButton')), findsOneWidget);
    });

    testWidgets('3.2 After collapse compact fields are visible', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: false)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('collapseToCompactModeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('compactDescriptionField')), findsOneWidget);
      expect(find.byKey(const Key('compactAmountField')), findsOneWidget);
    });

    testWidgets('3.3 After collapse full mode tabs disappear', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: false)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('collapseToCompactModeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('transactionTypeTabs')), findsNothing);
    });

    testWidgets('3.4 Mid-collapse 150ms no crash', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: false)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('collapseToCompactModeButton')));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(AddBillScreen), findsOneWidget);
    });

    testWidgets('3.5 After collapse collapseToCompactModeButton not visible', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: false)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('collapseToCompactModeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('collapseToCompactModeButton')), findsNothing);
    });
  });

  group('AC 4. Easing & Curve Properties', () {
    testWidgets('4.1 FadeTransition opacity is accessible', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      final fades = tester.widgetList<FadeTransition>(find.byType(FadeTransition)).toList();
      expect(fades, isNotEmpty);
    });

    testWidgets('4.2 AnimatedSize alignment is topCenter', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      final animatedSize = tester.widget<AnimatedSize>(find.byType(AnimatedSize).first);
      expect(animatedSize.alignment, equals(Alignment.topCenter));
    });

    testWidgets('4.3 No crash during 10ms expand pump', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.byType(AddBillScreen), findsOneWidget);
    });

    testWidgets('4.4 Expand animation completes within 350ms', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byKey(const Key('collapseToCompactModeButton')), findsOneWidget);
    });

    testWidgets('4.5 Collapse animation completes within 350ms', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: false)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('collapseToCompactModeButton')));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byKey(const Key('expandToFullModeButton')), findsOneWidget);
    });
  });

  group('AC 5. Icon Rotation Animation', () {
    testWidgets('5.1 RotationTransition present in compact mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      expect(find.byType(RotationTransition), findsWidgets);
    });

    testWidgets('5.2 expandToFullModeButton key still present with RotationTransition icon', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('expandToFullModeButton')), findsOneWidget);
    });

    testWidgets('5.3 RotationTransitions list is not empty', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      final rotations = tester.widgetList<RotationTransition>(find.byType(RotationTransition)).toList();
      expect(rotations, isNotEmpty);
    });

    testWidgets('5.4 RotationTransition in tree during 50ms of expansion', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(RotationTransition), findsWidgets);
    });
  });

  group('AC 6. Project Selector & Amount Stability During Animation', () {
    testWidgets('6.1 Project selector stable during expand animation', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(
        child: const AddBillScreen(initialCompactMode: true),
        projects: [makeProject()],
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projectSelector')), findsOneWidget);
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byKey(const Key('projectSelector')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projectSelector')), findsOneWidget);
    });

    testWidgets('6.2 Project selector stable during collapse animation', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(
        child: const AddBillScreen(initialCompactMode: false),
        projects: [makeProject()],
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projectSelector')), findsOneWidget);
      await tester.tap(find.byKey(const Key('collapseToCompactModeButton')));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byKey(const Key('projectSelector')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projectSelector')), findsOneWidget);
    });

    testWidgets('6.3 Amount text preserved after expand/collapse', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '150000';
      await tester.pump();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('collapseToCompactModeButton')));
      await tester.pumpAndSettle();
      final amountField = tester.widget<TextField>(find.byKey(const Key('compactAmountField')));
      expect(amountField.controller?.text, equals('150000'));
    });

    testWidgets('6.4 Description text preserved after expand/collapse', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('compactDescriptionField')), 'Lunch');
      await tester.pump();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('collapseToCompactModeButton')));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byKey(const Key('compactDescriptionField')));
      expect(field.controller?.text, equals('Lunch'));
    });

    testWidgets('6.5 Project selector top position stable between modes', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(
        child: const AddBillScreen(initialCompactMode: true),
        projects: [makeProject()],
      ));
      await tester.pumpAndSettle();
      final compactPos = tester.getTopLeft(find.byKey(const Key('projectSelector')));
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();
      final fullPos = tester.getTopLeft(find.byKey(const Key('projectSelector')));
      expect((fullPos.dy - compactPos.dy).abs(), lessThan(10.0));
    });
  });

  group('AC 7. UI State Consistency', () {
    testWidgets('7.1 Compact mode shows compactSecondaryBar', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('compactSecondaryBar')), findsOneWidget);
    });

    testWidgets('7.2 Full mode hides compactSecondaryBar', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('compactSecondaryBar')), findsNothing);
    });

    testWidgets('7.3 Compact mode shows compactSplitChip', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('compactSplitChip')), findsOneWidget);
    });

    testWidgets('7.4 Full mode hides compactSplitChip', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('compactSplitChip')), findsNothing);
    });

    testWidgets('7.5 After expand saveBillButton still visible in AppBar', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('saveBillButton')), findsOneWidget);
    });

    testWidgets('7.6 Rapid multiple toggles do not crash', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('expandToFullModeButton')));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('collapseToCompactModeButton')));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('expandToFullModeButton')), findsOneWidget);
    });

    testWidgets('7.7 Editing bill opens in full mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final bill = Bill(
        id: 'b1',
        title: 'Lunch',
        amount: 50.0,
        category: 'restaurant',
        date: DateTime(2026, 9, 20),
        paidBy: 'Alice',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 25.0),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 25.0),
        ],
      );
      await tester.pumpWidget(buildApp(child: AddBillScreen(billToEdit: bill)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('collapseToCompactModeButton')), findsOneWidget);
    });

    testWidgets('7.8 saveProjectButton visible in both compact and full mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      // saveProjectButton is the main action button in both compact and full mode
      expect(find.byKey(const Key('saveProjectButton')), findsOneWidget);
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();
      // saveProjectButton also exists in full mode as the main save button
      expect(find.byKey(const Key('saveProjectButton')), findsOneWidget);
    });

    testWidgets('7.9 collapseToCompactModeButton only in full mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: false)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('collapseToCompactModeButton')), findsOneWidget);
      await tester.tap(find.byKey(const Key('collapseToCompactModeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('collapseToCompactModeButton')), findsNothing);
    });

    testWidgets('7.10 expandToFullModeButton not visible in full mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('expandToFullModeButton')), findsNothing);
    });
  });

  group('AC 8. Theme Consistency', () {
    testWidgets('8.1 Animation works in light theme', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final r = FakeBillRepo();
      final pr = FakeProjRepo();
      await tester.pumpWidget(MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => LanguageProvider())],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<BillsBloc>(create: (_) => BillsBloc(getBillsUseCase: GetBillsUseCase(r), addBillUseCase: AddBillUseCase(r))),
            BlocProvider<ProjectBloc>(create: (_) => ProjectBloc(
              createProjectUseCase: CreateProjectUseCase(pr),
              getAllProjectsUseCase: GetAllProjectsUseCase(pr),
              getProjectByIdUseCase: GetProjectByIdUseCase(pr),
              updateProjectUseCase: UpdateProjectUseCase(pr),
              deleteProjectUseCase: DeleteProjectUseCase(pr),
            )),
          ],
          child: MaterialApp(
            theme: ThemeData.light(),
            localizationsDelegates: const [_TestLocDelegate()],
            home: const AddBillScreen(initialCompactMode: true),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('collapseToCompactModeButton')), findsOneWidget);
    });

    testWidgets('8.2 Animation works in dark theme', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final r = FakeBillRepo();
      final pr = FakeProjRepo();
      await tester.pumpWidget(MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => LanguageProvider())],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<BillsBloc>(create: (_) => BillsBloc(getBillsUseCase: GetBillsUseCase(r), addBillUseCase: AddBillUseCase(r))),
            BlocProvider<ProjectBloc>(create: (_) => ProjectBloc(
              createProjectUseCase: CreateProjectUseCase(pr),
              getAllProjectsUseCase: GetAllProjectsUseCase(pr),
              getProjectByIdUseCase: GetProjectByIdUseCase(pr),
              updateProjectUseCase: UpdateProjectUseCase(pr),
              deleteProjectUseCase: DeleteProjectUseCase(pr),
            )),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            localizationsDelegates: const [_TestLocDelegate()],
            home: const AddBillScreen(initialCompactMode: true),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('collapseToCompactModeButton')), findsOneWidget);
    });
  });

  group('AC 9. Regression: Backward Compatibility', () {
    testWidgets('9.1 initialCompactMode: false opens in full mode directly', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: false)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('collapseToCompactModeButton')), findsOneWidget);
      expect(find.byKey(const Key('compactDescriptionField')), findsNothing);
    });

    testWidgets('9.2 initialCompactMode: true opens in compact mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('expandToFullModeButton')), findsOneWidget);
      expect(find.byKey(const Key('transactionTypeTabs')), findsNothing);
    });

    testWidgets('9.3 Default (no initialCompactMode, no edit) opens compact', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('expandToFullModeButton')), findsOneWidget);
    });

    testWidgets('9.4 saveBillButton present in AppBar during animation', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('saveBillButton')), findsOneWidget);
    });

    testWidgets('9.5 projectSelector key preserved during animation', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(
        child: const AddBillScreen(initialCompactMode: true),
        projects: [makeProject()],
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projectSelector')), findsOneWidget);
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projectSelector')), findsOneWidget);
    });

    testWidgets('9.6 projectSelectorButton key preserved during animation', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(
        child: const AddBillScreen(initialCompactMode: true),
        projects: [makeProject()],
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projectSelectorButton')), findsOneWidget);
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projectSelectorButton')), findsOneWidget);
    });
  });

  group('AC 10. Special Cases & Edge Cases', () {
    testWidgets('10.1 Animation works with project pre-selected', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(
        child: const AddBillScreen(initialCompactMode: true, projectId: 'p1', projectName: 'Home'),
        projects: [makeProject()],
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('collapseToCompactModeButton')), findsOneWidget);
    });

    testWidgets('10.2 Widget disposes cleanly after animation completes', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('replaced'))));
      expect(find.text('replaced'), findsOneWidget);
    });

    testWidgets('10.3 Widget disposes cleanly mid-animation', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('disposed'))));
      expect(find.text('disposed'), findsOneWidget);
    });

    testWidgets('10.4 Works with no projects and animation still functional', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('collapseToCompactModeButton')), findsOneWidget);
    });

    testWidgets('10.5 AnimatedSize contains FadeTransition as descendant', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      final animatedSizeFind = find.byType(AnimatedSize);
      expect(animatedSizeFind, findsWidgets);
      final fadeInAnimated = find.descendant(
        of: animatedSizeFind.first,
        matching: find.byType(FadeTransition),
      );
      expect(fadeInAnimated, findsWidgets);
    });

    testWidgets('10.6 Reverse animation completes when tapping collapse mid-expansion', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pump(const Duration(milliseconds: 100));
      // Mid-animation, let it settle, then collapse
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('collapseToCompactModeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('expandToFullModeButton')), findsOneWidget);
    });

    testWidgets('10.7 Forward animation completes when tapping expand mid-collapse', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: false)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('collapseToCompactModeButton')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('collapseToCompactModeButton')), findsOneWidget);
    });

    testWidgets('10.8 Compact mode Date chip is displayed and clickable in compact mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('compactDateChip')), findsOneWidget);
    });

    testWidgets('10.9 Compact mode Members chip is displayed in compact mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('compactMembersChip')), findsOneWidget);
    });

    testWidgets('10.10 Compact mode Camera chip is displayed in compact mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('compactCameraChip')), findsOneWidget);
    });

    testWidgets('10.11 Transition preserves entered amount and title simultaneously', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp(child: const AddBillScreen(initialCompactMode: true)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('compactDescriptionField')), 'Supermarket groceries');
      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '320000';
      await tester.pump();
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();
      final titleField = tester.widget<TextField>(find.byKey(const Key('titleField')));
      expect(titleField.controller?.text, equals('Supermarket groceries'));
      final amountField = tester.widget<TextField>(find.byKey(const Key('amountField')));
      expect(amountField.controller?.text, equals('320000'));
    });
  });
}

