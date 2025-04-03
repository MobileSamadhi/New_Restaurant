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
      version: 3,
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
            user TEXT,
            isRefunded INTEGER DEFAULT 0,
            refundDate TEXT,
            refundBy TEXT,
            refundQuantity INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE refunds (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            originalBillId INTEGER,
            productId INTEGER,
            productName TEXT,
            originalQuantity INTEGER,
            refundQuantity INTEGER,
            price REAL,
            amountRefunded REAL,
            refundDate TEXT,
            refundBy TEXT,
            FOREIGN KEY (originalBillId) REFERENCES bills(id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE bills ADD COLUMN refundQuantity INTEGER DEFAULT 0');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS refunds (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              originalBillId INTEGER,
              productId INTEGER,
              productName TEXT,
              originalQuantity INTEGER,
              refundQuantity INTEGER,
              price REAL,
              amountRefunded REAL,
              refundDate TEXT,
              refundBy TEXT,
              FOREIGN KEY (originalBillId) REFERENCES bills(id)
            )
          ''');
        }
      },
    );
  }

  Future<void> insertBill(Map<String, dynamic> bill) async {
    final db = await database;
    await db.insert('bills', bill, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getBillsById(int billId) async {
    final db = await database;
    final results = await db.query(
      'bills',
      where: 'billId = ?',
      whereArgs: [billId],
    );

    return results.map((item) {
      // Safely parse values with proper type casting
      final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
      final refundQty = (item['refundQuantity'] as num?)?.toInt() ?? 0;

      return {
        ...item,
        'remainingQuantity': quantity - refundQty,
        'isFullyRefunded': refundQty >= quantity,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getAllBills() async {
    final db = await database;
    return await db.query('bills');
  }

  Future<void> updateRefundQuantity(int id, int refundQty) async {
    final db = await database;
    await db.update(
      'bills',
      {
        'refundQuantity': refundQty,
        'isRefunded': refundQty > 0 ? 1 : 0,
        'refundDate': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> addRefundRecord(Map<String, dynamic> refund) async {
    final db = await database;
    await db.insert('refunds', refund);
  }

  Future<List<Map<String, dynamic>>> getRefundHistory() async {
    final db = await database;
    return await db.query('refunds', orderBy: 'refundDate DESC');
  }

  // Helper method to safely parse numeric values
  static num? parseNumber(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }
}