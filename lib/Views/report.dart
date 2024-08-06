import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../JsonModels/company_model.dart';
import '../SQLite/db_helper.dart';
import 'dashboard.dart';

class DBHelper1 {
  DBHelper1._();

  static final DBHelper1 instance = DBHelper1._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'cart_database.db');
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
        CREATE TABLE cart(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          productId INTEGER,
          productName TEXT,
          quantity INTEGER,
          price REAL,
          date TEXT,
          time TEXT
        )
      ''');
  }

  Future<List<Map<String, dynamic>>> getCartItems(
      {required String startDate, required String endDate}) async {
    Database db = await instance.database;
    return await db.query(
      'cart',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
    );
  }
}

class SalesSummaryPage extends StatefulWidget {
  @override
  _SalesSummaryPageState createState() => _SalesSummaryPageState();
}

class _SalesSummaryPageState extends State<SalesSummaryPage> {
  List<Map<String, dynamic>> cartItems = [];
  late TextEditingController startDateController;
  late TextEditingController endDateController;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  final DBHelper dbHelper = DBHelper();
  CompanyModel? company;

  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  @override
  void initState() {
    super.initState();
    startDateController = TextEditingController();
    endDateController = TextEditingController();
    connectToPrinter();
    _loadCompanyDetails();
  }

  @override
  void dispose() {
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyDetails() async {
    CompanyModel? fetchedCompany = await dbHelper.getCompany(1);
    setState(() {
      company = fetchedCompany;
    });
  }

  Future<void> connectToPrinter() async {
    List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
    if (devices.isNotEmpty) {
      await bluetooth.connect(devices[0]);
    }
  }

  Future<void> _fetchCartItems(String startDate, String endDate) async {
    List<Map<String, dynamic>> items = await DBHelper1.instance.getCartItems(
        startDate: startDate, endDate: endDate);
    setState(() {
      cartItems = items;
    });
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedStartDate) {
      setState(() {
        selectedStartDate = picked;
        startDateController.text = DateFormat('yyyy-MM-dd').format(selectedStartDate!);
        _fetchCartItems(startDateController.text, endDateController.text);
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedEndDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedEndDate) {
      setState(() {
        selectedEndDate = picked;
        endDateController.text = DateFormat('yyyy-MM-dd').format(selectedEndDate!);
        _fetchCartItems(startDateController.text, endDateController.text);
      });
    }
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Sales Summary',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['No.', 'Product ID', 'Product Name', 'Quantity', 'Price', 'Total Price', 'Date', 'Time'],
                  ...cartItems.asMap().entries.map((entry) {
                    int index = entry.key + 1;
                    var item = entry.value;
                    return [
                      index.toString(),
                      item['productId'].toString(),
                      item['productName'].toString(),
                      item['quantity'].toString(),
                      item['price'].toString(),
                      (item['price'] * item['quantity']).toStringAsFixed(2),
                      item['date'].toString(),
                      item['time'].toString(),
                    ];
                  }).map((item) => item.map((e) => e.toString()).toList()).toList(),  // Convert each item to List<String>
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Total Items: ${cartItems.length}',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Total Quantity: ${cartItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int))}',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Total Sales: ${cartItems.fold<double>(0, (sum, item) => sum + (item['price'] * item['quantity'])).toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/sales_summary.pdf");
    await file.writeAsBytes(await pdf.save());

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'sales_summary.pdf');
  }

  Future<void> _printSummary() async {
    String addCenterMargin(String text, {int totalWidth = 42}) {
      int padding = (totalWidth - text.length) ~/ 2;
      return ' ' * padding + text + ' ' * padding;
    }

    String addRightMargin(String text, {int totalWidth = 42, int rightMargin = 10}) {
      int padding = totalWidth - text.length - rightMargin;
      return text.padRight(totalWidth - rightMargin);
    }

    String currentDateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());

    bluetooth.printCustom("", 1, 1);
    bluetooth.printCustom(addCenterMargin("Sales Summary", totalWidth: 42), 5, 1);
    bluetooth.printNewLine();

    bluetooth.printCustom(company!.companyName, 3, 1);
    bluetooth.printNewLine();
    bluetooth.printCustom(company!.address, 1, 1);
    bluetooth.printCustom(company!.phone, 1, 1);
    bluetooth.printNewLine();
    bluetooth.printCustom(addCenterMargin("Date: $currentDateTime", totalWidth: 42), 1, 1);
    bluetooth.printNewLine();
    bluetooth.printCustom(addRightMargin("------------------------------------------", totalWidth: 42), 1, 1);
    bluetooth.printCustom(addRightMargin("Date Range: ${startDateController.text} to ${endDateController.text}", totalWidth: 42), 1, 1);
    bluetooth.printCustom(addRightMargin("------------------------------------------", totalWidth: 42), 1, 1);
    bluetooth.printNewLine();

   //bluetooth.printCustom("No.  Product Name     Qty     Price     Total", 1, 1);
   //bluetooth.printCustom("------------------------------------------", 1, 1);

    bluetooth.printCustom(addRightMargin("No  Name          Qty     Price     Total", totalWidth: 42), 1, 1);
    bluetooth.printCustom(addRightMargin("------------------------------------------", totalWidth: 42), 1, 1);

    final mergedItems = mergeCartItems(cartItems);
    for (var i = 0; i < mergedItems.length; i++) {
      var item = mergedItems[i];
      String name = item['productName'];
      int quantity = item['quantity'];
      double price = item['price'];
      double total = item['totalPrice'];

      String itemLine = formatLine((i + 1).toString(), name, quantity.toString(), price.toStringAsFixed(2), total.toStringAsFixed(2));
      bluetooth.printCustom(itemLine, 1, 1);
    }

    bluetooth.printCustom("------------------------------------------", 1, 1);
    bluetooth.printNewLine();
    bluetooth.printCustom("Total Items: ${mergedItems.length}", 1, 1);
    bluetooth.printCustom("Total Quantity: ${mergedItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int))}", 1, 1);
    bluetooth.printCustom("Total Sales: ${mergedItems.fold<double>(0, (sum, item) => sum + item['totalPrice']).toStringAsFixed(2)}", 1, 1);
    bluetooth.printNewLine();

    bluetooth.printCustom(addCenterMargin("Thank You, Come Again!", totalWidth: 42), 1, 1);
    bluetooth.printCustom(addCenterMargin("Software provided by", totalWidth: 42), 1, 1);
    bluetooth.printCustom(addCenterMargin("Synnex IT Solution", totalWidth: 42), 1, 1);
    bluetooth.printNewLine();

    bluetooth.printCustom("", 1, 1);
    bluetooth.paperCut();
  }

  String formatLine(String no, String name, String qty, String price, String total) {
    const int noWidth = 4;
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

  List<Map<String, dynamic>> mergeCartItems(List<Map<String, dynamic>> items) {
    final mergedItems = <String, Map<String, dynamic>>{};

    for (var item in items) {
      final productName = item['productName'];
      if (mergedItems.containsKey(productName)) {
        mergedItems[productName]!['quantity'] += item['quantity'];
        mergedItems[productName]!['totalPrice'] += item['quantity'] * item['price'];
      } else {
        mergedItems[productName] = {
          'productName': productName,
          'quantity': item['quantity'],
          'price': item['price'],
          'totalPrice': item['quantity'] * item['price'],
          'date': item['date'],
          'time': item['time'],
        };
      }
    }

    return mergedItems.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales Summary',
          style: GoogleFonts.poppins(
            fontSize: 22, // Adjust the font size as needed
            fontWeight: FontWeight.bold, // Adjust the font weight as needed
            color: Color(0xFFE0FFFF), // Adjust the text color as needed
          ),
        ),
        backgroundColor: Color(0xFF470404),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white,),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage()),
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Start Date (YYYY-MM-DD)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                TextField(
                  controller: startDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: () => _selectStartDate(context),
                      icon: Icon(Icons.calendar_today),
                      color: Color(0xFFad6c47), // Change calendar icon color
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'End Date (YYYY-MM-DD)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                TextField(
                  controller: endDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: () => _selectEndDate(context),
                      icon: Icon(Icons.calendar_today),
                      color: Color(0xFFad6c47), // Change calendar icon color
                    ),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    _fetchCartItems(startDateController.text, endDateController.text);
                  },
                  child: Text('Filter'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Color(0xFFad6c47), // Change text color
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _generatePDF,
                  child: Text('Download PDF Report'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Color(0xFFad6c47), // Change text color
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _printSummary,
                  child: Text('Print Report'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Color(0xFFad6c47), // Change text color
                  ),
                ),
                SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Sales Summary Details',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Add the summary table
                    SalesSummaryTable(cartItems),
                    cartItems.isEmpty
                        ? Center(
                      child: Text(
                        'No items in cart',
                        style: TextStyle(color: Colors.red), // Change text color
                      ),
                    )
                        : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Summary Table Widget
class SalesSummaryTable extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;

  SalesSummaryTable(this.cartItems);

  List<Map<String, dynamic>> mergeCartItems(List<Map<String, dynamic>> items) {
    final mergedItems = <String, Map<String, dynamic>>{};

    for (var item in items) {
      final productName = item['productName'];
      if (mergedItems.containsKey(productName)) {
        mergedItems[productName]!['quantity'] += item['quantity'];
        mergedItems[productName]!['totalPrice'] += item['quantity'] * item['price'];
      } else {
        mergedItems[productName] = {
          'productName': productName,
          'quantity': item['quantity'],
          'price': item['price'],
          'totalPrice': item['quantity'] * item['price'],
          'date': item['date'],
          'time': item['time'],
        };
      }
    }

    return mergedItems.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final mergedItems = mergeCartItems(cartItems);

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text('No.')),
              DataColumn(label: Text('Product Name')),
              DataColumn(label: Text('Quantity')),
              DataColumn(label: Text('Price')),
              DataColumn(label: Text('Total Price')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Time')),
            ],
            rows: mergedItems.asMap().entries.map((entry) {
              int index = entry.key + 1;
              var item = entry.value;
              final productName = item['productName'] ?? 'Unknown Product';
              final quantity = item['quantity'] ?? 0;
              final price = item['price'] ?? 0.0;
              final totalPrice = item['totalPrice'] ?? 0.0;
              final date = item['date'] ?? '';
              final time = item['time'] ?? '';

              return DataRow(cells: [
                DataCell(Text(index.toString())),
                DataCell(Text(productName)),
                DataCell(Text(quantity.toString())),
                DataCell(Text(price.toStringAsFixed(2))),
                DataCell(Text(totalPrice.toStringAsFixed(2))),
                DataCell(Text(date)),
                DataCell(Text(time)),
              ]);
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Total Items: ${mergedItems.length}',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.end,
              ),
              Text(
                'Total Quantity: ${mergedItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int))}',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
