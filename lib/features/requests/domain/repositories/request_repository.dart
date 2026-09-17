import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/request_item.dart';

abstract class RequestRepository {
  Future<Either<Failure, RequestItem>> createRequest(RequestItem request);
  Future<Either<Failure, List<RequestItem>>> getAllRequests();
  Future<Either<Failure, List<RequestItem>>> getRequestsByProjectId(String projectId);
  Future<Either<Failure, RequestItem>> getRequestById(String id);
  Future<Either<Failure, RequestItem>> updateRequest(RequestItem request);
  Future<Either<Failure, void>> deleteRequest(String id);
  Future<Either<Failure, int>> getRequestCountByProjectId(String projectId);
}
