// signup.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:synnex_mobile/Authtentication/login.dart';
import 'package:synnex_mobile/JsonModels/users.dart';
import 'package:synnex_mobile/SQLite/sqlite.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final username = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  final formKey = GlobalKey<FormState>();

  bool isVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // SingleChildScrollView to have a scroll in the screen
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // We will copy the previous textfield we designed to avoid time consuming

                  ListTile(
                    title: Center(
                      child: Text(
                        "User Registration",
                        style: GoogleFonts.poppins(
                          fontSize: 29,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF470404), // Dark Gray color
                        ),
                      ),
                    ),
                  ),


                  Image.asset(
                    "lib/assets/sign.jpg",
                    width: 210,
                  ),

                  // As we assigned our controller to the textformfields

                  Container(
                    margin: EdgeInsets.all(8),
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
                          return "Password is required";
                        }
                        if (value.length < 8) {
                          return "Password must be at least 8 characters";
                        }
                        // Check if password contains at least one symbol
                        if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                          return "Password must include at least one symbol";
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
                            setState(() {
                              isVisible = !isVisible;
                            });
                          },
                          icon: Icon(
                            isVisible ? Icons.visibility : Icons.visibility_off,
                            color: Color(0xFF414042), // Dark Gray color
                          ),
                        ),
                      ),
                    ),

                  ),
                  // Confirm Password field
                  // Now we check whether password matches or not
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Color(0xFF470404).withOpacity(.2), // Blue color with opacity
                    ),
                    child: TextFormField(
                      controller: confirmPassword,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "password is required";
                        } else if (password.text != confirmPassword.text) {
                          return "Passwords don't match";
                        }
                        return null;
                      },
                      obscureText: !isVisible,
                      decoration: InputDecoration(
                        icon: const Icon(Icons.lock, color: Color(0xFF470404)), // Blue color
                        border: InputBorder.none,
                        hintText: "Confirm Password",
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
                            // Signup method will be here

                            final db = DatabaseHelper();
                            db
                                .signup(Users(
                                usrName: username.text,
                                usrPassword: password.text))
                                .whenComplete(() {
                              // After success user creation go to login screen
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const LoginScreen()));
                            });
                          }
                        },
                        child: const Text(
                          "SIGN UP",
                          style: TextStyle(color: Colors.white),
                        )),
                  ),

                  // Sign up button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account?",
                        style: TextStyle(color: Color(0xFF414042)), // Dark Gray color
                      ),
                      TextButton(
                          onPressed: () {
                            // Navigate to login
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()));
                          },
                          child: const Text(
                            "Login",
                            style: TextStyle(color: Color(0xFF470404)), // Blue color
                          ))
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
