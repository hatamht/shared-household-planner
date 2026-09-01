import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/bill.dart';
import '../repositories/bill_repository.dart';

class GetBillsUseCase implements UseCase<List<Bill>, NoParams> {
  final BillRepository repository;

  GetBillsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Bill>>> call(NoParams params) {
    return repository.getAll();
  }
}
