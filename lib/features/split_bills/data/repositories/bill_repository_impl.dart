import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/bill.dart';
import '../../domain/repositories/bill_repository.dart';
import '../datasources/local_bill_datasource.dart';
import '../models/bill_model.dart';

class BillRepositoryImpl implements BillRepository {
  final LocalBillDataSource localDataSource;

  BillRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, Bill>> create(Bill bill) async {
    try {
      final billModel = BillModel.fromEntity(bill);
      final result = await localDataSource.addBill(billModel);
      return Right(result);
    } catch (e) {
      return Left(LocalFailure('Failed to create bill: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Bill>>> getAll() async {
    try {
      final bills = await localDataSource.getAllBills();
      return Right(bills);
    } catch (e) {
      return Left(LocalFailure('Failed to fetch bills: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Bill>> getById(String billId) async {
    try {
      final bill = await localDataSource.getBillById(billId);
      return Right(bill);
    } catch (e) {
      return Left(LocalFailure('Failed to fetch bill: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Bill>> update(Bill bill) async {
    try {
      final billModel = BillModel.fromEntity(bill);
      final result = await localDataSource.updateBill(billModel);
      return Right(result);
    } catch (e) {
      return Left(LocalFailure('Failed to update bill: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String billId) async {
    try {
      await localDataSource.deleteBill(billId);
      return const Right(null);
    } catch (e) {
      return Left(LocalFailure('Failed to delete bill: ${e.toString()}'));
    }
  }
}
