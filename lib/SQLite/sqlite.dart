import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:synnex_mobile/JsonModels/product_model.dart';
import 'package:synnex_mobile/JsonModels/users.dart';
import '../JsonModels/category_model.dart';
import '../JsonModels/sales_model.dart';


class DatabaseHelper {
  final databaseName = "notes.db";
  String noteTable =
      "CREATE TABLE notes (noteId INTEGER PRIMARY KEY AUTOINCREMENT, noteTitle TEXT NOT NULL, noteContent TEXT NOT NULL, notePrice REAL NOT NULL, noteCategory TEXT NOT NULL, createdAt TEXT DEFAULT CURRENT_TIMESTAMP, noteImage REAL NOT NULL)";

  //Now we must create our user table into our sqlite db

  String users =
      "CREATE TABLE users (usrId INTEGER PRIMARY KEY AUTOINCREMENT, usrName TEXT UNIQUE, usrPassword TEXT, usrPhone TEXT)";


  String salesTable =
      "CREATE TABLE sales (id INTEGER PRIMARY KEY AUTOINCREMENT, product_name TEXT NOT NULL, total_quantity INTEGER NOT NULL, total_sales REAL NOT NULL, date TEXT NOT NULL)";


  String transactionsTable =
      "CREATE TABLE transactions (id INTEGER PRIMARY KEY AUTOINCREMENT, product_name TEXT NOT NULL, total_quantity INTEGER NOT NULL, total_sales REAL NOT NULL, date TEXT NOT NULL)";


  //We are done in this section

  Future<Database> initDB() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, databaseName);

    return openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute(users);
      await db.execute(noteTable);
      await db.execute(salesTable);
      await db.execute(transactionsTable);

    });
  }


  Future<List<SalesModel>> getSalesDataInRange(String startDate, String endDate) async {
    try {
      final Database db = await initDB();
      final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT product_name, SUM(total_quantity) as total_quantity, SUM(total_sales) as total_sales, date
      FROM sales
      WHERE date BETWEEN ? AND ?
      GROUP BY product_name, date
      ''', [startDate, endDate]);

      return result.map((map) => SalesModel.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching sales data: $e');
      return [];
    }
  }

  Future<void> insertSampleData() async {
    final Database db = await initDB();
    await db.insert('sales', {
      'product_name': 'Sample Product 1',
      'total_quantity': 10,
      'total_sales': 100.0,
      'date': '2024-05-27'
    });
    await db.insert('sales', {
      'product_name': 'Sample Product 2',
      'total_quantity': 5,
      'total_sales': 50.0,
      'date': '2024-05-28'
    });
    print('Sample data inserted');
  }




  //Now we create login and sign up method
  //as we create sqlite other functionality in our previous video

  //IF you didn't watch my previous videos, check part 1 and part 2

  //Login Method
  Future<bool> login(Users user) async {
    final Database db = await initDB();

    // I forgot the password to check
    var result = await db.rawQuery(
        "select * from users where usrName = '${user.usrName}' AND usrPassword = '${user.usrPassword}'");
    if (result.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

  //Sign up

  Future<int?> signup(Users user) async {
    final Database db = await initDB();

    // Check if the user already exists
    bool userExists = await doesUserExist(user.usrName);

    if (userExists) {
      return null; // Return null if the user already exists
    } else {
      return db.insert('users', user.toMap());
    }
  }




  Future<bool> doesUserExist(String username) async {
    final Database db = await initDB();
    print("Checking username: $username"); // Debugging log
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'usrName = ?',
      whereArgs: [username],
    );
    print("User exists result: $result"); // Debugging log
    return result.isNotEmpty;
  }

  Future<bool> doesPhoneExist(String phone) async {
    final Database db = await initDB();
    final result = await db.query(
      'users',
      where: 'usrPhone = ?',
      whereArgs: [phone],
    );
    return result.isNotEmpty; // Returns true if a phone number already exists
  }





  // Method to fetch all users
  Future<List<Users>> getAllUsers() async {
    final db = await initDB();
    final List<Map<String, dynamic>> result = await db.query('users');
    return result.map((map) => Users.fromMap(map)).toList();
  }

  // Method to delete a user by ID
  Future<void> deleteUserById(int id) async {
    final db = await initDB();
    await db.delete('users', where: 'usrId = ?', whereArgs: [id]);
  }


  //Search Method
  Future<List<NoteModel>> searchNotes(String keyword) async {
    final Database db = await initDB();
    List<Map<String, Object?>> searchResult = await db
        .rawQuery("select * from notes where noteTitle LIKE ?", ["%$keyword%"]);
    return searchResult.map((e) => NoteModel.fromMap(e)).toList();
  }

  //CRUD Methods

  //Create Note
  Future<int> createNote(NoteModel note) async {
    final Database db = await initDB();
    return db.insert('notes', note.toMap());
  }

  //Get notes
  Future<List<NoteModel>> getNotes() async {
    final Database db = await initDB();
    List<Map<String, Object?>> result = await db.query('notes');
    return result.map((e) => NoteModel.fromMap(e)).toList();
  }

  //Delete Notes
  Future<int> deleteNote(int id) async {
    final Database db = await initDB();
    return db.delete('notes', where: 'noteId = ?', whereArgs: [id]);
  }

  //Update Notes
  Future<int> updateNote(title, content, price, noteId) async {
    final Database db = await initDB();
    return db.rawUpdate(
      'update notes set noteTitle = ?, noteContent = ?, notePrice = ? where noteId = ?',
      [title, content, price, noteId],
    );
  }

  Future<List<NoteModel>> getNotesByCategory(String category) async {
    final Database db = await initDB();
    if (category == "All") {
      // Fetch all notes if the category is "All"
      return getNotes();
    } else {
      // Fetch notes filtered by category
      List<Map<String, dynamic>> result = await db.query('notes', where: 'noteCategory = ?', whereArgs: [category]);
      return result.map((e) => NoteModel.fromMap(e)).toList();
    }
  }

  Future<List<NoteModel>> searchNotesByCategory(String keyword, String category) async {
    final Database db = await initDB();
    if (category == "All") {
      // Search all notes if the category is "All"
      List<Map<String, dynamic>> result = await db.rawQuery(
          "SELECT * FROM notes WHERE noteTitle LIKE ? OR noteContent LIKE ?",
          ["%$keyword%", "%$keyword%"]);
      return result.map((e) => NoteModel.fromMap(e)).toList();
    } else {
      // Search notes filtered by category
      List<Map<String, dynamic>> result = await db.rawQuery(
          "SELECT * FROM notes WHERE (noteTitle LIKE ? OR noteContent LIKE ?) AND noteCategory = ?",
          ["%$keyword%", "%$keyword%", category]);
      return result.map((e) => NoteModel.fromMap(e)).toList();
    }
  }

  // category data

  static Database? _database;
  static final _dbName = "synnex.db";
  static final _categoryTable = "categories";

  // Singleton DatabaseHelper1
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Default constructor
  DatabaseHelper();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_categoryTable (
        categoryId INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryName TEXT
      )
    ''');
  }

  Future<int> addCategory(CategoryModel category) async {
    Database db = await instance.database;
    return await db.insert(_categoryTable, category.toMap());
  }

  Future<List<CategoryModel>> getCategories() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(_categoryTable);
    return List.generate(maps.length, (i) {
      return CategoryModel(
        categoryId: maps[i]['categoryId'],
        categoryName: maps[i]['categoryName'],
      );
    });
  }

  Future<int> updateCategory(CategoryModel category) async {
    Database db = await instance.database;
    return await db.update(
      _categoryTable,
      category.toMap(),
      where: 'categoryId = ?',
      whereArgs: [category.categoryId],
    );
  }

  Future<int> deleteCategory(int categoryId) async {
    Database db = await instance.database;
    return await db.delete(
      _categoryTable,
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
  }



}
