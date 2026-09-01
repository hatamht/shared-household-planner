import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';

void main() {
  group('BillParticipant', () {
    test('should create BillParticipant with memberId and amount', () {
      const participant = BillParticipant(memberId: 'member1', amount: 50.0);

      expect(participant.memberId, 'member1');
      expect(participant.amount, 50.0);
    });

    test('two BillParticipants with same values should be equal', () {
      const participant1 = BillParticipant(memberId: 'member1', amount: 50.0);
      const participant2 = BillParticipant(memberId: 'member1', amount: 50.0);

      expect(participant1, participant2);
    });

    test('two BillParticipants with different values should not be equal', () {
      const participant1 = BillParticipant(memberId: 'member1', amount: 50.0);
      const participant2 = BillParticipant(memberId: 'member2', amount: 50.0);

      expect(participant1, isNot(participant2));
    });
  });

  group('Bill', () {
    test('should create Bill with all required fields', () {
      final date = DateTime.now();
      final participants = const [
        BillParticipant(memberId: 'member1', amount: 50.0),
        BillParticipant(memberId: 'member2', amount: 50.0),
      ];
      final bill = Bill(
        id: 'bill1',
        title: 'Dinner',
        amount: 100.0,
        category: 'Food',
        date: date,
        paidBy: 'member1',
        participants: participants,
      );

      expect(bill.id, 'bill1');
      expect(bill.title, 'Dinner');
      expect(bill.amount, 100.0);
      expect(bill.category, 'Food');
      expect(bill.date, date);
      expect(bill.paidBy, 'member1');
      expect(bill.participants.length, 2);
    });

    test('two Bills with same values should be equal', () {
      final date = DateTime(2026, 9, 1);
      final participants = const [
        BillParticipant(memberId: 'member1', amount: 50.0),
        BillParticipant(memberId: 'member2', amount: 50.0),
      ];

      final bill1 = Bill(
        id: 'bill1',
        title: 'Dinner',
        amount: 100.0,
        category: 'Food',
        date: date,
        paidBy: 'member1',
        participants: participants,
      );

      final bill2 = Bill(
        id: 'bill1',
        title: 'Dinner',
        amount: 100.0,
        category: 'Food',
        date: date,
        paidBy: 'member1',
        participants: participants,
      );

      expect(bill1, bill2);
    });
  });
}
