import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:synnex_mobile/Views/bill_page.dart';
import 'package:synnex_mobile/Views/print_bill.dart'; // Import the PrintBillPage

class PaymentPage extends StatefulWidget {
  final double amount;
  final String billNumber; // Add billNumber
  final List<Map<String, dynamic>> cart; // Add cart
  final double discount; // Add discount
  final double grossAmount; // Add grossAmount
  final String user; // Add user

  PaymentPage({
    required this.amount,
    required this.billNumber,
    required this.cart,
    required this.discount,
    required this.grossAmount,
    required this.user,
  });

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _paymentSuccess = false;
  String selectedCardType = 'Visa'; // Default selection
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountPaidController = TextEditingController();
  final TextEditingController _changeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountPaidController.text = widget.amount.toStringAsFixed(2); // Auto load the amount to be paid
    _amountPaidController.addListener(_calculateChange);
  }

  @override
  void dispose() {
    _amountPaidController.dispose();
    _changeController.dispose();
    super.dispose();
  }

  void _calculateChange() {
    double amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;
    double change = amountPaid - widget.amount;
    _changeController.text = change.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment Options',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE0FFFF),
          ),
        ),
        backgroundColor: const Color(0xFF470404),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[200],
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Amount to Pay: ${widget.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFad6c47),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    if (widget.amount <= 0) {
                      _showMessage(context, 'Invalid Amount', 'Please enter a valid amount to pay.', Colors.red);
                    } else {
                      _showCashPaymentDialog(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFCD7F32),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                  child: const Text('Pay with Cash'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (widget.amount <= 0) {
                      _showMessage(context, 'Invalid Amount', 'Please enter a valid amount to pay.', Colors.red);
                    } else {
                      _showCardPaymentDialog(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFC19A6B),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                  child: const Text('Pay with Card'),
                ),
                const SizedBox(height: 20),
                _paymentSuccess
                    ? Column(
                  children: [
                    const Text(
                      'Payment Successful',
                      style: TextStyle(color: Colors.green, fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrintBillPage(
                              cart: widget.cart,
                              address: '117 Galle Rd, Colombo 00400',
                              billNumber: widget.billNumber,
                              dateTime: DateTime.now(),
                              discount: widget.discount,
                              grossAmount: widget.grossAmount,
                              netAmount: widget.amount,
                              contactNumber: '',
                              user: widget.user,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF470404)),
                      child: const Text('Print Bill'),
                    ),
                  ],
                )
                    : const SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String title, String message, Color color) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(color: color),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFF470404)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCashPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: const Color(0xFFF9F9F9),
          title: Row(
            children: [
              const Icon(Icons.money, color: Color(0xFF470404)),
              const SizedBox(width: 8),
              const Text(
                'Cash Payment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF470404),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Please enter the amount paid and view the change:',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _amountPaidController,
                  enabled: true,
                  decoration: InputDecoration(
                    labelText: 'Amount Paid',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF470404)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF470404)),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _changeController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Change',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF470404)),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _paymentSuccess = false;
                });
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF470404),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    _paymentSuccess = true;
                  });
                  Navigator.of(context).pop();
                  _showMessage(context, 'Payment Successful', 'Cash payment received successfully.', Colors.green);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrintBillPage(
                        cart: widget.cart,
                        billNumber: widget.billNumber,
                        dateTime: DateTime.now(),
                        discount: widget.discount,
                        grossAmount: widget.grossAmount,
                        netAmount: widget.amount,
                        contactNumber: '',
                        user: widget.user,
                        address: '117 Galle Rd, Colombo 00400',
                      ),
                    ),
                  );
                }
              },
              label: const Text(
                'Submit',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCardPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: const Color(0xFFF9F9F9),
          title: Row(
            children: [
              const Icon(Icons.credit_card, color: Color(0xFF470404)),
              const SizedBox(width: 8),
              const Text(
                'Card Payment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF470404),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Please select your card type:',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCardType,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCardType = newValue!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Card Type',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF470404)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF470404)),
                    ),
                  ),
                  items: const <String>[
                    'Visa',
                    'MasterCard',
                    'American Express',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Text(
                  'Amount to Pay: ${widget.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _paymentSuccess = false;
                });
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF470404),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    _paymentSuccess = true;
                  });
                  Navigator.of(context).pop();
                  _showMessage(context, 'Payment Successful', 'Card payment processed successfully.', Colors.green);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrintBillPage(
                        cart: widget.cart,
                        billNumber: widget.billNumber,
                        dateTime: DateTime.now(),
                        discount: widget.discount,
                        grossAmount: widget.grossAmount,
                        netAmount: widget.amount,
                        contactNumber: '',
                        user: widget.user,
                        address: '117 Galle Rd, Colombo 00400',
                      ),
                    ),
                  );
                }
              },
              label: const Text(
                'Submit',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }
}
