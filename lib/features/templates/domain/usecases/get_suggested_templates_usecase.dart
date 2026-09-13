import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/bill_template.dart';
import '../repositories/bill_template_repository.dart';

class GetSuggestedTemplatesUseCase {
  final BillTemplateRepository repository;

  GetSuggestedTemplatesUseCase(this.repository);

  Future<Either<Failure, List<BillTemplate>>> call({String? projectId, int limit = 3}) {
    return repository.getSuggestedTemplates(projectId: projectId, limit: limit);
  }
}
