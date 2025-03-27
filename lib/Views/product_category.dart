import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../JsonModels/category_model.dart';
import '../SQLite/sqlite.dart';
import 'dashboard.dart';

class ProductCategoryPage extends StatefulWidget {
  const ProductCategoryPage({Key? key}) : super(key: key);

  @override
  _ProductCategoryPageState createState() => _ProductCategoryPageState();
}

class _ProductCategoryPageState extends State<ProductCategoryPage> {
  List<CategoryModel> categories = [];
  bool showActiveOnly = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() async {
    final categoriesFromDb = await DatabaseHelper.instance.getCategories(activeOnly: showActiveOnly);
    setState(() {
      categories = categoriesFromDb;
    });
  }

  void _addCategory(String categoryName) async {
    if (categories.any((category) =>
    category.categoryName.toLowerCase() == categoryName.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A category with the name "$categoryName" already exists.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newCategory = CategoryModel(categoryName: categoryName, isActive: true);
    await DatabaseHelper.instance.addCategory(newCategory);
    _loadCategories();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Category "$categoryName" added successfully.'),
        backgroundColor: const Color(0xFFad6c47),
      ),
    );
  }

  void _deleteCategory(int categoryId) async {
    await DatabaseHelper.instance.deleteCategory(categoryId);
    _loadCategories();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Category deleted successfully.'),
        backgroundColor: const Color(0xFFad6c47),
      ),
    );
  }

  void _updateCategory(CategoryModel category, String newName) async {
    if (categories.any((c) =>
    c.categoryName.toLowerCase() == newName.toLowerCase() &&
        c.categoryId != category.categoryId)) {
      _showErrorDialog('Category already exists.');
      return;
    }

    final updatedCategory = category.copyWith(categoryName: newName);
    await DatabaseHelper.instance.updateCategory(updatedCategory);
    _loadCategories();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Category updated successfully!!'),
        backgroundColor: const Color(0xFFad6c47),
      ),
    );
  }

  Future<void> _toggleCategoryStatus(CategoryModel category) async {
    final updatedCategory = category.copyWith(isActive: !category.isActive);
    await DatabaseHelper.instance.updateCategory(updatedCategory);
    _loadCategories();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Category ${updatedCategory.isActive ? 'activated' : 'deactivated'}'),
        backgroundColor: const Color(0xFFad6c47),
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
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFE0FFFF),
          ),
        ),
        backgroundColor: const Color(0xFF470404),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Show Active Only:',
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  const SizedBox(width: 10),
                  Switch(
                    value: showActiveOnly,
                    onChanged: (value) {
                      setState(() {
                        showActiveOnly = value;
                        _loadCategories();
                      });
                    },
                    activeColor: const Color(0xFF470404),
                  ),
                  const Spacer(),
                  Chip(
                    backgroundColor: const Color(0xFF470404),
                    label: Text(
                      '${categories.length} ${categories.length == 1 ? 'Category' : 'Categories'}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
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
                      color: category.isActive
                          ? const Color(0xFFDAB3AC)
                          : Colors.grey[300],
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        title: Text(
                          category.categoryName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: category.isActive ? Colors.black : Colors.grey[700],
                          ),
                        ),
                        leading: IconButton(
                          icon: Icon(
                            category.isActive ? Icons.toggle_on : Icons.toggle_off,
                            color: category.isActive ? Colors.green : Colors.red,
                            size: 30,
                          ),
                          onPressed: () => _toggleCategoryStatus(category),
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
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF470404),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Add Category',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFad6c47),
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter category name',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFad6c47)),
            ),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFB0BEC5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFad6c47),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _addCategory(controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text(
              'Add',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(CategoryModel category) {
    final controller = TextEditingController(text: category.categoryName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Edit Category',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFad6c47),
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Category Name',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFad6c47)),
            ),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFB0BEC5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFad6c47),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _updateCategory(category, controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(int categoryId) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15)),
        backgroundColor: const Color(0xFFF7F7F7),
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Confirm Delete',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this category?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFE0E0E0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}