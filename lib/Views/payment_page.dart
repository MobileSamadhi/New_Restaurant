import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
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
        title: const Text(
          'Payment Options',
          style: TextStyle(
            fontSize: 25, // Adjust the font size as needed
            fontWeight: FontWeight.bold, // Adjust the font weight as needed
            color: Color(0xFF414042), // Adjust the text color as needed
          ),
        ),
        backgroundColor: const Color(0xFF0072bc),
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
                    color: Color(0xFF0072bc),
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
                    backgroundColor: Colors.green,
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
                    backgroundColor: Colors.blue,
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
                              items: widget.cart,
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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
                if (color == Colors.green) {
                  // Return true to indicate a successful payment
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.teal),
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
          title: const Text('Cash Payment', style: TextStyle(color: Colors.green)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Please enter the amount paid and the change to be returned:',
                    style: TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _amountPaidController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the amount paid';
                      }
                      double amountPaid = double.tryParse(value) ?? 0.0;
                      if (amountPaid < widget.amount) {
                        return 'Amount paid must be equal to or greater than ${widget.amount}';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Amount Paid',
                      labelStyle: TextStyle(color: Colors.teal),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.teal),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.teal),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _changeController,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Change',
                      labelStyle: TextStyle(color: Colors.teal),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.teal),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.teal),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Reset payment success status
                setState(() {
                  _paymentSuccess = false;
                });
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    _paymentSuccess = true; // Update payment success status
                  });
                  Navigator.of(context).pop();
                  _showMessage(context, 'Payment Result', 'Payment Successful', Colors.green);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Submit'),
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
          title: const Text('Card Payment', style: TextStyle(color: Colors.blue)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Please select card type:',
                    style: TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedCardType,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCardType = newValue!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Card Type',
                      labelStyle: TextStyle(color: Colors.teal),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.teal),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.teal),
                      ),
                    ),
                    items: <String>[
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
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _paymentSuccess = false;
                });
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    _paymentSuccess = true; // Update payment success status
                  });
                  Navigator.of(context).pop();
                  _showMessage(context, 'Payment Result', 'Payment Successful', Colors.green);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
