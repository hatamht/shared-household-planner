import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/bill.dart';
import '../repositories/bill_repository.dart';

class AddBillUseCase implements UseCase<Bill, AddBillParams> {
  final BillRepository repository;

  AddBillUseCase(this.repository);

  @override
  Future<Either<Failure, Bill>> call(AddBillParams params) {
    return repository.create(params.bill);
  }
}

class AddBillParams extends Equatable {
  final Bill bill;

  const AddBillParams({required this.bill});

  @override
  List<Object?> get props => [bill];
}
