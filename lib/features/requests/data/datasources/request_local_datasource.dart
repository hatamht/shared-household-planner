import 'package:sqflite/sqflite.dart';
import '../models/request_model.dart';

abstract class RequestLocalDataSource {
  Future<List<RequestModel>> getAllRequests();
  Future<List<RequestModel>> getRequestsByProjectId(String projectId);
  Future<RequestModel> getRequestById(String id);
  Future<RequestModel> createRequest(RequestModel request);
  Future<RequestModel> updateRequest(RequestModel request);
  Future<void> deleteRequest(String id);
  Future<int> getRequestCountByProjectId(String projectId);
}

class RequestLocalDataSourceImpl implements RequestLocalDataSource {
  final Database database;

  const RequestLocalDataSourceImpl(this.database);

  @override
  Future<List<RequestModel>> getAllRequests() async {
    final results = await database.query(
      'requests',
      orderBy: 'createdAt DESC',
    );
    return results.map((map) => RequestModel.fromJson(map)).toList();
  }

  @override
  Future<List<RequestModel>> getRequestsByProjectId(String projectId) async {
    final results = await database.query(
      'requests',
      where: 'projectId = ?',
      whereArgs: [projectId],
      orderBy: 'createdAt DESC',
    );
    return results.map((map) => RequestModel.fromJson(map)).toList();
  }

  @override
  Future<RequestModel> getRequestById(String id) async {
    final results = await database.query(
      'requests',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) {
      throw Exception('Request with id $id not found');
    }

    return RequestModel.fromJson(results.first);
  }

  @override
  Future<RequestModel> createRequest(RequestModel request) async {
    await database.insert(
      'requests',
      request.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return request;
  }

  @override
  Future<RequestModel> updateRequest(RequestModel request) async {
    final count = await database.update(
      'requests',
      request.toJson(),
      where: 'id = ?',
      whereArgs: [request.id],
    );

    if (count == 0) {
      throw Exception('Failed to update request with id ${request.id}');
    }

    return request;
  }

  @override
  Future<void> deleteRequest(String id) async {
    final count = await database.delete(
      'requests',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count == 0) {
      throw Exception('Failed to delete request with id $id');
    }
  }

  @override
  Future<int> getRequestCountByProjectId(String projectId) async {
    final count = Sqflite.firstIntValue(await database.rawQuery(
      'SELECT COUNT(*) FROM requests WHERE projectId = ?',
      [projectId],
    ));
    return count ?? 0;
  }
}
