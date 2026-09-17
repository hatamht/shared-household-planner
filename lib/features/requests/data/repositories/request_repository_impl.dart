import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/request_item.dart';
import '../../domain/repositories/request_repository.dart';
import '../datasources/request_local_datasource.dart';
import '../models/request_model.dart';

class RequestRepositoryImpl implements RequestRepository {
  final RequestLocalDataSource localDataSource;

  const RequestRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, RequestItem>> createRequest(RequestItem request) async {
    try {
      final model = RequestModel.fromEntity(request);
      final created = await localDataSource.createRequest(model);
      return Right(created);
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RequestItem>>> getAllRequests() async {
    try {
      final list = await localDataSource.getAllRequests();
      return Right(list);
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RequestItem>>> getRequestsByProjectId(String projectId) async {
    try {
      final list = await localDataSource.getRequestsByProjectId(projectId);
      return Right(list);
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RequestItem>> getRequestById(String id) async {
    try {
      final item = await localDataSource.getRequestById(id);
      return Right(item);
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RequestItem>> updateRequest(RequestItem request) async {
    try {
      final model = RequestModel.fromEntity(request);
      final updated = await localDataSource.updateRequest(model);
      return Right(updated);
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRequest(String id) async {
    try {
      await localDataSource.deleteRequest(id);
      return const Right(null);
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getRequestCountByProjectId(String projectId) async {
    try {
      final count = await localDataSource.getRequestCountByProjectId(projectId);
      return Right(count);
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }
}
