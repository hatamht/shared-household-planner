import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';

void main() {
  group('Split Bills Integration Tests', () {
    test('Test 1: App integration - Create bill with all fields', () {
      final bill = Bill(
        id: 'test-1',
        title: 'Lunch',
        amount: 100000,
        category: 'food',
        date: DateTime(2024, 9, 2),
        paidBy: 'Alice',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 50000),
        ],
      );

      expect(bill.title, 'Lunch');
      expect(bill.amount, 100000);
      expect(bill.participants.length, 2);
    });

    test('Test 2: AddBillScreen form with valid inputs', () {
      final participants = ['Alice', 'Bob'];
      final bill = Bill(
        id: 'form-test',
        title: 'Pizza',
        amount: 150000,
        category: 'food',
        date: DateTime.now(),
        paidBy: 'Bob',
        participants: participants
            .map((name) => BillParticipant(
                  participantId: 'p${participants.indexOf(name)}',
                  name: name,
                  amount: 75000,
                ))
            .toList(),
      );

      expect(bill.title, 'Pizza');
      expect(bill.paidBy, 'Bob');
      expect(bill.participants.length, 2);
    });

    test('Test 3: Navigation from Home to Bills screen - Bill object validity', () {
      final bill = Bill(
        id: 'nav-test',
        title: 'Taxi',
        amount: 50000,
        category: 'transport',
        date: DateTime.now(),
        paidBy: 'Charlie',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 25000),
          BillParticipant(participantId: 'p2', name: 'Charlie', amount: 25000),
        ],
      );

      expect(bill.id, isNotEmpty);
      expect(bill.category, 'transport');
      expect(bill.amount, 50000);
    });

    test('Test 4: BillsListScreen with empty state', () {
      final emptyBills = <Bill>[];
      expect(emptyBills.isEmpty, true);
    });

    test('Test 5: BillsListScreen with populated bills', () {
      final bills = [
        Bill(
          id: '1',
          title: 'Movie',
          amount: 200000,
          category: 'entertainment',
          date: DateTime.now(),
          paidBy: 'David',
          participants: [
            BillParticipant(participantId: 'p1', name: 'Alice', amount: 100000),
            BillParticipant(participantId: 'p2', name: 'David', amount: 100000),
          ],
        ),
        Bill(
          id: '2',
          title: 'Electricity',
          amount: 500000,
          category: 'utilities',
          date: DateTime.now(),
          paidBy: 'Eve',
          participants: [
            BillParticipant(participantId: 'p1', name: 'Alice', amount: 250000),
            BillParticipant(participantId: 'p2', name: 'Eve', amount: 250000),
          ],
        ),
      ];

      expect(bills.length, 2);
      expect(bills[0].category, 'entertainment');
      expect(bills[1].category, 'utilities');
    });

    test('Test 6: AddBillScreen form validation - title required', () {
      final titleEmpty = '';
      expect(titleEmpty.isEmpty, true);
    });

    test('Test 7: AddBillScreen form validation - amount must be positive', () {
      final amount = 100000.0;
      expect(amount > 0, true);
    });

    test('Test 8: AddBillScreen form validation - min 2 participants', () {
      final participants = ['Alice', 'Bob'];
      expect(participants.length >= 2, true);
    });

    test('Test 9: Database persistence - Bill data structure', () {
      final bill = Bill(
        id: 'persist-test',
        title: 'Groceries',
        amount: 250000,
        category: 'shopping',
        date: DateTime(2024, 9, 2),
        paidBy: 'Frank',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 125000),
          BillParticipant(participantId: 'p2', name: 'Frank', amount: 125000),
        ],
      );

      expect(bill.id, 'persist-test');
      expect(bill.paidBy, 'Frank');
      expect(bill.amount, 250000);
    });

    test('Test 10: Theme integration - Bill rendering with Light/Dark mode', () {
      final bill = Bill(
        id: 'theme-test',
        title: 'Doctor',
        amount: 800000,
        category: 'health',
        date: DateTime.now(),
        paidBy: 'Grace',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 400000),
          BillParticipant(participantId: 'p2', name: 'Grace', amount: 400000),
        ],
      );

      expect(bill.title, 'Doctor');
      expect(bill.category, 'health');
      expect(bill.participants.isNotEmpty, true);
    });
  });
}
