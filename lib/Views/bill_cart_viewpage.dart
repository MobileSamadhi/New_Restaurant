import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:synnex_mobile/Views/dashboard.dart';
import '../SQLite/cart_db.dart';

class BillAndCartViewPage extends StatefulWidget {
  @override
  _BillAndCartViewPageState createState() => _BillAndCartViewPageState();
}

class _BillAndCartViewPageState extends State<BillAndCartViewPage> {
  CartDatabaseHelper dbHelper = CartDatabaseHelper();
  List<int> billIds = [];
  List<Map<String, dynamic>> billDetails = [];
  int? selectedBillId;

  @override
  void initState() {
    super.initState();
    fetchBillIds();
  }

  Future<void> fetchBillIds() async {
    final products = await dbHelper.getAllProducts();
    final uniqueBillIds = products.map((product) => product['billId']).toSet().toList();
    setState(() {
      billIds = uniqueBillIds.cast<int>();
    });
  }

  Future<void> fetchBillDetails(int billId) async {
    final products = await dbHelper.getCartItems(
      startDate: '2000-01-01', // Arbitrary start date
      endDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final filteredProducts = products.where((product) => product['billId'] == billId).toList();
    setState(() {
      billDetails = filteredProducts;
      selectedBillId = billId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bill and Cart View',
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
                  : ListView.builder(
                itemCount: billDetails.length,
                itemBuilder: (context, index) {
                  final product = billDetails[index];
                  return Card(
                    color:  Color(0xFFDAB3AC),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Date: ${product['date']}', style: TextStyle(color: Colors.black54)),
                              Text('Time: ${product['time']}', style: TextStyle(color: Colors.black54)),
                            ],
                          ),
                          SizedBox(height: 5),
                          Text('Total: ${(product['quantity'] * product['price']).toStringAsFixed(2)}', style: TextStyle(color: Colors.black)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}