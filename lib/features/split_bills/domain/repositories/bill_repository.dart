import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/bill.dart';

abstract class BillRepository {
  Future<Either<Failure, Bill>> create(Bill bill);
  Future<Either<Failure, List<Bill>>> getAll();
  Future<Either<Failure, Bill>> getById(String billId);
  Future<Either<Failure, Bill>> update(Bill bill);
  Future<Either<Failure, void>> delete(String billId);
}
