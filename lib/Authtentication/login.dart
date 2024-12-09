import 'package:flutter/material.dart';
import 'package:synnex_mobile/Authtentication/signup.dart';
import 'package:synnex_mobile/JsonModels/users.dart';
import 'package:synnex_mobile/SQLite/sqlite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Views/dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final username = TextEditingController();
  final password = TextEditingController();
  bool isVisible = false;
  bool rememberPassword = false;
  bool isLoginTrue = false;
  final db = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    loadSavedCredentials();
  }

  Future<void> loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('username') ?? '';
    final savedPassword = prefs.getString('password') ?? '';
    final remember = prefs.getBool('rememberPassword') ?? false;

    if (remember) {
      setState(() {
        username.text = savedUsername;
        password.text = savedPassword;
        rememberPassword = remember;
      });
    }
  }

  Future<void> saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberPassword) {
      await prefs.setString('username', username.text);
      await prefs.setString('password', password.text);
    } else {
      await prefs.remove('username');
      await prefs.remove('password');
    }
    await prefs.setBool('rememberPassword', rememberPassword);
  }

  login() async {
    var response = await db
        .login(Users(usrName: username.text, usrPassword: password.text));
    if (response == true) {
      if (!mounted) return;
      await saveCredentials();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => DashboardPage()));
    } else {
      setState(() {
        isLoginTrue = true;
      });
    }
  }

  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 10.0), // Adjust padding as needed
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Powered by Synnex IT Solution 2024',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("lib/assets/bg.jpeg"), // Background image
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 15),
                    // Username field
                    Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white70,
                      ),
                      child: TextFormField(
                        controller: username,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "username is required";
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          icon: Icon(Icons.person, color: Color(0xFF470404)),
                          border: InputBorder.none,
                          hintText: "Username",
                          hintStyle: TextStyle(color: Color(0xFF414042)),
                        ),
                      ),
                    ),
                    // Password field
                    Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white70,
                      ),
                      child: TextFormField(
                        controller: password,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "password is required";
                          }
                          return null;
                        },
                        obscureText: !isVisible,
                        decoration: InputDecoration(
                          icon: const Icon(Icons.lock, color: Color(0xFF470404)),
                          border: InputBorder.none,
                          hintText: "Password",
                          hintStyle: const TextStyle(color: Color(0xFF414042)),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                isVisible = !isVisible;
                              });
                            },
                            icon: Icon(
                              isVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: const Color(0xFF414042),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Remember password checkbox
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.scale(
                          scale: 1.5, // Enlarges the checkbox for better visibility
                          child: Checkbox(
                            value: rememberPassword,
                            onChanged: (value) {
                              setState(() {
                                rememberPassword = value!;
                              });
                            },
                            checkColor: Colors.white, // Color of the checkmark
                            activeColor: Colors.blueAccent, // Background color when checked
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0), // Rounded corners
                            ),
                            side: const BorderSide(
                              color: Colors.white70, // Border color when unchecked
                              width: 2.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10), // Adds spacing between the checkbox and text
                        const Text(
                          "Remember Password",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0, // Adds spacing between letters
                            shadows: [
                              Shadow(
                                offset: Offset(1.0, 1.0), // Subtle shadow
                                blurRadius: 2.0,
                                color: Colors.black45,
                              ),
                            ],
                            decoration: TextDecoration.none, // Keeps the text clean
                            height: 1.5, // Adjusts line height for spacing
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Login button
                    Container(
                      height: 55,
                      width: MediaQuery.of(context).size.width * .9,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF470404),
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
                    // Sign up button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0, // Adds spacing between letters
                            shadows: [
                              Shadow(
                                offset: Offset(1.0, 1.0), // Adds a subtle shadow
                                blurRadius: 2.0,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignUp()),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0), // Adds rounded corners
                            ),
                            backgroundColor: Colors.blueAccent.withOpacity(0.2), // Subtle background color
                          ),
                          child: const Text(
                            "SIGN UP",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0, // Adds spacing between letters
                              shadows: [
                                Shadow(
                                  offset: Offset(1.0, 1.0), // Adds a subtle shadow
                                  blurRadius: 3.0,
                                  color: Colors.black26,
                                ),
                              ],
                              decoration: TextDecoration.underline, // Underlines the text
                              decorationThickness: 1.5, // Thickness of the underline
                              decorationColor: Colors.white38, // Color of the underline
                            ),
                          ),
                        ),
                      ],
                    ),
                    isLoginTrue
                        ? const Text(
                      "Username or password is incorrect",
                      style: TextStyle(color: Color(0xFFD71920)),
                    )
                        : const SizedBox(),
                    const SizedBox(height: 20),
                    // Footer Text
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
