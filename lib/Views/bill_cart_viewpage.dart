import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synnex_mobi/Views/dashboard.dart';
import '../SQLite/print_bill_db.dart';
import '../SQLite/db_helper.dart';
import '../SQLite/sqlite.dart';
import '../JsonModels/company_model.dart';

class BillAndCartViewPage extends StatefulWidget {
  @override
  _BillAndCartViewPageState createState() => _BillAndCartViewPageState();
}

class _BillAndCartViewPageState extends State<BillAndCartViewPage> {
  PrintBillDBHelper dbHelper = PrintBillDBHelper();
  DBHelper companyDbHelper = DBHelper();
  DatabaseHelper userDbHelper = DatabaseHelper();
  List<int> billIds = [];
  List<Map<String, dynamic>> billDetails = [];
  int? selectedBillId;
  Map<String, dynamic>? commonBillDetails;
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  bool _isPrinting = false;
  CompanyModel? company;
  String currentUser = 'Guest';

  @override
  void initState() {
    super.initState();
    fetchBillIds();
    _loadCompanyDetails();
    _loadCurrentUser();
    connectToPrinter();
  }

  Future<void> _loadCompanyDetails() async {
    CompanyModel? fetchedCompany = await companyDbHelper.getCompany(1);
    setState(() {
      company = fetchedCompany;
    });
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? prefUser = prefs.getString('currentUser');

    if (prefUser != null) {
      setState(() {
        currentUser = prefUser;
      });
      return;
    }

    String? dbUser = await userDbHelper.getCurrentUser();
    if (dbUser != null) {
      setState(() {
        currentUser = dbUser;
      });
      await prefs.setString('currentUser', dbUser);
    }
  }

  Future<void> connectToPrinter() async {
    List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
    if (devices.isNotEmpty) {
      await bluetooth.connect(devices[0]);
    }
  }

  Future<void> fetchBillIds() async {
    final products = await dbHelper.getAllBills();
    final uniqueBillIds = products.map((product) => product['billId']).toSet().toList();
    setState(() {
      billIds = uniqueBillIds.cast<int>();
    });
  }

  Future<void> fetchBillDetails(int billId) async {
    final products = await dbHelper.getBillsById(billId);
    if (products.isNotEmpty) {
      setState(() {
        billDetails = products;
        selectedBillId = billId;
        commonBillDetails = {
          'date': products[0]['date'],
          'time': products[0]['time'],
          'grossAmount': products[0]['grossAmount'],
          'discount': products[0]['discount'],
          'totalItemDiscount': products[0]['totalItemDiscount'],
          'netAmount': products[0]['netAmount'],
          'user': products[0]['user'],
        };
      });
    }
  }

  Future<void> _printBill() async {
    if (_isPrinting || company == null || commonBillDetails == null) return;

    setState(() {
      _isPrinting = true;
    });

    try {
      String addCenterMargin(String text, {int totalWidth = 42}) {
        int padding = (totalWidth - text.length) ~/ 2;
        return ' ' * padding + text + ' ' * padding;
      }

      String addRightMargin(String text, {int totalWidth = 42, int rightMargin = 10}) {
        int padding = totalWidth - text.length - rightMargin;
        return text.padRight(totalWidth - rightMargin);
      }

      String leftRightAlign(String left, String right, {int lineLength = 42}) {
        int space = lineLength - left.length - right.length;
        if (space <= 0) return '$left$right';
        return left + (' ' * space) + right;
      }

      bluetooth.printCustom(company!.companyName, 3, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom("Address: ${company!.address}", 1, 1);
      bluetooth.printCustom("Tel: ${company!.phone}", 1, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom('INVOICE', 2, 1);
      bluetooth.printNewLine();

      // Print invoice info
      bluetooth.printCustom(leftRightAlign('Invoice No :', selectedBillId.toString()), 1, 1);
      bluetooth.printCustom(leftRightAlign('Date :', commonBillDetails!['date']), 1, 1);
      bluetooth.printNewLine();

      bluetooth.printCustom(addRightMargin("------------------------------------------", totalWidth: 42), 1, 1);
      bluetooth.printNewLine();

      bluetooth.printCustom(addRightMargin("No  Name          Qty     Price     Total", totalWidth: 42), 1, 1);
      bluetooth.printCustom(addRightMargin("------------------------------------------", totalWidth: 42), 1, 1);

      int totalItems = 0;
      int totalQuantity = 0;
      double totalItemDiscounts = 0; // You may need to adjust this based on your data

      for (var i = 0; i < billDetails.length; i++) {
        var product = billDetails[i];
        String name = product['productName'];
        double price = product['price'];
        int quantity = product['quantity'];
        double totalPrice = price * quantity;

        String itemLine = formatLine(
            (i + 1).toString(),
            name,
            quantity.toString(),
            price.toStringAsFixed(2),
            totalPrice.toStringAsFixed(2)
        );

        bluetooth.printCustom(addRightMargin(itemLine, totalWidth: 42), 1, 1);

        totalItems++;
        totalQuantity += quantity;
      }

      bluetooth.printCustom(addRightMargin("------------------------------------------", totalWidth: 42), 1, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom(addRightMargin(formatRightAligned("Total Items:", totalItems.toString()), totalWidth: 42), 1, 1);
      bluetooth.printCustom(addRightMargin(formatRightAligned("Total Quantity:", totalQuantity.toString()), totalWidth: 42), 1, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom(addRightMargin(formatRightAligned("Gross Amount:", commonBillDetails!['grossAmount'].toStringAsFixed(2)), totalWidth: 42), 1, 1);
      bluetooth.printCustom(addRightMargin(formatRightAligned("Total Item Discount:", commonBillDetails!['totalItemDiscount'].toStringAsFixed(2)), totalWidth: 42), 1, 1);
      bluetooth.printCustom(addRightMargin(formatRightAligned("Bill Discount:", commonBillDetails!['discount'].toStringAsFixed(2)), totalWidth: 42), 1, 1);
      bluetooth.printCustom(addRightMargin(formatRightAligned("Net Amount:", commonBillDetails!['netAmount'].toStringAsFixed(2)), totalWidth: 42), 1, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom(addRightMargin("------------------------------------------", totalWidth: 42), 1, 1);
      bluetooth.printNewLine();

      bluetooth.printCustom(addCenterMargin("Thank You, Come Again!", totalWidth: 42), 1, 1);
      bluetooth.printCustom(addCenterMargin("Software provided by", totalWidth: 42), 1, 1);
      bluetooth.printCustom(addCenterMargin("Synnex IT Solution", totalWidth: 42), 1, 1);
      bluetooth.printNewLine();

      bluetooth.printCustom("", 1, 1);
      bluetooth.paperCut();

    } catch (e) {
      print('Printing error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Printing failed: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }

  String formatLine(String no, String name, String qty, String price, String total) {
    const int noWidth = 3;
    const int nameWidth = 12;
    const int qtyWidth = 6;
    const int priceWidth = 9;
    const int totalWidth = 10;

    String paddedNo = no.padRight(noWidth);
    String paddedName = (name.length > nameWidth) ? name.substring(0, nameWidth) : name.padRight(nameWidth);
    String paddedQty = qty.padLeft(qtyWidth);
    String paddedPrice = price.padLeft(priceWidth);
    String paddedTotal = total.padLeft(totalWidth);

    return '$paddedNo$paddedName$paddedQty$paddedPrice$paddedTotal';
  }

  String formatRightAligned(String key, String value, {int totalWidth = 42}) {
    int keyLength = key.length;
    int valueLength = value.length;
    int spaces = totalWidth - keyLength - valueLength;
    return key + ' ' * spaces + value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bill and Cart View',
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
        backgroundColor: Color(0xFF470404),
      ),
      body: Row(
        children: [
          // Bill IDs List
          Expanded(
            flex: 1,
            child: Container(
              color: Color(0xFFDAB3AC).withOpacity(0.3),
              child: ListView.builder(
                itemCount: billIds.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: selectedBillId == billIds[index] ? Color(0xFFDAB3AC) : Colors.white,
                    child: ListTile(
                      title: Text('Bill ID: ${billIds[index]}'),
                      onTap: () => fetchBillDetails(billIds[index]),
                    ),
                  );
                },
              ),
            ),
          ),
          // Bill Details
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              child: selectedBillId == null
                  ? Center(child: Text('Select a Bill ID to see details', style: TextStyle(fontSize: 18, color: Colors.grey)))
                  : Column(
                children: [
                  // Common Bill Details
                  if (commonBillDetails != null)
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Date: ${commonBillDetails!['date']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Bill No: $selectedBillId', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text('Gross Amount: ${(commonBillDetails!['grossAmount'] as double).toStringAsFixed(2)}', style: TextStyle(fontSize: 16)),
                          Text('Total Item Discount: ${(commonBillDetails!['totalItemDiscount'] as double).toStringAsFixed(2)}', style: TextStyle(fontSize: 16)),
                          Text('Bill Discount: ${(commonBillDetails!['discount'] as double).toStringAsFixed(2)}', style: TextStyle(fontSize: 16)),
                          Text('Net Amount: ${(commonBillDetails!['netAmount'] as double).toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Divider(color: Colors.black),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isPrinting ? null : _printBill,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF470404),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isPrinting
                                  ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text('Printing...'),
                                ],
                              )
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.print, size: 20),
                                  SizedBox(width: 10),
                                  Text('Print Bill'),
                                ],
                              ),
                            ),
                          ),
                          Divider(color: Colors.black),
                        ],
                      ),
                    ),
                  // Bill Product Details
                  Expanded(
                    child: ListView.builder(
                      itemCount: billDetails.length,
                      itemBuilder: (context, index) {
                        final product = billDetails[index];
                        final totalPrice = (product['price'] as double) * (product['quantity'] as int);

                        return Card(
                          color: Color(0xFFDAB3AC),
                          margin: EdgeInsets.all(10),
                          child: ListTile(
                            title: Text(product['productName'], style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Quantity: ${product['quantity']}', style: TextStyle(color: Colors.black54)),
                                    Text('Price: ${(product['price']).toStringAsFixed(2)}', style: TextStyle(color: Colors.black54)),
                                  ],
                                ),
                                SizedBox(height: 5),
                                Text('Total: ${totalPrice.toStringAsFixed(2)}',
                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                SizedBox(height: 5),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}