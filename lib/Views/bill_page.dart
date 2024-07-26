import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:synnex_mobile/Views/payment_page.dart';
import 'package:synnex_mobile/Views/print_bill.dart';
import 'package:synnex_mobile/Views/report.dart';
import '../JsonModels/add_product_model.dart';
import '../SQLite/cart_db.dart';
import '../SQLite/sqlite.dart'; // Import your SQLite database helper
import 'dashboard.dart';
import '../JsonModels/category_model.dart';
import '../SQLite/add_product_db.dart'; // AddProductDb import

class BillingPage extends StatefulWidget {
  @override
  _BillingPageState createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  static int billCounter = 1;
  late String billNumber;
  late int billId;
  late Future<List<AddProductModel>> products; // Use AddProductModel
  List<AddProductModel> filteredProducts = []; // Use AddProductModel
  List<Map<String, dynamic>> cart = []; // List to hold cart items with quantities
  double discount = 0.0; // Variable to hold the discount value
  TextEditingController productSearchController = TextEditingController();
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    billNumber = billCounter.toString();
    billId = billCounter; // Initialize billId
    products = AddProductDb().getProducts(); // Fetch the products from SQLite database
    products.then((productList) {
      setState(() {
        filteredProducts = productList; // Initialize filteredProducts with all products
      });
    });
    productSearchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    productSearchController.dispose();
    super.dispose();
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
              title: Text('Product Added'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${product.noteTitle} has been added to the cart.'),
                  Text('Quantity: $quantity'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          if (quantity > 1) {
                            setState(() {
                              quantity--;
                            });
                          }
                        },
                      ),
                      Text('$quantity'),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          if (quantity < product.availableStock) {
                            setState(() {
                              quantity++;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Cannot add more than available stock.'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (quantity > product.availableStock) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Cannot add more than available stock.'),
                        ),
                      );
                    } else {
                      setState(() {
                        cart.add({
                          'product': product,
                          'quantity': quantity,
                        });

                        // Update the saleStock and availableStock
                        product.saleStock += quantity;
                        product.availableStock = product.noteStock - product.saleStock;

                        // Update the product in the database
                        AddProductDb().updateProduct(product);
                      });
                      Navigator.of(context).pop();
                      updateSummary(); // Update the summary whenever a product is added
                      CartDatabaseHelper().insertProduct({
                        'productId': product.noteId,
                        'billId': billId, // Add the billId here
                        'productName': product.noteTitle,
                        'quantity': quantity,
                        'price': product.notePrice,
                      }); // Insert the product into the SQLite database
                    }
                  },
                  child: Text('Add to Cart'),
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
          billNumber: billNumber, // Pass billNumber
          cart: cart, // Pass cart
          discount: discount, // Pass discount
          grossAmount: calculateGrossAmount(cart), // Pass grossAmount
          user: 'Admin', // Pass user (you can change this value accordingly)
        ),
      ),
    ).then((value) {
      if (value == true) {
        setState(() {
          billCounter++; // Increment bill counter only after successful payment
          billNumber = billCounter.toString();
          billId = billCounter;
          cart.clear(); // Clear the cart
          discount = 0.0; // Reset discount
          productSearchController.clear(); // Clear the search field
          selectedCategory = null; // Reset category selection
          products = AddProductDb().getProducts(); // Refresh products
          filteredProducts = []; // Clear filtered products
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SalesSummaryPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bill Page',
          style: GoogleFonts.poppins(
            fontSize: 22, // Adjust the font size as needed
            fontWeight: FontWeight.bold, // Adjust the font weight as needed
            color: Color(0xFFE0FFFF), // Adjust the text color as needed
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
        backgroundColor: Color(0xFF0072BC),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0072BC)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: buildTextField('Bill Number', initialValue: billNumber, readOnly: true)),
              const SizedBox(width: 10),
            ],
          ),
          const SizedBox(height: 10),
          buildTextField('Name'),
          const SizedBox(height: 10),
          buildTextField('Location'),
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
        labelStyle: TextStyle(color: Color(0xFF0072BC)), // Label color
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0072BC)), // Border color
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0072BC)), // Focused border color
        ),
      ),
      controller: TextEditingController(text: initialValue),
      onChanged: onChanged,
    );
  }

  Widget buildProductsContainer() {
    return Container(
      height: 500, // Set the height of the container
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0072BC)),
          ),
          const SizedBox(height: 10),
          buildProductSearchBar(),
          const SizedBox(height: 10),
          buildCategoryDropdown(),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<AddProductModel>>(
              future: products, // Use AddProductModel
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
                            addToCart(product); // Use AddProductModel
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
          color: Colors.blue[50], // Light blue background
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Display the product image
            CircleAvatar(
              backgroundImage: imagePath.startsWith('lib/assets/')
                  ? AssetImage(imagePath)
                  : FileImage(File(imagePath)) as ImageProvider,
            ),
            // Add space between the image and name
            const SizedBox(width: 15),
            // Display the product name
            Expanded(
              flex: 3,
              child: Text(
                name,
                style: const TextStyle(fontSize: 16, color: Color(0xFF0072BC)),
              ),
            ),
            // Add space between the name and price
            const SizedBox(width: 6),
            // Display the product price
            Expanded(
              flex: 1,
              child: Text(
                '$price',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 16, color: Color(0xFF0072BC)),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0072BC)),
          ),
          const SizedBox(height: 10),
          ...cart.map((item) {
            return buildSummaryRow(
              '${item['product'].noteTitle} x${item['quantity']}',
              '${(item['product'].notePrice * item['quantity']).toStringAsFixed(2)}',
            );
          }).toList(),
          const Divider(),
          buildSummaryRow('Gross Amount', '${grossAmount.toStringAsFixed(2)}'),
          buildSummaryRow('Discount', '-${discount.toStringAsFixed(2)}'),
          buildSummaryRow('Net Amount', '${netAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              labelText: 'Discount',
              labelStyle: TextStyle(color: Color(0xFF0072BC)),
              border: OutlineInputBorder(),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF0072BC)),
              ),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              setState(() {
                discount = double.tryParse(value) ?? 0.0;
              });
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    handlePayBill(netAmount); // Use the updated method
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Pay Bill'),
                ),
              ),
              const SizedBox(width: 10),
            ],
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
          Text(label, style: const TextStyle(fontSize: 16, color: Color(0xFF0072BC))),
          Text(value, style: const TextStyle(fontSize: 16, color: Color(0xFF0072BC))),
        ],
      ),
    );
  }
}
