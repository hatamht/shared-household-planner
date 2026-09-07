import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/project.dart';
import '../repositories/project_repository.dart';

class UpdateProjectUseCase implements UseCase<Project, UpdateProjectParams> {
  final ProjectRepository repository;

  UpdateProjectUseCase(this.repository);

  @override
  Future<Either<Failure, Project>> call(UpdateProjectParams params) {
    return repository.update(params.project);
  }
}

class UpdateProjectParams extends Equatable {
  final Project project;

  const UpdateProjectParams({required this.project});

  @override
  List<Object?> get props => [project];
}
