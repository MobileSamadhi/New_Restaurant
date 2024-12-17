import 'package:flutter/material.dart';
import 'package:synnex_mobile/Authtentication/signup.dart';
import 'package:synnex_mobile/JsonModels/users.dart';
import 'package:synnex_mobile/SQLite/sqlite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Views/dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final username = TextEditingController();
  final password = TextEditingController();
  bool isVisible = false;
  final db = DatabaseHelper();
  final formKey = GlobalKey<FormState>();

  void showErrorPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Rounded corners
          ),
          backgroundColor: const Color(0xFFEFEFEF), // Light gray background
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red, // Blue color
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF414042), // Dark Gray color
            ),
          ),
          actions: [
            Center(
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF470404), // Blue button background
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                ),
                child: const Text(
                  "OK",
                  style: TextStyle(
                    color: Colors.white, // White text color
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> login() async {
    var response = await db.login(
      Users(
        usrName: username.text,
        usrPassword: password.text,
        usrPhone: '', // Provide an empty string as a placeholder
      ),
    );

    if (response == true) {
      if (!mounted) return;

      // Show success message using SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Login Successful! Welcome ${username.text}!",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF470404), // Blue color
          duration: const Duration(seconds: 5),
        ),
      );

      // Navigate to DashboardPage after showing the success message
      await Future.delayed(const Duration(seconds: 1)); // Optional delay for better UX
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardPage()),
      );
    } else {
      showErrorPopup(
        "Login Failed",
        "The username or password you entered is incorrect. Please try again.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevents resizing on keyboard appearance
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              "lib/assets/bg.jpeg", // Replace with your background image path
              fit: BoxFit.cover,
            ),
          ),
          // Content
          Positioned(
            top: MediaQuery.of(context).size.height * 0.1, // Adjust as needed
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 100), // Adjust spacing as needed
                    Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white70.withOpacity(0.7), // Blue color with opacity
                      ),
                      child: TextFormField(
                        controller: username,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Username is required";
                          }
                          return null;
                        },
                        style: TextStyle(
                          fontWeight: FontWeight.bold, // Makes the text bold
                          color: Colors.black, // Text color (black in this case)
                          fontSize: 18,
                        ),
                        decoration: const InputDecoration(
                          icon: Icon(Icons.person, color: Colors.black), // Blue color
                          border: InputBorder.none,
                          hintText: "Username",
                          hintStyle: TextStyle(color: Colors.black), // Dark Gray color
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white70.withOpacity(0.7), // Blue color with opacity
                      ),
                      child: TextFormField(
                        controller: password,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Password is required";
                          }
                          return null;
                        },
                        style: TextStyle(
                          fontWeight: FontWeight.bold, // Makes the text bold
                          color: Colors.black, // Text color (black in this case)
                          fontSize: 18,
                        ),
                        obscureText: !isVisible,
                        decoration: InputDecoration(
                          icon: const Icon(Icons.lock, color: Colors.black), // Blue color
                          border: InputBorder.none,
                          hintText: "Password",
                          hintStyle: const TextStyle(color: Colors.black), // Dark Gray color
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                isVisible = !isVisible;
                              });
                            },
                            icon: Icon(
                              isVisible ? Icons.visibility : Icons.visibility_off,
                              color:  Colors.black, // Dark Gray color
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 55,
                      width: MediaQuery.of(context).size.width * .9,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF470404), // Blue color
                      ),
                      child: TextButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            login();
                          }
                        },
                        child: const Text(
                          "LOGIN",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(color: Colors.white70, fontSize: 18,fontWeight: FontWeight.bold,), // Dark Gray color
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignUp()),
                            );
                          },
                          child: const Text(
                            "SIGN UP",
                            style: TextStyle(color: Colors.white70,fontWeight: FontWeight.bold,fontSize: 18), // Blue color
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Powered by Synnex IT Solution by 2024',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70, // Dark Gray color
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}