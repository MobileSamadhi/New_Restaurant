import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synnex_mobi/Views/dashboard.dart';
import '../JsonModels/company_model.dart';
import '../SQLite/db_helper.dart';
import '../SQLite/print_bill_db.dart';
import '../SQLite/sqlite.dart';

class CashRefundPage extends StatefulWidget {
  const CashRefundPage({Key? key}) : super(key: key);

  @override
  _CashRefundPageState createState() => _CashRefundPageState();
}

class _CashRefundPageState extends State<CashRefundPage> {
  final PrintBillDBHelper _dbHelper = PrintBillDBHelper();
  final DatabaseHelper _userDbHelper = DatabaseHelper();
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _selectedItems = [];
  double _totalRefundAmount = 0.0;
  bool _isSearching = false;
  bool _isProcessing = false;
  bool _isPrinting = false;
  String _currentUser = 'Guest';
  final DBHelper dbHelper = DBHelper();
  CompanyModel? company;

  static const Color darkRedColor = Color(0xFF470404);

  @override
  void initState() {
    super.initState();
    _connectToPrinter();
    _loadCurrentUser();
    _loadCompanyDetails();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _connectToPrinter() async {
    List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
    if (devices.isNotEmpty) {
      await _bluetooth.connect(devices[0]);
    }
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
        _currentUser = prefUser;
      });
      return;
    }

    // Fallback to database if not in SharedPreferences
    String? dbUser = await _userDbHelper.getCurrentUser();
    if (dbUser != null) {
      setState(() {
        _currentUser = dbUser;
      });
      await prefs.setString('currentUser', dbUser);
    }
  }

  Future<void> _searchBills() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    final billId = int.tryParse(_searchController.text);
    if (billId == null) {
      setState(() => _isSearching = false);
      return;
    }

    await Future.delayed(const Duration(milliseconds: 300));

    final results = await _dbHelper.getBillsById(billId);
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  void _toggleItemSelection(Map<String, dynamic> item) {
    setState(() {
      if (_selectedItems.any((i) => i['id'] == item['id'])) {
        _selectedItems.removeWhere((i) => i['id'] == item['id']);
      } else if ((item['remainingQuantity'] as int) > 0) {
        _selectedItems.add(item);
      }
      _calculateTotalRefund();
    });
  }

  void _calculateTotalRefund() {
    _totalRefundAmount = _selectedItems.fold(
      0.0,
          (double sum, Map<String, dynamic> item) {
        final price = (item['price'] as num).toDouble();
        final quantity = (item['remainingQuantity'] as int);
        return sum + (price * quantity);
      },
    );
  }

  Future<int?> _showQuantityDialog(Map<String, dynamic> item) async {
    int selectedQuantity = 1;
    final maxQuantity = item['remainingQuantity'] as int;
    final productName = item['productName'] ?? 'Product';
    final price = (item['price'] as num).toDouble();

    return showDialog<int>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 4,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Refund Quantity',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkRedColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Product Info Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available: $maxQuantity',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            'Price: RS ${price.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: darkRedColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quantity Selector
                StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Decrease Button
                            Container(
                              decoration: BoxDecoration(
                                color: selectedQuantity > 1
                                    ? darkRedColor.withOpacity(0.2)
                                    : Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(Icons.remove,
                                    color: selectedQuantity > 1
                                        ? darkRedColor
                                        : Colors.grey),
                                onPressed: () {
                                  if (selectedQuantity > 1) {
                                    setState(() => selectedQuantity--);
                                  }
                                },
                              ),
                            ),

                            // Quantity Display
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$selectedQuantity',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // Increase Button
                            Container(
                              decoration: BoxDecoration(
                                color: selectedQuantity < maxQuantity
                                    ? darkRedColor.withOpacity(0.2)
                                    : Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(Icons.add,
                                    color: selectedQuantity < maxQuantity
                                        ? darkRedColor
                                        : Colors.grey),
                                onPressed: () {
                                  if (selectedQuantity < maxQuantity) {
                                    setState(() => selectedQuantity++);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Amount Display
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: darkRedColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Refund Amount:',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'RS ${(price * selectedQuantity).toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: darkRedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, null),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: darkRedColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            color: darkRedColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, selectedQuantity),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkRedColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Confirm Refund',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _processRefund() async {
    if (_selectedItems.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final currentDate = DateTime.now().toIso8601String();
      final refundRecords = <Map<String, dynamic>>[];

      for (final item in _selectedItems) {
        final refundQty = await _showQuantityDialog(item);
        if (refundQty == null || refundQty <= 0) continue;

        final refundAmount = (item['price'] as num).toDouble() * refundQty;

        await _dbHelper.updateRefundQuantity(
          item['id'],
          (item['refundQuantity'] ?? 0) + refundQty,
        );

        final refundRecord = {
          'originalBillId': item['id'],
          'productId': item['productId'],
          'productName': item['productName'],
          'originalQuantity': item['quantity'],
          'refundQuantity': refundQty,
          'price': item['price'],
          'amountRefunded': refundAmount,
          'refundDate': currentDate,
          'refundBy': _currentUser,
        };

        await _dbHelper.addRefundRecord(refundRecord);
        refundRecords.add(refundRecord);
      }

      // Print refund receipt after processing all items
      if (refundRecords.isNotEmpty) {
        await _printRefundReceipt(refundRecords);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Refund processed successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing refund: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        _selectedItems.clear();
        _totalRefundAmount = 0.0;
        _isProcessing = false;
        _searchBills();
      });
    }
  }

  Future<void> _printRefundReceipt(List<Map<String, dynamic>> refundRecords) async {
    if (_isPrinting) return;

    setState(() => _isPrinting = true);

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

      // Load company details if not already loaded
      if (company == null) {
        await _loadCompanyDetails();
      }

      // Print company header
      if (company != null) {
        _bluetooth.printCustom(company!.companyName, 1, 1);
        _bluetooth.printNewLine();
        _bluetooth.printCustom(company!.address, 0, 1);
        _bluetooth.printCustom(company!.phone, 0, 1);
        _bluetooth.printNewLine();
      }

      _bluetooth.printCustom(addCenterMargin("REFUND RECEIPT", totalWidth: 42), 1, 1);
      _bluetooth.printNewLine();

      // Print refund info
      final now = DateTime.now();
      _bluetooth.printCustom(leftRightAlign('Refund No :', 'REF-${now.millisecondsSinceEpoch}'), 0, 1);
      _bluetooth.printCustom(leftRightAlign('Date :', DateFormat('yyyy-MM-dd').format(now)), 0, 1);
      _bluetooth.printCustom(leftRightAlign('Time :', DateFormat('HH:mm:ss').format(now)), 0, 1);
      _bluetooth.printCustom(leftRightAlign('Cashier :', _currentUser), 0, 1);
      _bluetooth.printNewLine();

      _bluetooth.printCustom(addRightMargin("------------------------------------------", totalWidth: 42), 0, 1);
      _bluetooth.printNewLine();

      _bluetooth.printCustom(addRightMargin("No  Name          Qty     Price     Total", totalWidth: 42), 0, 1);
      _bluetooth.printCustom(addRightMargin("------------------------------------------", totalWidth: 42), 0, 1);

      double totalRefundAmount = 0.0;
      int totalRefundItems = 0;
      int totalRefundQuantity = 0;

      for (var i = 0; i < refundRecords.length; i++) {
        var record = refundRecords[i];
        String name = record['productName'];
        double price = (record['price'] as num).toDouble();
        int quantity = record['refundQuantity'] as int;
        double amount = (record['amountRefunded'] as num).toDouble();

        String itemLine = _formatLine(
            (i + 1).toString(),
            name,
            quantity.toString(),
            price.toStringAsFixed(2),
            amount.toStringAsFixed(2)
        );
        _bluetooth.printCustom(addRightMargin(itemLine, totalWidth: 42), 0, 1);

        totalRefundItems++;
        totalRefundQuantity += quantity;
        totalRefundAmount += amount;
      }

      _bluetooth.printCustom(addRightMargin("------------------------------------------", totalWidth: 42), 0, 1);
      _bluetooth.printNewLine();
      _bluetooth.printCustom(addRightMargin(_formatRightAligned("Total Items:", totalRefundItems.toString()), totalWidth: 42), 0, 1);
      _bluetooth.printCustom(addRightMargin(_formatRightAligned("Total Quantity:", totalRefundQuantity.toString()), totalWidth: 42), 0, 1);
      _bluetooth.printNewLine();
      _bluetooth.printCustom(addRightMargin(_formatRightAligned("Total Refund:", totalRefundAmount.toStringAsFixed(2)), totalWidth: 42), 0, 1);
      _bluetooth.printNewLine();
      _bluetooth.printCustom(addRightMargin("------------------------------------------", totalWidth: 42), 0, 1);
      _bluetooth.printNewLine();

      _bluetooth.printCustom(addCenterMargin("Thank You!", totalWidth: 42), 0, 1);
      if (company != null) {
        _bluetooth.printCustom(addCenterMargin(company!.companyName, totalWidth: 42), 0, 1);
      }
      _bluetooth.printCustom(addCenterMargin("Software provided by", totalWidth: 42), 0, 1);
      _bluetooth.printCustom(addCenterMargin("Synnex IT Solution", totalWidth: 42), 0, 1);
      _bluetooth.printNewLine();

      _bluetooth.printCustom("", 0, 1);
      _bluetooth.paperCut();

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
      setState(() => _isPrinting = false);
    }
  }

  String _formatLine(String no, String name, String qty, String price, String total) {
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

  String _formatRightAligned(String key, String value, {int totalWidth = 42}) {
    int keyLength = key.length;
    int valueLength = value.length;
    int spaces = totalWidth - keyLength - valueLength;
    return key + ' ' * spaces + value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkRedColor,
        title: Text(
          "Cash Refund",
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
              MaterialPageRoute(builder: (context) => DashboardPage()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Enter Bill ID',
                          labelStyle: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.6)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          prefixIcon: Icon(Icons.search, color: darkRedColor),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: colorScheme.onSurface),
                        onSubmitted: (_) => _searchBills(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _isSearching ? 48 : 120,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [darkRedColor, darkRedColor.withOpacity(0.7)],
                        ),
                      ),
                      child: _isSearching
                          ? const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                          : ElevatedButton(
                        onPressed: _searchBills,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Search',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _searchResults.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: darkRedColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No bills found',
                        style: TextStyle(
                          fontSize: 18,
                          color: darkRedColor.withOpacity(0.6),
                        ),
                      ),
                      if (_searchController.text.isEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Enter a bill ID to search',
                          style: TextStyle(
                            color: darkRedColor.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final item = _searchResults[index];
                    final isSelected = _selectedItems.any((i) => i['id'] == item['id']);
                    final remainingQty = item['remainingQuantity'] as int;
                    final isFullyRefunded = item['isFullyRefunded'] as bool;
                    final refundQty = item['refundQuantity'] ?? 0;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: darkRedColor.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? darkRedColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        color: isSelected
                            ? darkRedColor.withOpacity(0.05)
                            : (isFullyRefunded
                            ? Colors.grey[200]
                            : colorScheme.surface),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: isFullyRefunded ? null : () => _toggleItemSelection(item),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  onChanged: isFullyRefunded
                                      ? null
                                      : (_) => _toggleItemSelection(item),
                                  activeColor: darkRedColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['productName'] ?? 'Unnamed Product',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: darkRedColor,
                                          decoration: isFullyRefunded
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Chip(
                                            label: Text(
                                              'Qty: ${item['quantity']}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor: darkRedColor,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          const SizedBox(width: 8),
                                          Chip(
                                            label: Text(
                                              'Price: RS ${NumberFormat.currency(
                                                decimalDigits: 2,
                                                symbol: '',
                                              ).format(item['price'])}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor: darkRedColor,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Date: ${item['date']} ${item['time']}',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: darkRedColor.withOpacity(0.6),
                                                ),
                                              ), // Added missing comma here
                                              if (isFullyRefunded)
                                                const Text(
                                                  'FULLY REFUNDED',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              if (!isFullyRefunded && refundQty > 0)
                                                Text(
                                                  'Refunded: $refundQty (RS ${NumberFormat.currency(
                                                    decimalDigits: 2,
                                                    symbol: '',
                                                  ).format((item['price'] as num).toDouble() * refundQty)})',
                                                  style: const TextStyle(
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          Text(
                                            'RS: ${NumberFormat.currency(
                                              decimalDigits: 2,
                                              symbol: '',
                                            ).format(item['netAmount'])}',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: darkRedColor,
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
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_selectedItems.isNotEmpty) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: darkRedColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: darkRedColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Items Selected:',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: darkRedColor,
                          ),
                        ),
                        Text(
                          '${_selectedItems.length}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: darkRedColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Refund:',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: darkRedColor,
                          ),
                        ),
                        Text(
                          'RS: ${NumberFormat.currency(
                            decimalDigits: 2,
                            symbol: '',
                          ).format(_totalRefundAmount)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: darkRedColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: _isProcessing || _isPrinting
                          ? ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkRedColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                      )
                          : ElevatedButton.icon(
                        onPressed: _processRefund,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkRedColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.currency_exchange),
                        label: const Text(
                          'Process Refund',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}