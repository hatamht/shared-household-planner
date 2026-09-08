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
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/add_bill_screen.dart';
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
  @override
  Future<Either<Failure, List<Project>>> getAll() async => const Right([]);
  @override
  Future<Either<Failure, Project>> create(Project project) async => Right(project);
  @override
  Future<Either<Failure, Project>> getById(String id) async =>
      Right(Project(id: id, name: 'P', members: const [], createdAt: DateTime.now(), updatedAt: DateTime.now()));
  @override
  Future<Either<Failure, Project>> update(Project project) async => Right(project);
  @override
  Future<Either<Failure, void>> delete(String id) async => const Right(null);
}

class DualLangAppLocalizations extends AppLocalizations {
  final Locale _locale;
  DualLangAppLocalizations(this._locale) : super(_locale);

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
    'add_category': 'Add Category',
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

  static const Map<String, String> _vi = {
    'add_bill': 'Thêm chi tiêu',
    'bill_name': 'Tên chi tiêu',
    'bill_name_example': 'vd: Bữa trưa',
    'amount': 'Số tiền',
    'category': 'Danh mục',
    'payer': 'Người trả',
    'payer_hint': 'Ai đã thanh toán?',
    'participants': 'Người tham gia',
    'save_bill': 'Lưu chi tiêu',
    'add_category': 'Thêm danh mục',
    'category_restaurant': 'Nhà hàng',
    'category_transport': 'Giao thông',
    'category_shopping': 'Mua sắm',
    'category_health': 'Sức khỏe',
    'category_entertainment': 'Giải trí',
    'category_travel': 'Du lịch',
    'category_utilities': 'Tiện ích',
    'category_education': 'Giáo dục',
    'category_party': 'Tiệc tùng',
    'category_office': 'Văn phòng',
    'category_pet': 'Thú cưng',
    'category_sport': 'Thể thao',
  };

  @override
  Locale get locale => _locale;

  @override
  String translate(String key) {
    if (_locale.languageCode == 'vi') {
      return _vi[key] ?? _en[key] ?? key;
    }
    return _en[key] ?? key;
  }
}

class DualLangDelegate extends LocalizationsDelegate<AppLocalizations> {
  final Locale locale;
  const DualLangDelegate(this.locale);
  @override
  bool isSupported(Locale l) => true;
  @override
  Future<AppLocalizations> load(Locale l) async => DualLangAppLocalizations(locale);
  @override
  bool shouldReload(DualLangDelegate old) => old.locale != locale;
}

Widget buildTestAddBillApp({
  Locale locale = const Locale('en'),
}) {
  final billRepo = FakeBillRepo();
  final billsBloc = BillsBloc(
    getBillsUseCase: GetBillsUseCase(billRepo),
    addBillUseCase: AddBillUseCase(billRepo),
  );
  final projectBloc = ProjectBloc(
    createProjectUseCase: CreateProjectUseCase(FakeProjRepo()),
    getAllProjectsUseCase: GetAllProjectsUseCase(FakeProjRepo()),
    updateProjectUseCase: UpdateProjectUseCase(FakeProjRepo()),
    deleteProjectUseCase: DeleteProjectUseCase(FakeProjRepo()),
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
        localizationsDelegates: [
          DualLangDelegate(locale),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('vi')],
        locale: locale,
        home: const AddBillScreen(),
      ),
    ),
  );
}

void main() {
  group('1. Auto-fill Title on Category Selection', () {
    testWidgets('Selecting Transport category auto-fills title with "Transport" (EN)', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestAddBillApp(locale: const Locale('en')));
      await tester.pumpAndSettle();

      // Tap Transport 🚕
      await tester.tap(find.byKey(const Key('category_icon_transport')));
      await tester.pumpAndSettle();

      // Title field is populated with "Transport"
      expect(find.widgetWithText(TextField, 'Transport'), findsOneWidget);
    });

    testWidgets('Selecting Restaurant category in Vietnamese auto-fills title with "Nhà hàng" (VI)', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestAddBillApp(locale: const Locale('vi')));
      await tester.pumpAndSettle();

      // Tap Restaurant 🍽️
      await tester.tap(find.byKey(const Key('category_icon_restaurant')));
      await tester.pumpAndSettle();

      // Title field is populated with "Nhà hàng"
      expect(find.widgetWithText(TextField, 'Nhà hàng'), findsOneWidget);
    });

    testWidgets('Selecting Shopping category in Vietnamese auto-fills title with "Mua sắm"', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestAddBillApp(locale: const Locale('vi')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('category_icon_shopping')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Mua sắm'), findsOneWidget);
    });
  });

  group('2. Real-time Title Updates on Category Change', () {
    testWidgets('Title updates dynamically when changing category before manual edit', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestAddBillApp());
      await tester.pumpAndSettle();

      // Tap Transport -> Title = Transport
      await tester.tap(find.byKey(const Key('category_icon_transport')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Transport'), findsOneWidget);

      // Tap Shopping -> Title updates to Shopping
      await tester.tap(find.byKey(const Key('category_icon_shopping')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Shopping'), findsOneWidget);

      // Tap Health -> Title updates to Health
      await tester.tap(find.byKey(const Key('category_icon_health')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Health'), findsOneWidget);
    });

    testWidgets('Rapid multiple category selections always reflect the latest category', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestAddBillApp());
      await tester.pumpAndSettle();

      // Rapid taps
      await tester.tap(find.byKey(const Key('category_icon_transport')));
      await tester.tap(find.byKey(const Key('category_icon_shopping')));
      await tester.tap(find.byKey(const Key('category_icon_entertainment')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Entertainment'), findsOneWidget);
    });
  });

  group('3. Clear Button Visibility & Functionality', () {
    testWidgets('Clear button is hidden when title field is empty', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestAddBillApp());
      await tester.pumpAndSettle();

      // Initially empty
      expect(find.byKey(const Key('clearTitleButton')), findsNothing);
    });

    testWidgets('Clear button appears when title has text', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestAddBillApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('category_icon_transport')));
      await tester.pumpAndSettle();

      // Clear button visible
      expect(find.byKey(const Key('clearTitleButton')), findsOneWidget);
    });

    testWidgets('Tapping clear button empties title and keeps focus', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestAddBillApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('category_icon_transport')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Transport'), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byKey(const Key('clearTitleButton')));
      await tester.pumpAndSettle();

      // Field is empty
      final titleField = tester.widget<TextField>(find.byKey(const Key('titleField')));
      expect(titleField.controller?.text, isEmpty);

      // Clear button is hidden now
      expect(find.byKey(const Key('clearTitleButton')), findsNothing);

      // Category remains selected (badge still shows 🚕)
      expect(find.descendant(
        of: find.byKey(const Key('selectedCategoryIconBadge')),
        matching: find.text('🚕'),
      ), findsOneWidget);
    });
  });

  group('4. User Override & Editing Behavior', () {
    testWidgets('User manual edit overrides category auto-fill', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestAddBillApp());
      await tester.pumpAndSettle();

      // Auto-fill Restaurant
      await tester.tap(find.byKey(const Key('category_icon_restaurant')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Restaurant'), findsOneWidget);

      // User manually edits title to "Restaurant with Alex"
      await tester.enterText(find.byKey(const Key('titleField')), 'Restaurant with Alex');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Restaurant with Alex'), findsOneWidget);

      // Now change category to Transport
      await tester.tap(find.byKey(const Key('category_icon_transport')));
      await tester.pumpAndSettle();

      // Title should RETAIN user override "Restaurant with Alex"
      expect(find.widgetWithText(TextField, 'Restaurant with Alex'), findsOneWidget);

      // But category badge updates to 🚕
      expect(find.descendant(
        of: find.byKey(const Key('selectedCategoryIconBadge')),
        matching: find.text('🚕'),
      ), findsOneWidget);
    });

    testWidgets('Clearing title allows auto-fill again on next category selection', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestAddBillApp());
      await tester.pumpAndSettle();

      // Custom title
      await tester.enterText(find.byKey(const Key('titleField')), 'Custom Coffee');
      await tester.pumpAndSettle();

      // Clear with clear button
      await tester.tap(find.byKey(const Key('clearTitleButton')));
      await tester.pumpAndSettle();

      // Now select category Health -> Auto-fills "Health"
      await tester.tap(find.byKey(const Key('category_icon_health')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Health'), findsOneWidget);
    });
  });
}
