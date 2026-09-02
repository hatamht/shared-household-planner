import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';

void main() {
  group('Bills Presentation Layer Tests', () {
    test('Test 1: Bill entity can be created with correct fields',
        () {
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

      expect(bill.title, 'Lunch');
      expect(bill.amount, 100000);
      expect(bill.category, 'food');
    });

    test('Test 2: Bill amount is stored correctly', () {
      final bill = Bill(
        id: '2',
        title: 'Pizza',
        amount: 150000,
        category: 'food',
        date: DateTime.now(),
        paidBy: 'Bob',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 75000),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 75000),
        ],
      );

      expect(bill.amount, 150000);
    });

    test('Test 3: Bill participants list has correct length', () {
      final bill = Bill(
        id: '3',
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

      expect(bill.participants.length, 2);
    });

    test('Test 4: Bill category is stored correctly', () {
      final bill = Bill(
        id: '4',
        title: 'Movie',
        amount: 200000,
        category: 'entertainment',
        date: DateTime.now(),
        paidBy: 'David',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 100000),
          BillParticipant(participantId: 'p2', name: 'David', amount: 100000),
        ],
      );

      expect(bill.category, 'entertainment');
    });

    test('Test 5: Bill paidBy field stores payer name', () {
      final bill = Bill(
        id: '5',
        title: 'Electricity',
        amount: 500000,
        category: 'utilities',
        date: DateTime.now(),
        paidBy: 'Eve',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 250000),
          BillParticipant(participantId: 'p2', name: 'Eve', amount: 250000),
        ],
      );

      expect(bill.paidBy, 'Eve');
    });

    test('Test 6: BillParticipant stores correct data', () {
      final participant =
          BillParticipant(participantId: 'p1', name: 'Frank', amount: 125000);

      expect(participant.name, 'Frank');
      expect(participant.amount, 125000);
    });

    test('Test 7: Bill with 3 participants stores all', () {
      final bill = Bill(
        id: '7',
        title: 'Group Bill',
        amount: 300000,
        category: 'food',
        date: DateTime.now(),
        paidBy: 'Grace',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 100000),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 100000),
          BillParticipant(participantId: 'p3', name: 'Grace', amount: 100000),
        ],
      );

      expect(bill.participants.length, 3);
      expect(bill.amount, 300000);
    });

    test('Test 8: Bill date is stored correctly', () {
      final now = DateTime.now();
      final bill = Bill(
        id: '8',
        title: 'Test',
        amount: 100000,
        category: 'food',
        date: now,
        paidBy: 'Henry',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000),
          BillParticipant(participantId: 'p2', name: 'Henry', amount: 50000),
        ],
      );

      expect(bill.date, now);
    });

    test('Test 9: Bill ID is unique identifier', () {
      final bill = Bill(
        id: 'unique-id-123',
        title: 'Test',
        amount: 100000,
        category: 'food',
        date: DateTime.now(),
        paidBy: 'Iris',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000),
          BillParticipant(participantId: 'p2', name: 'Iris', amount: 50000),
        ],
      );

      expect(bill.id, 'unique-id-123');
    });

    test('Test 10: Bill with food category', () {
      final bill = Bill(
        id: '10',
        title: 'Dinner',
        amount: 150000,
        category: 'food',
        date: DateTime.now(),
        paidBy: 'Jack',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 75000),
          BillParticipant(participantId: 'p2', name: 'Jack', amount: 75000),
        ],
      );

      expect(bill.category, 'food');
    });

    test('Test 11: Bill with transport category', () {
      final bill = Bill(
        id: '11',
        title: 'Taxi Ride',
        amount: 80000,
        category: 'transport',
        date: DateTime.now(),
        paidBy: 'Kelly',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 40000),
          BillParticipant(participantId: 'p2', name: 'Kelly', amount: 40000),
        ],
      );

      expect(bill.category, 'transport');
    });

    test('Test 12: Bill participants have correct amounts', () {
      final participant =
          BillParticipant(participantId: 'p1', name: 'Leo', amount: 200000);

      expect(participant.amount, 200000);
    });

    test('Test 13: Multiple bills can be created independently', () {
      final bill1 = Bill(
        id: '1',
        title: 'Bill 1',
        amount: 100000,
        category: 'food',
        date: DateTime.now(),
        paidBy: 'Mona',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000),
          BillParticipant(participantId: 'p2', name: 'Mona', amount: 50000),
        ],
      );

      final bill2 = Bill(
        id: '2',
        title: 'Bill 2',
        amount: 200000,
        category: 'transport',
        date: DateTime.now(),
        paidBy: 'Nina',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 100000),
          BillParticipant(participantId: 'p2', name: 'Nina', amount: 100000),
        ],
      );

      expect(bill1.title, 'Bill 1');
      expect(bill2.title, 'Bill 2');
      expect(bill1.amount, 100000);
      expect(bill2.amount, 200000);
    });

    test('Test 14: BillParticipant participantId is correctly stored', () {
      final participant = BillParticipant(
        participantId: 'unique-p-id',
        name: 'Oscar',
        amount: 150000,
      );

      expect(participant.participantId, 'unique-p-id');
    });

    test('Test 15: Bill entity validates all acceptance criteria', () {
      final bill = Bill(
        id: 'bill-123',
        title: 'Complete Bill',
        amount: 500000,
        category: 'shopping',
        date: DateTime(2024, 9, 2),
        paidBy: 'Patricia',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 250000),
          BillParticipant(participantId: 'p2', name: 'Patricia', amount: 250000),
        ],
      );

      expect(bill.id, isNotEmpty);
      expect(bill.title, isNotEmpty);
      expect(bill.amount, greaterThan(0));
      expect(bill.category, isNotEmpty);
      expect(bill.paidBy, isNotEmpty);
      expect(bill.participants.length, greaterThanOrEqualTo(2));
    });
  });
}
