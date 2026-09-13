import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/bill_template.dart';
import '../repositories/bill_template_repository.dart';

class CreateTemplateUseCase {
  final BillTemplateRepository repository;

  CreateTemplateUseCase(this.repository);

  Future<Either<Failure, BillTemplate>> call(BillTemplate template) {
    return repository.createTemplate(template);
  }
}
