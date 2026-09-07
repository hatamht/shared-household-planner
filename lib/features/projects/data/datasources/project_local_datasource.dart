import 'package:sqflite/sqflite.dart';
import '../models/project_model.dart';

class ProjectDatabaseException implements Exception {
  final String message;
  ProjectDatabaseException(this.message);

  @override
  String toString() => 'ProjectDatabaseException: $message';
}

abstract class ProjectLocalDataSource {
  Future<ProjectModel> addProject(ProjectModel project);
  Future<List<ProjectModel>> getAllProjects();
  Future<ProjectModel> getProjectById(String id);
  Future<ProjectModel> updateProject(ProjectModel project);
  Future<void> deleteProject(String id);
}

class ProjectLocalDataSourceImpl implements ProjectLocalDataSource {
  final Database database;

  ProjectLocalDataSourceImpl(this.database);

  @override
  Future<ProjectModel> addProject(ProjectModel project) async {
    try {
      await database.insert(
        'projects',
        project.toSqliteMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return project;
    } catch (e) {
      throw ProjectDatabaseException('Failed to add project: $e');
    }
  }

  @override
  Future<List<ProjectModel>> getAllProjects() async {
    try {
      final maps = await database.query(
        'projects',
        orderBy: 'createdAt DESC',
      );
      return maps.map((map) => ProjectModel.fromJson(map)).toList();
    } catch (e) {
      throw ProjectDatabaseException('Failed to fetch projects: $e');
    }
  }

  @override
  Future<ProjectModel> getProjectById(String id) async {
    try {
      final maps = await database.query(
        'projects',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return ProjectModel.fromJson(maps.first);
      }
      throw ProjectDatabaseException('Project with id $id not found');
    } catch (e) {
      throw ProjectDatabaseException('Failed to fetch project: $e');
    }
  }

  @override
  Future<ProjectModel> updateProject(ProjectModel project) async {
    try {
      final rowsAffected = await database.update(
        'projects',
        project.toSqliteMap(),
        where: 'id = ?',
        whereArgs: [project.id],
      );
      if (rowsAffected == 0) {
        throw ProjectDatabaseException('Project with id ${project.id} not found');
      }
      return project;
    } catch (e) {
      throw ProjectDatabaseException('Failed to update project: $e');
    }
  }

  @override
  Future<void> deleteProject(String id) async {
    try {
      final rowsAffected = await database.delete(
        'projects',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rowsAffected == 0) {
        throw ProjectDatabaseException('Project with id $id not found');
      }
    } catch (e) {
      throw ProjectDatabaseException('Failed to delete project: $e');
    }
  }
}
