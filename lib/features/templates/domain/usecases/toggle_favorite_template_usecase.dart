import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/bill_template.dart';
import '../repositories/bill_template_repository.dart';

class ToggleFavoriteTemplateUseCase {
  final BillTemplateRepository repository;

  ToggleFavoriteTemplateUseCase(this.repository);

  Future<Either<Failure, BillTemplate>> call(String id) {
    return repository.toggleFavorite(id);
  }
}
