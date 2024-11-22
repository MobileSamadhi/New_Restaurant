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
      // Show an error dialog if the category name already exists
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A category with the name "$categoryName" already exists.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Add the new category if it doesn't exist
    final newCategory = CategoryModel(categoryName: categoryName);
    await DatabaseHelper.instance.addCategory(newCategory);
    _loadCategories();

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Category "$categoryName" added successfully.'),
        backgroundColor:  Color(0xFFad6c47),
      ),
    );
  }

  void _deleteCategory(int categoryId) async {
    await DatabaseHelper.instance.deleteCategory(categoryId);
    _loadCategories();

    // Show a snackbar to indicate deletion success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Category deleted successfully.'),
        backgroundColor: Color(0xFFad6c47),
      ),
    );
  }

  void _updateCategory(int categoryId, String categoryName) async {
    if (categories.any((category) => category.categoryName.toLowerCase() == categoryName.toLowerCase() && category.categoryId != categoryId)) {
      _showErrorDialog('Category already exists.');
      return;
    }
    final updatedCategory = CategoryModel(categoryId: categoryId, categoryName: categoryName);
    await DatabaseHelper.instance.updateCategory(updatedCategory);
    _loadCategories();

    // Show a snackbar to indicate update success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Category updated successfully!!'),
        backgroundColor: Color(0xFFad6c47),
      ),
    );
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
                        trailing: const Icon(Icons.edit, color: Color(0xFF470404)),
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
    // Ensure dialog uses correct context
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        String newCategory = '';
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Rounded corners for the dialog
          ),
          backgroundColor: const Color(0xFFF5F5F5), // Light gray background for the dialog
          title: const Text(
            'Add Category',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFad6c47), // Blue color for the title
            ),
          ),
          content: TextField(
            onChanged: (value) => newCategory = value,
            decoration: InputDecoration(
              hintText: 'Enter category name',
              hintStyle: const TextStyle(color: Color(0xFF757575)), // Subtle gray hint text
              filled: true,
              fillColor: Colors.white, // White background for the input
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8), // Rounded input field corners
                borderSide: const BorderSide(color: Color(0xFFBDBDBD)), // Light gray border
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFad6c47)), // Blue border when focused
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFB0BEC5), // Neutral gray button background
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Rounded corners for the button
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white, // White text color
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFad6c47), // Blue button background
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Rounded corners for the button
                ),
              ),
              onPressed: () {
                if (newCategory.isNotEmpty) {
                  _addCategory(newCategory); // Use the main `context` for `_addCategory`
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Add',
                style: TextStyle(
                  color: Colors.white, // White text color
                  fontSize: 16,
                ),
              ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Rounded corners for the dialog
          ),
          backgroundColor: const Color(0xFFF5F5F5), // Light gray background for the dialog
          title: const Text(
            'Edit Category',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFad6c47), // Blue color for the title
            ),
          ),
          content: TextField(
            onChanged: (value) => editedCategory = value,
            decoration: InputDecoration(
              hintText: 'Enter new category name',
              labelText: category.categoryName,
              labelStyle: const TextStyle(
                color: Color(0xFFad6c47), // Blue color for label text
                fontWeight: FontWeight.bold,
              ),
              hintStyle: const TextStyle(color: Color(0xFF757575)), // Subtle gray hint text
              filled: true,
              fillColor: Colors.white, // White background for the input
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8), // Rounded input field corners
                borderSide: const BorderSide(color: Color(0xFFBDBDBD)), // Light gray border
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFad6c47)), // Blue border when focused
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFB0BEC5), // Neutral gray button background
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Rounded corners for the button
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white, // White text color
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFad6c47), // Blue button background
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Rounded corners for the button
                ),
              ),
              onPressed: () {
                if (editedCategory.isNotEmpty) {
                  _updateCategory(category.categoryId!, editedCategory);
                }
                Navigator.of(context).pop();
              },
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white, // White text color
                  fontSize: 16,
                ),
              ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Rounded corners for the dialog
          ),
          backgroundColor: const Color(0xFFF7F7F7), // Light background color for the dialog
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              const Text(
                'Confirm Delete',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this category?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          actionsPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                backgroundColor: const Color(0xFFE0E0E0), // Gray button background
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.black87, // Dark text color
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                backgroundColor: Colors.red, // Red button background for "Delete"
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white, // White text color
                  fontSize: 16,
                ),
              ),
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
