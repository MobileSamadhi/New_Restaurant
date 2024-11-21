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

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      final formattedDate = "${selectedDate.toLocal()}".split(' ')[0]; // Format to YYYY-MM-DD
      controller.text = formattedDate;
    }
  }

  Future<void> _saveCompanyDetails() async {
    if (_formKey.currentState!.validate()) {
      CompanyModel company = CompanyModel(
        companyId: 1, // Assuming a single company record with ID 1
        companyName: _nameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        startDate: _startDateController.text,
        version: _versionController.text,
        logoPath: _logoPathController.text,
      );

      // Check if company exists
      CompanyModel? existingCompany = await dbHelper.getCompany(1);
      if (existingCompany != null) {
        // Update existing company
        await dbHelper.updateCompany(company);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company details updated successfully')),
        );
      } else {
        // Insert new company
        await dbHelper.insertCompany(company);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company details saved successfully')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _startDateController.dispose();
    _versionController.dispose();
    _logoPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Company Details',
          style: GoogleFonts.poppins(
            fontSize: 22, // Adjust the font size as needed
            fontWeight: FontWeight.bold, // Adjust the font weight as needed
            color: Color(0xFFE0FFFF), // Adjust the text color as needed
          ),
        ),
        backgroundColor: Color(0xFF470404),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                buildEditableField('Company Name:', _nameController, validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the company name';
                  }
                  return null;
                }),
                buildDivider(),
                buildEditableField('Address:', _addressController, validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the address';
                  }
                  return null;
                }),
                buildDivider(),
                buildEditableField('Phone No:', _phoneController, validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the phone number';
                  }
                  if (value.length != 10) {
                    return 'Phone number must be exactly 10 digits';
                  }
                  return null;
                }),
                buildDivider(),
                buildEditableField(
                  'Start Date:',
                  _startDateController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the start date';
                    }
                    try {
                      DateTime.parse(value); // Check if the value can be parsed as a date
                    } catch (e) {
                      return 'Please enter a valid date in YYYY-MM-DD format';
                    }
                    return null;
                  },
                  iconButton: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context, _startDateController),
                  ),
                ),
                buildDivider(),
                buildEditableField('Version No:', _versionController, validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the version number';
                  }
                  return null;
                }),
                buildDivider(),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _saveCompanyDetails,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Color(0xFFad6c47),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      textStyle: TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Save Details'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Divider buildDivider() {
    return Divider(
      color: Colors.grey,
      thickness: 1,
      height: 30,
    );
  }

  Widget buildEditableField(String label, TextEditingController controller, {String? Function(String?)? validator, IconButton? iconButton}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFad6c47),
          ),
        ),
        SizedBox(height: 5),
        TextFormField(
          controller: controller,
          style: TextStyle(fontSize: 16, color: Colors.black87),
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            suffixIcon: iconButton, // Add the icon button here
          ),
          keyboardType: label == 'Phone No:' ? TextInputType.phone : TextInputType.text,
          inputFormatters: label == 'Phone No:' ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)] : [],
          validator: validator,
        ),
        SizedBox(height: 10),
      ],
    );
  }
}
