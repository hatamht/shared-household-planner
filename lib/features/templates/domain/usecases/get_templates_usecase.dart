import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/bill_template.dart';
import '../repositories/bill_template_repository.dart';

class GetTemplatesUseCase {
  final BillTemplateRepository repository;

  GetTemplatesUseCase(this.repository);

  Future<Either<Failure, List<BillTemplate>>> call({String? projectId}) {
    return repository.getTemplates(projectId: projectId);
  }
}
