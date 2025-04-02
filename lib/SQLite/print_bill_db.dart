import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class PrintBillDBHelper {
  static final PrintBillDBHelper _instance = PrintBillDBHelper._internal();
  factory PrintBillDBHelper() => _instance;
  PrintBillDBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bill_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE bills (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            productId INTEGER,
            billId INTEGER,
            productName TEXT,
            quantity INTEGER,
            price REAL,
            grossAmount REAL,
            discount REAL,
            totalItemDiscount REAL,
            netAmount REAL,
            date TEXT,
            time TEXT,
            user TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertBill(Map<String, dynamic> bill) async {
    final db = await database;
    await db.insert('bills', bill, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getBillsById(int billId) async {
    final db = await database;
    return await db.query(
      'bills',
      where: 'billId = ?',
      whereArgs: [billId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllBills() async {
    final db = await database;
    return await db.query('bills');
  }
}
