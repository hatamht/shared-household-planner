import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/project.dart';

abstract class ProjectRepository {
  Future<Either<Failure, Project>> create(Project project);
  Future<Either<Failure, List<Project>>> getAll();
  Future<Either<Failure, Project>> getById(String id);
  Future<Either<Failure, Project>> update(Project project);
  Future<Either<Failure, void>> delete(String id);
}
