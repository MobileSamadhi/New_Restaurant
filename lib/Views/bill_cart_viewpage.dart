import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:synnex_mobi/Views/dashboard.dart';
import '../SQLite/print_bill_db.dart';

class BillAndCartViewPage extends StatefulWidget {
  @override
  _BillAndCartViewPageState createState() => _BillAndCartViewPageState();
}

class _BillAndCartViewPageState extends State<BillAndCartViewPage> {
  PrintBillDBHelper dbHelper = PrintBillDBHelper();
  List<int> billIds = [];
  List<Map<String, dynamic>> billDetails = [];
  int? selectedBillId;
  Map<String, dynamic>? commonBillDetails;

  @override
  void initState() {
    super.initState();
    fetchBillIds();
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
          'grossAmount': products[0]['grossAmount'],
          'discount': products[0]['discount'],
          'netAmount': products[0]['netAmount'],
        };
      });
    }
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
          icon: Icon(Icons.arrow_back, color: Colors.white),
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
                          Text('Date: ${commonBillDetails!['date']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Gross Amount: ${(commonBillDetails!['grossAmount'] as double).toStringAsFixed(2)}', style: TextStyle(fontSize: 16)),
                          Text('Discount: ${(commonBillDetails!['discount'] as double).toStringAsFixed(2)}', style: TextStyle(fontSize: 16)),
                          Text('Net Amount: ${(commonBillDetails!['netAmount'] as double).toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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