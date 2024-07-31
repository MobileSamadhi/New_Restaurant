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
                  <String>['Product ID', 'Product Name', 'Quantity', 'Price', 'Total Price', 'Date', 'Time'],
                  ...cartItems.map((item) => [
                    item['productId'].toString(),
                    item['productName'],
                    item['quantity'].toString(),
                    item['price'].toString(),
                    (item['price'] * item['quantity']).toStringAsFixed(2),
                    item['date'],
                    item['time'],
                  ])
                ],
              ),
              pw.SizedBox(height: 20),
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

    String currentDateTime = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

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

    bluetooth.printCustom("Product Name     Qty     Price     Total", 1, 1);
    bluetooth.printCustom("------------------------------------------", 1, 1);

    for (var item in cartItems) {
      String name = item['productName'];
      int quantity = item['quantity'];
      double price = item['price'];
      double total = price * quantity;

      String itemLine = formatLine(name, quantity.toString(), price.toStringAsFixed(2), total.toStringAsFixed(2));
      bluetooth.printCustom(itemLine, 1, 1);
    }

    bluetooth.printCustom("------------------------------------------", 1, 1);
    bluetooth.printNewLine();
    bluetooth.printCustom("Total Quantity: ${cartItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int))}", 1, 1);
    bluetooth.printCustom("Total Sales: ${cartItems.fold<double>(0, (sum, item) => sum + item['price'] * item['quantity']).toStringAsFixed(2)}", 1, 1);
    bluetooth.printNewLine();

    bluetooth.printCustom(addCenterMargin("Thank You, Come Again!", totalWidth: 42), 1, 1);
    bluetooth.printCustom(addCenterMargin("Software provided by", totalWidth: 42), 1, 1);
    bluetooth.printCustom(addCenterMargin("Synnex IT Solution", totalWidth: 42), 1, 1);
    bluetooth.printNewLine();

    bluetooth.printCustom("", 1, 1);
    bluetooth.paperCut();
  }

  String formatLine(String name, String qty, String price, String total) {
    const int nameWidth = 12;
    const int qtyWidth = 6;
    const int priceWidth = 9;
    const int totalWidth = 10;

    String paddedName = (name.length > nameWidth) ? name.substring(0, nameWidth) : name.padRight(nameWidth);
    String paddedQty = qty.padLeft(qtyWidth);
    String paddedPrice = price.padLeft(priceWidth);
    String paddedTotal = total.padLeft(totalWidth);

    return '$paddedName$paddedQty$paddedPrice$paddedTotal';
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
      body: Padding(
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
            Expanded(
              child: Column(
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
                  Expanded(
                    child: cartItems.isEmpty
                        ? Center(
                      child: Text(
                        'No items in cart',
                        style: TextStyle(color: Colors.red), // Change text color
                      ),
                    )
                        : ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final productName = item['productName'] != null ? item['productName'] : 'Unknown Product';
                        final quantity = item['quantity'] ?? 0;
                        final price = item['price'] ?? 0.0;
                        final totalPrice = price * quantity;
                        final date = item['date'];
                        final time = item['time'];

                        return ListTile(
                          title: Text(
                            productName,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Quantity: $quantity'),
                              Text('Price: ${price.toStringAsFixed(2)}'),
                              Text('Total Price: ${totalPrice.toStringAsFixed(2)}'),
                              Text('Date: $date'),
                              Text('Time: $time'),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Summary Table Widget
class SalesSummaryTable extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;

  SalesSummaryTable(this.cartItems);

  @override
  Widget build(BuildContext context) {
    int totalQuantity = 0;
    double totalSales = 0.0;

    for (var item in cartItems) {
      totalQuantity += (item['quantity'] ?? 0) as int;
      totalSales += (item['quantity'] ?? 0) * (item['price'] ?? 0.0);
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(5.0),
      ),
      margin: EdgeInsets.symmetric(horizontal: 10.0),
      child: Table(
        columnWidths: {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(2),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Total Quantity',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '$totalQuantity',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          TableRow(
            children: [
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Total Sales',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${totalSales.toStringAsFixed(2)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
