import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../repositories/bill_template_repository.dart';

class RecordTemplateUsageUseCase {
  final BillTemplateRepository repository;

  RecordTemplateUsageUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.recordTemplateUsage(id);
  }
}
