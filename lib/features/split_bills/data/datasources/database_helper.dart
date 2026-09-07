import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'shared_household_planner.db');

    return openDatabase(
      path,
      version: 3,
      onCreate: _createTables,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS projects (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              description TEXT,
              members TEXT NOT NULL,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE bills ADD COLUMN projectId TEXT',
          );
        }
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bills (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        paidBy TEXT NOT NULL,
        participants TEXT NOT NULL,
        projectId TEXT,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS bill_participants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        billId TEXT NOT NULL,
        participantId TEXT NOT NULL,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY (billId) REFERENCES bills(id) ON DELETE CASCADE,
        UNIQUE(billId, participantId)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        members TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    _database?.close();
    _database = null;
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'shared_household_planner.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
