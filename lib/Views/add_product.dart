import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synnex_mobi/JsonModels/add_product_model.dart';
import 'package:synnex_mobi/SQLite/add_product_db.dart';
import 'package:synnex_mobi/SQLite/sqlite.dart';
import 'package:synnex_mobi/Views/products.dart';
import '../JsonModels/category_model.dart';
import '../JsonModels/product_model.dart';
import '../SQLite/category_db.dart';
import 'dart:io';

class AddProduct extends StatefulWidget {
  const AddProduct({Key? key}) : super(key: key);

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final title = TextEditingController();
  final price = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final _focusNode = FocusNode();

  final database = AddProductDb();
  final db = DatabaseHelper();

  String selectedCategory = '';
  List<CategoryModel> categories = [];
  File? _image;

  @override
  void initState() {
    super.initState();
    fetchActiveCategories();
  }

  @override
  void dispose() {
    title.dispose();
    price.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void fetchActiveCategories() async {
    categories = await DatabaseHelper().getCategories(activeOnly: true);
    if (categories.isNotEmpty) {
      setState(() {
        selectedCategory = categories[0].categoryName;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');

        setState(() {
          _image = savedImage;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image selection failed: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF470404),
          title: Text(
            "Add Products",
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
                MaterialPageRoute(builder: (context) => Products()),
              );
            },
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF9F9F9),
                Color(0xFFEEEEEE),
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Product Information Card
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Product Information'),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: title,
                            label: 'Product Name',
                            icon: Icons.shopping_bag,
                            validator: (value) => value!.isEmpty ? 'Required field' : null,
                          ),
                          const SizedBox(height: 20),
                          _buildPriceField(),
                          const SizedBox(height: 20),
                          _buildCategoryDropdown(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Image Upload Card
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Product Image'),
                          const SizedBox(height: 15),
                          _buildImageUploadSection(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Submit Button
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF470404),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                        shadowColor: const Color(0xFF470404).withOpacity(0.3),
                      ),
                      child: Text(
                        'ADD PRODUCT',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
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
          width: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF470404),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(color: Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
        prefixIcon: Icon(icon, color: const Color(0xFF470404)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF470404), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: price,
      validator: (value) {
        if (value!.isEmpty) return 'Required field';
        if (double.tryParse(value) == null) return 'Invalid number';
        return null;
      },
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      style: GoogleFonts.poppins(color: Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Unit Price',
        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
        prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF470404)),
        prefixText: 'Rs. ',
        prefixStyle: GoogleFonts.poppins(color: Colors.grey[700]),
        suffixText: '.00',
        suffixStyle: GoogleFonts.poppins(color: Colors.grey[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF470404), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCategory.isNotEmpty ? selectedCategory : null,
      items: categories.map((category) {
        return DropdownMenuItem<String>(
          value: category.categoryName,
          child: Text(
            category.categoryName,
            style: GoogleFonts.poppins(),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            selectedCategory = newValue;
          });
        }
      },
      decoration: InputDecoration(
        labelText: "Category",
        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
        prefixIcon: const Icon(Icons.category, color: Color(0xFF470404)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF470404), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please select a category";
        }
        return null;
      },
      dropdownColor: Colors.white,
      style: GoogleFonts.poppins(color: Colors.black87),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _pickImage,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFad6c47),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_upload, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'Upload Product Image',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _image == null
            ? Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 50, color: Colors.grey[400]),
                const SizedBox(height: 10),
                Text(
                  'No image selected',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        )
            : ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Image.file(
                _image!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.white),
                    onPressed: () => setState(() => _image = null),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus(); // Close keyboard

      try {
        final product = AddProductModel(
          noteTitle: title.text,
          noteContent: '',
          notePrice: double.parse(price.text),
          noteCategory: selectedCategory,
          noteImage: _image?.path ?? '',
          availableStock: 0,
          date: DateTime.now().toIso8601String(),
          noteStock: 0,
          saleStock: 0,
          time: TimeOfDay.now().format(context),
        );

        final note = NoteModel(
          noteTitle: title.text,
          noteContent: '',
          notePrice: double.parse(price.text),
          createdAt: DateTime.now().toIso8601String(),
          noteCategory: selectedCategory,
          noteImage: _image?.path ?? '',
        );

        await Future.wait([
          database.insertProduct(product),
          db.createNote(note),
        ]);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${title.text} added successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to add product: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}