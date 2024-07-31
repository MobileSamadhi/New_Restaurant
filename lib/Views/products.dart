import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:synnex_mobile/JsonModels/product_model.dart';
import 'package:synnex_mobile/SQLite/add_product_db.dart';
import 'package:synnex_mobile/Views/add_product.dart';
import 'package:synnex_mobile/Views/product_category.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../JsonModels/add_product_model.dart';
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
    return handler.getProducts();
  }

  Future<List<AddProductModel>> filterProductsByCategory() async {
    if (selectedCategory == null || selectedCategory == 'All') {
      return getAllProducts();
    } else {
      return handler.getProducts();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      products = filterProductsByCategory();
    });
  }

  void fetchCategories() async {
    try {
      final fetchedCategories = await db.getProducts();
      setState(() {
        categories = ['All', ...fetchedCategories.map((category) => category.noteCategory)];
        selectedCategory = categories.isNotEmpty ? categories[0] : 'All';
      });
      print("Fetched categories: $categories");
    } catch (e) {
      print("Error fetching categories: $e");
    }
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
        backgroundColor: Color(0xFF0072BC),
        title: Text(
          "Products",
          style: GoogleFonts.poppins(
            fontSize: 22, // Adjust the font size as needed
            fontWeight: FontWeight.bold, // Adjust the font weight as needed
            color: Color(0xFFE0FFFF), // Adjust the text color as needed
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white,),
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
            icon: const Icon(Icons.category, color: Colors.white,),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BillingPage()),
              );
            },
            icon: const Icon(Icons.receipt, color: Colors.white,),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProduct()),
          ).then((value) {
            if (value == true) {
              _refresh();
            }
          });
        },
        child: const Icon(Icons.add, color: Colors.white,),
        backgroundColor: Color(0xFF2874A6),
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
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Color(0xFF414042)),
                  hintText: "Search",
                  hintStyle: TextStyle(color: Color(0xFF414042)),
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
                      String category = items[index].noteCategory.toLowerCase();
                      String imagePath;

                      // Set image path based on the category or the saved image
                      if (items[index].noteImage != null && items[index].noteImage!.isNotEmpty) {
                        imagePath = items[index].noteImage!;
                      } else {
                        switch (category) {
                          case 'clothes':
                            imagePath = 'lib/assets/tshirt.jpg';
                            break;
                          case 'furnitures':
                            imagePath = 'lib/assets/furniture.jpg';
                            break;
                          case 'biscuits':
                            imagePath = 'lib/assets/biscuit.jpg';
                            break;
                          case 'soaps':
                            imagePath = 'lib/assets/soap.jpg';
                            break;
                          default:
                            imagePath = 'lib/assets/product.png';
                            break;
                        }
                      }

                      return Card(
                        color: Color(0xFFAED6F1),
                        elevation: 3,
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: imagePath.startsWith('lib/assets/')
                                ? AssetImage(imagePath)
                                : FileImage(File(imagePath)) as ImageProvider,
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
                                icon: const Icon(Icons.edit, color: Color(0xFF0072BC)),
                                onPressed: () {
                                  setState(() {
                                    title.text = items[index].noteTitle;
                                    content.text = items[index].noteContent;
                                    price.text = items[index].notePrice.toString();
                                  });
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        actions: [
                                          Row(
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  db.updateProduct(AddProductModel(
                                                    noteId: items[index].noteId,
                                                    noteTitle: title.text,
                                                    noteContent: content.text,
                                                    notePrice: double.parse(price.text),
                                                    noteCategory: items[index].noteCategory,
                                                    date: items[index].date,
                                                    time: items[index].time,
                                                    noteStock: items[index].noteStock,
                                                    saleStock: items[index].saleStock,
                                                    availableStock: items[index].availableStock,
                                                    noteImage: items[index].noteImage,
                                                  )).whenComplete(() {
                                                    _refresh();
                                                    Navigator.pop(context);
                                                  });
                                                },
                                                child: const Text("Update"),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text("Cancel"),
                                              ),
                                            ],
                                          ),
                                        ],
                                        title: const Text("Update Product"),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextFormField(
                                              controller: title,
                                              validator: (value) {
                                                if (value!.isEmpty) {
                                                  return "Product Name is required";
                                                }
                                                return null;
                                              },
                                              decoration: const InputDecoration(
                                                labelText: "Product Name",
                                              ),
                                            ),
                                            TextFormField(
                                              controller: content,
                                              validator: (value) {
                                                if (value!.isEmpty) {
                                                  return "Quantity is required";
                                                }
                                                return null;
                                              },
                                              decoration: const InputDecoration(
                                                labelText: "Quantity",
                                              ),
                                            ),
                                            TextFormField(
                                              controller: price,
                                              validator: (value) {
                                                if (value!.isEmpty) {
                                                  return "Price is required";
                                                }
                                                return null;
                                              },
                                              keyboardType: TextInputType.number,
                                              decoration: const InputDecoration(
                                                labelText: "Price",
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Color(0xFF414042)), // Delete icon color
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text("Delete Item"),
                                        content: Text("Are you sure you want to delete this Item?"),
                                        actions: <Widget>[
                                          TextButton( // Changed FlatButton to TextButton
                                            child: Text("Cancel"),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          TextButton( // Changed FlatButton to TextButton
                                            child: Text("Delete"),
                                            onPressed: () {
                                              db.deleteProduct(items[index].noteId!).whenComplete(() {
                                                _refresh();
                                              });
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),

                            ],
                          ),
                          onTap: () {
                            // Add your existing onTap functionality here if needed
                          },
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



