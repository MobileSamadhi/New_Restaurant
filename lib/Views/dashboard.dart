import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:synnex_mobile/Views/product_category.dart';
import 'package:synnex_mobile/Views/products.dart';
import 'package:synnex_mobile/Views/report.dart';
import 'package:synnex_mobile/Views/setting_page.dart';
import 'bill_cart_viewpage.dart';
import 'bill_page.dart';
import 'company_details.dart';

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
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
        backgroundColor: Color(0xFF470404),
        centerTitle: true,
        elevation: 5,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white), // Add the settings icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()), // Navigate to SettingsPage
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
      Positioned.fill(
      child: Image.asset(
        "lib/assets/bg.jpeg", // Replace with your asset path
        fit: BoxFit.cover,
      ),
    ),
    Column(
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
                        'Company Details',
                        Colors.white70,
                        Icons.business,
                        CompanyDetailsPage(),
                      ),
                      const SizedBox(height: 20),
                      buildDashboardButton(
                        context,
                        'Product Category',
                        Colors.white70,
                        Icons.category,
                        ProductCategoryPage(),
                      ),
                      const SizedBox(height: 20),
                      buildDashboardButton(
                        context,
                        'Products',
                        Colors.white70,
                        Icons.shopping_bag,
                        Products(),
                      ),
                      const SizedBox(height: 20),
                      buildDashboardButton(
                        context,
                        'Cart',
                        Colors.white70,
                        Icons.shopping_cart,
                        BillingPage(),
                      ),
                      const SizedBox(height: 20),
                      buildDashboardButton(
                        context,
                        'Report',
                        Colors.white70,
                        Icons.report,
                        SalesSummaryPage(),
                      ),
                      const SizedBox(height: 20),
                      buildDashboardButton(
                        context,
                        'View',
                        Colors.white70,
                        Icons.view_agenda_rounded,
                        BillAndCartViewPage(),
                      ),
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
              'Powered by Synnex IT Solution 2024',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF414042),
              ),
            ),
          ),
        ],
      ),
    ],
      ),
    );
  }

  ElevatedButton buildDashboardButton(
      BuildContext context, String text, Color color, IconData icon, Widget page) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
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

