import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:synnex_mobi/JsonModels/product_model.dart';
import 'package:synnex_mobi/SQLite/add_product_db.dart';
import 'package:synnex_mobi/Views/add_product.dart';
import 'package:synnex_mobi/Views/product_category.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../JsonModels/add_product_model.dart';
import '../SQLite/sqlite.dart';
import 'bill_page.dart';
import 'dashboard.dart';

class Products extends StatefulWidget {
  const Products({Key? key}) : super(key: key);

  @override
  State<Products> createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  late AddProductDb handler;
  late Future<List<AddProductModel>> products;
  final db = AddProductDb();
  final database = DatabaseHelper();

  final title = TextEditingController();
  final content = TextEditingController();
  final price = TextEditingController();
  final keyword = TextEditingController();
  String? selectedCategory;
  List<String> categories = ['All'];
  File? _image;

  @override
  void initState() {
    super.initState();
    handler = AddProductDb();
    products = handler.getProducts();

    handler.database.whenComplete(() {
      setState(() {
        products = getAllProducts();
        fetchCategories();
      });
    });
  }

  Future<List<AddProductModel>> getAllProducts() {
    return handler.getProducts();
  }

  Future<List<AddProductModel>> searchProduct() {
    return handler.searchProducts(keyword.text);
  }

  Future<List<AddProductModel>> filterProductsByCategory() async {
    if (selectedCategory == null || selectedCategory == 'All') {
      return getAllProducts();
    } else {
      return handler.getProductsByCategory(selectedCategory!);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      products = filterProductsByCategory();
    });
  }

  void fetchCategories() async {
    try {
      final fetchedCategories = await database.getCategories();
      setState(() {
        categories = ['All', ...fetchedCategories.map((category) => category.categoryName)];
        selectedCategory = categories.isNotEmpty ? categories[0] : 'All';
      });
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF470404),
        title: Text(
          "Products",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE0FFFF),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage()),
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductCategoryPage()),
              );
            },
            icon: const Icon(Icons.category, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BillingPage()),
              );
            },
            icon: const Icon(Icons.receipt, color: Colors.white),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProduct()),
          ).then((value) {
            if (value == true) {
              _refresh();
            }
          });
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Product",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFFad6c47),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFFEAECEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextFormField(
                controller: keyword,
                onChanged: (value) {
                  setState(() {
                    products = value.isNotEmpty ? searchProduct() : filterProductsByCategory();
                  });
                },
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Color(0xFF414042)),
                  hintText: "Search",
                  hintStyle: TextStyle(color: Color(0xFF470404)),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: DropdownButton<String>(
                value: selectedCategory,
                isExpanded: true,
                hint: const Text("Select Category", style: TextStyle(color: Colors.black)),
                items: categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category, style: TextStyle(color: Colors.black)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue;
                    products = filterProductsByCategory();
                  });
                },
              ),
            ),
            FutureBuilder<List<AddProductModel>>(
              future: products,
              builder: (BuildContext context, AsyncSnapshot<List<AddProductModel>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasData && snapshot.data!.isEmpty) {
                  return const Center(child: Text("No data"));
                } else if (snapshot.hasError) {
                  return Text(snapshot.error.toString());
                } else {
                  final items = snapshot.data ?? <AddProductModel>[];
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      String imagePath = items[index].noteImage ?? '';

                      return Card(
                        color: Color(0xFFDAB3AC),
                        elevation: 3,
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: imagePath.isNotEmpty
                                  ? Image.file(
                                File(imagePath),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.image, size: 30, color: Colors.grey);
                                },
                              )
                                  : Icon(Icons.image, size: 30, color: Colors.grey),
                            ),
                          ),
                          subtitle: Text(
                            DateFormat("yMd").format(DateTime.parse(items[index].date)),
                            style: TextStyle(color: Color(0xFF414042)),
                          ),
                          title: Text(
                            items[index].noteTitle,
                            style: TextStyle(color: Color(0xFF414042)),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Color(0xFFad6c47)),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddProduct(productToEdit: items[index]),
                                    ),
                                  ).then((value) {
                                    if (value == true) {
                                      _refresh();
                                    }
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Color(0xFF414042)),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        backgroundColor: const Color(0xFFF9F9F9),
                                        title: Row(
                                          children: [
                                            const Icon(Icons.warning, color: Colors.red),
                                            const SizedBox(width: 8),
                                            const Text(
                                              "Delete Item",
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF470404),
                                              ),
                                            ),
                                          ],
                                        ),
                                        content: const Text(
                                          "Are you sure you want to delete this item?",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF414042),
                                          ),
                                        ),
                                        actionsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        actions: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.grey,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text(
                                              "Cancel",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () {
                                              db.deleteProduct(items[index].noteId!).whenComplete(() {
                                                _refresh();
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      "Product '${items[index].noteTitle}' deleted successfully!",
                                                      style: const TextStyle(color: Colors.white),
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }).catchError((error) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      "Failed to delete product: $error",
                                                      style: const TextStyle(color: Colors.white),
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              });
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text(
                                              "Delete",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}