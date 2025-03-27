import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:synnex_mobi/JsonModels/product_model.dart';
import '../JsonModels/add_product_model.dart';

class AddProductDb {
  static final AddProductDb _instance = AddProductDb._internal();
  factory AddProductDb() => _instance;
  AddProductDb._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'products.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE products("
              "noteId INTEGER PRIMARY KEY AUTOINCREMENT,"
              "noteTitle TEXT,"
              "notePrice REAL,"
              "noteContent TEXT,"
              "noteCategory TEXT,"
              "date TEXT,"
              "time TEXT,"
              "noteStock INTEGER,"
              "saleStock INTEGER,"
              "availableStock INTEGER,"
              "noteImage TEXT"
              ")",
        );
      },
    );
  }

  Future<int> insertProduct(AddProductModel product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<AddProductModel>> searchProducts(String keyword) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'noteTitle LIKE ?',
      whereArgs: ['%$keyword%'],
    );
    return List.generate(maps.length, (i) {
      return AddProductModel.fromMap(maps[i]);
    });
  }

  Future<List<AddProductModel>> getProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) {
      return AddProductModel.fromMap(maps[i]);
    });
  }

  Future<int> updateProduct(AddProductModel product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'noteId = ?',
      whereArgs: [product.noteId],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      'products',
      where: 'noteId = ?',
      whereArgs: [id],
    );
  }

  Future<List<AddProductModel>> getProductsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'noteCategory = ?',
      whereArgs: [category],
    );
    return List.generate(maps.length, (i) {
      return AddProductModel.fromMap(maps[i]);
    });
  }

  // New method to update product image
  Future<int> updateProductImage(int productId, String imagePath) async {
    final db = await database;
    return await db.rawUpdate(
      'UPDATE products SET noteImage = ? WHERE noteId = ?',
      [imagePath, productId],
    );
  }

  // New method to get a single product by ID
  Future<AddProductModel?> getProductById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'noteId = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return AddProductModel.fromMap(maps.first);
    }
    return null;
  }
}