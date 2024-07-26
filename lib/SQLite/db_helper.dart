// lib/helpers/db_helper.dart

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../JsonModels/company_model.dart';


class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  static Database? _database;

  DBHelper._internal();

  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'company.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE company(
        companyId INTEGER PRIMARY KEY AUTOINCREMENT,
        companyName TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT NOT NULL,
        startDate TEXT NOT NULL,
        version TEXT NOT NULL,
        logoPath TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertCompany(CompanyModel company) async {
    Database? db = await database;
    return await db!.insert('company', company.toMap());
  }

  Future<CompanyModel?> getCompany(int id) async {
    Database? db = await database;
    List<Map<String, dynamic>> maps = await db!.query(
      'company',
      where: 'companyId = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return CompanyModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<int> updateCompany(CompanyModel company) async {
    Database? db = await database;
    return await db!.update(
      'company',
      company.toMap(),
      where: 'companyId = ?',
      whereArgs: [company.companyId],
    );
  }

  Future<int> deleteCompany(int id) async {
    Database? db = await database;
    return await db!.delete(
      'company',
      where: 'companyId = ?',
      whereArgs: [id],
    );
  }
}
