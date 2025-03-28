import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:synnex_mobi/Authtentication/login.dart';
import 'package:synnex_mobi/Views/product_category.dart';
import 'package:synnex_mobi/Views/products.dart';
import 'package:synnex_mobi/Views/report.dart';
import 'package:synnex_mobi/Views/setting_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bill_cart_viewpage.dart';
import 'bill_page.dart';
import 'company_details.dart';

class DashboardPage extends StatelessWidget {
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }

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
          icon: Icon(
            Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back,
            color: Colors.white,
          ),
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
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("lib/assets/bg.jpeg"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
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
                          const SizedBox(height: 20),
                          // Logout button using the same style
                          buildDashboardButton(
                            context,
                            'Logout',
                            Colors.white70, // Background color remains white70
                            Icons.logout,
                            null,
                            textColor: Colors.black, // Force black text
                            iconColor: Colors.black, // Force black icon
                            isLogout: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                color: Colors.white.withOpacity(0.9),
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Powered by Synnex IT Solution 2024',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
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
      BuildContext context,
      String text,
      Color color,
      IconData icon,
      Widget? page, {
        bool isLogout = false,
        Color? textColor,  // Optional text color override
        Color? iconColor,  // Optional icon color override
      }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        foregroundColor: textColor ?? (isLogout ? Colors.white : Colors.black),
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        textStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        shadowColor: Colors.black45,
        elevation: 10,
      ),
      icon: Icon(icon, size: 24, color: iconColor ?? (isLogout ? Colors.white : null)),
      label: Text(text),
      onPressed: () {
        if (isLogout) {
          _showLogoutConfirmation(context);
        } else if (page != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        }
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Logout",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF470404),
            ),
          ),
          content: Text(
            "Are you sure you want to logout?",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF470404),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Logout",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _logout(context);
              },
            ),
          ],
        );
      },
    );
  }
}