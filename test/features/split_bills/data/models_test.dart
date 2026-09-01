import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_planner/features/split_bills/data/models/bill_model.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';

void main() {
  final tDate = DateTime(2026, 9, 1);
  const tParticipants = [
    BillParticipant(memberId: 'member1', amount: 50.0),
    BillParticipant(memberId: 'member2', amount: 50.0),
  ];
  final tBillModel = BillModel(
    id: 'bill1',
    title: 'Dinner',
    amount: 100.0,
    category: 'Food',
    date: tDate,
    paidBy: 'member1',
    participants: tParticipants,
  );

  group('BillModel', () {
    test('should be a subclass of Bill entity', () async {
      expect(tBillModel, isA<Bill>());
    });

    test('should correctly map from JSON', () async {
      final json = {
        'id': 'bill1',
        'title': 'Dinner',
        'amount': 100.0,
        'category': 'Food',
        'date': '2026-09-01T00:00:00.000',
        'paidBy': 'member1',
        'participants': [
          {'memberId': 'member1', 'amount': 50.0},
          {'memberId': 'member2', 'amount': 50.0},
        ]
      };

      final result = BillModel.fromJson(json);

      expect(result.id, 'bill1');
      expect(result.title, 'Dinner');
      expect(result.amount, 100.0);
      expect(result.participants.length, 2);
    });

    test('should correctly convert to JSON', () async {
      final result = tBillModel.toJson();

      expect(result['id'], 'bill1');
      expect(result['title'], 'Dinner');
      expect(result['amount'], 100.0);
      expect(result['paidBy'], 'member1');
      expect((result['participants'] as List).length, 2);
    });

    test('should create model from entity', () async {
      final result = BillModel.fromEntity(tBillModel);

      expect(result, tBillModel);
    });
  });
}
