import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/bill_template.dart';
import '../repositories/bill_template_repository.dart';

class UpdateTemplateUseCase {
  final BillTemplateRepository repository;

  UpdateTemplateUseCase(this.repository);

  Future<Either<Failure, BillTemplate>> call(BillTemplate template) {
    return repository.updateTemplate(template);
  }
}
