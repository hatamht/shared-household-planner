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
      version: 5,
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
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE bills ADD COLUMN categoryIcon TEXT',
          );
          await db.execute(
            "ALTER TABLE bills ADD COLUMN currency TEXT DEFAULT 'VND'",
          );
          await db.execute(
            'ALTER TABLE bills ADD COLUMN imagePath TEXT',
          );
        }
        if (oldVersion < 5) {
          await db.execute(
            'ALTER TABLE bills ADD COLUMN categoryColor TEXT',
          );
          await db.execute('''
            CREATE TABLE IF NOT EXISTS categories (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              icon TEXT NOT NULL,
              colorHex TEXT NOT NULL,
              iconCodePoint INTEGER
            )
          ''');
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
        categoryIcon TEXT,
        currency TEXT DEFAULT 'VND',
        imagePath TEXT,
        categoryColor TEXT,
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        colorHex TEXT NOT NULL,
        iconCodePoint INTEGER
      )
    ''');
  }

  Future<void> updateCategoryAndBills({
    required String oldCategoryId,
    required String newName,
    required String newIcon,
    required String newColorHex,
    int? newIconCodePoint,
  }) async {
    final db = await database;
    await db.update(
      'categories',
      {
        'name': newName,
        'icon': newIcon,
        'colorHex': newColorHex,
        if (newIconCodePoint != null) 'iconCodePoint': newIconCodePoint,
      },
      where: 'id = ?',
      whereArgs: [oldCategoryId],
    );
    await db.update(
      'bills',
      {
        'categoryIcon': newIcon,
        'categoryColor': newColorHex,
      },
      where: 'category = ?',
      whereArgs: [oldCategoryId],
    );
  }

  Future<void> deleteCategoryAndMigrateBills({
    required String categoryId,
    String targetCategory = 'restaurant',
    String targetCategoryIcon = '🍽️',
    String targetCategoryColor = '#F44336',
  }) async {
    final db = await database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [categoryId],
    );
    await db.update(
      'bills',
      {
        'category': targetCategory,
        'categoryIcon': targetCategoryIcon,
        'categoryColor': targetCategoryColor,
      },
      where: 'category = ?',
      whereArgs: [categoryId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await database;
    return await db.query('categories');
  }

  Future<void> insertCategory(Map<String, dynamic> categoryJson) async {
    final db = await database;
    await db.insert('categories', categoryJson, conflictAlgorithm: ConflictAlgorithm.replace);
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
