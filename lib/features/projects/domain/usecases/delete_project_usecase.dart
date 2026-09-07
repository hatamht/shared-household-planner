import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/project_repository.dart';

class DeleteProjectUseCase implements UseCase<void, DeleteProjectParams> {
  final ProjectRepository repository;

  DeleteProjectUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteProjectParams params) {
    return repository.delete(params.id);
  }
}

class DeleteProjectParams extends Equatable {
  final String id;

  const DeleteProjectParams({required this.id});

  @override
  List<Object?> get props => [id];
}
