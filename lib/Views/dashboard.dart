import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:synnex_mobile/Views/product_category.dart';
import 'package:synnex_mobile/Views/products.dart';
import 'package:synnex_mobile/Views/report.dart';
import 'bill_page.dart';
import 'company_details.dart';

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard',
          style: GoogleFonts.poppins(
            fontSize: 22, // Adjust the font size as needed
            fontWeight: FontWeight.bold, // Adjust the font weight as needed
            color: Color(0xFFE0FFFF), // Adjust the text color as needed
          ),
          ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,color: Colors.white,),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Products()),
            );
          },
        ),
        backgroundColor: Color(0xFF0072BC), // Blue color
        centerTitle: true,
        elevation: 5,
        actions: [
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buildDashboardButton(
                        context,
                        'Product Category',
                        Color(0xFF1ABC9C), // Green color
                        Icons.category,
                        ProductCategoryPage(),
                      ),
                      const SizedBox(height: 20),
                      buildDashboardButton(
                        context,
                        'Go to Product',
                        Color(0xFF3498DB), // Blue color
                        Icons.shopping_bag,
                        Products(),
                      ),
                      const SizedBox(height: 20),
                      buildDashboardButton(
                        context,
                        'Company Details',
                        Color(0xFF9B59B6), // Purple color
                        Icons.business,
                        CompanyDetailsPage(),
                      ),
                      const SizedBox(height: 20),
                      buildDashboardButton(
                        context,
                        'Cart',
                        Color(0xFFF1C40F), // Orange color
                        Icons.shopping_cart,
                        BillingPage(),
                      ),
                      const SizedBox(height: 20),
                      buildDashboardButton(
                        context,
                        'Report',
                        Color(0xFFE74C3C), // Red color
                        Icons.report,
                        SalesSummaryPage(),
                      ),
                   //   const SizedBox(height: 40),
                   //   const Divider(color: Color(0xFF414042), thickness: 1), // Dark Gray color
                  //    const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: Text(
              'Powered by Synnex IT Solution by 2024',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF414042), // Dark Gray color
              ),
            ),
          ),
        ],
      ),
    );
  }

  ElevatedButton buildDashboardButton(
      BuildContext context, String text, Color color, IconData icon, Widget page) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        shadowColor: Colors.black45,
        elevation: 10,
      ),
      icon: Icon(icon, size: 24),
      label: Text(text),
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }
}
