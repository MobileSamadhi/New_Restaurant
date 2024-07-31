import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../JsonModels/add_product_model.dart';
import '../JsonModels/product_model.dart';
import 'bill_page.dart'; // Ensure correct import if using AddProductModel

class PrintBillPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart; // Add cart
  final String billNumber;
  final DateTime dateTime;
  final String address;
  final String contactNumber;
  final String user;
  final double grossAmount;
  final double discount;
  final double netAmount;

  PrintBillPage({
    required this.cart,
    required this.billNumber,
    required this.dateTime,
    required this.address,
    required this.contactNumber,
    required this.user,
    required this.grossAmount,
    required this.discount,
    required this.netAmount,
  })
  {
    print('Received Bill Number: $billNumber');
    print('Received received Items: ${cart.map((item) => item.toString()).join(', ')}');
// Add other prints to verify values
  }

  @override
  _PrintBillPageState createState() => _PrintBillPageState();
}

class _PrintBillPageState extends State<PrintBillPage> {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  @override
  void initState() {
    super.initState();
    connectToPrinter();
  }

  Future<void> connectToPrinter() async {
    List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
    if (devices.isNotEmpty) {
      await bluetooth.connect(devices[0]);
    }
  }

  Future<void> _printBill() async {
    String addCenterMargin(String text, {int totalWidth = 42}) {
      int padding = (totalWidth - text.length) ~/ 2;
      return ' ' * padding + text + ' ' * padding;
    }

    String addRightMargin(String text, {int totalWidth = 42, int rightMargin = 10}) {
      int padding = totalWidth - text.length - rightMargin;
      return text.padRight(totalWidth - rightMargin);
    }

    bluetooth.printCustom("", 1, 1);
    bluetooth.printCustom(addCenterMargin("Synnex IT Solution", totalWidth: 42), 5, 1);
    bluetooth.printNewLine();
    bluetooth.printCustom(addCenterMargin("117 Galle Rd, Colombo 00400", totalWidth: 42), 1, 1);
    bluetooth.printCustom(addCenterMargin("Contact No: 0777452345", totalWidth: 42), 1, 1);
    bluetooth.printNewLine();
    bluetooth.printCustom(addRightMargin("Bill No: ${widget.billNumber}", totalWidth: 42), 1, 1);
    bluetooth.printCustom(addRightMargin("Date: ${DateFormat('yyyy-MM-dd HH:mm').format(widget.dateTime)}", totalWidth: 42), 1, 1);
    bluetooth.printNewLine();
    bluetooth.printCustom(addRightMargin("------------------------------------------", totalWidth: 42), 1, 1);
    bluetooth.printNewLine();

    bluetooth.printCustom(addRightMargin("Name          Qty     Price     Total", totalWidth: 42), 1, 1);
    bluetooth.printCustom(addRightMargin("------------------------------------------", totalWidth: 42), 1, 1);

    for (var item in widget.cart) {
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
      var quantity = item['quantity'].toString();
      var total = (price * item['quantity']).toStringAsFixed(2);

      String itemLine = formatLine(name, quantity, price.toStringAsFixed(2), total);
      bluetooth.printCustom(addRightMargin(itemLine, totalWidth: 42), 1, 1);
    }

    bluetooth.printCustom(addRightMargin("------------------------------------------", totalWidth: 42), 1, 1);
    bluetooth.printNewLine();
    bluetooth.printCustom(addRightMargin(formatRightAligned("Gross Amount:", widget.grossAmount.toStringAsFixed(2)), totalWidth: 42), 1, 1);
    bluetooth.printCustom(addRightMargin(formatRightAligned("Discount:", widget.discount.toStringAsFixed(2)), totalWidth: 42), 1, 1);
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
          'Print Bill',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE0FFFF),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => BillingPage()),
            );
          },
        ),
        backgroundColor: Color(0xFF0072BC),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Center(
                  child: Text(
                    widget.address,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Center(
                  child: Text(
                    'Contact No: ${widget.contactNumber}',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Center(
                  child: Text(
                    'Bill Id: ${widget.billNumber}',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Center(
                  child: Text(
                    'User: ${widget.user}',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                DataTable(
                  columns: const <DataColumn>[
                    DataColumn(
                      label: Text(
                        'Name',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Qty',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Price',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Total',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                  rows: widget.cart.map((item) {
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
                      cells: <DataCell>[
                        DataCell(Text(name)),
                        DataCell(Text(item['quantity'].toString())),
                        DataCell(Text(price.toStringAsFixed(2))),
                        DataCell(Text((price * item['quantity']).toStringAsFixed(2))),
                      ],
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    'Gross Amount: ${widget.grossAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Discount: ${widget.discount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Net Amount: ${widget.netAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    'Thank you, come again!',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Software provided by:',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Synnex IT Solution',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _printBill,
                    child: Text('Print Bill'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
