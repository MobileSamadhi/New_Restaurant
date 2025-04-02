import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../SQLite/cart_db.dart';
import '../SQLite/add_product_db.dart';
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
  double totalItemDiscounts = 0.0;
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
      billNumber = (latestBillNumber + 1).toString().padLeft(7, '0');
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

  double calculateTotalDiscount(List<Map<String, dynamic>> cart) {
    return cart.fold(0, (sum, item) => sum + (item['discount'] ?? 0.0));
  }

  double calculateNetAmount(List<Map<String, dynamic>> cart, double discount) {
    double grossAmount = calculateGrossAmount(cart);
    double totalDiscount = calculateTotalDiscount(cart) + discount;
    return grossAmount - totalDiscount;
  }

  void addToCart(AddProductModel product) {
    int quantity = 1;
    double itemDiscount = 0.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with close button
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF470404),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shopping_bag_outlined,
                              color: Colors.white,
                              size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Add to Order',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: 20),
                            color: Colors.white,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Info
                          Text(
                            product.noteTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Rs.${product.notePrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 24),

                          // Quantity Selector
                          Text('Quantity',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              )),
                          SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () {
                                    if (quantity > 1) {
                                      setState(() => quantity--);
                                    }
                                  },
                                  color: quantity > 1 ? Color(0xFF470404) : Colors.grey,
                                ),
                                Container(
                                  width: 40,
                                  alignment: Alignment.center,
                                  child: Text('$quantity',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      )),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    setState(() => quantity++);
                                  },
                                  color: Color(0xFF470404),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),

                          // Discount Field
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Discount Amount (Rs.)',
                              labelStyle: TextStyle(color: Colors.grey.shade600),
                              floatingLabelStyle: TextStyle(color: Color(0xFF470404)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFF470404)),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                itemDiscount = double.tryParse(value) ?? 0.0;
                              });
                            },
                          ),
                          SizedBox(height: 24),

                          // Summary Card
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Subtotal',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        )),
                                    Text(
                                      'Rs.${(product.notePrice * quantity).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Discount',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        )),
                                    Text(
                                      '- Rs.${itemDiscount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(height: 24, thickness: 1),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        )),
                                    Text(
                                      'Rs.${(product.notePrice * quantity - itemDiscount).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF470404),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action Buttons
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: Colors.grey.shade400),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF470404),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                // Your existing add to cart logic
                                setState(() {
                                  bool productExists = false;
                                  for (var item in cart) {
                                    if (item['product'].noteId == product.noteId) {
                                      item['quantity'] += quantity;
                                      item['discount'] =
                                          (item['discount'] ?? 0.0) + itemDiscount;
                                      productExists = true;
                                      break;
                                    }
                                  }
                                  if (!productExists) {
                                    cart.add({
                                      'product': product,
                                      'quantity': quantity,
                                      'discount': itemDiscount,
                                    });
                                  }
                                });
                                Navigator.pop(context);
                                updateSummary();

                                CartDatabaseHelper().insertProduct({
                                  'productId': product.noteId,
                                  'billId': billId,
                                  'productName': product.noteTitle,
                                  'quantity': quantity,
                                  'price': product.notePrice,
                                  'discount': itemDiscount,
                                  'netAmount':
                                  (product.notePrice * quantity) - itemDiscount,
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${product.noteTitle} added to cart!'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    backgroundColor: Color(0xFF470404),
                                    duration: Duration(seconds: 2),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 14),
                                  ),
                                );
                              },
                              child: Text('Add to Order',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void editCartItem(int index) {
    var item = cart[index];
    int quantity = item['quantity'];
    double itemDiscount = item['discount'] ?? 0.0;
    double price = item['product'].notePrice;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item['product'].noteTitle),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Quantity:'),
                      Row(
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
                              setState(() {
                                quantity++;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Item Discount (Rs.)',
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: itemDiscount.toStringAsFixed(2)),
                    onChanged: (value) {
                      itemDiscount = double.tryParse(value) ?? 0.0;
                    },
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Subtotal: Rs.${(price * quantity - itemDiscount).toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      cart[index]['quantity'] = quantity;
                      cart[index]['discount'] = itemDiscount;
                    });
                    Navigator.pop(context);
                    updateSummary();
                  },
                  child: Text('Save'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      cart.removeAt(index);
                    });
                    Navigator.pop(context);
                    updateSummary();
                  },
                  child: Text('Remove', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void updateSummary() {
    setState(() {});
  }

  void handlePayBill(double netAmount) {
    double totalItemDiscounts = calculateTotalDiscount(cart); // Calculate item discounts

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          amount: netAmount,
          billNumber: billNumber,
          cart: cart,
          discount: discount,
          totalItemDiscounts: totalItemDiscounts, // Pass the calculated item discounts
          grossAmount: calculateGrossAmount(cart),
          user: 'Admin',
          address: '',
          contactNumber: '',
        ),
      ),
    ).then((value) {
      if (value == true) {
        setState(() {
          _initializeBillNumber();
          cart.clear();
          discount = 0.0;
          productSearchController.clear();
          selectedCategory = null;
          products = AddProductDb().getProducts();
          filteredProducts = [];
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
              totalItemDiscounts: totalItemDiscounts, // Pass to PrintBillPage too
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
              title: Text('Bill Page'),
              backgroundColor: Color(0xFF470404),
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Bill Page'),
              backgroundColor: Color(0xFF470404),
            ),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Bill Page',
                style: TextStyle(color: Colors.white), // White text
              ),
              leading: IconButton(
                icon: Icon(
                  Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back,
                  color: Colors.white, // White icon
                ),
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardPage()),
                ),
              ),
              backgroundColor: Color(0xFF470404),
              iconTheme: IconThemeData(color: Colors.white), // Sets all icons to white
              toolbarTextStyle: TextStyle(color: Colors.white), // Sets text color
              titleTextStyle: TextStyle(
                color: Colors.white, // Explicitly set title color
                fontSize: 20, // Optional: set font size
                fontWeight: FontWeight.bold, // Optional: set font weight
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      buildBillInfoContainer(),
                      SizedBox(height: 20),
                      buildProductsContainer(),
                      SizedBox(height: 20),
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
      padding: EdgeInsets.all(16),
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
          Text('Bill Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          buildTextField('Bill Number', initialValue: billNumber, readOnly: true),
          SizedBox(height: 10),
          buildTextField('Date', initialValue: DateFormat('yyyy-MM-dd').format(DateTime.now()), readOnly: true),
        ],
      ),
    );
  }

  Widget buildTextField(String label, {String initialValue = '', bool readOnly = false}) {
    return TextField(
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      controller: TextEditingController(text: initialValue),
    );
  }

  Widget buildProductsContainer() {
    return Container(
      padding: EdgeInsets.all(16),
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
          Text('Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          buildProductSearchBar(),
          SizedBox(height: 10),
          buildCategoryDropdown(),
          SizedBox(height: 10),
          SizedBox(
            height: 400,
            child: FutureBuilder<List<AddProductModel>>(
              future: products,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No products available'));
                } else {
                  filteredProducts = snapshot.data!.where((product) {
                    final matchesCategory = selectedCategory == null || selectedCategory == product.noteCategory;
                    final matchesSearch = product.noteTitle.toLowerCase().contains(productSearchController.text.toLowerCase());
                    return matchesCategory && matchesSearch;
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return GestureDetector(
                        onTap: () => addToCart(product),
                        child: buildProductRow(
                            product.noteTitle,
                            product.notePrice.toString(),
                            getProductImagePath(product)
                        ),
                      );
                    },
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
      future: DatabaseHelper().getCategories(activeOnly: true),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        return DropdownButtonFormField<String>(
          hint: Text("Select Category"),
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
          decoration: InputDecoration(
            border: OutlineInputBorder(),
          ),
        );
      },
    );
  }

  Widget buildProductRow(String name, String price, String imagePath) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Color(0xFFDAB3AC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: imagePath.startsWith('lib/assets/')
                  ? AssetImage(imagePath)
                  : FileImage(File(imagePath)) as ImageProvider,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: TextStyle(color: Color(0xFF470404)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Rs.${double.parse(price).toStringAsFixed(2)}',
                style: TextStyle(
                  color: Color(0xFF470404),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF470404),
                borderRadius: BorderRadius.circular(6),
              ),
              padding: EdgeInsets.all(5),
              child: Icon(
                Icons.shopping_cart,
                size: 16,
                color: Colors.white,
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
        case 'clothes': return 'lib/assets/tshirt.jpg';
        case 'furnitures': return 'lib/assets/furniture.jpg';
        case 'biscuits': return 'lib/assets/biscuit.jpg';
        case 'soaps': return 'lib/assets/soap.jpg';
        default: return 'lib/assets/product.png';
      }
    }
  }

  Widget buildBillingSummaryContainer(BuildContext context) {
    double grossAmount = calculateGrossAmount(cart);
    double totalItemDiscounts = calculateTotalDiscount(cart);
    double netAmount = calculateNetAmount(cart, discount);

    return Container(
      padding: EdgeInsets.all(16),
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
          Text('Billing Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          ...cart.asMap().entries.map((entry) {
            int index = entry.key;
            var item = entry.value;
            return GestureDetector(
              onTap: () => editCartItem(index),
              child: buildCartItemRow(
                item['product'].noteTitle,
                item['quantity'],
                item['product'].notePrice,
                item['discount'] ?? 0.0,
              ),
            );
          }).toList(),
          SizedBox(height: 10),
          Divider(),
          buildSummaryRow('Gross Amount', 'Rs.${grossAmount.toStringAsFixed(2)}'),
          buildSummaryRow('Item Discounts', '-Rs.${totalItemDiscounts.toStringAsFixed(2)}'),
          buildSummaryRow('Bill Discount', '-Rs.${discount.toStringAsFixed(2)}'),
          Divider(),
          buildSummaryRow('Net Amount', 'Rs.${netAmount.toStringAsFixed(2)}', isTotal: true),
          SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              labelText: 'Bill Discount (Rs.)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                discount = double.tryParse(value) ?? 0.0;
              });
            },
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: cart.isEmpty ? null : () => handlePayBill(netAmount),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF470404),
              minimumSize: Size(double.infinity, 50),
            ),
            child: Text('Pay Bill', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget buildCartItemRow(String name, int quantity, double price, double discount) {
    double subtotal = (price * quantity) - discount;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '$name x$quantity',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text('Rs.${subtotal.toStringAsFixed(2)}'),
            ],
          ),
          if (discount > 0)
            Padding(
              padding: EdgeInsets.only(left: 10),
              child: Text(
                'Discount: -Rs.${discount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: Colors.green),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
              color: isTotal ? Color(0xFF470404) : null,
            ),
          ),
        ],
      ),
    );
  }
}