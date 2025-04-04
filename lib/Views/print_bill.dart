import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../JsonModels/add_product_model.dart';
import '../JsonModels/company_model.dart';
import '../JsonModels/product_model.dart';
import '../SQLite/db_helper.dart';
import '../SQLite/print_bill_db.dart';
import '../SQLite/sqlite.dart';
import 'bill_page.dart';

class PrintBillPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final String billNumber;
  final DateTime dateTime;
  final String address;
  final String contactNumber;
  final double grossAmount;
  final double discount;
  final double netAmount;
  final double totalItemDiscounts;

  PrintBillPage({
    required this.cart,
    required this.billNumber,
    required this.dateTime,
    required this.address,
    required this.contactNumber,
    required this.grossAmount,
    required this.discount,
    required this.netAmount, required String user, required this.totalItemDiscounts,
  }) {
    print('Received Bill Number: $billNumber');
    print('Received Items: ${cart.map((item) => item.toString()).join(', ')}');
  }

  @override
  _PrintBillPageState createState() => _PrintBillPageState();
}

class _PrintBillPageState extends State<PrintBillPage> {
  final DBHelper dbHelper = DBHelper();
  final DatabaseHelper userDbHelper = DatabaseHelper();
  CompanyModel? company;
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  bool _isPrinting = false;
  bool _isSaved = false;
  String currentUser = 'Guest'; // Initialize with default value

  @override
  void initState() {
    super.initState();
    connectToPrinter();
    _loadCompanyDetails();
    _loadCurrentUser();
  }

  Future<void> _loadCompanyDetails() async {
    CompanyModel? fetchedCompany = await dbHelper.getCompany(1);
    setState(() {
      company = fetchedCompany;
    });
  }

  Future<void> _loadCurrentUser() async {
    // First try to get from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    String? prefUser = prefs.getString('currentUser');

    if (prefUser != null) {
      setState(() {
        currentUser = prefUser;
      });
      return;
    }

    // Fallback to database if not in SharedPreferences
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

  Future<void> _printBill() async {
    if (_isPrinting) return;

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
        if (space <= 0) return '$left$right'; // No space if line is full
        return left + (' ' * space) + right;
      }

      if (company == null) return;

      bluetooth.printCustom(company!.companyName, 3, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom("Address: ${company!.address}", 1, 1);
      bluetooth.printCustom("Tel: ${company!.phone}", 1, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom('INVOICE', 2, 1);
      bluetooth.printNewLine();

      // Print invoice info
      bluetooth.printCustom(leftRightAlign('Invoice No :', widget.billNumber), 1, 1);
      bluetooth.printCustom(leftRightAlign('Date :', DateFormat('yyyy-MM-dd').format(widget.dateTime)), 1, 1);
      bluetooth.printCustom(leftRightAlign('Time :', DateFormat('HH:mm:ss').format(widget.dateTime)), 1, 1);
      bluetooth.printCustom(leftRightAlign('Cashier :', currentUser), 1, 1);
      bluetooth.printNewLine();

      bluetooth.printCustom(addRightMargin("------------------------------------------", totalWidth: 42), 1, 1);
      bluetooth.printNewLine();

      bluetooth.printCustom(addRightMargin("No  Name          Qty     Price     Total", totalWidth: 42), 1, 1);
      bluetooth.printCustom(addRightMargin("------------------------------------------", totalWidth: 42), 1, 1);

      final dbHelper = PrintBillDBHelper();
      final date = DateFormat('yyyy-MM-dd').format(widget.dateTime);
      final time = DateFormat('HH:mm').format(widget.dateTime);

      int totalItems = 0;
      int totalQuantity = 0;

      for (var i = 0; i < widget.cart.length; i++) {
        var item = widget.cart[i];
        var product = item['product'];
        String name = '';
        double price = 0.0;
        if (product is AddProductModel) {
          name = product.noteTitle;
          price = product.notePrice;
        } else if (product is NoteModel) {
          name = product.noteTitle;
          price = product.notePrice!;
        }
        var quantity = item['quantity'] as int;
        var grossAmount = price * quantity;
        var netAmount = grossAmount - widget.discount;

        if (!_isSaved) {
          await dbHelper.insertBill({
            'productId': product.noteId,
            'billId': int.tryParse(widget.billNumber) ?? 0,
            'productName': name,
            'quantity': quantity,
            'price': price,
            'grossAmount': widget.grossAmount,
            'discount': widget.discount,
            'totalItemDiscount': widget.totalItemDiscounts,
            'netAmount': widget.netAmount,
            'date': date,
            'time': time,
            'user': currentUser,
          });
        }

        String itemLine = formatLine((i + 1).toString(), name, quantity.toString(), price.toStringAsFixed(2), netAmount.toStringAsFixed(2));
        bluetooth.printCustom(addRightMargin(itemLine, totalWidth: 42), 1, 1);

        totalItems++;
        totalQuantity += quantity;
      }

      setState(() {
        _isSaved = true;
      });

      bluetooth.printCustom(addRightMargin("------------------------------------------", totalWidth: 42), 1, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom(addRightMargin(formatRightAligned("Total Items:", totalItems.toString()), totalWidth: 42), 1, 1);
      bluetooth.printCustom(addRightMargin(formatRightAligned("Total Quantity:", totalQuantity.toString()), totalWidth: 42), 1, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom(addRightMargin(formatRightAligned("Gross Amount:", widget.grossAmount.toStringAsFixed(2)), totalWidth: 42), 1, 1);
      bluetooth.printCustom(addRightMargin(formatRightAligned("Total Item Discount:", widget.totalItemDiscounts.toStringAsFixed(2)), totalWidth: 42), 1, 1);
      bluetooth.printCustom(addRightMargin(formatRightAligned("Bill Discount:", widget.discount.toStringAsFixed(2)), totalWidth: 42), 1, 1);
      bluetooth.printCustom(addRightMargin(formatRightAligned("Net Amount:", widget.netAmount.toStringAsFixed(2)), totalWidth: 42), 1, 1);
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
    final theme = Theme.of(context);
    final totalQuantity = widget.cart.fold(0, (previousValue, item) => previousValue + (item['quantity'] as int));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Print Bill',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
              MaterialPageRoute(builder: (context) => BillingPage()),
            );
          },
        ),
        backgroundColor: Color(0xFF470404),
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F5F5),
              Color(0xFFE0E0E0),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Center(
              child: company == null
                  ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF470404)),
              )
                  : Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Color(0xFFF9F9F9),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Company Header
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFF470404).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              company!.companyName,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF470404),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              company!.address,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4),
                            Text(
                              company!.phone,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),

                      // Bill Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoCard('Date', DateFormat('yyyy-MM-dd').format(widget.dateTime)),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoCard('Bill No', widget.billNumber),
                          _buildInfoCard('User', currentUser),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Items Table
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 20,
                              dataRowHeight: 40,
                              headingRowHeight: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                              ),
                              columns: [
                                DataColumn(
                                  label: Text(
                                    'No',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF470404),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Name',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF470404),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Qty',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF470404),
                                    ),
                                  ),
                                  numeric: true,
                                ),
                                DataColumn(
                                  label: Text(
                                    'Price',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF470404),
                                    ),
                                  ),
                                  numeric: true,
                                ),
                                DataColumn(
                                  label: Text(
                                    'Total',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF470404),
                                    ),
                                  ),
                                  numeric: true,
                                ),
                              ],
                              rows: widget.cart.asMap().entries.map((entry) {
                                var item = entry.value;
                                var product = item['product'];
                                String name = '';
                                double price = 0.0;
                                if (product is AddProductModel) {
                                  name = product.noteTitle;
                                  price = product.notePrice;
                                } else if (product is NoteModel) {
                                  name = product.noteTitle;
                                  price = product.notePrice!;
                                }
                                return DataRow(
                                  cells: [
                                    DataCell(Text(
                                      (entry.key + 1).toString(),
                                      style: GoogleFonts.poppins(),
                                    )),
                                    DataCell(Container(
                                      width: 150,
                                      child: Text(
                                        name,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(),
                                      ),
                                    )),
                                    DataCell(Text(
                                      item['quantity'].toString(),
                                      style: GoogleFonts.poppins(),
                                      textAlign: TextAlign.right,
                                    )),
                                    DataCell(Text(
                                      price.toStringAsFixed(2),
                                      style: GoogleFonts.poppins(),
                                      textAlign: TextAlign.right,
                                    )),
                                    DataCell(Text(
                                      (price * item['quantity']).toStringAsFixed(2),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.right,
                                    )),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 25),

                      // Summary Cards
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildSummaryRow('Total Items:', widget.cart.length.toString()),
                            _buildSummaryRow('Total Quantity:', totalQuantity.toString()),
                            Divider(height: 20, thickness: 1),
                            _buildSummaryRow('Gross Amount:', widget.grossAmount.toStringAsFixed(2), isHighlighted: true),
                            _buildSummaryRow('Total Item Discount:', widget.totalItemDiscounts.toStringAsFixed(2)),
                            _buildSummaryRow('Bill Discount:', widget.discount.toStringAsFixed(2)),
                            Divider(height: 20, thickness: 1),
                            _buildSummaryRow('Net Amount:', widget.netAmount.toStringAsFixed(2), isHighlighted: true, isTotal: true),
                          ],
                        ),
                      ),
                      SizedBox(height: 25),

                      // Footer
                      Column(
                        children: [
                          Text(
                            'Thank you for your business!',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Software provided by',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Synnex IT Solution',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF470404),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Print Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isPrinting ? null : _printBill,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF470404),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 5,
                            shadowColor: Color(0xFF470404).withOpacity(0.3),
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
                              Text(
                                'Printing...',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.print, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Print Bill',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF470404),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlighted = false, bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isHighlighted ? Color(0xFF470404) : Colors.grey[700],
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 16 : 14,
              color: isHighlighted ? Color(0xFF470404) : Colors.grey[700],
              fontWeight: isTotal ? FontWeight.bold : (isHighlighted ? FontWeight.w600 : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
}