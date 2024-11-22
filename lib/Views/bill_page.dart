import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../SQLite/cart_db.dart'; // Ensure you have this import
import '../SQLite/add_product_db.dart'; // AddProductDb import
import '../JsonModels/add_product_model.dart';
import '../JsonModels/category_model.dart';
import '../SQLite/sqlite.dart';
import 'payment_page.dart';
import 'print_bill.dart';
import 'dashboard.dart';
import 'report.dart';

class BillingPage extends StatefulWidget {
  @override
  _BillingPageState createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  late Future<void> _initializationFuture;
  late String billNumber;
  late int billId;
  late Future<List<AddProductModel>> products;
  List<AddProductModel> filteredProducts = [];
  List<Map<String, dynamic>> cart = [];
  double discount = 0.0;
  TextEditingController productSearchController = TextEditingController();
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeBillNumber();
    products = AddProductDb().getProducts();
    products.then((productList) {
      setState(() {
        filteredProducts = productList;
      });
    });
    productSearchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    productSearchController.dispose();
    super.dispose();
  }

  Future<void> _initializeBillNumber() async {
    final dbCartHelper = CartDatabaseHelper();
    int latestBillNumber = await dbCartHelper.getLatestBillNumber();
    setState(() {
      billNumber = (latestBillNumber + 1).toString();
      billId = latestBillNumber + 1;
    });
  }

  void _filterProducts() {
    products.then((productList) {
      setState(() {
        filteredProducts = productList.where((product) {
          final matchesCategory = selectedCategory == null || selectedCategory == product.noteCategory;
          final matchesSearch = product.noteTitle.toLowerCase().contains(productSearchController.text.toLowerCase());
          return matchesCategory && matchesSearch;
        }).toList();
      });
    });
  }

  double calculateGrossAmount(List<Map<String, dynamic>> cart) {
    return cart.fold(0, (sum, item) => sum + (item['product'].notePrice * item['quantity']));
  }

  double calculateNetAmount(List<Map<String, dynamic>> cart, double discount) {
    double grossAmount = calculateGrossAmount(cart);
    return grossAmount - discount;
  }

  void addToCart(AddProductModel product) {
    int quantity = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15), // Rounded corners
              ),
              backgroundColor: const Color(0xFFF9F9F9), // Light background color
              title: Row(
                children: [
                  Icon(Icons.shopping_cart, color: Color(0xFF470404)),
                  SizedBox(width: 8),
                  const Text(
                    'Product Added',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF470404), // Dark primary color
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${product.noteTitle} has been added to the cart.',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF414042), // Neutral text color
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Quantity: $quantity',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF414042),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(8),
                            backgroundColor: Colors.redAccent,
                          ),
                          onPressed: () {
                            if (quantity > 1) {
                              setState(() {
                                quantity--;
                              });
                            }
                          },
                          child: const Icon(Icons.remove, color: Colors.white),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '$quantity',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF470404),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(8),
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            setState(() {
                              quantity++;
                            });
                          },
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey, // Cancel button color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF470404), // Add to Cart button color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          bool productExists = false;
                          for (var item in cart) {
                            if (item['product'].noteId == product.noteId) {
                              item['quantity'] += quantity;
                              productExists = true;
                              break;
                            }
                          }
                          if (!productExists) {
                            cart.add({
                              'product': product,
                              'quantity': quantity,
                            });
                          }
                        });
                        Navigator.of(context).pop();
                        updateSummary(); // Update the summary whenever a product is added

                        double grossAmount = product.notePrice * quantity;
                        double netAmount = grossAmount - discount;

                        CartDatabaseHelper().insertProduct({
                          'productId': product.noteId,
                          'billId': billId,
                          'productName': product.noteTitle,
                          'quantity': quantity,
                          'price': product.notePrice,
                          'grossAmount': grossAmount,
                          'discount': discount,
                          'netAmount': netAmount,
                        }); // Insert the product into the SQLite database
                      },
                      child: const Text(
                        'Add to Cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void updateSummary() {
    setState(() {
      // Trigger the UI update to reflect the cart changes
    });
  }

  void handlePayBill(double netAmount) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          amount: netAmount,
          billNumber: billNumber,
          cart: cart,
          discount: discount,
          grossAmount: calculateGrossAmount(cart),
          user: 'Admin',
        ),
      ),
    ).then((value) {
      if (value == true) {
        setState(() {
          _initializeBillNumber();
          cart.clear(); // Clear the cart
          discount = 0.0; // Reset discount
          productSearchController.clear(); // Clear the search field
          selectedCategory = null; // Reset category selection
          products = AddProductDb().getProducts(); // Refresh products
          filteredProducts = []; // Clear filtered products
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PrintBillPage(
              cart: cart,
              address: '117 Galle Rd, Colombo 00400',
              billNumber: billNumber,
              dateTime: DateTime.now(),
              discount: discount,
              grossAmount: calculateGrossAmount(cart),
              netAmount: netAmount,
              contactNumber: '',
              user: 'Admin',
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Bill Page',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE0FFFF),
                ),
              ),
              backgroundColor: Color(0xFF470404),
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Bill Page',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE0FFFF),
                ),
              ),
              backgroundColor: Color(0xFF470404),
            ),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Bill Page',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE0FFFF),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => DashboardPage()),
                  );
                },
              ),
              backgroundColor: Color(0xFF470404),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      buildBillInfoContainer(),
                      const SizedBox(height: 20),
                      buildProductsContainer(),
                      const SizedBox(height: 20),
                      buildBillingSummaryContainer(context),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget buildBillInfoContainer() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bill Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFad6c47)),
          ),
          const SizedBox(height: 10),
          buildTextField('Bill Number', initialValue: billNumber, readOnly: true),
          const SizedBox(height: 10),
          buildTextField('Date', initialValue: DateFormat('yyyy-MM-dd').format(DateTime.now()), readOnly: true),
        ],
      ),
    );
  }

  Widget buildTextField(String label, {String initialValue = '', bool readOnly = false, ValueChanged<String>? onChanged}) {
    return TextField(
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF470404)),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF470404)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF470404)),
        ),
      ),
      controller: TextEditingController(text: initialValue),
      onChanged: onChanged,
    );
  }

  Widget buildProductsContainer() {
    return Container(
      height: 500,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Products',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFad6c47)),
          ),
          const SizedBox(height: 10),
          buildProductSearchBar(),
          const SizedBox(height: 10),
          buildCategoryDropdown(),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<AddProductModel>>(
              future: products,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No products available');
                } else {
                  // Update filteredProducts when data is loaded
                  filteredProducts = snapshot.data!.where((product) {
                    final matchesCategory = selectedCategory == null || selectedCategory == product.noteCategory;
                    final matchesSearch = product.noteTitle.toLowerCase().contains(productSearchController.text.toLowerCase());
                    return matchesCategory && matchesSearch;
                  }).toList();
                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      children: filteredProducts.map((product) {
                        return GestureDetector(
                          onTap: () {
                            addToCart(product);
                          },
                          child: buildProductRow(product.noteTitle, product.notePrice.toString(), getProductImagePath(product)),
                        );
                      }).toList(),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProductSearchBar() {
    return TextField(
      controller: productSearchController,
      decoration: InputDecoration(
        hintText: 'Search Products',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.search),
      ),
    );
  }

  Widget buildCategoryDropdown() {
    return FutureBuilder<List<CategoryModel>>(
      future: DatabaseHelper().getCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        return DropdownButton<String>(
          hint: const Text("Select Category"),
          value: selectedCategory,
          onChanged: (String? newValue) {
            setState(() {
              selectedCategory = newValue;
              _filterProducts();
            });
          },
          items: snapshot.data!.map((CategoryModel category) {
            return DropdownMenuItem<String>(
              value: category.categoryName,
              child: Text(category.categoryName),
            );
          }).toList(),
        );
      },
    );
  }

  Widget buildProductRow(String name, String price, String imagePath) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Color(0xFFDAB3AC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundImage: imagePath.startsWith('lib/assets/')
                  ? AssetImage(imagePath)
                  : FileImage(File(imagePath)) as ImageProvider,
            ),
            const SizedBox(width: 15),
            Expanded(
              flex: 3,
              child: Text(
                name,
                style: const TextStyle(fontSize: 16, color: Color(0xFF470404)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 1,
              child: Text(
                '$price',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 16, color: Color(0xFF470404)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getProductImagePath(AddProductModel product) {
    if (product.noteImage != null && product.noteImage!.isNotEmpty) {
      return product.noteImage!;
    } else {
      switch (product.noteCategory.toLowerCase()) {
        case 'clothes':
          return 'lib/assets/tshirt.jpg';
        case 'furnitures':
          return 'lib/assets/furniture.jpg';
        case 'biscuits':
          return 'lib/assets/biscuit.jpg';
        case 'soaps':
          return 'lib/assets/soap.jpg';
        default:
          return 'lib/assets/product.png';
      }
    }
  }

  Widget buildBillingSummaryContainer(BuildContext context) {
    double grossAmount = calculateGrossAmount(cart);
    double netAmount = calculateNetAmount(cart, discount);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Billing Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFad6c47)),
          ),
          const SizedBox(height: 10),
          ...cart.map((item) {
            return buildSummaryRow(
              '${item['product'].noteTitle} x${item['quantity']}',
              '${(item['product'].notePrice * item['quantity']).toStringAsFixed(2)}',
            );
          }).toList(),
          const SizedBox(height: 10),
          const Divider(),
          buildSummaryRow('Gross Amount', '${grossAmount.toStringAsFixed(2)}'),
          buildSummaryRow('Discount', '-${discount.toStringAsFixed(2)}'),
          buildSummaryRow('Net Amount', '${netAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              labelText: 'Discount',
              labelStyle: TextStyle(color: Color(0xFF470404)),
              border: OutlineInputBorder(),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF470404)),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                discount = double.tryParse(value) ?? 0.0; // Handle discount value parsing
                updateSummary(); // Update the summary whenever discount is updated
              });
            },
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => handlePayBill(netAmount),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF470404),
              padding: EdgeInsets.symmetric(horizontal: 120.0),
            ),
            child: const Text(
              'Pay Bill',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Color(0xFF470404))),
          Text(value, style: const TextStyle(fontSize: 16, color: Color(0xFF470404))),
        ],
      ),
    );
  }
}
