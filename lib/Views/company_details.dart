import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../JsonModels/company_model.dart';
import '../SQLite/db_helper.dart';
import 'dashboard.dart';

class CompanyDetailsPage extends StatefulWidget {
  const CompanyDetailsPage({Key? key}) : super(key: key);

  @override
  _CompanyDetailsPageState createState() => _CompanyDetailsPageState();
}

class _CompanyDetailsPageState extends State<CompanyDetailsPage> {
  final DBHelper dbHelper = DBHelper();
  final _formKey = GlobalKey<FormState>();
  final _focusNode = FocusNode();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _startDateController;
  late TextEditingController _versionController;
  late TextEditingController _logoPathController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _startDateController = TextEditingController();
    _versionController = TextEditingController();
    _logoPathController = TextEditingController();

    _loadCompanyDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _startDateController.dispose();
    _versionController.dispose();
    _logoPathController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyDetails() async {
    CompanyModel? company = await dbHelper.getCompany(1);
    if (company != null) {
      setState(() {
        _nameController.text = company.companyName;
        _addressController.text = company.address;
        _phoneController.text = company.phone;
        _startDateController.text = company.startDate;
        _versionController.text = company.version;
        _logoPathController.text = company.logoPath;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF470404),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF470404),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      _startDateController.text = "${selectedDate.toLocal()}".split(' ')[0];
    }
  }

  Future<void> _saveCompanyDetails() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus(); // Close keyboard

      final company = CompanyModel(
        companyId: 1,
        companyName: _nameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        startDate: _startDateController.text,
        version: _versionController.text,
        logoPath: _logoPathController.text,
      );

      try {
        final existingCompany = await dbHelper.getCompany(1);
        if (existingCompany != null) {
          await dbHelper.updateCompany(company);
        } else {
          await dbHelper.insertCompany(company);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Company details ${existingCompany != null ? 'updated' : 'saved'} successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving company details: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Company Details',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE0FFFF),
            ),
          ),
          backgroundColor: Color(0xFF470404),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage()),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildSectionHeader('Basic Information'),
                          SizedBox(height: 20),
                          _buildTextField(
                            label: 'Company Name',
                            controller: _nameController,
                            icon: Icons.business,
                            validator: (value) => value!.isEmpty ? 'Please enter company name' : null,
                          ),
                          SizedBox(height: 20),
                          _buildTextField(
                            label: 'Address',
                            controller: _addressController,
                            icon: Icons.location_on,
                            validator: (value) => value!.isEmpty ? 'Please enter address' : null,
                            maxLines: 3,
                          ),
                          SizedBox(height: 20),
                          _buildTextField(
                            label: 'Phone Number',
                            controller: _phoneController,
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: (value) {
                              if (value!.isEmpty) return 'Please enter phone number';
                              if (value.length != 10) return 'Must be 10 digits';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildSectionHeader('Additional Information'),
                          SizedBox(height: 20),
                          _buildDateField(),
                          SizedBox(height: 20),
                          _buildTextField(
                            label: 'Version Number',
                            controller: _versionController,
                            icon: Icons.code,
                            validator: (value) => value!.isEmpty ? 'Please enter version' : null,
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveCompanyDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF470404),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                        shadowColor: Color(0xFF470404).withOpacity(0.3),
                      ),
                      child: Text(
                        'SAVE COMPANY DETAILS',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          height: 24,
          width: 5,
          decoration: BoxDecoration(
            color: Color(0xFF470404),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF470404),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: GoogleFonts.poppins(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
        prefixIcon: Icon(icon, color: Color(0xFF470404)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF470404), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _startDateController,
      readOnly: true,
      validator: (value) {
        if (value!.isEmpty) return 'Please select start date';
        try {
          DateTime.parse(value);
        } catch (e) {
          return 'Invalid date format';
        }
        return null;
      },
      style: GoogleFonts.poppins(color: Colors.black87),
      decoration: InputDecoration(
        labelText: 'Start Date',
        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
        prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF470404)),
        suffixIcon: IconButton(
          icon: Icon(Icons.arrow_drop_down, color: Color(0xFF470404)),
          onPressed: () => _selectDate(context),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF470404), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}