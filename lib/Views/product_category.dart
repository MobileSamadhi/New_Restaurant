import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../JsonModels/category_model.dart';
import '../SQLite/category_db.dart';
import '../SQLite/sqlite.dart';
import 'dashboard.dart';

class ProductCategoryPage extends StatefulWidget {
  ProductCategoryPage({Key? key}) : super(key: key);

  @override
  _ProductCategoryPageState createState() => _ProductCategoryPageState();
}

class _ProductCategoryPageState extends State<ProductCategoryPage> {
  List<CategoryModel> categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() async {
    final categoriesFromDb = await DatabaseHelper.instance.getCategories();
    setState(() {
      categories = categoriesFromDb;
    });
  }

  void _addCategory(String categoryName) async {
    if (categories.any((category) => category.categoryName.toLowerCase() == categoryName.toLowerCase())) {
      _showErrorDialog('Category already exists.');
      return;
    }
    final newCategory = CategoryModel(categoryName: categoryName);
    await DatabaseHelper.instance.addCategory(newCategory);
    _loadCategories();
  }

  void _deleteCategory(int categoryId) async {
    await DatabaseHelper.instance.deleteCategory(categoryId);
    _loadCategories();
  }

  void _updateCategory(int categoryId, String categoryName) async {
    if (categories.any((category) => category.categoryName.toLowerCase() == categoryName.toLowerCase() && category.categoryId != categoryId)) {
      _showErrorDialog('Category already exists.');
      return;
    }
    final updatedCategory = CategoryModel(categoryId: categoryId, categoryName: categoryName);
    await DatabaseHelper.instance.updateCategory(updatedCategory);
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Product Categories",
          style: GoogleFonts.poppins(
            fontSize: 22, // Adjust the font size as needed
            fontWeight: FontWeight.bold, // Adjust the font weight as needed
            color: Color(0xFFE0FFFF), // Adjust the text color as needed
          ),
        ),
        backgroundColor: Color(0xFF470404),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,color: Colors.white,),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage()),
            );
          },
        ),
        centerTitle: true,
        elevation: 5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Dismissible(
                    key: Key(category.categoryId.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) {
                      return _showDeleteConfirmationDialog(category.categoryId!);
                    },
                    onDismissed: (direction) {
                      _deleteCategory(category.categoryId!);
                    },
                    child: Card(
                      color: Color(0xFFDAB3AC),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        title: Text(
                          category.categoryName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF470404)),
                        onTap: () {
                          _showEditDialog(category);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddDialog();
        },
        backgroundColor: Color(0xFF470404),
        child: const Icon(Icons.add, color: Colors.white,),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newCategory = '';
        return AlertDialog(
          title: const Text('Add Category'),
          content: TextField(
            onChanged: (value) => newCategory = value,
            decoration: const InputDecoration(hintText: 'Enter category name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (newCategory.isNotEmpty) {
                  _addCategory(newCategory);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(CategoryModel category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String editedCategory = category.categoryName;
        return AlertDialog(
          title: const Text('Edit Category'),
          content: TextField(
            onChanged: (value) => editedCategory = value,
            decoration: InputDecoration(hintText: 'Enter new category name', labelText: category.categoryName),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (editedCategory.isNotEmpty) {
                  _updateCategory(category.categoryId!, editedCategory);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(int categoryId) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this category?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
