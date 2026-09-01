import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_household_planner/features/split_bills/data/datasources/local_bill_datasource.dart';
import 'package:shared_household_planner/features/split_bills/data/models/bill_model.dart';
import 'package:shared_household_planner/features/split_bills/data/repositories/bill_repository_impl.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';

import 'repository_impl_test.mocks.dart';

@GenerateMocks([LocalBillDataSource])
void main() {
  late BillRepositoryImpl repository;
  late MockLocalBillDataSource mockLocalDataSource;

  setUp(() {
    mockLocalDataSource = MockLocalBillDataSource();
    repository = BillRepositoryImpl(mockLocalDataSource);
  });

  final tDate = DateTime(2026, 9, 1);
  const tParticipants = [
    BillParticipant(participantId: 'member1', name: 'John', amount: 50.0),
    BillParticipant(participantId: 'member2', name: 'John', amount: 50.0),
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

  group('BillRepositoryImpl', () {
    group('create', () {
      test('should return Bill when data source succeeds', () async {
        when(mockLocalDataSource.addBill(any)).thenAnswer(
          (_) async => tBillModel,
        );

        final result = await repository.create(tBillModel);

        expect(result.isRight(), true);
        verify(mockLocalDataSource.addBill(any)).called(1);
      });

      test('should return Failure when data source fails', () async {
        when(mockLocalDataSource.addBill(any))
            .thenThrow(Exception('Error'));

        final result = await repository.create(tBillModel);

        expect(result.isLeft(), true);
        verify(mockLocalDataSource.addBill(any)).called(1);
      });
    });

    group('getAll', () {
      test('should return List<Bill> when data source succeeds', () async {
        when(mockLocalDataSource.getAllBills()).thenAnswer(
          (_) async => [tBillModel],
        );

        final result = await repository.getAll();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (bills) => expect(bills.length, 1),
        );
        verify(mockLocalDataSource.getAllBills()).called(1);
      });

      test('should return Failure when data source fails', () async {
        when(mockLocalDataSource.getAllBills())
            .thenThrow(Exception('Error'));

        final result = await repository.getAll();

        expect(result.isLeft(), true);
        verify(mockLocalDataSource.getAllBills()).called(1);
      });
    });

    group('getById', () {
      test('should return Bill when data source succeeds', () async {
        when(mockLocalDataSource.getBillById('bill1')).thenAnswer(
          (_) async => tBillModel,
        );

        final result = await repository.getById('bill1');

        expect(result.isRight(), true);
        verify(mockLocalDataSource.getBillById('bill1')).called(1);
      });
    });

    group('update', () {
      test('should return Bill when data source succeeds', () async {
        when(mockLocalDataSource.updateBill(any)).thenAnswer(
          (_) async => tBillModel,
        );

        final result = await repository.update(tBillModel);

        expect(result.isRight(), true);
        verify(mockLocalDataSource.updateBill(any)).called(1);
      });
    });

    group('delete', () {
      test('should return void when data source succeeds', () async {
        when(mockLocalDataSource.deleteBill('bill1'))
            .thenAnswer((_) async => null);

        final result = await repository.delete('bill1');

        expect(result.isRight(), true);
        verify(mockLocalDataSource.deleteBill('bill1')).called(1);
      });
    });
  });
}
