import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:synnex_mobile/JsonModels/add_product_model.dart';
import 'package:synnex_mobile/SQLite/add_product_db.dart';
import 'package:synnex_mobile/SQLite/sqlite.dart';
import 'package:synnex_mobile/Views/products.dart';
import '../JsonModels/category_model.dart';
import '../JsonModels/product_model.dart';
import '../SQLite/category_db.dart';
import 'dart:io';

class AddProduct extends StatefulWidget {
  const AddProduct({Key? key}) : super(key: key);

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final title = TextEditingController();
  final content = TextEditingController();
  final price = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final database = AddProductDb();
  final db = DatabaseHelper();

  String selectedCategory = '';
  List<CategoryModel> categories = [];
  File? _image;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  void fetchCategories() async {
    categories = await DatabaseHelper().getCategories();
    setState(() {
      selectedCategory = categories.isNotEmpty ? categories[0].categoryName : '';
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF470404),
        title: Text(
          "Add Products",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE0FFFF),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Products()),
            );
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: title,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Product Name is required";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: "Product Name",
                      labelStyle: const TextStyle(color: Color(0xFF470404)),
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF470404)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: content,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Quantity is required";
                      }
                      return null;
                    },

                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1000), // Limits input to 10 characters
                    ],
                    decoration: InputDecoration(
                      labelText: "Quantity",
                      labelStyle: const TextStyle(color: Color(0xFF470404)),
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF470404)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: price,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Price is required";
                      }
                      return null;
                    },
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1000), // Limits input to 10 characters
                    ],
                    decoration: InputDecoration(
                      labelText: "Add one Item Price",
                      labelStyle: const TextStyle(color: Color(0xFF470404)),
                      suffixText: '.00', // Suffix text to display on the right side
                      suffixStyle: TextStyle(color: Colors.grey[600]),
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF470404)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category.categoryName,
                        child: Text(category.categoryName),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCategory = newValue!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Category",
                      labelStyle: const TextStyle(color: Color(0xFF470404)),
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF470404)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFad6c47),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    "Upload Image",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                _image == null
                    ? const Text('No image selected.')
                    : Image.file(_image!, height: 200, width: 200),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final product = AddProductModel(
                        noteTitle: title.text,
                        noteContent: content.text,
                        notePrice: double.parse(price.text),
                        noteCategory: selectedCategory,
                        noteImage: _image?.path ?? '', // Save image path or an empty string
                        availableStock: int.parse(content.text), // Set the available stock
                        date: DateTime.now().toIso8601String(),
                        noteStock: int.parse(content.text),
                        saleStock: 0, // Set saleStock to 0 by default
                        time: TimeOfDay.now().format(context),
                      );

                      final note = NoteModel(
                        noteTitle: title.text,
                        noteContent: content.text,
                        notePrice: double.parse(price.text),
                        createdAt: DateTime.now().toIso8601String(),
                        noteCategory: selectedCategory,
                        noteImage: _image?.path ?? '', // Save image path or an empty string
                      );

                      // Insert into both databases
                      Future.wait([
                        database.insertProduct(product),
                        db.createNote(note),
                      ]).then((_) {
                        Navigator.of(context).pop(true);
                      }).catchError((error) {
                        print("Error Adding Product/Note: $error");
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFad6c47),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    "Add Product",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
