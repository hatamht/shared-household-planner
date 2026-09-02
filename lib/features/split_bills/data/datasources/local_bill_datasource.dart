import 'package:sqflite/sqflite.dart';
import '../models/bill_model.dart';

class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}

abstract class LocalBillDataSource {
  Future<BillModel> addBill(BillModel bill);
  Future<List<BillModel>> getAllBills();
  Future<BillModel> getBillById(String billId);
  Future<BillModel> updateBill(BillModel bill);
  Future<void> deleteBill(String billId);
}

class LocalBillDataSourceImpl implements LocalBillDataSource {
  final Database database;

  LocalBillDataSourceImpl(this.database);

  @override
  Future<BillModel> addBill(BillModel bill) async {
    try {
      await database.insert(
        'bills',
        bill.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return bill;
    } on DatabaseException catch (e) {
      throw DatabaseException('Failed to add bill: ${e.message}');
    }
  }

  @override
  Future<List<BillModel>> getAllBills() async {
    try {
      final maps = await database.query('bills');
      return maps.map((map) => BillModel.fromJson(map)).toList();
    } on DatabaseException catch (e) {
      throw DatabaseException('Failed to fetch bills: ${e.message}');
    }
  }

  @override
  Future<BillModel> getBillById(String billId) async {
    try {
      final maps = await database.query(
        'bills',
        where: 'id = ?',
        whereArgs: [billId],
      );
      if (maps.isNotEmpty) {
        return BillModel.fromJson(maps.first);
      }
      throw DatabaseException('Bill with id $billId not found');
    } on DatabaseException catch (e) {
      throw DatabaseException('Failed to fetch bill: ${e.message}');
    }
  }

  @override
  Future<BillModel> updateBill(BillModel bill) async {
    try {
      final rowsAffected = await database.update(
        'bills',
        bill.toJson(),
        where: 'id = ?',
        whereArgs: [bill.id],
      );
      if (rowsAffected == 0) {
        throw DatabaseException('Bill with id ${bill.id} not found');
      }
      return bill;
    } on DatabaseException catch (e) {
      throw DatabaseException('Failed to update bill: ${e.message}');
    }
  }

  @override
  Future<void> deleteBill(String billId) async {
    try {
      final rowsAffected = await database.delete(
        'bills',
        where: 'id = ?',
        whereArgs: [billId],
      );
      if (rowsAffected == 0) {
        throw DatabaseException('Bill with id $billId not found');
      }
    } on DatabaseException catch (e) {
      throw DatabaseException('Failed to delete bill: ${e.message}');
    }
  }
}
