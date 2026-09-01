import 'package:sqflite/sqflite.dart';
import '../models/bill_model.dart';

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
    await database.insert(
      'bills',
      bill.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return bill;
  }

  @override
  Future<List<BillModel>> getAllBills() async {
    final maps = await database.query('bills');
    return maps.map((map) => BillModel.fromJson(map)).toList();
  }

  @override
  Future<BillModel> getBillById(String billId) async {
    final maps = await database.query(
      'bills',
      where: 'id = ?',
      whereArgs: [billId],
    );
    if (maps.isNotEmpty) {
      return BillModel.fromJson(maps.first);
    }
    throw Exception('Bill not found');
  }

  @override
  Future<BillModel> updateBill(BillModel bill) async {
    await database.update(
      'bills',
      bill.toJson(),
      where: 'id = ?',
      whereArgs: [bill.id],
    );
    return bill;
  }

  @override
  Future<void> deleteBill(String billId) async {
    await database.delete(
      'bills',
      where: 'id = ?',
      whereArgs: [billId],
    );
  }
}
