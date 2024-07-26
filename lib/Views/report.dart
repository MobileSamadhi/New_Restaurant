import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dashboard.dart';

class DBHelper {
  DBHelper._();

  static final DBHelper instance = DBHelper._();
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

  @override
  void initState() {
    super.initState();
    startDateController = TextEditingController();
    endDateController = TextEditingController();
  }

  @override
  void dispose() {
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }

  Future<void> _fetchCartItems(String startDate, String endDate) async {
    List<Map<String, dynamic>> items = await DBHelper.instance.getCartItems(
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
        backgroundColor: Color(0xFF0072BC),
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
                  color: Colors.blue, // Change calendar icon color
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
                  color: Colors.blue, // Change calendar icon color
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
                foregroundColor: Colors.white, backgroundColor: Colors.blue, // Change text color
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generatePDF,
              child: Text('Download PDF Report'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.blue, // Change text color
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
