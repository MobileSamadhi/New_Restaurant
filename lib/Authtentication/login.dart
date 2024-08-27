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
  // We need two text editing controllers
  final username = TextEditingController();
  final password = TextEditingController();

  // A bool variable for show and hide password
  bool isVisible = false;

  // A bool variable for remember password
  bool rememberPassword = false;

  // Here is our bool variable
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

  // Now we should call this function in login button
  login() async {
    var response = await db
        .login(Users(usrName: username.text, usrPassword: password.text));
    if (response == true) {
      // If login is correct, then goto dashboard
      if (!mounted) return;
      await saveCredentials();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => DashboardPage()));
    } else {
      // If not, true the bool value to show error message
      setState(() {
        isLoginTrue = true;
      });
    }
  }

  // We have to create global key for our form
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            // We put all our textfields into a form to be controlled and not allow empty fields
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  // Page header image
                  Image.asset(
                    "lib/assets/logo.jpg",
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 15),
                  // Username field

                  // Before we show the image, after we copied the image we need to define the location in pubspec.yaml
                  Image.asset(
                    "lib/assets/login.png",
                    width: 350,
                    height: 250,
                  ),
                  const SizedBox(height: 15),
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Color(0xFF470404).withOpacity(.2), // Blue color with opacity
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
                        icon: Icon(Icons.person, color: Color(0xFF470404)), // Blue color
                        border: InputBorder.none,
                        hintText: "Username",
                        hintStyle: TextStyle(color: Color(0xFF414042)), // Dark Gray color
                      ),
                    ),
                  ),

                  // Password field
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Color(0xFF470404).withOpacity(.2), // Blue color with opacity
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
                        icon: const Icon(Icons.lock, color: Color(0xFF470404)), // Blue color
                        border: InputBorder.none,
                        hintText: "Password",
                        hintStyle: const TextStyle(color: Color(0xFF414042)), // Dark Gray color
                        suffixIcon: IconButton(
                          onPressed: () {
                            // In here we will create a click to show and hide the password a toggle button
                            setState(() {
                              // toggle button
                              isVisible = !isVisible;
                            });
                          },
                          icon: Icon(isVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                              color: Color(0xFF414042)), // Dark Gray color
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
                        style: TextStyle(color: Color(0xFF414042)), // Dark Gray color
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
                      color: Color(0xFF470404), // Blue color
                    ),
                    child: TextButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            // Login method will be here
                            login();
                          }
                        },
                        child: const Text(
                          "LOGIN",
                          style: TextStyle(color: Colors.white),
                        )),
                  ),

                  // Sign up button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(color: Color(0xFF414042)), // Dark Gray color
                      ),
                      TextButton(
                          onPressed: () {
                            // Navigate to sign up
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SignUp()));
                          },
                          child: const Text(
                            "SIGN UP",
                            style: TextStyle(color: Color(0xFF470404)), // Blue color
                          ))
                    ],
                  ),

                  // We will disable this message by default, when user and pass is incorrect we will trigger this message to user
                  isLoginTrue
                      ? const Text(
                    "Username or password is incorrect",
                    style: TextStyle(color: Color(0xFFD71920)), // Red color
                  )
                      : const SizedBox(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Container(
          height: 10, // Adjust the height as needed
          padding: const EdgeInsets.all(8),
          child: Center(
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
        ),
      ),
    );
  }
}
