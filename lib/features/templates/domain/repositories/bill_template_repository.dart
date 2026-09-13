import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/bill_template.dart';

abstract class BillTemplateRepository {
  Future<Either<Failure, List<BillTemplate>>> getTemplates({String? projectId});
  Future<Either<Failure, BillTemplate>> getTemplateById(String id);
  Future<Either<Failure, BillTemplate>> createTemplate(BillTemplate template);
  Future<Either<Failure, BillTemplate>> updateTemplate(BillTemplate template);
  Future<Either<Failure, void>> deleteTemplate(String id);
  Future<Either<Failure, List<BillTemplate>>> getFavoriteTemplates({String? projectId});
  Future<Either<Failure, List<BillTemplate>>> getSuggestedTemplates({String? projectId, int limit = 3});
  Future<Either<Failure, void>> recordTemplateUsage(String id);
  Future<Either<Failure, BillTemplate>> toggleFavorite(String id);
  Future<Either<Failure, BillTemplate>> toggleFavoriteTemplate(String id);
}
