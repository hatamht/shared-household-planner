import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';

import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/fast_add_bill_screen.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project_settings.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────────

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
  Future<Either<Failure, Bill>> update(Bill bill) async {
    final idx = bills.indexWhere((b) => b.id == bill.id);
    if (idx != -1) bills[idx] = bill;
    return Right(bill);
  }

  @override
  Future<Either<Failure, void>> delete(String billId) async {
    bills.removeWhere((b) => b.id == billId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Bill>>> getByProjectId(String projectId) async =>
      Right(bills.where((b) => b.projectId == projectId).toList());

  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(String projectId) async =>
      getByProjectId(projectId);

  @override
  Future<Either<Failure, List<Bill>>> getByDateRange(DateTime start, DateTime end) async =>
      Right(List.from(bills));

  @override
  Future<Either<Failure, List<Bill>>> getByPayer(String payerName) async =>
      Right(bills.where((b) => b.paidBy == payerName).toList());

  @override
  Future<Either<Failure, List<Bill>>> getByCategory(String category) async =>
      Right(bills.where((b) => b.category == category).toList());
}

// ─── Localizations ────────────────────────────────────────────────────────────

class TestLocalizations extends AppLocalizations {
  TestLocalizations(Locale locale) : super(locale);

  static Map<String, String> _loadJson(String code) {
    try {
      final file = File('lib/core/localization/translations/$code.json');
      if (file.existsSync()) {
        final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, v.toString()));
      }
    } catch (_) {}
    return {};
  }

  static final Map<String, String> _en = _loadJson('en');
  static final Map<String, String> _vi = _loadJson('vi');

  @override
  String translate(String key) {
    if (locale.languageCode == 'vi') {
      return _vi[key] ?? _en[key] ?? key;
    }
    return _en[key] ?? key;
  }
}

class TestLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const TestLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(TestLocalizations(locale));
  }

  @override
  bool shouldReload(TestLocalizationsDelegate old) => false;
}

// ─── Test app builder ────────────────────────────────────────────────────────

Widget buildFastAddApp({
  required Widget child,
  FakeBillRepo? repo,
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
}) {
  final fakeBillRepo = repo ?? FakeBillRepo();
  final billsBloc = BillsBloc(
    getBillsUseCase: GetBillsUseCase(fakeBillRepo),
    addBillUseCase: AddBillUseCase(fakeBillRepo),
  );

  return BlocProvider<BillsBloc>.value(
    value: billsBloc,
    child: MaterialApp(
      locale: locale,
      themeMode: themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      localizationsDelegates: const [
        TestLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('vi')],
      home: child,
    ),
  );
}

// Shorthand
Widget buildScreen({
  List<String> projectMembers = const [],
  String? projectId,
  String? currentUser,
  FakeBillRepo? repo,
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
}) {
  return buildFastAddApp(
    repo: repo,
    locale: locale,
    themeMode: themeMode,
    child: FastAddBillScreen(
      projectMembers: projectMembers,
      projectId: projectId,
      currentUser: currentUser,
      projectSettings: const ProjectSettings(defaultCurrency: 'USD'),
    ),
  );
}

void setLargeScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
}

void resetScreen(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}


// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── Group 1: Screen structure ────────────────────────────────────────────────
  group('Group 1: Screen structure', () {
    testWidgets('1. Renders AppBar with close button', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byKey(const Key('fastAddBillAppBar')), findsOneWidget);
      expect(find.byKey(const Key('fastAddBillCloseButton')), findsOneWidget);
    });

    testWidgets('2. Renders description field', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byKey(const Key('fastDescriptionField')), findsOneWidget);
      expect(find.byKey(const Key('fastDescriptionContainer')), findsOneWidget);
    });

    testWidgets('3. Renders amount field', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byKey(const Key('fastAmountField')), findsOneWidget);
      expect(find.byKey(const Key('fastAmountContainer')), findsOneWidget);
    });

    testWidgets('4. Renders secondary bar with all chips', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byKey(const Key('fastSecondaryBar')), findsOneWidget);
      expect(find.byKey(const Key('fastDateChip')), findsOneWidget);
      expect(find.byKey(const Key('fastMembersChip')), findsOneWidget);
      expect(find.byKey(const Key('fastCameraChip')), findsOneWidget);
      expect(find.byKey(const Key('fastMoreChip')), findsOneWidget);
    });

    testWidgets('5. Renders split chip', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byKey(const Key('fastSplitChip')), findsOneWidget);
    });

    testWidgets('6. Save button is disabled when amount is 0', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      final saveBtn = tester.widget<TextButton>(find.byKey(const Key('fastSaveButton')));
      expect(saveBtn.onPressed, isNull);
    });

    testWidgets('7. Save button enabled after entering amount > 0', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastAmountField')), '100');
      await tester.pump();

      final saveBtn = tester.widget<TextButton>(find.byKey(const Key('fastSaveButton')));
      expect(saveBtn.onPressed, isNotNull);
    });

    testWidgets('8. Close button pops route', (tester) async {
      setLargeScreen(tester);
      bool popped = false;
      final repo = FakeBillRepo();
      await tester.pumpWidget(buildFastAddApp(
        repo: repo,
        child: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () {
              Navigator.of(ctx)
                  .push(MaterialPageRoute(
                    builder: (_) => BlocProvider<BillsBloc>.value(
                      value: BlocProvider.of<BillsBloc>(ctx),
                      child: const FastAddBillScreen(),
                    ),
                  ))
                  .then((_) => popped = true);
            },
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fastAddBillCloseButton')));
      await tester.pumpAndSettle();
      expect(popped, isTrue);
    });

    testWidgets('9. AppBar title "Add Bill" is visible', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Add Bill'), findsOneWidget);
    });

    testWidgets('10. Screen body is scrollable', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  // ── Group 2: Category auto-detection (widget tests) ──────────────────────────
  group('Group 2: Category auto-detection (widget)', () {
    testWidgets('11. Default category is restaurant emoji 🍽️', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('🍽️'), findsWidgets);
    });

    testWidgets('12. Detects transport category from "taxi"', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastDescriptionField')), 'taxi');
      await tester.pump();

      expect(find.text('🚕'), findsWidgets);
    });

    testWidgets('13. Detects shopping from "buy groceries"', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastDescriptionField')), 'buy groceries');
      await tester.pump();

      expect(find.text('🛍️'), findsWidgets);
    });

    testWidgets('14. Detects entertainment from "movie"', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastDescriptionField')), 'movie night');
      await tester.pump();

      expect(find.text('🎬'), findsWidgets);
    });

    testWidgets('15. Detects health from "doctor"', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastDescriptionField')), 'doctor visit');
      await tester.pump();

      expect(find.text('💊'), findsWidgets);
    });

    testWidgets('16. Detects travel from "hotel"', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastDescriptionField')), 'hotel booking');
      await tester.pump();

      expect(find.text('✈️'), findsWidgets);
    });

    testWidgets('17. Falls back to restaurant for unknown text', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastDescriptionField')), 'zyxwvuts');
      await tester.pump();

      expect(find.text('🍽️'), findsWidgets);
    });

    testWidgets('18. Detects Vietnamese "cơm" as restaurant', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastDescriptionField')), 'cơm tối');
      await tester.pump();

      expect(find.text('🍽️'), findsWidgets);
    });

    testWidgets('19. Detects Vietnamese "xe" as transport', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastDescriptionField')), 'tiền xe');
      await tester.pump();

      expect(find.text('🚕'), findsWidgets);
    });

    testWidgets('20. Category emoji animates on change', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastDescriptionField')), 'taxi');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('🚕'), findsWidgets);
    });
  });

  // ── Group 3: Date chip ────────────────────────────────────────────────────────
  group('Group 3: Date chip', () {
    testWidgets('21. Date chip is visible', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byKey(const Key('fastDateChip')), findsOneWidget);
    });

    testWidgets('22. Date chip shows "Today" by default (EN)', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('23. Tapping date chip shows date picker dialog', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastDateChip')));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('24. Cancelling date picker keeps "Today" label', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastDateChip')));
      await tester.pumpAndSettle();

      // Dismiss by tapping outside the dialog (barrier)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('25. Date chip is InkWell tappable', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      final chip = find.byKey(const Key('fastDateChip'));
      expect(chip, findsOneWidget);
      expect(tester.widget<InkWell>(find.descendant(of: chip, matching: find.byType(InkWell))), isNotNull);
    });
  });

  // ── Group 4: Members chip & bottom sheet ─────────────────────────────────────
  group('Group 4: Members chip & bottom sheet', () {
    testWidgets('26. Members chip is visible', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byKey(const Key('fastMembersChip')), findsOneWidget);
    });

    testWidgets('27. Tapping members chip opens bottom sheet', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen(
        projectMembers: ['Alice', 'Bob'],
      ));
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastMembersChip')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fastMembersConfirmButton')), findsOneWidget);
    });

    testWidgets('28. Members bottom sheet lists all project members', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen(
        projectMembers: ['Alice', 'Bob', 'Charlie'],
      ));
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastMembersChip')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fast_member_checkbox_Alice')), findsOneWidget);
      expect(find.byKey(const Key('fast_member_checkbox_Bob')), findsOneWidget);
      expect(find.byKey(const Key('fast_member_checkbox_Charlie')), findsOneWidget);
    });

    testWidgets('29. Members bottom sheet confirm button closes sheet', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen(
        projectMembers: ['Alice', 'Bob'],
      ));
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastMembersChip')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fastMembersConfirmButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fastMembersConfirmButton')), findsNothing);
    });

    testWidgets('30. Can deselect a member in bottom sheet', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen(
        projectMembers: ['Alice', 'Bob'],
      ));
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastMembersChip')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fast_member_checkbox_Alice')));
      await tester.pumpAndSettle();

      final checkbox = tester.widget<CheckboxListTile>(
        find.byKey(const Key('fast_member_checkbox_Alice')),
      );
      expect(checkbox.value, isFalse);
    });

    testWidgets('31. Can re-select a member in bottom sheet', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen(
        projectMembers: ['Alice', 'Bob'],
      ));
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastMembersChip')));
      await tester.pumpAndSettle();

      // Deselect then reselect
      await tester.tap(find.byKey(const Key('fast_member_checkbox_Alice')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fast_member_checkbox_Alice')));
      await tester.pumpAndSettle();

      final checkbox = tester.widget<CheckboxListTile>(
        find.byKey(const Key('fast_member_checkbox_Alice')),
      );
      expect(checkbox.value, isTrue);
    });

    testWidgets('32. No-project flow shows add member inline field', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastMembersChip')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fastAddMemberField')), findsOneWidget);
      expect(find.byKey(const Key('fastAddMemberButton')), findsOneWidget);
    });

    testWidgets('33. Can add member inline and see checkbox', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastMembersChip')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('fastAddMemberField')), 'Dave');
      await tester.tap(find.byKey(const Key('fastAddMemberButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fast_member_checkbox_Dave')), findsOneWidget);
    });

    testWidgets('34. Empty name is not added as member', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastMembersChip')));
      await tester.pumpAndSettle();

      // tap add with empty field
      await tester.tap(find.byKey(const Key('fastAddMemberButton')));
      await tester.pumpAndSettle();

      // No checkboxes added (since name is empty)
      expect(find.byType(CheckboxListTile), findsNothing);
    });

    testWidgets('35. Members chip label shows "Members" when none pre-selected', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Members'), findsOneWidget);
    });
  });

  // ── Group 5: Split chip & bottom sheet ───────────────────────────────────────
  group('Group 5: Split chip & bottom sheet', () {
    testWidgets('36. Split chip is visible', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byKey(const Key('fastSplitChip')), findsOneWidget);
    });

    testWidgets('37. Tapping split chip opens split bottom sheet', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastSplitChip')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fastSplitConfirmButton')), findsOneWidget);
    });

    testWidgets('38. Split sheet shows all 4 mode chips', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastSplitChip')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fast_split_equal_chip')), findsOneWidget);
      expect(find.byKey(const Key('fast_split_percentage_chip')), findsOneWidget);
      expect(find.byKey(const Key('fast_split_shares_chip')), findsOneWidget);
      expect(find.byKey(const Key('fast_split_custom_chip')), findsOneWidget);
    });

    testWidgets('39. Can select percentage split mode', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastSplitChip')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fast_split_percentage_chip')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fastSplitConfirmButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fastSplitConfirmButton')), findsNothing);
    });

    testWidgets('40. Can select shares split mode', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastSplitChip')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fast_split_shares_chip')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fastSplitConfirmButton')));
      await tester.pumpAndSettle();
    });

    testWidgets('41. Can select custom split mode', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastSplitChip')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fast_split_custom_chip')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fastSplitConfirmButton')));
      await tester.pumpAndSettle();
    });

    testWidgets('42. Split sheet shows paid-by chips for project members', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen(
        projectMembers: ['Alice', 'Bob'],
      ));
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastSplitChip')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fast_paidby_chip_Alice')), findsOneWidget);
      expect(find.byKey(const Key('fast_paidby_chip_Bob')), findsOneWidget);
    });

    testWidgets('43. Can change paid-by in split sheet', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen(
        projectMembers: ['Alice', 'Bob'],
        currentUser: 'Alice',
      ));
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastSplitChip')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fast_paidby_chip_Bob')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fastSplitConfirmButton')));
      await tester.pumpAndSettle();
    });

    testWidgets('44. Split confirm button closes sheet', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastSplitChip')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fastSplitConfirmButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fastSplitConfirmButton')), findsNothing);
    });

    testWidgets('45. Equal mode is selected by default in split sheet', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastSplitChip')));
      await tester.pumpAndSettle();

      // Equal chip should be visually selected
      expect(find.byKey(const Key('fast_split_equal_chip')), findsOneWidget);
    });
  });

  // ── Group 6: Camera & More chips ─────────────────────────────────────────────
  group('Group 6: Camera and More chips', () {
    testWidgets('46. Camera chip is tappable and shows snackbar', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastCameraChip')));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('47. More chip is tappable and shows snackbar', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastMoreChip')));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  // ── Group 7: Save/submit flow ─────────────────────────────────────────────────
  group('Group 7: Save flow', () {
    testWidgets('48. Save adds bill to repository with correct amount', (tester) async {
      setLargeScreen(tester);
      final repo = FakeBillRepo();
      await tester.pumpWidget(buildScreen(
        repo: repo,
        projectMembers: ['Alice', 'Bob'],
        currentUser: 'Alice',
      ));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastAmountField')), '200');
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastSaveButton')));
      await tester.pumpAndSettle();

      expect(repo.bills, hasLength(1));
      expect(repo.bills.first.amount, 200.0);
    });

    testWidgets('49. Save uses description as bill title', (tester) async {
      setLargeScreen(tester);
      final repo = FakeBillRepo();
      await tester.pumpWidget(buildScreen(
        repo: repo,
        projectMembers: ['Alice', 'Bob'],
        currentUser: 'Alice',
      ));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastDescriptionField')), 'Coffee break');
      await tester.enterText(find.byKey(const Key('fastAmountField')), '50');
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastSaveButton')));
      await tester.pumpAndSettle();

      expect(repo.bills.first.title, 'Coffee break');
    });

    testWidgets('50. Save uses auto-detected category (taxi → transport)', (tester) async {
      setLargeScreen(tester);
      final repo = FakeBillRepo();
      await tester.pumpWidget(buildScreen(
        repo: repo,
        projectMembers: ['Alice', 'Bob'],
        currentUser: 'Alice',
      ));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastDescriptionField')), 'taxi to airport');
      await tester.enterText(find.byKey(const Key('fastAmountField')), '75');
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastSaveButton')));
      await tester.pumpAndSettle();

      expect(repo.bills.first.category, 'transport');
    });

    testWidgets('51. Save pops the screen', (tester) async {
      setLargeScreen(tester);
      final repo = FakeBillRepo();
      bool wasPopped = false;
      await tester.pumpWidget(buildFastAddApp(
        repo: repo,
        child: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () {
              Navigator.of(ctx)
                  .push(MaterialPageRoute(
                    builder: (_) => BlocProvider<BillsBloc>.value(
                      value: BlocProvider.of<BillsBloc>(ctx),
                      child: const FastAddBillScreen(
                        projectMembers: ['A', 'B'],
                        currentUser: 'A',
                      ),
                    ),
                  ))
                  .then((_) => wasPopped = true);
            },
            child: const Text('open'),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('fastAmountField')), '100');
      await tester.pump();
      await tester.tap(find.byKey(const Key('fastSaveButton')));
      await tester.pumpAndSettle();

      expect(wasPopped, isTrue);
    });

    testWidgets('52. Save without description uses category name as title', (tester) async {
      setLargeScreen(tester);
      final repo = FakeBillRepo();
      await tester.pumpWidget(buildScreen(
        repo: repo,
        projectMembers: ['Alice', 'Bob'],
        currentUser: 'Alice',
      ));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastAmountField')), '150');
      await tester.pump();

      await tester.tap(find.byKey(const Key('fastSaveButton')));
      await tester.pumpAndSettle();

      expect(repo.bills.first.title.isNotEmpty, isTrue);
    });

    testWidgets('53. Bill has correct paidBy from currentUser', (tester) async {
      setLargeScreen(tester);
      final repo = FakeBillRepo();
      await tester.pumpWidget(buildScreen(
        repo: repo,
        projectMembers: ['Alice', 'Bob'],
        currentUser: 'Alice',
      ));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastAmountField')), '100');
      await tester.pump();
      await tester.tap(find.byKey(const Key('fastSaveButton')));
      await tester.pumpAndSettle();

      expect(repo.bills.first.paidBy, 'Alice');
    });

    testWidgets('54. Bill currency matches projectSettings (USD)', (tester) async {
      setLargeScreen(tester);
      final repo = FakeBillRepo();
      await tester.pumpWidget(buildScreen(
        repo: repo,
        projectMembers: ['Alice', 'Bob'],
        currentUser: 'Alice',
      ));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastAmountField')), '100');
      await tester.pump();
      await tester.tap(find.byKey(const Key('fastSaveButton')));
      await tester.pumpAndSettle();

      expect(repo.bills.first.currency, 'USD');
    });

    testWidgets('55. Bill has splitMode equal by default', (tester) async {
      setLargeScreen(tester);
      final repo = FakeBillRepo();
      await tester.pumpWidget(buildScreen(
        repo: repo,
        projectMembers: ['Alice', 'Bob'],
        currentUser: 'Alice',
      ));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastAmountField')), '100');
      await tester.pump();
      await tester.tap(find.byKey(const Key('fastSaveButton')));
      await tester.pumpAndSettle();

      expect(repo.bills.first.splitMode, 'equal');
    });

    testWidgets('56. Bill has projectId when provided', (tester) async {
      setLargeScreen(tester);
      final repo = FakeBillRepo();
      await tester.pumpWidget(buildScreen(
        repo: repo,
        projectMembers: ['Alice', 'Bob'],
        currentUser: 'Alice',
        projectId: 'proj_abc',
      ));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastAmountField')), '100');
      await tester.pump();
      await tester.tap(find.byKey(const Key('fastSaveButton')));
      await tester.pumpAndSettle();

      expect(repo.bills.first.projectId, 'proj_abc');
    });

    testWidgets('57. Bill date is today by default', (tester) async {
      setLargeScreen(tester);
      final repo = FakeBillRepo();
      await tester.pumpWidget(buildScreen(
        repo: repo,
        projectMembers: ['Alice', 'Bob'],
        currentUser: 'Alice',
      ));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastAmountField')), '100');
      await tester.pump();
      await tester.tap(find.byKey(const Key('fastSaveButton')));
      await tester.pumpAndSettle();

      final today = DateTime.now();
      expect(repo.bills.first.date.year, today.year);
      expect(repo.bills.first.date.month, today.month);
      expect(repo.bills.first.date.day, today.day);
    });
  });

  // ── Group 8: Amount field behavior ───────────────────────────────────────────
  group('Group 8: Amount field', () {
    testWidgets('58. Amount field only accepts numeric input', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastAmountField')), '12abc34');
      await tester.pump();

      final field = tester.widget<TextField>(find.byKey(const Key('fastAmountField')));
      final text = field.controller?.text ?? '';
      expect(RegExp(r'^[0-9.]*$').hasMatch(text), isTrue);
    });

    testWidgets('59. Amount field allows decimals', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastAmountField')), '12.50');
      await tester.pump();

      final saveBtn = tester.widget<TextButton>(find.byKey(const Key('fastSaveButton')));
      expect(saveBtn.onPressed, isNotNull);
    });

    testWidgets('60. Amount 0 keeps save button disabled', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastAmountField')), '0');
      await tester.pump();

      final saveBtn = tester.widget<TextButton>(find.byKey(const Key('fastSaveButton')));
      expect(saveBtn.onPressed, isNull);
    });

    testWidgets('61. Entering then clearing amount disables save', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byKey(const Key('fastAmountField')), '100');
      await tester.pump();

      expect(
        tester.widget<TextButton>(find.byKey(const Key('fastSaveButton'))).onPressed,
        isNotNull,
      );

      await tester.enterText(find.byKey(const Key('fastAmountField')), '');
      await tester.pump();

      expect(
        tester.widget<TextButton>(find.byKey(const Key('fastSaveButton'))).onPressed,
        isNull,
      );
    });

    testWidgets('62. USD currency symbol is displayed', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('\$'), findsOneWidget);
    });

    testWidgets('63. Currency code "USD" label shown', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('USD'), findsOneWidget);
    });

    testWidgets('64. Amount field uses number keyboard type', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      final field = tester.widget<TextField>(find.byKey(const Key('fastAmountField')));
      expect(field.keyboardType?.decimal, isTrue);
    });

    testWidgets('65. Amount hint text is "0"', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      final field = tester.widget<TextField>(find.byKey(const Key('fastAmountField')));
      expect(field.decoration?.hintText, '0');
    });
  });

  // ── Group 9: Dark/Light theme ─────────────────────────────────────────────────
  group('Group 9: Dark/Light theme', () {
    testWidgets('66. Renders in dark theme without errors', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen(themeMode: ThemeMode.dark));
      await tester.pump();

      expect(find.byKey(const Key('fastAmountField')), findsOneWidget);
      expect(find.byKey(const Key('fastDescriptionField')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('67. Renders in light theme without errors', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen(themeMode: ThemeMode.light));
      await tester.pump();

      expect(find.byKey(const Key('fastAmountField')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('68. Dark theme: secondary bar chips visible', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen(themeMode: ThemeMode.dark));
      await tester.pump();

      expect(find.byKey(const Key('fastSecondaryBar')), findsOneWidget);
    });

    testWidgets('69. Light theme: secondary bar chips visible', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen(themeMode: ThemeMode.light));
      await tester.pump();

      expect(find.byKey(const Key('fastSecondaryBar')), findsOneWidget);
    });

    testWidgets('70. Dark theme: split chip visible', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen(themeMode: ThemeMode.dark));
      await tester.pump();

      expect(find.byKey(const Key('fastSplitChip')), findsOneWidget);
    });
  });

  // ── Group 10: i18n ───────────────────────────────────────────────────────────
  group('Group 10: i18n', () {
    testWidgets('71. Renders correctly with Vietnamese locale', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen(locale: const Locale('vi')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fastAmountField')), findsOneWidget);
      expect(find.byKey(const Key('fastDescriptionField')), findsOneWidget);
    });

    testWidgets('72. Date chip shows "Hôm nay" in Vietnamese', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen(locale: const Locale('vi')));
      await tester.pumpAndSettle();

      expect(find.text('Hôm nay'), findsOneWidget);
    });

    testWidgets('73. Date chip shows "Today" in English', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('74. Vietnamese locale shows "Thêm" for More chip', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen(locale: const Locale('vi')));
      await tester.pumpAndSettle();

      expect(find.text('Thêm'), findsOneWidget);
    });

    testWidgets('75. English locale shows "More" for More chip', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(buildScreen(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('More'), findsOneWidget);
    });
  });

  // ── Group 11: Category detection logic (unit tests) ──────────────────────────
  group('Group 11: Category detection logic', () {
    test('76. "lunch" → restaurant', () {
      expect(detectCategoryFromText('lunch'), 'restaurant');
    });

    test('77. "ăn tối" → restaurant', () {
      expect(detectCategoryFromText('ăn tối'), 'restaurant');
    });

    test('78. "cơm" → restaurant', () {
      expect(detectCategoryFromText('cơm'), 'restaurant');
    });

    test('79. "phở" → restaurant', () {
      expect(detectCategoryFromText('phở'), 'restaurant');
    });

    test('80. "taxi" → transport', () {
      expect(detectCategoryFromText('taxi'), 'transport');
    });

    test('81. "grab" → transport', () {
      expect(detectCategoryFromText('grab'), 'transport');
    });

    test('82. "bus fare" → transport', () {
      expect(detectCategoryFromText('bus fare'), 'transport');
    });

    test('83. "xăng xe" → transport', () {
      expect(detectCategoryFromText('xăng xe'), 'transport');
    });

    test('84. "grocery shopping" → shopping', () {
      expect(detectCategoryFromText('grocery shopping'), 'shopping');
    });

    test('85. "mua sắm" → shopping', () {
      expect(detectCategoryFromText('mua sắm'), 'shopping');
    });

    test('86. "chợ" → shopping', () {
      expect(detectCategoryFromText('chợ'), 'shopping');
    });

    test('87. "movie ticket" → entertainment', () {
      expect(detectCategoryFromText('movie ticket'), 'entertainment');
    });

    test('88. "netflix" → entertainment', () {
      expect(detectCategoryFromText('netflix'), 'entertainment');
    });

    test('89. "medicine" → health', () {
      expect(detectCategoryFromText('medicine'), 'health');
    });

    test('90. "thuốc" → health', () {
      expect(detectCategoryFromText('thuốc'), 'health');
    });

    test('91. "hospital" → health', () {
      expect(detectCategoryFromText('hospital'), 'health');
    });

    test('92. "hotel" → travel', () {
      expect(detectCategoryFromText('hotel'), 'travel');
    });

    test('93. "flight" → travel', () {
      expect(detectCategoryFromText('flight'), 'travel');
    });

    test('94. "du lịch" → travel', () {
      expect(detectCategoryFromText('du lịch'), 'travel');
    });

    test('95. "electric bill" → utilities', () {
      expect(detectCategoryFromText('electric bill'), 'utilities');
    });

    test('96. "party supplies" → party', () {
      expect(detectCategoryFromText('party supplies'), 'party');
    });

    test('97. "gym monthly" → sport', () {
      expect(detectCategoryFromText('gym monthly'), 'sport');
    });

    test('98. Empty string → restaurant (default)', () {
      expect(detectCategoryFromText(''), 'restaurant');
    });

    test('99. Unknown text → restaurant (default)', () {
      expect(detectCategoryFromText('zyxwvuts'), 'restaurant');
    });

    test('100. Case insensitive match "TAXI" → transport', () {
      expect(detectCategoryFromText('TAXI'), 'transport');
    });
  });
}
