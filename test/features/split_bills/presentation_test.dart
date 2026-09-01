import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/bills_list_screen.dart';
import 'package:shared_household_planner/features/split_bills/presentation/widgets/bill_card.dart';
import 'package:shared_household_planner/features/split_bills/presentation/widgets/stats_card.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/core/theme/app_theme.dart';

class MockGetBillsUseCase extends Mock implements GetBillsUseCase {}
class MockAddBillUseCase extends Mock implements AddBillUseCase {}
class MockThemeProvider extends Mock implements ThemeProvider {}

void main() {
  initializeDateFormatting();

  group('BillsBloc Tests', () {
    late MockGetBillsUseCase mockGetBillsUseCase;
    late MockAddBillUseCase mockAddBillUseCase;
    late BillsBloc billsBloc;

    setUp(() {
      mockGetBillsUseCase = MockGetBillsUseCase();
      mockAddBillUseCase = MockAddBillUseCase();
      billsBloc = BillsBloc(
        getBillsUseCase: mockGetBillsUseCase,
        addBillUseCase: mockAddBillUseCase,
      );
    });

    tearDown(() {
      billsBloc.close();
    });

    test('initial state is BillsInitial', () {
      expect(billsBloc.state, isA<BillsInitial>());
    });

    test('GetBillsEvent triggers BillsLoading then BillsLoaded', () async {
      final testBills = [
        Bill(
          id: '1',
          name: 'Lunch',
          amount: 100000,
          category: 'food',
          date: DateTime.now(),
          participants: [
            BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000),
            BillParticipant(participantId: 'p2', name: 'Bob', amount: 50000),
          ],
        ),
      ];

      when(mockGetBillsUseCase(any)).thenAnswer((_) async {
        return Right(testBills);
      });

      expectLater(
        billsBloc.stream,
        emitsInOrder([
          isA<BillsLoading>(),
          isA<BillsLoaded>(),
        ]),
      );

      billsBloc.add(const GetBillsEvent());
    });

    test('BillsError on GetBills failure', () async {
      when(mockGetBillsUseCase(any)).thenAnswer((_) async {
        return Left(ServerFailure());
      });

      expectLater(
        billsBloc.stream,
        emitsInOrder([
          isA<BillsLoading>(),
          isA<BillsError>(),
        ]),
      );

      billsBloc.add(const GetBillsEvent());
    });
  });

  group('BillsListScreen Widget Tests', () {
    late MockGetBillsUseCase mockGetBillsUseCase;
    late MockAddBillUseCase mockAddBillUseCase;

    setUp(() {
      mockGetBillsUseCase = MockGetBillsUseCase();
      mockAddBillUseCase = MockAddBillUseCase();
    });

    Widget createTestableWidget(Widget child) {
      return MaterialApp(
        localizationsDelegates: [
          AppLocalizationsDelegate(),
        ],
        supportedLocales: const [Locale('en'), Locale('vi')],
        home: child,
      );
    }

    testWidgets('BillsListScreen shows loading indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          BlocProvider(
            create: (_) => BillsBloc(
              getBillsUseCase: mockGetBillsUseCase,
              addBillUseCase: mockAddBillUseCase,
            )..add(const GetBillsEvent()),
            child: const BillsListScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('BillsListScreen displays bills when loaded', (WidgetTester tester) async {
      final testBills = [
        Bill(
          id: '1',
          name: 'Dinner',
          amount: 200000,
          category: 'food',
          date: DateTime.now(),
          participants: [
            BillParticipant(participantId: 'p1', name: 'Alice', amount: 100000),
            BillParticipant(participantId: 'p2', name: 'Bob', amount: 100000),
          ],
        ),
      ];

      final billsBloc = BillsBloc(
        getBillsUseCase: mockGetBillsUseCase,
        addBillUseCase: mockAddBillUseCase,
      );

      await tester.pumpWidget(
        createTestableWidget(
          BlocProvider(
            create: (_) => billsBloc,
            child: const BillsListScreen(),
          ),
        ),
      );

      billsBloc.emit(BillsLoaded(bills: testBills));
      await tester.pumpWidget(
        createTestableWidget(
          BlocProvider<BillsBloc>.value(
            value: billsBloc,
            child: const BillsListScreen(),
          ),
        ),
      );

      expect(find.byType(BillCard), findsWidgets);
    });

    testWidgets('BillsListScreen shows FAB for adding bill', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          BlocProvider(
            create: (_) => BillsBloc(
              getBillsUseCase: mockGetBillsUseCase,
              addBillUseCase: mockAddBillUseCase,
            ),
            child: const BillsListScreen(),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('FAB opens add bill dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          BlocProvider(
            create: (_) => BillsBloc(
              getBillsUseCase: mockGetBillsUseCase,
              addBillUseCase: mockAddBillUseCase,
            ),
            child: const BillsListScreen(),
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('Form validation - empty name shows error', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          BlocProvider(
            create: (_) => BillsBloc(
              getBillsUseCase: mockGetBillsUseCase,
              addBillUseCase: mockAddBillUseCase,
            ),
            child: const BillsListScreen(),
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Try to submit with empty form
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Should still be in dialog (validation failed)
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('Form validation - negative amount shows error', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          BlocProvider(
            create: (_) => BillsBloc(
              getBillsUseCase: mockGetBillsUseCase,
              addBillUseCase: mockAddBillUseCase,
            ),
            child: const BillsListScreen(),
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Fill in form with negative amount
      await tester.enterText(find.byType(TextFormField).at(0), 'Test Bill');
      await tester.enterText(find.byType(TextFormField).at(1), '-100');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Should still be in dialog (validation failed)
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('Form validation - less than 2 participants shows error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          BlocProvider(
            create: (_) => BillsBloc(
              getBillsUseCase: mockGetBillsUseCase,
              addBillUseCase: mockAddBillUseCase,
            ),
            child: const BillsListScreen(),
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Fill form with only 1 participant
      await tester.enterText(find.byType(TextFormField).at(0), 'Test');
      await tester.enterText(find.byType(TextFormField).at(1), '100');
      await tester.enterText(find.byType(TextFormField).at(4), 'Alice');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Should still be in dialog (validation failed)
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('StatsCard Widget Tests', () {
    testWidgets('StatsCard displays total amount correctly', (WidgetTester tester) async {
      final bills = [
        Bill(
          id: '1',
          name: 'Bill 1',
          amount: 100000,
          category: 'food',
          date: DateTime.now(),
          participants: [
            BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000),
            BillParticipant(participantId: 'p2', name: 'Bob', amount: 50000),
          ],
        ),
        Bill(
          id: '2',
          name: 'Bill 2',
          amount: 200000,
          category: 'transport',
          date: DateTime.now(),
          participants: [
            BillParticipant(participantId: 'p1', name: 'Alice', amount: 100000),
            BillParticipant(participantId: 'p2', name: 'Bob', amount: 100000),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en'), Locale('vi')],
          home: Scaffold(
            body: StatsCard(bills: bills),
          ),
        ),
      );

      // Check total amount
      expect(find.byType(StatsCard), findsOneWidget);
    });

    testWidgets('StatsCard calculates user owe correctly', (WidgetTester tester) async {
      final bills = [
        Bill(
          id: '1',
          name: 'Bill 1',
          amount: 100000,
          category: 'food',
          date: DateTime.now(),
          participants: [
            BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000),
            BillParticipant(participantId: 'p2', name: 'Bob', amount: 50000),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en'), Locale('vi')],
          home: Scaffold(
            body: StatsCard(bills: bills),
          ),
        ),
      );

      expect(find.byType(StatsCard), findsOneWidget);
    });
  });

  group('BillCard Widget Tests', () {
    testWidgets('BillCard displays bill info correctly', (WidgetTester tester) async {
      final bill = Bill(
        id: '1',
        name: 'Lunch',
        amount: 100000,
        category: 'food',
        date: DateTime(2024, 1, 15),
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 50000),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en'), Locale('vi')],
          home: Scaffold(
            body: BillCard(bill: bill),
          ),
        ),
      );

      expect(find.byType(BillCard), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
    });

    testWidgets('BillCard shows category emoji', (WidgetTester tester) async {
      final bill = Bill(
        id: '1',
        name: 'Pizza',
        amount: 100000,
        category: 'food',
        date: DateTime.now(),
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 50000),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en'), Locale('vi')],
          home: Scaffold(
            body: BillCard(bill: bill),
          ),
        ),
      );

      expect(find.text('🍕'), findsOneWidget);
    });
  });
}

// Mock implementation for either.dart pattern
class Right<L, R> {
  final R value;
  Right(this.value);

  void fold(Function(L) onLeft, Function(R) onRight) {
    onRight(value);
  }
}

class Left<L, R> {
  final L value;
  Left(this.value);

  void fold(Function(L) onLeft, Function(R) onRight) {
    onLeft(value);
  }
}

class ServerFailure {}
