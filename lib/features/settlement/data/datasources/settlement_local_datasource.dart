import 'package:sqflite/sqflite.dart';
import '../models/settlement_log_model.dart';

/// Data source interface managing local SQLite storage for settlement logs.
abstract class SettlementLocalDataSource {
  Future<List<SettlementLogModel>> getSettlementLogs({String? projectId});
  Future<SettlementLogModel> getSettlementLogById(String id);
  Future<SettlementLogModel> createSettlementLog(SettlementLogModel log);
  Future<SettlementLogModel> updateSettlementLog(SettlementLogModel log);
  Future<void> deleteSettlementLog(String id);
}

class SettlementLocalDataSourceImpl implements SettlementLocalDataSource {
  final Database database;

  const SettlementLocalDataSourceImpl(this.database);

  @override
  Future<List<SettlementLogModel>> getSettlementLogs({String? projectId}) async {
    final List<Map<String, dynamic>> results;
    if (projectId != null && projectId.isNotEmpty) {
      results = await database.query(
        'settlement_logs',
        where: 'projectId = ?',
        whereArgs: [projectId],
        orderBy: 'date ASC, createdAt ASC',
      );
    } else {
      results = await database.query(
        'settlement_logs',
        orderBy: 'date ASC, createdAt ASC',
      );
    }

    return results.map((map) => SettlementLogModel.fromMap(map)).toList();
  }

  @override
  Future<SettlementLogModel> getSettlementLogById(String id) async {
    final results = await database.query(
      'settlement_logs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) {
      throw Exception('SettlementLog with id $id not found');
    }

    return SettlementLogModel.fromMap(results.first);
  }

  @override
  Future<SettlementLogModel> createSettlementLog(SettlementLogModel log) async {
    await database.insert(
      'settlement_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return log;
  }

  @override
  Future<SettlementLogModel> updateSettlementLog(SettlementLogModel log) async {
    final count = await database.update(
      'settlement_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );

    if (count == 0) {
      throw Exception('SettlementLog with id ${log.id} not found to update');
    }

    return log;
  }

  @override
  Future<void> deleteSettlementLog(String id) async {
    await database.delete(
      'settlement_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
