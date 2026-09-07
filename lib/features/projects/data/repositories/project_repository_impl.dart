import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/project_local_datasource.dart';
import '../models/project_model.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectLocalDataSource localDataSource;

  ProjectRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, Project>> create(Project project) async {
    try {
      final model = ProjectModel.fromEntity(project);
      final result = await localDataSource.addProject(model);
      return Right(result);
    } catch (e) {
      return Left(LocalFailure('Failed to create project: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Project>>> getAll() async {
    try {
      final result = await localDataSource.getAllProjects();
      return Right(result);
    } catch (e) {
      return Left(LocalFailure('Failed to fetch projects: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Project>> getById(String id) async {
    try {
      final result = await localDataSource.getProjectById(id);
      return Right(result);
    } catch (e) {
      return Left(LocalFailure('Failed to fetch project: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Project>> update(Project project) async {
    try {
      final model = ProjectModel.fromEntity(project);
      final result = await localDataSource.updateProject(model);
      return Right(result);
    } catch (e) {
      return Left(LocalFailure('Failed to update project: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await localDataSource.deleteProject(id);
      return const Right(null);
    } catch (e) {
      return Left(LocalFailure('Failed to delete project: ${e.toString()}'));
    }
  }
}
