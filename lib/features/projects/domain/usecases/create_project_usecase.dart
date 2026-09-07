import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/project.dart';
import '../repositories/project_repository.dart';

class CreateProjectUseCase implements UseCase<Project, CreateProjectParams> {
  final ProjectRepository repository;

  CreateProjectUseCase(this.repository);

  @override
  Future<Either<Failure, Project>> call(CreateProjectParams params) {
    return repository.create(params.project);
  }
}

class CreateProjectParams extends Equatable {
  final Project project;

  const CreateProjectParams({required this.project});

  @override
  List<Object?> get props => [project];
}
