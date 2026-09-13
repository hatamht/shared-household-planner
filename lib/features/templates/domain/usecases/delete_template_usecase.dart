import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../repositories/bill_template_repository.dart';

class DeleteTemplateUseCase {
  final BillTemplateRepository repository;

  DeleteTemplateUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.deleteTemplate(id);
  }
}
