import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
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
  bool isLoading = false;
  bool isPrinting = false;

  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  @override
  void initState() {
    super.initState();
    startDateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    endDateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    connectToPrinter();
    _loadCompanyDetails();
    _fetchCartItems(startDateController.text, endDateController.text);
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
    try {
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
      if (devices.isNotEmpty) {
        await bluetooth.connect(devices[0]);
      }
    } catch (e) {
      print('Printer connection error: $e');
    }
  }

  Future<void> _fetchCartItems(String startDate, String endDate) async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Map<String, dynamic>> items = await DBHelper1.instance.getCartItems(
          startDate: startDate, endDate: endDate);
      setState(() {
        cartItems = items;
      });
    } catch (e) {
      print('Error fetching cart items: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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

    final mergedItems = mergeCartItems(cartItems);
    final totalQuantity = mergedItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
    final totalSales = mergedItems.fold<double>(0, (sum, item) => sum + (item['totalPrice'] as double));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Sales Summary Report',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                    style: pw.TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Date Range: ${startDateController.text} to ${endDateController.text}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),

              // Company Info
              if (company != null) ...[
                pw.Text(
                  company!.companyName,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(company!.address),
                pw.Text(company!.phone),
                pw.SizedBox(height: 20),
              ],

              // Table
              pw.TableHelper.fromTextArray(
                context: context,
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),  // No.
                  1: const pw.FixedColumnWidth(150), // Product Name
                  2: const pw.FixedColumnWidth(50),  // Quantity
                  3: const pw.FixedColumnWidth(70),  // Price
                  4: const pw.FixedColumnWidth(80),  // Total
                },
                headers: [
                  'No.',
                  'Product Name',
                  'Qty',
                  'Price',
                  'Total',
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
                cellStyle: pw.TextStyle(
                  fontSize: 10,
                ),
                cellAlignment: pw.Alignment.centerRight,
                headerAlignment: pw.Alignment.center,
                data: List<List<String>>.generate(mergedItems.length, (index) {
                  var item = mergedItems[index];
                  return [
                    (index + 1).toString(),
                    item['productName'].toString(),
                    item['quantity'].toString(),
                    NumberFormat.currency(symbol: 'Rs ').format(item['price']),
                    NumberFormat.currency(symbol: 'Rs ').format(item['totalPrice']),
                  ];
                }),
              ),
              pw.SizedBox(height: 20),

              // Summary
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Total Items: ${mergedItems.length}',
                      style: pw.TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    pw.Text(
                      'Total Quantity: $totalQuantity',
                      style: pw.TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    pw.Text(
                      'Total Sales: ${NumberFormat.currency(symbol: 'Rs ').format(totalSales)}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Center(
                child: pw.Text(
                  'Software provided by Synnex IT Solution',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/sales_summary_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(await pdf.save());

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'sales_summary_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _printSummary() async {
    if (isPrinting) return;

    setState(() {
      isPrinting = true;
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

      if (company == null) return;

      final mergedItems = mergeCartItems(cartItems);
      final totalQuantity = mergedItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
      final totalSales = mergedItems.fold<double>(0, (sum, item) => sum + (item['totalPrice'] as double));

      // Print header
      bluetooth.printCustom(company!.companyName, 1, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom(company!.address, 1, 1);
      bluetooth.printCustom(company!.phone, 1, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom('SALES SUMMARY', 1, 1);
      bluetooth.printNewLine();

      // Print date range
      bluetooth.printCustom(leftRightAlign('From:', startDateController.text), 1, 1);
      bluetooth.printCustom(leftRightAlign('To:', endDateController.text), 1, 1);
      bluetooth.printCustom(leftRightAlign('Printed:', DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())), 1, 1);
      bluetooth.printNewLine();

      bluetooth.printCustom(addRightMargin("------------------------------------------", totalWidth: 42), 1, 1);
      bluetooth.printNewLine();

      // Print column headers
      bluetooth.printCustom(addRightMargin("No  Name          Qty     Price     Total", totalWidth: 42), 1, 1);
      bluetooth.printCustom(addRightMargin("------------------------------------------", totalWidth: 42), 1, 1);

    // Print Items
    for (var i = 0; i < mergedItems.length; i++) {
    var item = mergedItems[i];
    String name = item['productName'];
    if (name.length > 10) {
    name = name.substring(0, 10) + '...';
    }
    int quantity = item['quantity'];
    double price = item['price'];
    double total = item['totalPrice'];

    // Format each column
    String line =
    "${(i + 1).toString().padRight(3)}" +      // No. (3 chars)
    "${name.padRight(10)}" +                   // Name (10 chars)
    "${quantity.toString().padLeft(4)}" +      // Qty (4 chars)
    "${price.toStringAsFixed(2).padLeft(7)}" + // Price (7 chars)
    "${total.toStringAsFixed(2).padLeft(9)}";  // Total (9 chars)

    bluetooth.printCustom(addRightMargin(line, totalWidth: 42), 1, 1);
    }

      bluetooth.printCustom(addRightMargin("------------------------------------------", totalWidth: 42), 1, 1);
      bluetooth.printNewLine();

      // Print summary
      bluetooth.printCustom(addRightMargin(_formatRightAligned("Total Items:", mergedItems.length.toString()), totalWidth: 42), 1, 1);
      bluetooth.printCustom(addRightMargin(_formatRightAligned("Total Quantity:", totalQuantity.toString()), totalWidth: 42), 1, 1);
      bluetooth.printCustom(addRightMargin(_formatRightAligned("Total Sales:", totalSales.toStringAsFixed(2)), totalWidth: 42), 1, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom(addRightMargin("------------------------------------------", totalWidth: 42), 0, 1);
      bluetooth.printNewLine();

      bluetooth.printCustom(addCenterMargin("Thank You!", totalWidth: 42), 1, 1);
      bluetooth.printCustom(addCenterMargin("Software by Synnex IT", totalWidth: 42), 1, 1);
      bluetooth.printNewLine();

      bluetooth.printCustom("", 1, 1);
      bluetooth.paperCut();

    } catch (e) {
      print('Printing error: $e');
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
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
        isPrinting = false;
      });
    }
  }

  String _formatSummaryLine(String no, String name, String qty, String total) {
    const int noWidth = 3;
    const int nameWidth = 12;
    const int qtyWidth = 6;
    const int totalWidth = 10;

    String paddedNo = no.padRight(noWidth);
    String paddedName = name.padRight(nameWidth);
    String paddedQty = qty.padLeft(qtyWidth);
    String paddedTotal = total.padLeft(totalWidth);

    return '$paddedNo$paddedName$paddedQty$paddedTotal';
  }

  String _formatRightAligned(String key, String value, {int totalWidth = 42}) {
    int keyLength = key.length;
    int valueLength = value.length;
    int spaces = totalWidth - keyLength - valueLength;
    return key + ' ' * spaces + value;
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
    final mergedItems = mergeCartItems(cartItems);
    final totalQuantity = mergedItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
    final totalSales = mergedItems.fold<double>(0, (sum, item) => sum + (item['totalPrice'] as double));

    // Prepare data for pie chart
    final pieChartData = mergedItems.map((item) {
      return _PieChartData(
        item['productName'],
        item['totalPrice'],
        _getRandomColor(),
      );
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Sales Summary',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF470404),
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
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Range Selection Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Select Date Range',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF470404),
                        ),
                      ),
                      SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Start Date Row
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Date',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 4),
                              TextField(
                                controller: startDateController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  hintText: 'Start Date',
                                  suffixIcon: IconButton(
                                    onPressed: () => _selectStartDate(context),
                                    icon: Icon(Icons.calendar_today, size: 20),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade400),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade400),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          // End Date Row
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'End Date',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 4),
                              TextField(
                                controller: endDateController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  hintText: 'End Date',
                                  suffixIcon: IconButton(
                                    onPressed: () => _selectEndDate(context),
                                    icon: Icon(Icons.calendar_today, size: 20),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade400),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade400),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _fetchCartItems(
                              startDateController.text, endDateController.text);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF470404),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          'Apply Filter',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _generatePDF,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xFF470404),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Color(0xFF470404)),
                        ),
                        elevation: 2,
                      ),
                      icon: Icon(Icons.download, size: 20),
                      label: Text(
                        'PDF Report',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isPrinting ? null : _printSummary,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF470404),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: isPrinting
                          ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Icon(Icons.print, size: 20, color: Colors.white),
                      label: Text(
                        'Print',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Summary Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Summary',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF470404),
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Items:',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            mergedItems.length.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Quantity:',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            totalQuantity.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Divider(height: 1, color: Colors.grey[300]),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Sales:',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF470404),
                            ),
                          ),
                          Text(
                            NumberFormat.currency(symbol: 'Rs: ').format(totalSales),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF470404),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Sales Distribution Pie Chart
              if (mergedItems.isNotEmpty) ...[
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Sales Distribution',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF470404),
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          height: 300,
                          child: SfCircularChart(
                            legend: Legend(
                              isVisible: true,
                              overflowMode: LegendItemOverflowMode.wrap,
                              position: LegendPosition.bottom,
                            ),
                            series: <CircularSeries>[
                              PieSeries<_PieChartData, String>(
                                dataSource: pieChartData,
                                xValueMapper: (_PieChartData data, _) => data.productName,
                                yValueMapper: (_PieChartData data, _) => data.totalSales,
                                pointColorMapper: (_PieChartData data, _) => data.color,
                                dataLabelSettings: DataLabelSettings(
                                  isVisible: true,
                                  labelPosition: ChartDataLabelPosition.outside,
                                  textStyle: GoogleFonts.poppins(fontSize: 10),
                                  connectorLineSettings: ConnectorLineSettings(
                                    length: '10%',
                                    type: ConnectorType.curve,
                                  ),
                                  builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                                    return Text(
                                      '${data.productName}\nRs ${NumberFormat('#,##0.00').format(data.totalSales)}\n(${(data.totalSales / totalSales * 100).toStringAsFixed(1)}%)',
                                      style: GoogleFonts.poppins(fontSize: 10),
                                    );
                                  },
                                ),
                                explode: true,
                                explodeIndex: 0,
                                explodeOffset: '10%',
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        // Product legend with separate colors
                        Column(
                          children: [
                            Text(
                              'Product Breakdown',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF470404),
                              ),
                            ),
                            SizedBox(height: 8),
                            ...pieChartData.map((item) => Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: item.color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.productName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${(item.totalSales / totalSales * 100).toStringAsFixed(1)}%',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Rs ${NumberFormat('#,##0.00').format(item.totalSales)}',
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
              // Sales Table
              if (mergedItems.isNotEmpty) ...[
                Text(
                  'Sales Details',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF470404),
                  ),
                ),
                SizedBox(height: 12),
                SalesSummaryTable(mergedItems),
              ] else ...[
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No sales data found',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your date range',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRandomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.deepPurple,
      Colors.lightBlue,
      Colors.lime,
    ];
    return colors[(DateTime.now().millisecondsSinceEpoch % colors.length)];
  }
}

class _PieChartData {
  final String productName;
  final double totalSales;
  final Color color;

  _PieChartData(this.productName, this.totalSales, this.color);
}

class SalesSummaryTable extends StatelessWidget {
  final List<Map<String, dynamic>> mergedItems;

  SalesSummaryTable(this.mergedItems);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                dataRowHeight: 40,
                headingRowHeight: 40,
                columns: [
                  DataColumn(
                    label: Text(
                      'No.',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF470404),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Product',
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
                rows: mergedItems.asMap().entries.map((entry) {
                  int index = entry.key + 1;
                  var item = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text(
                        index.toString(),
                        style: GoogleFonts.poppins(),
                      )),
                      DataCell(Container(
                        width: 120,
                        child: Text(
                          item['productName'],
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(),
                        ),
                      )),
                      DataCell(Text(
                        item['quantity'].toString(),
                        style: GoogleFonts.poppins(),
                      )),
                      DataCell(Text(
                        NumberFormat.currency(symbol: 'Rs: ').format(item['price']),
                        style: GoogleFonts.poppins(),
                      )),
                      DataCell(Text(
                        NumberFormat.currency(symbol: 'Rs: ').format(item['totalPrice']),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}