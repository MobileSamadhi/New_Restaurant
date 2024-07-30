import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class CartDatabaseHelper {
  static Database? _database;
  static final String tableName = 'cart';

  Future<Database> get database async {
    if (_database != null) return _database!;
    // If _database is null, initialize it
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    // Get the directory for the app's database
    final String path = join(await getDatabasesPath(), 'cart_database.db');

    // Open/create the database at a given path
    return openDatabase(path, version: 1, onCreate: (Database db, int version) async {
      // Create the cart table
      await db.execute('''
        CREATE TABLE $tableName(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          productId INTEGER,
          billId INTEGER,
          productName TEXT,
          quantity INTEGER,
          price REAL,
          date TEXT,
          time TEXT
        )
      ''');
    });
  }

  // Get all cart products from the database
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    Database db = await database;
    return await db.query(tableName);
  }

  // Delete a cart product from the database
  Future<int> deleteProduct(int id) async {
    Database db = await database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertProduct(Map<String, dynamic> product) async {
    Database db = await database;
    DateTime now = DateTime.now();
    product['date'] = DateFormat('yyyy-MM-dd').format(now); // Format: YYYY-MM-DD
    product['time'] = DateFormat('HH:mm').format(now); // Format: HH:MM:SS
    return await db.insert(tableName, product);
  }

  Future<int> updateProduct(Map<String, dynamic> product) async {
    Database db = await database;
    DateTime now = DateTime.now();
    product['date'] = DateFormat('yyyy-MM-dd').format(now); // Format: YYYY-MM-DD
    product['time'] = DateFormat('HH:mm').format(now); // Format: HH:MM
    return await db.update(tableName, product, where: 'id = ?', whereArgs: [product['id']]);
  }

  Future<List<Map<String, dynamic>>> getCartItems({required String startDate, required String endDate}) async {
    Database db = await database;
    return await db.rawQuery('''
    SELECT * FROM cart 
    WHERE date BETWEEN ? AND ?
  ''', [startDate, endDate]);
  }


  Future<int> getLatestBillNumber() async {
    final db = await database;
    final result = await db.rawQuery('SELECT billId FROM cart ORDER BY billId DESC LIMIT 1');
    if (result.isNotEmpty) {
      return result.first['billId'] as int;
    } else {
      return 0; // No bills found, start with 0
    }
  }

  Future<void> insertPayment( ) async {
    // Insert payment method
    final db = await database;
    await db.insert('payments', {/* payment details */});
  }
}
