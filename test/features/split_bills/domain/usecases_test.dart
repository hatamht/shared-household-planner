import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/usecases/usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';

import 'usecases_test.mocks.dart';

@GenerateMocks([BillRepository])
void main() {
  late GetBillsUseCase getBillsUseCase;
  late AddBillUseCase addBillUseCase;
  late MockBillRepository mockBillRepository;

  setUp(() {
    mockBillRepository = MockBillRepository();
    getBillsUseCase = GetBillsUseCase(mockBillRepository);
    addBillUseCase = AddBillUseCase(mockBillRepository);
  });

  final testBill = Bill(
    id: 'bill1',
    title: 'Dinner',
    amount: 100.0,
    category: 'Food',
    date: DateTime(2026, 9, 1),
    paidBy: 'member1',
    participants: const [
      BillParticipant(memberId: 'member1', amount: 50.0),
      BillParticipant(memberId: 'member2', amount: 50.0),
    ],
  );

  group('GetBillsUseCase', () {
    test('should get bills from repository', () async {
      // arrange
      when(mockBillRepository.getAll()).thenAnswer(
        (_) async => Right<Failure, List<Bill>>([testBill]),
      );

      // act
      final result = await getBillsUseCase(const NoParams());

      // assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (bills) => expect(bills, [testBill]),
      );
      verify(mockBillRepository.getAll()).called(1);
    });

    test('should return failure when repository fails', () async {
      // arrange
      when(mockBillRepository.getAll()).thenAnswer(
        (_) async => const Left<Failure, List<Bill>>(
          CacheFailure('Cache error'),
        ),
      );

      // act
      final result = await getBillsUseCase(const NoParams());

      // assert
      expect(result.isLeft(), true);
      verify(mockBillRepository.getAll()).called(1);
    });
  });

  group('AddBillUseCase', () {
    test('should add bill to repository', () async {
      // arrange
      when(mockBillRepository.create(testBill)).thenAnswer(
        (_) async => Right<Failure, Bill>(testBill),
      );

      // act
      final result = await addBillUseCase(AddBillParams(bill: testBill));

      // assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (bill) => expect(bill, testBill),
      );
      verify(mockBillRepository.create(testBill)).called(1);
    });

    test('should return failure when repository fails', () async {
      // arrange
      when(mockBillRepository.create(testBill)).thenAnswer(
        (_) async => const Left<Failure, Bill>(
          ServerFailure('Server error'),
        ),
      );

      // act
      final result = await addBillUseCase(AddBillParams(bill: testBill));

      // assert
      expect(result.isLeft(), true);
      verify(mockBillRepository.create(testBill)).called(1);
    });
  });;
}
