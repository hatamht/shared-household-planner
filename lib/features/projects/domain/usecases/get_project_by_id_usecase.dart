import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/project.dart';
import '../repositories/project_repository.dart';

class GetProjectByIdUseCase implements UseCase<Project, GetProjectByIdParams> {
  final ProjectRepository repository;

  GetProjectByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Project>> call(GetProjectByIdParams params) {
    return repository.getById(params.id);
  }
}

class GetProjectByIdParams extends Equatable {
  final String id;

  const GetProjectByIdParams({required this.id});

  @override
  List<Object?> get props => [id];
}
