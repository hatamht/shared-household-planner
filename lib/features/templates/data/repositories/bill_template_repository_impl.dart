import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/bill_template.dart';
import '../../domain/repositories/bill_template_repository.dart';
import '../datasources/bill_template_local_datasource.dart';
import '../models/bill_template_model.dart';

class BillTemplateRepositoryImpl implements BillTemplateRepository {
  final BillTemplateLocalDataSource localDataSource;

  BillTemplateRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<BillTemplate>>> getTemplates({String? projectId}) async {
    try {
      final models = await localDataSource.getTemplates(projectId: projectId);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BillTemplate>> getTemplateById(String id) async {
    try {
      final model = await localDataSource.getTemplateById(id);
      return Right(model.toEntity());
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BillTemplate>> createTemplate(BillTemplate template) async {
    try {
      final model = BillTemplateModel.fromEntity(template);
      final inserted = await localDataSource.insertTemplate(model);
      return Right(inserted.toEntity());
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BillTemplate>> updateTemplate(BillTemplate template) async {
    try {
      final model = BillTemplateModel.fromEntity(template);
      final updated = await localDataSource.updateTemplate(model);
      return Right(updated.toEntity());
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTemplate(String id) async {
    try {
      await localDataSource.deleteTemplate(id);
      return const Right(null);
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BillTemplate>>> getFavoriteTemplates({String? projectId}) async {
    try {
      final models = await localDataSource.getFavoriteTemplates(projectId: projectId);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BillTemplate>>> getSuggestedTemplates({String? projectId, int limit = 3}) async {
    try {
      final models = await localDataSource.getSuggestedTemplates(projectId: projectId, limit: limit);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> recordTemplateUsage(String id) async {
    try {
      await localDataSource.recordTemplateUsage(id);
      return const Right(null);
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BillTemplate>> toggleFavorite(String id) async {
    try {
      final model = await localDataSource.toggleFavorite(id);
      return Right(model.toEntity());
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BillTemplate>> toggleFavoriteTemplate(String id) => toggleFavorite(id);
}
