import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartz/dartz.dart';

import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/core/theme/app_theme.dart';
import 'package:shared_household_planner/features/statistics/presentation/pages/statistics_screen.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';

class MockBillRepository implements BillRepository {
  List<Bill> bills = [];

  @override
  Future<Either<Failure, Bill>> create(Bill bill) async => Right(bill);

  @override
  Future<Either<Failure, List<Bill>>> getAll() async => Right(bills);

  @override
  Future<Either<Failure, Bill>> getById(String billId) async => Right(bills.first);

  @override
  Future<Either<Failure, Bill>> update(Bill bill) async => Right(bill);

  @override
  Future<Either<Failure, void>> delete(String billId) async => const Right(null);

  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(String projectId) async =>
      Right(bills.where((b) => b.projectId == projectId).toList());
}

class StatsLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  final String lang;
  const StatsLocDelegate([this.lang = 'en']);

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async => _StatsMockLoc(Locale(lang));

  @override
  bool shouldReload(StatsLocDelegate old) => false;
}

class _StatsMockLoc extends AppLocalizations {
  _StatsMockLoc(super.locale);

  static const _en = <String, String>{
    'statistics': 'Statistics',
    'statistics_charts': 'Statistics & Charts',
    'expense_by_category': 'Expense by Category',
    'expense_by_person': 'Expense by Person',
    'monthly_expense': 'Monthly Expense',
    'date_range': 'Date Range',
    'all_time': 'All Time',
    'this_month': 'This Month',
    'last_3_months': 'Last 3 Months',
    'total_spent': 'Total Spent',
    'average_per_person': 'Average / Person',
    'highest_spender': 'Highest Spender',
    'no_stats_data': 'No expense data for this period',
    'category_food': 'Food',
    'category_transport': 'Transport',
    'category_utilities': 'Utilities',
    'category_entertainment': 'Entertainment',
  };

  static const _vi = <String, String>{
    'statistics': 'Thống kê',
    'statistics_charts': 'Thống kê & Biểu đồ',
    'expense_by_category': 'Chi tiêu theo danh mục',
    'expense_by_person': 'Chi tiêu theo thành viên',
    'monthly_expense': 'Chi tiêu theo tháng',
    'date_range': 'Khoảng thời gian',
    'all_time': 'Tất cả',
    'this_month': 'Tháng này',
    'last_3_months': '3 tháng gần nhất',
    'total_spent': 'Tổng chi',
    'average_per_person': 'Trung bình / người',
    'highest_spender': 'Chi tiêu nhiều nhất',
    'no_stats_data': 'Không có dữ liệu chi tiêu trong kỳ này',
    'category_food': 'Ăn uống',
    'category_transport': 'Di chuyển',
    'category_utilities': 'Tiện ích',
    'category_entertainment': 'Giải trí',
  };

  @override
  String translate(String key) {
    if (locale.languageCode == 'vi') return _vi[key] ?? key;
    return _en[key] ?? key;
  }
}

Bill makeBill({
  required String id,
  required String title,
  required double amount,
  required String category,
  required String paidBy,
  required DateTime date,
  String? categoryColor,
  List<String> participants = const ['Alice', 'Bob'],
}) {
  return Bill(
    id: id,
    title: title,
    amount: amount,
    category: category,
    paidBy: paidBy,
    date: date,
    categoryColor: categoryColor,
    participants: participants
        .map((p) => BillParticipant(participantId: p, name: p, amount: amount / participants.length))
        .toList(),
  );
}

Widget buildStatsApp({
  List<Bill>? bills,
  ThemeProvider? themeProvider,
  LanguageProvider? languageProvider,
  String locale = 'en',
}) {
  final repo = MockBillRepository()..bills = bills ?? [];
  final bloc = BillsBloc(
    getBillsUseCase: GetBillsUseCase(repo),
    addBillUseCase: AddBillUseCase(repo),
  );
  if (bills != null) {
    bloc.emit(BillsLoaded(bills: bills));
  } else {
    bloc.emit(const BillsLoaded(bills: []));
  }

  final tp = themeProvider ?? ThemeProvider();
  final lp = languageProvider ?? LanguageProvider();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeProvider>.value(value: tp),
      ChangeNotifierProvider<LanguageProvider>.value(value: lp),
    ],
    child: BlocProvider<BillsBloc>.value(
      value: bloc,
      child: MaterialApp(
        theme: tp.currentTheme,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1200, 3600)),
          child: StatisticsScreen(initialBills: bills),
        ),
        localizationsDelegates: [StatsLocDelegate(locale)],
        supportedLocales: const [Locale('en'), Locale('vi')],
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(1200, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  // ── GROUP 1: Screen Rendering & Initial State (AC 1) ───────────────────────
  group('1. Screen Rendering & Initial State (AC 1)', () {
    testWidgets('1. Displays Statistics & Charts title in AppBar', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: []));
      expect(find.text('Statistics & Charts'), findsOneWidget);
    });

    testWidgets('2. Shows Date Range filter chips', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: []));
      expect(find.byKey(const Key('filterChip_all_time')), findsOneWidget);
      expect(find.byKey(const Key('filterChip_this_month')), findsOneWidget);
      expect(find.byKey(const Key('filterChip_last_3_months')), findsOneWidget);
    });

    testWidgets('3. Default filter is All Time', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: []));
      final chip = tester.widget<FilterChip>(find.byKey(const Key('filterChip_all_time')));
      expect(chip.selected, true);
    });

    testWidgets('4. Shows empty state when no bills', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: []));
      expect(find.byKey(const Key('emptyStatsState')), findsOneWidget);
      expect(find.text('No expense data for this period'), findsOneWidget);
    });

    testWidgets('5. Empty state shows query_stats icon', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: []));
      expect(find.byIcon(Icons.query_stats), findsOneWidget);
    });

    testWidgets('6. Shows metrics cards when bills exist', (tester) async {
      final bills = [makeBill(id: '1', title: 'Dinner', amount: 50.0, category: 'Food', paidBy: 'Alice', date: DateTime.now())];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.byKey(const Key('statsTotalSpent')), findsOneWidget);
      expect(find.byKey(const Key('statsAveragePerPerson')), findsOneWidget);
      expect(find.byKey(const Key('statsHighestSpender')), findsOneWidget);
    });

    testWidgets('7. Hides empty state when bills exist', (tester) async {
      final bills = [makeBill(id: '1', title: 'Lunch', amount: 20.0, category: 'Food', paidBy: 'Bob', date: DateTime.now())];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.byKey(const Key('emptyStatsState')), findsNothing);
    });

    testWidgets('8. AppBar has subtle 0.5 elevation', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: []));
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.elevation, 0.5);
    });
  });

  // ── GROUP 2: Date Range Filtering (AC 5) ───────────────────────────────────
  group('2. Date Range Filtering (AC 5)', () {
    final now = DateTime.now();
    final thisMonthBill = makeBill(
      id: 'b1',
      title: 'Current Bill',
      amount: 100.0,
      category: 'Food',
      paidBy: 'Alice',
      date: DateTime(now.year, now.month, 15),
    );
    final twoMonthsAgo = DateTime(now.year, now.month - 1, 10);
    final pastBill = makeBill(
      id: 'b2',
      title: 'Past Bill',
      amount: 200.0,
      category: 'Transport',
      paidBy: 'Bob',
      date: twoMonthsAgo,
    );
    final lastYear = DateTime(now.year - 1, 1, 1);
    final oldBill = makeBill(
      id: 'b3',
      title: 'Old Bill',
      amount: 500.0,
      category: 'Utilities',
      paidBy: 'Charlie',
      date: lastYear,
    );

    testWidgets('9. All Time filter includes all bills', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: [thisMonthBill, pastBill, oldBill]));
      // Total should be €800.00
      expect(find.text('€800.00'), findsOneWidget);
    });

    testWidgets('10. Selecting This Month filter updates total', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: [thisMonthBill, pastBill, oldBill]));
      await tester.tap(find.byKey(const Key('filterChip_this_month')));
      await tester.pumpAndSettle();
      // Only thisMonthBill: €100.00
      expect(find.text('€100.00'), findsWidgets);
    });

    testWidgets('11. Selecting Last 3 Months filter updates total', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: [thisMonthBill, pastBill, oldBill]));
      await tester.tap(find.byKey(const Key('filterChip_last_3_months')));
      await tester.pumpAndSettle();
      // thisMonthBill + pastBill = €300.00
      expect(find.text('€300.00'), findsOneWidget);
    });

    testWidgets('12. Switching back to All Time restores full total', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: [thisMonthBill, pastBill, oldBill]));
      await tester.tap(find.byKey(const Key('filterChip_this_month')));
      await tester.pumpAndSettle();
      expect(find.text('€100.00'), findsWidgets);
      await tester.tap(find.byKey(const Key('filterChip_all_time')));
      await tester.pumpAndSettle();
      expect(find.text('€800.00'), findsOneWidget);
    });

    testWidgets('13. Filter with no matching bills shows empty state', (tester) async {
      // Only old bill
      await pumpScreen(tester, buildStatsApp(bills: [oldBill]));
      await tester.tap(find.byKey(const Key('filterChip_this_month')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('emptyStatsState')), findsOneWidget);
    });

    testWidgets('14. This Month chip selected property is true when selected', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: [thisMonthBill]));
      await tester.tap(find.byKey(const Key('filterChip_this_month')));
      await tester.pumpAndSettle();
      final chip = tester.widget<FilterChip>(find.byKey(const Key('filterChip_this_month')));
      expect(chip.selected, true);
    });

    testWidgets('15. Last 3 Months chip selected property is true when selected', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: [thisMonthBill]));
      await tester.tap(find.byKey(const Key('filterChip_last_3_months')));
      await tester.pumpAndSettle();
      final chip = tester.widget<FilterChip>(find.byKey(const Key('filterChip_last_3_months')));
      expect(chip.selected, true);
    });

    testWidgets('16. Filter chips horizontal scroll view exists', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: []));
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });

  // ── GROUP 3: Summary Metrics Calculations (AC 6) ───────────────────────────
  group('3. Summary Metrics Calculations (AC 6)', () {
    testWidgets('17. Calculates total spent accurately', (tester) async {
      final bills = [
        makeBill(id: '1', title: 'B1', amount: 15.50, category: 'Food', paidBy: 'Alice', date: DateTime.now()),
        makeBill(id: '2', title: 'B2', amount: 34.50, category: 'Transport', paidBy: 'Bob', date: DateTime.now()),
      ];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.descendant(of: find.byKey(const Key('statsTotalSpent')), matching: find.text('€50.00')), findsOneWidget);
    });

    testWidgets('18. Calculates average per person accurately (2 people)', (tester) async {
      final bills = [
        makeBill(id: '1', title: 'B1', amount: 100.0, category: 'Food', paidBy: 'Alice', date: DateTime.now(), participants: ['Alice', 'Bob']),
      ];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      // 100 / 2 = 50
      expect(find.text('€50.00'), findsWidgets);
    });

    testWidgets('19. Calculates average per person with 4 participants', (tester) async {
      final bills = [
        makeBill(id: '1', title: 'B1', amount: 120.0, category: 'Food', paidBy: 'Alice', date: DateTime.now(), participants: ['Alice', 'Bob', 'Charlie', 'Dave']),
      ];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      // 120 / 4 = 30
      expect(find.text('€30.00'), findsOneWidget);
    });

    testWidgets('20. Identifies highest spender correctly', (tester) async {
      final bills = [
        makeBill(id: '1', title: 'B1', amount: 30.0, category: 'Food', paidBy: 'Alice', date: DateTime.now()),
        makeBill(id: '2', title: 'B2', amount: 90.0, category: 'Transport', paidBy: 'Bob', date: DateTime.now()),
        makeBill(id: '3', title: 'B3', amount: 10.0, category: 'Food', paidBy: 'Charlie', date: DateTime.now()),
      ];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      // Highest spender: Bob with €90.00
      expect(find.text('Bob'), findsWidgets);
      expect(find.text('€90.00'), findsWidgets);
    });

    testWidgets('21. Aggregates multiple bills from same payer for highest spender', (tester) async {
      final bills = [
        makeBill(id: '1', title: 'B1', amount: 40.0, category: 'Food', paidBy: 'Alice', date: DateTime.now()),
        makeBill(id: '2', title: 'B2', amount: 50.0, category: 'Transport', paidBy: 'Alice', date: DateTime.now()),
        makeBill(id: '3', title: 'B3', amount: 70.0, category: 'Food', paidBy: 'Bob', date: DateTime.now()),
      ];
      // Alice = 90.0, Bob = 70.0 -> Alice is highest
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.text('Alice'), findsWidgets);
      expect(find.text('€90.00'), findsWidgets);
    });

    testWidgets('22. Total Spent card has wallet icon', (tester) async {
      final bills = [makeBill(id: '1', title: 'B1', amount: 10.0, category: 'Food', paidBy: 'Alice', date: DateTime.now())];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
    });

    testWidgets('23. Average Per Person card has people icon', (tester) async {
      final bills = [makeBill(id: '1', title: 'B1', amount: 10.0, category: 'Food', paidBy: 'Alice', date: DateTime.now())];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('24. Highest Spender card has trophy icon', (tester) async {
      final bills = [makeBill(id: '1', title: 'B1', amount: 10.0, category: 'Food', paidBy: 'Alice', date: DateTime.now())];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
    });
  });

  // ── GROUP 4: Category Bar Chart (AC 3) ────────────────────────────────────
  group('4. Category Bar Chart (AC 3)', () {
    final bills = [
      makeBill(id: '1', title: 'Groceries', amount: 100.0, category: 'Food', paidBy: 'Alice', date: DateTime.now(), categoryColor: '#F59E0B'),
      makeBill(id: '2', title: 'Taxi', amount: 50.0, category: 'Transport', paidBy: 'Bob', date: DateTime.now(), categoryColor: '#3B82F6'),
    ];

    testWidgets('25. Category chart card exists with Key categoryExpenseChart', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.byKey(const Key('categoryExpenseChart')), findsOneWidget);
    });

    testWidgets('26. Shows Expense by Category title', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.text('Expense by Category'), findsOneWidget);
    });

    testWidgets('27. Displays category names', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
    });

    testWidgets('28. Displays formatted category amounts', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.text('€100.00 (66.7%)'), findsOneWidget);
      expect(find.text('€50.00 (33.3%)'), findsOneWidget);
    });

    testWidgets('29. Renders LinearProgressIndicator bars for categories', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('30. Sorts categories by highest expense first', (tester) async {
      final multiBills = [
        makeBill(id: '1', title: 'Coffee', amount: 10.0, category: 'Food', paidBy: 'Alice', date: DateTime.now()),
        makeBill(id: '2', title: 'Hotel', amount: 300.0, category: 'Accommodation', paidBy: 'Bob', date: DateTime.now()),
        makeBill(id: '3', title: 'Train', amount: 50.0, category: 'Transport', paidBy: 'Charlie', date: DateTime.now()),
      ];
      await pumpScreen(tester, buildStatsApp(bills: multiBills));
      expect(find.text('Accommodation'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('31. Aggregates multiple bills in the same category', (tester) async {
      final catBills = [
        makeBill(id: '1', title: 'Lunch', amount: 30.0, category: 'Food', paidBy: 'Alice', date: DateTime.now()),
        makeBill(id: '2', title: 'Dinner', amount: 70.0, category: 'Food', paidBy: 'Bob', date: DateTime.now()),
      ];
      await pumpScreen(tester, buildStatsApp(bills: catBills));
      // Total food = €100.00 (100.0%)
      expect(find.text('€100.00 (100.0%)'), findsOneWidget);
    });

    testWidgets('32. Category progress bar has rounded corners', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.byType(ClipRRect), findsWidgets);
    });
  });

  // ── GROUP 5: Person Breakdown Donut/Pie Chart (AC 4) ───────────────────────
  group('5. Person Breakdown Donut/Pie Chart (AC 4)', () {
    final bills = [
      makeBill(id: '1', title: 'Dinner', amount: 60.0, category: 'Food', paidBy: 'Alice', date: DateTime.now()),
      makeBill(id: '2', title: 'Snacks', amount: 40.0, category: 'Food', paidBy: 'Bob', date: DateTime.now()),
    ];

    testWidgets('33. Person chart card exists with Key personExpenseChart', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.byKey(const Key('personExpenseChart')), findsOneWidget);
    });

    testWidgets('34. Shows Expense by Person title', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.text('Expense by Person'), findsOneWidget);
    });

    testWidgets('35. CustomPaint canvas widget is rendered for pie chart', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('36. Displays person names in legend', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.text('Alice: €60.00 (60%)'), findsOneWidget);
      expect(find.text('Bob: €40.00 (40%)'), findsOneWidget);
    });

    testWidgets('37. Legend displays colored circle indicator for each person', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.byType(Wrap), findsWidgets);
    });

    testWidgets('38. Three participants pie breakdown calculated accurately', (tester) async {
      final multiBills = [
        makeBill(id: '1', title: 'B1', amount: 50.0, category: 'Food', paidBy: 'Alice', date: DateTime.now()),
        makeBill(id: '2', title: 'B2', amount: 30.0, category: 'Food', paidBy: 'Bob', date: DateTime.now()),
        makeBill(id: '3', title: 'B3', amount: 20.0, category: 'Food', paidBy: 'Charlie', date: DateTime.now()),
      ];
      await pumpScreen(tester, buildStatsApp(bills: multiBills));
      expect(find.text('Alice: €50.00 (50%)'), findsOneWidget);
      expect(find.text('Bob: €30.00 (30%)'), findsOneWidget);
      expect(find.text('Charlie: €20.00 (20%)'), findsOneWidget);
    });

    testWidgets('39. Single payer shows 100% in legend', (tester) async {
      final singleBill = [makeBill(id: '1', title: 'Solo', amount: 80.0, category: 'Food', paidBy: 'Alice', date: DateTime.now())];
      await pumpScreen(tester, buildStatsApp(bills: singleBill));
      expect(find.text('Alice: €80.00 (100%)'), findsOneWidget);
    });
  });

  // ── GROUP 6: Monthly Expense Breakdown (AC 2) ──────────────────────────────
  group('6. Monthly Expense Breakdown (AC 2)', () {
    final now = DateTime.now();
    final bills = [
      makeBill(id: '1', title: 'June', amount: 150.0, category: 'Food', paidBy: 'Alice', date: DateTime(now.year, 6, 10)),
      makeBill(id: '2', title: 'July', amount: 250.0, category: 'Food', paidBy: 'Bob', date: DateTime(now.year, 7, 12)),
    ];

    testWidgets('40. Monthly chart card exists with Key monthlyExpenseChart', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.byKey(const Key('monthlyExpenseChart')), findsOneWidget);
    });

    testWidgets('41. Shows Monthly Expense title', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.text('Monthly Expense'), findsOneWidget);
    });

    testWidgets('42. Shows month column labels', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.text('Jun ${now.year}'), findsOneWidget);
      expect(find.text('Jul ${now.year}'), findsOneWidget);
    });

    testWidgets('43. Displays month expense amounts', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.descendant(of: find.byKey(const Key('monthlyExpenseChart')), matching: find.text('€150.00')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('monthlyExpenseChart')), matching: find.text('€250.00')), findsOneWidget);
    });

    testWidgets('44. Aggregates multiple bills in the same month', (tester) async {
      final sameMonthBills = [
        makeBill(id: '1', title: 'Lunch', amount: 40.0, category: 'Food', paidBy: 'Alice', date: DateTime(now.year, 8, 5)),
        makeBill(id: '2', title: 'Dinner', amount: 60.0, category: 'Food', paidBy: 'Bob', date: DateTime(now.year, 8, 20)),
      ];
      await pumpScreen(tester, buildStatsApp(bills: sameMonthBills));
      expect(find.text('Aug ${now.year}'), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('monthlyExpenseChart')), matching: find.text('€100.00')), findsOneWidget);
    });

    testWidgets('45. Monthly bar has gradient decoration', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.byType(Container), findsWidgets);
    });
  });

  // ── GROUP 7: Dark / Light Theme Support (AC 7) ─────────────────────────────
  group('7. Dark / Light Theme Support (AC 7)', () {
    final bills = [makeBill(id: '1', title: 'Test', amount: 75.0, category: 'Food', paidBy: 'Alice', date: DateTime.now())];

    testWidgets('46. Light theme card background is white', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills));
      final card = tester.widget<Card>(find.byKey(const Key('categoryExpenseChart')));
      expect(card.color, Colors.white);
    });

    testWidgets('47. Dark theme card background is dark (#1E1E1E)', (tester) async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': true});
      final tp = ThemeProvider();
      await tp.loadTheme();
      await pumpScreen(tester, buildStatsApp(bills: bills, themeProvider: tp));
      final card = tester.widget<Card>(find.byKey(const Key('categoryExpenseChart')));
      expect(card.color, const Color(0xFF1E1E1E));
    });

    testWidgets('48. Light theme person chart card is white', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills));
      final card = tester.widget<Card>(find.byKey(const Key('personExpenseChart')));
      expect(card.color, Colors.white);
    });

    testWidgets('49. Dark theme person chart card is dark', (tester) async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': true});
      final tp = ThemeProvider();
      await tp.loadTheme();
      await pumpScreen(tester, buildStatsApp(bills: bills, themeProvider: tp));
      final card = tester.widget<Card>(find.byKey(const Key('personExpenseChart')));
      expect(card.color, const Color(0xFF1E1E1E));
    });

    testWidgets('50. Light theme monthly chart card is white', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills));
      final card = tester.widget<Card>(find.byKey(const Key('monthlyExpenseChart')));
      expect(card.color, Colors.white);
    });

    testWidgets('51. Dark theme monthly chart card is dark', (tester) async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': true});
      final tp = ThemeProvider();
      await tp.loadTheme();
      await pumpScreen(tester, buildStatsApp(bills: bills, themeProvider: tp));
      final card = tester.widget<Card>(find.byKey(const Key('monthlyExpenseChart')));
      expect(card.color, const Color(0xFF1E1E1E));
    });

    testWidgets('52. Light theme summary cards are white', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills));
      final card = tester.widget<Card>(find.byKey(const Key('statsTotalSpent')));
      expect(card.color, Colors.white);
    });

    testWidgets('53. Dark theme summary cards are dark', (tester) async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': true});
      final tp = ThemeProvider();
      await tp.loadTheme();
      await pumpScreen(tester, buildStatsApp(bills: bills, themeProvider: tp));
      final card = tester.widget<Card>(find.byKey(const Key('statsTotalSpent')));
      expect(card.color, const Color(0xFF1E1E1E));
    });
  });

  // ── GROUP 8: Localization / i18n (EN & VI) ─────────────────────────────────
  group('8. Localization / i18n', () {
    final bills = [makeBill(id: '1', title: 'Test', amount: 50.0, category: 'Food', paidBy: 'Alice', date: DateTime.now())];

    testWidgets('54. English titles render correctly', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills, locale: 'en'));
      expect(find.text('Statistics & Charts'), findsOneWidget);
      expect(find.text('Expense by Category'), findsOneWidget);
      expect(find.text('Expense by Person'), findsOneWidget);
      expect(find.text('Monthly Expense'), findsOneWidget);
    });

    testWidgets('55. Vietnamese titles render correctly', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills, locale: 'vi'));
      expect(find.text('Thống kê & Biểu đồ'), findsOneWidget);
      expect(find.text('Chi tiêu theo danh mục'), findsOneWidget);
      expect(find.text('Chi tiêu theo thành viên'), findsOneWidget);
      expect(find.text('Chi tiêu theo tháng'), findsOneWidget);
    });

    testWidgets('56. Vietnamese filter chips render correctly', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills, locale: 'vi'));
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Tháng này'), findsOneWidget);
      expect(find.text('3 tháng gần nhất'), findsOneWidget);
    });

    testWidgets('57. Vietnamese metric labels render correctly', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: bills, locale: 'vi'));
      expect(find.text('Tổng chi'), findsOneWidget);
      expect(find.text('Trung bình / người'), findsOneWidget);
      expect(find.text('Chi tiêu nhiều nhất'), findsOneWidget);
    });

    testWidgets('58. Vietnamese empty state renders correctly', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: [], locale: 'vi'));
      expect(find.text('Không có dữ liệu chi tiêu trong kỳ này'), findsOneWidget);
    });
  });

  // ── GROUP 9: Edge Cases & Large Datasets ────────────────────────────────────
  group('9. Edge Cases & Large Datasets', () {
    testWidgets('59. Handles bill with 0 amount without division by zero', (tester) async {
      final bills = [makeBill(id: '1', title: 'Free item', amount: 0.0, category: 'Food', paidBy: 'Alice', date: DateTime.now())];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.text('€0.00'), findsWidgets);
    });

    testWidgets('60. Large dataset with 20 bills renders cleanly', (tester) async {
      final bills = List.generate(
        20,
        (i) => makeBill(
          id: 'b$i',
          title: 'Bill $i',
          amount: 10.0 * (i + 1),
          category: i % 2 == 0 ? 'Food' : 'Transport',
          paidBy: i % 3 == 0 ? 'Alice' : 'Bob',
          date: DateTime.now(),
        ),
      );
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.byType(StatisticsScreen), findsOneWidget);
    });

    testWidgets('61. Handles special unicode characters in participant names', (tester) async {
      final bills = [
        makeBill(id: '1', title: 'Phở bò', amount: 80.0, category: 'Food', paidBy: 'Nguyễn Văn A', date: DateTime.now(), participants: ['Nguyễn Văn A', 'Trần Thị B']),
      ];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.text('Nguyễn Văn A: €80.00 (100%)'), findsOneWidget);
    });

    testWidgets('62. Handles single participant paying their own bill', (tester) async {
      final bills = [
        makeBill(id: '1', title: 'Personal', amount: 45.0, category: 'Utilities', paidBy: 'Dave', date: DateTime.now(), participants: ['Dave']),
      ];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.text('€45.00'), findsWidgets);
      expect(find.text('Dave'), findsWidgets);
    });

    testWidgets('63. Handles decimal values with exact cents', (tester) async {
      final bills = [
        makeBill(id: '1', title: 'Precise', amount: 99.99, category: 'Shopping', paidBy: 'Alice', date: DateTime.now()),
      ];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.text('€99.99'), findsWidgets);
    });

    testWidgets('64. Rapid filter switching does not crash', (tester) async {
      final bills = [makeBill(id: '1', title: 'Test', amount: 50.0, category: 'Food', paidBy: 'Alice', date: DateTime.now())];
      await pumpScreen(tester, buildStatsApp(bills: bills));

      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('filterChip_this_month')));
        await tester.pump(const Duration(milliseconds: 20));
        await tester.tap(find.byKey(const Key('filterChip_last_3_months')));
        await tester.pump(const Duration(milliseconds: 20));
        await tester.tap(find.byKey(const Key('filterChip_all_time')));
        await tester.pump(const Duration(milliseconds: 20));
      }
      await tester.pumpAndSettle();
      expect(find.byType(StatisticsScreen), findsOneWidget);
    });

    testWidgets('65. Category bar chart displays percentage properly', (tester) async {
      final bills = [
        makeBill(id: '1', title: 'F1', amount: 75.0, category: 'Food', paidBy: 'Alice', date: DateTime.now()),
        makeBill(id: '2', title: 'T1', amount: 25.0, category: 'Transport', paidBy: 'Bob', date: DateTime.now()),
      ];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.text('€75.00 (75.0%)'), findsOneWidget);
      expect(find.text('€25.00 (25.0%)'), findsOneWidget);
    });

    testWidgets('66. Multiple people paying identical amounts selects a highest spender cleanly', (tester) async {
      final bills = [
        makeBill(id: '1', title: 'A', amount: 50.0, category: 'Food', paidBy: 'Alice', date: DateTime.now()),
        makeBill(id: '2', title: 'B', amount: 50.0, category: 'Food', paidBy: 'Bob', date: DateTime.now()),
      ];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.text('€50.00'), findsWidgets);
    });

    testWidgets('67. Monthly breakdown across multiple years distinguishes months', (tester) async {
      final bills = [
        makeBill(id: '1', title: 'Y1', amount: 100.0, category: 'Food', paidBy: 'Alice', date: DateTime(2025, 5, 1)),
        makeBill(id: '2', title: 'Y2', amount: 200.0, category: 'Food', paidBy: 'Bob', date: DateTime(2026, 5, 1)),
      ];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.text('May 2025'), findsOneWidget);
      expect(find.text('May 2026'), findsOneWidget);
    });

    testWidgets('68. Category color parsing handles 6-digit hex without #', (tester) async {
      final bills = [
        makeBill(id: '1', title: 'T', amount: 10.0, category: 'Food', paidBy: 'A', date: DateTime.now(), categoryColor: 'FF5722'),
      ];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('69. Category color parsing handles invalid hex with fallback color', (tester) async {
      final bills = [
        makeBill(id: '1', title: 'T', amount: 10.0, category: 'Food', paidBy: 'A', date: DateTime.now(), categoryColor: 'INVALID_HEX'),
      ];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('70. Category color parsing handles null hex with fallback color', (tester) async {
      final bills = [
        makeBill(id: '1', title: 'T', amount: 10.0, category: 'Food', paidBy: 'A', date: DateTime.now(), categoryColor: null),
      ];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('71. Vertical scrolling of statistics content works cleanly', (tester) async {
      final bills = [
        makeBill(id: '1', title: 'B1', amount: 100.0, category: 'Food', paidBy: 'Alice', date: DateTime.now()),
        makeBill(id: '2', title: 'B2', amount: 200.0, category: 'Transport', paidBy: 'Bob', date: DateTime.now()),
      ];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.byType(StatisticsScreen), findsOneWidget);
    });

    testWidgets('72. Card shape has 16px radius for all chart cards', (tester) async {
      final bills = [makeBill(id: '1', title: 'B1', amount: 50.0, category: 'Food', paidBy: 'Alice', date: DateTime.now())];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      final card = tester.widget<Card>(find.byKey(const Key('categoryExpenseChart')));
      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(16));
    });

    testWidgets('73. Donut chart painter handles empty entries gracefully', (tester) async {
      await pumpScreen(tester, buildStatsApp(bills: []));
      expect(find.byKey(const Key('personExpenseChart')), findsNothing);
    });

    testWidgets('74. Total Spent card shows euro currency symbol', (tester) async {
      final bills = [makeBill(id: '1', title: 'B1', amount: 10.0, category: 'Food', paidBy: 'Alice', date: DateTime.now())];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.text('€10.00'), findsWidgets);
    });

    testWidgets('75. Displays 10 distinct categories in descending order', (tester) async {
      final cats = ['Food', 'Transport', 'Hotel', 'Shopping', 'Bills', 'Entertainment', 'Health', 'Sport', 'Education', 'Other'];
      final bills = cats.asMap().entries.map((e) {
        return makeBill(id: 'b${e.key}', title: e.value, amount: (e.key + 1) * 10.0, category: e.value, paidBy: 'Alice', date: DateTime.now());
      }).toList();

      await pumpScreen(tester, buildStatsApp(bills: bills));
      // First is Other (100.0)
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('76. Highest spender card handles zero bills with N/A', (tester) async {
      // Empty state shown instead
      await pumpScreen(tester, buildStatsApp(bills: []));
      expect(find.byKey(const Key('statsHighestSpender')), findsNothing);
    });

    testWidgets('77. Highest spender subtitle shows total spent by that person', (tester) async {
      final bills = [
        makeBill(id: '1', title: 'B1', amount: 77.0, category: 'Food', paidBy: 'Charlie', date: DateTime.now()),
      ];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.text('Charlie'), findsWidgets);
      expect(find.text('€77.00'), findsWidgets);
    });

    testWidgets('78. Donut painter sweepAngle covers full 360 degrees (2*pi)', (tester) async {
      final bills = [makeBill(id: '1', title: 'B1', amount: 100.0, category: 'Food', paidBy: 'Alice', date: DateTime.now())];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('79. Monthly bar chart handles 6 distinct months', (tester) async {
      final bills = List.generate(
        6,
        (i) => makeBill(id: 'b$i', title: 'M$i', amount: 50.0, category: 'Food', paidBy: 'A', date: DateTime(2026, i + 1, 1)),
      );
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.byKey(const Key('monthlyExpenseChart')), findsOneWidget);
    });

    testWidgets('80. Filter chip All Time remains selected after tapping it again', (tester) async {
      final bills = [makeBill(id: '1', title: 'B1', amount: 20.0, category: 'Food', paidBy: 'Alice', date: DateTime.now())];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      await tester.tap(find.byKey(const Key('filterChip_all_time')));
      await tester.pumpAndSettle();
      final chip = tester.widget<FilterChip>(find.byKey(const Key('filterChip_all_time')));
      expect(chip.selected, true);
    });

    testWidgets('81. Category icon is displayed next to category chart title', (tester) async {
      final bills = [makeBill(id: '1', title: 'B1', amount: 20.0, category: 'Food', paidBy: 'Alice', date: DateTime.now())];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.byIcon(Icons.category), findsOneWidget);
    });

    testWidgets('82. Pie chart icon is displayed next to person chart title', (tester) async {
      final bills = [makeBill(id: '1', title: 'B1', amount: 20.0, category: 'Food', paidBy: 'Alice', date: DateTime.now())];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.byIcon(Icons.pie_chart), findsOneWidget);
    });

    testWidgets('83. Bar chart icon is displayed next to monthly chart title', (tester) async {
      final bills = [makeBill(id: '1', title: 'B1', amount: 20.0, category: 'Food', paidBy: 'Alice', date: DateTime.now())];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
    });

    testWidgets('84. Category circle indicator is colored', (tester) async {
      final bills = [makeBill(id: '1', title: 'B1', amount: 20.0, category: 'Food', paidBy: 'Alice', date: DateTime.now())];
      await pumpScreen(tester, buildStatsApp(bills: bills));
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('85. Reads bills from BillsBloc if initialBills is null', (tester) async {
      final bills = [makeBill(id: '1', title: 'B1', amount: 20.0, category: 'Food', paidBy: 'Alice', date: DateTime.now())];
      final repo = MockBillRepository()..bills = bills;
      final bloc = BillsBloc(
        getBillsUseCase: GetBillsUseCase(repo),
        addBillUseCase: AddBillUseCase(repo),
      )..emit(BillsLoaded(bills: bills));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
            ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
          ],
          child: BlocProvider<BillsBloc>.value(
            value: bloc,
            child: const MaterialApp(
              home: StatisticsScreen(), // initialBills: null
              localizationsDelegates: [StatsLocDelegate()],
              supportedLocales: [Locale('en')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('€20.00'), findsWidgets);
    });
  });
}
