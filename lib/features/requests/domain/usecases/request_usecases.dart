import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/request_item.dart';
import '../repositories/request_repository.dart';

class CreateRequestUseCase {
  final RequestRepository repository;

  const CreateRequestUseCase(this.repository);

  Future<Either<Failure, RequestItem>> call(RequestItem request) {
    return repository.createRequest(request);
  }
}

class GetAllRequestsUseCase {
  final RequestRepository repository;

  const GetAllRequestsUseCase(this.repository);

  Future<Either<Failure, List<RequestItem>>> call() {
    return repository.getAllRequests();
  }
}

class GetRequestsByProjectIdUseCase {
  final RequestRepository repository;

  const GetRequestsByProjectIdUseCase(this.repository);

  Future<Either<Failure, List<RequestItem>>> call(String projectId) {
    return repository.getRequestsByProjectId(projectId);
  }
}

class GetRequestByIdUseCase {
  final RequestRepository repository;

  const GetRequestByIdUseCase(this.repository);

  Future<Either<Failure, RequestItem>> call(String id) {
    return repository.getRequestById(id);
  }
}

class UpdateRequestUseCase {
  final RequestRepository repository;

  const UpdateRequestUseCase(this.repository);

  Future<Either<Failure, RequestItem>> call(RequestItem request) {
    return repository.updateRequest(request);
  }
}

class DeleteRequestUseCase {
  final RequestRepository repository;

  const DeleteRequestUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.deleteRequest(id);
  }
}

class GetRequestCountUseCase {
  final RequestRepository repository;

  const GetRequestCountUseCase(this.repository);

  Future<Either<Failure, int>> call(String projectId) {
    return repository.getRequestCountByProjectId(projectId);
  }
}
