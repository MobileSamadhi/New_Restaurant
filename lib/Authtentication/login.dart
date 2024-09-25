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
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Page header image
                  Image.asset(
                    "lib/assets/logo.jpg",
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 15),
                  Image.asset(
                    "lib/assets/login.png",
                    width: 350,
                    height: 250,
                  ),
                  const SizedBox(height: 15),
                  // Username field
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF470404).withOpacity(.2),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF470404).withOpacity(.2),
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
                      Checkbox(
                        value: rememberPassword,
                        onChanged: (value) {
                          setState(() {
                            rememberPassword = value!;
                          });
                        },
                      ),
                      const Text(
                        "Remember Password",
                        style: TextStyle(color: Color(0xFF414042)),
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
                        style: TextStyle(color: Color(0xFF414042)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignUp()));
                        },
                        child: const Text(
                          "SIGN UP",
                          style: TextStyle(color: Color(0xFF470404)),
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
                  // Powered by Synnex IT Solution by 2024 (Footer Text)
                  const Text(
                    'Powered by Synnex IT Solution 2024',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF414042),
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
}

