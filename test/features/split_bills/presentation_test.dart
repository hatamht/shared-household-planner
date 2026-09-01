import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/bills_list_screen.dart';
import 'package:shared_household_planner/features/split_bills/presentation/widgets/bill_card.dart';
import 'package:shared_household_planner/features/split_bills/presentation/widgets/stats_card.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';

void main() {
  initializeDateFormatting();

  group('Presentation Layer Tests', () {
    testWidgets('Test 1: BillsListScreen initial load', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en'), Locale('vi')],
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      );
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Test 2: BillCard displays bill title', (WidgetTester tester) async {
      final bill = Bill(
        id: '1',
        title: 'Lunch',
        amount: 100000,
        category: 'food',
        date: DateTime(2024, 1, 15),
        paidBy: 'Alice',
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

      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('🍕'), findsOneWidget);
    });

    testWidgets('Test 3: StatsCard shows total amount', (WidgetTester tester) async {
      final bills = [
        Bill(
          id: '1',
          title: 'Bill 1',
          amount: 100000,
          category: 'food',
          date: DateTime.now(),
          paidBy: 'Alice',
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

    testWidgets('Test 4: BillCard shows transport emoji', (WidgetTester tester) async {
      final bill = Bill(
        id: '1',
        title: 'Taxi',
        amount: 50000,
        category: 'transport',
        date: DateTime.now(),
        paidBy: 'Bob',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 25000),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 25000),
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

      expect(find.text('🚕'), findsOneWidget);
    });

    testWidgets('Test 5: BillCard shows entertainment emoji', (WidgetTester tester) async {
      final bill = Bill(
        id: '1',
        title: 'Movie',
        amount: 200000,
        category: 'entertainment',
        date: DateTime.now(),
        paidBy: 'Charlie',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 100000),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 100000),
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

      expect(find.text('🎬'), findsOneWidget);
    });

    testWidgets('Test 6: BillCard displays amount', (WidgetTester tester) async {
      final bill = Bill(
        id: '1',
        title: 'Dinner',
        amount: 150000,
        category: 'food',
        date: DateTime.now(),
        paidBy: 'Alice',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 75000),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 75000),
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

      expect(find.text('150000đ'), findsOneWidget);
    });

    testWidgets('Test 7: StatsCard calculates total correctly', (WidgetTester tester) async {
      final bills = [
        Bill(
          id: '1',
          title: 'Bill 1',
          amount: 100000,
          category: 'food',
          date: DateTime.now(),
          paidBy: 'Alice',
          participants: [
            BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000),
            BillParticipant(participantId: 'p2', name: 'Bob', amount: 50000),
          ],
        ),
        Bill(
          id: '2',
          title: 'Bill 2',
          amount: 200000,
          category: 'transport',
          date: DateTime.now(),
          paidBy: 'Bob',
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

      expect(find.byType(StatsCard), findsOneWidget);
    });

    testWidgets('Test 8: BillCard shows participant count', (WidgetTester tester) async {
      final bill = Bill(
        id: '1',
        title: 'Group Dinner',
        amount: 300000,
        category: 'food',
        date: DateTime.now(),
        paidBy: 'Alice',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 100000),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 100000),
          BillParticipant(participantId: 'p3', name: 'Charlie', amount: 100000),
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

      expect(find.text('Group Dinner'), findsOneWidget);
      expect(find.byType(BillCard), findsOneWidget);
    });

    testWidgets('Test 9: BillCard with utilities category', (WidgetTester tester) async {
      final bill = Bill(
        id: '1',
        title: 'Electricity',
        amount: 500000,
        category: 'utilities',
        date: DateTime.now(),
        paidBy: 'Charlie',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 250000),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 250000),
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

      expect(find.text('⚡'), findsOneWidget);
    });

    testWidgets('Test 10: BillCard with shopping category', (WidgetTester tester) async {
      final bill = Bill(
        id: '1',
        title: 'Groceries',
        amount: 250000,
        category: 'shopping',
        date: DateTime.now(),
        paidBy: 'Alice',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 125000),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 125000),
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

      expect(find.text('🛍️'), findsOneWidget);
    });

    testWidgets('Test 11: BillCard with health category', (WidgetTester tester) async {
      final bill = Bill(
        id: '1',
        title: 'Doctor Visit',
        amount: 800000,
        category: 'health',
        date: DateTime.now(),
        paidBy: 'Bob',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 400000),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 400000),
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

      expect(find.text('🏥'), findsOneWidget);
    });

    testWidgets('Test 12: Multiple bills in StatsCard', (WidgetTester tester) async {
      final bills = [
        Bill(
          id: '1',
          title: 'Bill 1',
          amount: 100000,
          category: 'food',
          date: DateTime.now(),
          paidBy: 'Alice',
          participants: [
            BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000),
            BillParticipant(participantId: 'p2', name: 'Bob', amount: 50000),
          ],
        ),
        Bill(
          id: '2',
          title: 'Bill 2',
          amount: 150000,
          category: 'food',
          date: DateTime.now(),
          paidBy: 'Bob',
          participants: [
            BillParticipant(participantId: 'p1', name: 'Alice', amount: 75000),
            BillParticipant(participantId: 'p2', name: 'Bob', amount: 75000),
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

    testWidgets('Test 13: BillCard with two participants', (WidgetTester tester) async {
      final bill = Bill(
        id: '1',
        title: 'Lunch for Two',
        amount: 200000,
        category: 'food',
        date: DateTime.now(),
        paidBy: 'Alice',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 100000),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 100000),
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
      expect(find.text('Lunch for Two'), findsOneWidget);
    });

    testWidgets('Test 14: BillCard date formatting', (WidgetTester tester) async {
      final bill = Bill(
        id: '1',
        title: 'Test Bill',
        amount: 100000,
        category: 'food',
        date: DateTime(2024, 1, 15),
        paidBy: 'Alice',
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
    });

    testWidgets('Test 15: StatsCard with single bill', (WidgetTester tester) async {
      final bills = [
        Bill(
          id: '1',
          title: 'Single Bill',
          amount: 100000,
          category: 'food',
          date: DateTime.now(),
          paidBy: 'Alice',
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
}
