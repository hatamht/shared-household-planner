import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/data/models/bill_model.dart';
import 'package:shared_household_planner/features/split_bills/data/models/bill_participant_model.dart';

void main() {
  group('Split Bills Data Layer Tests', () {
    test('Test 1: BillModel can be created from JSON', () {
      final json = {
        'id': '1',
        'title': 'Lunch',
        'amount': 100000,
        'category': 'food',
        'date': '2024-01-15T00:00:00.000Z',
        'paidBy': 'Alice',
        'participants': [
          {
            'participantId': 'p1',
            'name': 'Alice',
            'amount': 50000,
          },
          {
            'participantId': 'p2',
            'name': 'Bob',
            'amount': 50000,
          },
        ],
      };

      final billModel = BillModel.fromJson(json);

      expect(billModel.id, '1');
      expect(billModel.title, 'Lunch');
      expect(billModel.amount, 100000);
      expect(billModel.category, 'food');
    });

    test('Test 2: BillModel toJson serialization', () {
      final billModel = BillModel(
        id: '1',
        title: 'Pizza',
        amount: 150000,
        category: 'food',
        date: DateTime(2024, 1, 15),
        paidBy: 'Bob',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 75000),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 75000),
        ],
      );

      final json = billModel.toJson();

      expect(json['id'], '1');
      expect(json['title'], 'Pizza');
      expect(json['amount'], 150000);
      expect(json['category'], 'food');
    });

    test('Test 3: BillModel fromEntity factory', () {
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

      final billModel = BillModel.fromEntity(bill);

      expect(billModel.title, bill.title);
      expect(billModel.amount, bill.amount);
    });

    test('Test 4: BillParticipantModel fromJson', () {
      final json = {
        'participantId': 'p1',
        'name': 'Frank',
        'amount': 125000,
      };

      final model = BillParticipantModel.fromJson(json);

      expect(model.participantId, 'p1');
      expect(model.name, 'Frank');
      expect(model.amount, 125000);
    });

    test('Test 5: BillParticipantModel toJson', () {
      final model = BillParticipantModel(
        participantId: 'p2',
        name: 'Grace',
        amount: 200000,
      );

      final json = model.toJson();

      expect(json['participantId'], 'p2');
      expect(json['name'], 'Grace');
      expect(json['amount'], 200000);
    });

    test('Test 6: BillParticipantModel fromEntity', () {
      final participant = BillParticipant(
        participantId: 'p3',
        name: 'Henry',
        amount: 300000,
      );

      final model = BillParticipantModel.fromEntity(participant);

      expect(model.name, participant.name);
      expect(model.amount, participant.amount);
    });

    test('Test 7: BillModel with multiple participants', () {
      final billModel = BillModel(
        id: '4',
        title: 'Group Dinner',
        amount: 300000,
        category: 'food',
        date: DateTime.now(),
        paidBy: 'Iris',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 100000),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 100000),
          BillParticipant(participantId: 'p3', name: 'Iris', amount: 100000),
        ],
      );

      expect(billModel.participants.length, 3);
      expect(billModel.amount, 300000);
    });

    test('Test 8: BillModel date serialization', () {
      final date = DateTime(2024, 9, 2);
      final billModel = BillModel(
        id: '5',
        title: 'Date Test',
        amount: 100000,
        category: 'food',
        date: date,
        paidBy: 'Jack',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000),
          BillParticipant(participantId: 'p2', name: 'Jack', amount: 50000),
        ],
      );

      final json = billModel.toJson();
      final reconstructed = BillModel.fromJson(json);

      expect(reconstructed.date.year, 2024);
      expect(reconstructed.date.month, 9);
      expect(reconstructed.date.day, 2);
    });

    test('Test 9: BillModel category validation', () {
      final billModel = BillModel(
        id: '6',
        title: 'Shopping',
        amount: 250000,
        category: 'shopping',
        date: DateTime.now(),
        paidBy: 'Kelly',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 125000),
          BillParticipant(participantId: 'p2', name: 'Kelly', amount: 125000),
        ],
      );

      expect(billModel.category, 'shopping');
    });

    test('Test 10: BillModel paidBy tracking', () {
      final billModel = BillModel(
        id: '7',
        title: 'Payer Test',
        amount: 100000,
        category: 'food',
        date: DateTime.now(),
        paidBy: 'Leo',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000),
          BillParticipant(participantId: 'p2', name: 'Leo', amount: 50000),
        ],
      );

      expect(billModel.paidBy, 'Leo');
    });

    test('Test 11: BillModel with high amount', () {
      final billModel = BillModel(
        id: '8',
        title: 'Expensive',
        amount: 5000000,
        category: 'shopping',
        date: DateTime.now(),
        paidBy: 'Mona',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 2500000),
          BillParticipant(participantId: 'p2', name: 'Mona', amount: 2500000),
        ],
      );

      expect(billModel.amount, 5000000);
    });

    test('Test 12: BillParticipant serialization roundtrip', () {
      final participant = BillParticipantModel(
        participantId: 'p99',
        name: 'Nina',
        amount: 999999,
      );

      final json = participant.toJson();
      final reconstructed = BillParticipantModel.fromJson(json);

      expect(reconstructed.participantId, participant.participantId);
      expect(reconstructed.name, participant.name);
      expect(reconstructed.amount, participant.amount);
    });

    test('Test 13: BillModel all fields present', () {
      final billModel = BillModel(
        id: 'test-id-123',
        title: 'Complete Bill',
        amount: 500000,
        category: 'utilities',
        date: DateTime(2024, 9, 2),
        paidBy: 'Oscar',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 250000),
          BillParticipant(participantId: 'p2', name: 'Oscar', amount: 250000),
        ],
      );

      expect(billModel.id, isNotEmpty);
      expect(billModel.title, isNotEmpty);
      expect(billModel.amount, greaterThan(0));
      expect(billModel.category, isNotEmpty);
      expect(billModel.paidBy, isNotEmpty);
      expect(billModel.participants.length, greaterThanOrEqualTo(2));
    });

    test('Test 14: BillModel toString implementation', () {
      final billModel = BillModel(
        id: '14',
        title: 'Test Bill',
        amount: 100000,
        category: 'food',
        date: DateTime.now(),
        paidBy: 'Patricia',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000),
          BillParticipant(participantId: 'p2', name: 'Patricia', amount: 50000),
        ],
      );

      final str = billModel.toString();
      expect(str, isNotEmpty);
    });

    test('Test 15: BillModel extends Bill correctly', () {
      final billModel = BillModel(
        id: '15',
        title: 'Inheritance Test',
        amount: 100000,
        category: 'food',
        date: DateTime.now(),
        paidBy: 'Quincy',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000),
          BillParticipant(participantId: 'p2', name: 'Quincy', amount: 50000),
        ],
      );

      expect(billModel, isA<Bill>());
      expect(billModel.title, 'Inheritance Test');
    });
  });
}
