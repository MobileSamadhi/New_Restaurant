import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:synnex_mobi/Views/bill_page.dart';
import 'package:synnex_mobi/Views/print_bill.dart';

class PaymentPage extends StatefulWidget {
  final double amount;
  final String billNumber;
  final List<Map<String, dynamic>> cart;
  final double discount;
  final double grossAmount;
  final String user;
  final String address;
  final String contactNumber;

  const PaymentPage({
    Key? key,
    required this.amount,
    required this.billNumber,
    required this.cart,
    required this.discount,
    required this.grossAmount,
    required this.user,
    required this.address,
    required this.contactNumber,
  }) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _paymentSuccess = false;
  String _successMessage = '';
  String selectedCardType = 'Visa';
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountPaidController = TextEditingController();
  final TextEditingController _changeController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _cardNumberFocusNode = FocusNode();
  final FocusNode _cardHolderFocusNode = FocusNode();
  final FocusNode _expiryFocusNode = FocusNode();
  final FocusNode _cvvFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _amountPaidController.text = widget.amount.toStringAsFixed(2);
    _amountPaidController.addListener(_calculateChange);
  }

  @override
  void dispose() {
    _amountPaidController.dispose();
    _changeController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _amountFocusNode.dispose();
    _cardNumberFocusNode.dispose();
    _cardHolderFocusNode.dispose();
    _expiryFocusNode.dispose();
    _cvvFocusNode.dispose();
    super.dispose();
  }

  void _calculateChange() {
    double amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;
    double change = amountPaid - widget.amount;
    _changeController.text = change.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Payment Options',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF470404),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Payment Summary Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white,
                    shadowColor: Colors.black.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.receipt, color: Color(0xFF470404), size: 24),
                              const SizedBox(width: 10),
                              Text(
                                'Payment Summary',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF470404),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSummaryRow('Bill Number:', widget.billNumber),
                          _buildSummaryRow('Gross Amount:', 'Rs. ${widget.grossAmount.toStringAsFixed(2)}'),
                          _buildSummaryRow('Discount:', 'Rs. ${widget.discount.toStringAsFixed(2)}'),
                          const Divider(height: 24, thickness: 1),
                          _buildSummaryRow(
                            'Total Amount:',
                            'Rs. ${widget.amount.toStringAsFixed(2)}',
                            isHighlighted: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Options
                  Text(
                    'Select Payment Method',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Cash Payment Button
                  _buildPaymentOption(
                    icon: Icons.money,
                    title: 'Cash Payment',
                    color: Color(0xFFCD7F32),
                    onTap: () => _handlePaymentMethod('cash'),
                  ),
                  const SizedBox(height: 16),

                  // Card Payment Button
                  _buildPaymentOption(
                    icon: Icons.credit_card,
                    title: 'Card Payment',
                    color: Color(0xFFC19A6B),
                    onTap: () => _handlePaymentMethod('card'),
                  ),
                  const SizedBox(height: 24),

                  // Success Message and Print Button
                  if (_paymentSuccess) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _successMessage,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _navigateToPrintBill,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF470404),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.print, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              'Print Bill',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isHighlighted ? const Color(0xFF470404) : Colors.black87,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _handlePaymentMethod(String method) {
    if (widget.amount <= 0) {
      _showErrorDialog('Invalid Amount', 'Please enter a valid amount to pay.');
      return;
    }

    if (method == 'cash') {
      _showCashPaymentDialog();
    } else {
      _showCardPaymentDialog();
    }
  }

  void _showCashPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.money, color: Color(0xFF470404), size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Cash Payment',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF470404),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _amountPaidController,
                  focusNode: _amountFocusNode,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount Paid',
                    prefixText: 'Rs. ',
                    prefixStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFF470404), width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  style: GoogleFonts.poppins(),
                  onChanged: (value) => _calculateChange(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _changeController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Change',
                    prefixText: 'Rs. ',
                    prefixStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _completeCashPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF470404),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Complete',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
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
    ).then((_) => _amountFocusNode.unfocus());
  }

  void _showCardPaymentDialog() {
    String dialogSelectedCardType = selectedCardType;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.credit_card, color: Color(0xFF470404), size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Card Payment',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF470404),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: dialogSelectedCardType,
                      onChanged: (String? newValue) {
                        dialogSetState(() {
                          dialogSelectedCardType = newValue!;
                        });
                      },
                      items: ['Visa', 'MasterCard', 'American Express'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Icon(
                                Icons.credit_card,
                                color: _getCardColor(value),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                value,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        labelText: 'Card Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Color(0xFF470404), width: 1.5),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(Icons.arrow_drop_down),
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF470404).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFF470404).withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Amount to Pay:',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Rs. ${widget.amount.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF470404),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedCardType = dialogSelectedCardType;
                              _paymentSuccess = true;
                              _successMessage = 'Payment of Rs. ${widget.amount.toStringAsFixed(2)} with ${selectedCardType} processed successfully';
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF470404),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Process',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
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
      },
    );
  }

  Color _getCardColor(String cardType) {
    switch (cardType) {
      case 'Visa': return Colors.blue;
      case 'MasterCard': return Colors.red;
      case 'American Express': return Colors.green;
      default: return Colors.grey;
    }
  }

  void _completeCashPayment() {
    if (_amountPaidController.text.isEmpty) {
      _showErrorDialog('Invalid Amount', 'Please enter the amount paid.');
      return;
    }

    final amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;
    if (amountPaid < widget.amount) {
      _showErrorDialog('Insufficient Amount', 'Amount paid is less than the total.');
      return;
    }

    setState(() {
      _paymentSuccess = true;
      _successMessage = 'Cash payment of Rs. ${_amountPaidController.text} received successfully. Change: Rs. ${_changeController.text}';
    });
    Navigator.pop(context);
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF470404),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToPrintBill() {
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
          contactNumber: widget.contactNumber,
          user: widget.user,
          address: widget.address,
        ),
      ),
    );
  }
}