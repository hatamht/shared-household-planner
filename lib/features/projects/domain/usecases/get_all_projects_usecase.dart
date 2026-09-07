import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/project.dart';
import '../repositories/project_repository.dart';

class GetAllProjectsUseCase implements UseCase<List<Project>, NoParams> {
  final ProjectRepository repository;

  GetAllProjectsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Project>>> call(NoParams params) {
    return repository.getAll();
  }
}
