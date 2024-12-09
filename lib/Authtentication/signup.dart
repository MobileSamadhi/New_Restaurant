import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:synnex_mobile/Authtentication/login.dart';
import 'package:synnex_mobile/JsonModels/users.dart';
import 'package:synnex_mobile/SQLite/sqlite.dart';

class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final username = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final phoneNumber = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isVisible = false;

  Future<void> _showDialog(String title, String content) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            content,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          actionsPadding: const EdgeInsets.only(bottom: 10),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFad6c47),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  "OK",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(


              child: Image.asset(
                "lib/assets/bg.jpeg",
                fit: BoxFit.cover,
              ),
          ),

          Center(
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),

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
                              return "Username is required";
                            }
                            return null;
                          },
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 18,
                          ),
                          decoration: const InputDecoration(
                            icon: Icon(Icons.person, color: Colors.black),
                            border: InputBorder.none,
                            hintText: "Username",
                            hintStyle: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),

                      // Phone Number field
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white70,
                        ),
                        child: TextFormField(
                          controller: phoneNumber,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(10),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Phone number is required";
                            }
                            if (value.length != 10) {
                              return "Enter a valid 10-digit phone number";
                            }
                            return null;
                          },
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 18,
                          ),
                          decoration: const InputDecoration(
                            icon: Icon(Icons.phone, color: Colors.black),
                            border: InputBorder.none,
                            hintText: "Phone Number",
                            hintStyle: TextStyle(color: Colors.black),
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
                              return "Password is required";
                            }
                            if (value.length < 8) {
                              return "Password must be at least 8 characters";
                            }
                            if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                              return "Password must include at least one symbol";
                            }
                            return null;
                          },
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 18,
                          ),
                          obscureText: !isVisible,
                          decoration: InputDecoration(
                            icon: const Icon(Icons.lock, color: Colors.black),
                            border: InputBorder.none,
                            hintText: "Password",
                            hintStyle: const TextStyle(color: Colors.black),
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
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Confirm Password field
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white70,
                        ),
                        child: TextFormField(
                          controller: confirmPassword,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Confirm Password is required";
                            } else if (password.text != confirmPassword.text) {
                              return "Passwords don't match";
                            }
                            return null;
                          },
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 18,
                          ),
                          obscureText: !isVisible,
                          decoration: InputDecoration(
                            icon: const Icon(Icons.lock, color: Colors.black),
                            border: InputBorder.none,
                            hintText: "Confirm Password",
                            hintStyle: const TextStyle(color: Colors.black),
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
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Sign Up Button
                      Container(
                        height: 55,
                        width: MediaQuery.of(context).size.width * .9,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFF470404),
                        ),
                        child: TextButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final db = DatabaseHelper();

                              // Normalize username and validate
                              String normalizedUsername = username.text.trim();
                              bool userExists = await db.doesUserExist(normalizedUsername);
                              bool phoneExists = await db.doesPhoneExist(phoneNumber.text);

                              if (userExists) {
                                await _showDialog(
                                  "Username Already Taken",
                                  "The username '${username.text}' is already registered. Please choose a different one.",
                                );
                              } else if (phoneExists) {
                                await _showDialog(
                                  "Phone Number Already Taken",
                                  "The phone number '${phoneNumber.text}' is already registered. Please use a different one.",
                                );
                              } else {
                                int? result = await db.signup(
                                  Users(
                                    usrName: normalizedUsername,
                                    usrPassword: password.text,
                                    usrPhone: phoneNumber.text,
                                  ),
                                );

                                if (result != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Registration Successful!",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: Color(0xFF470404),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );

                                  await Future.delayed(const Duration(seconds: 2));
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                        const LoginScreen()),
                                  );
                                }
                              }
                            }
                          },
                          child: const Text(
                            "SIGN UP",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account?",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5, // Adds spacing between letters
                              shadows: [
                                Shadow(
                                  offset: Offset(2.0, 2.0), // Adds a shadow to the text
                                  blurRadius: 4.0,
                                  color: Colors.black45,
                                ),
                              ],
                              fontStyle: FontStyle.italic, // Makes the text italic
                              decoration: TextDecoration.underline, // Adds underline to the text
                              decorationColor: Colors.white38, // Underline color
                              decorationThickness: 2, // Underline thickness
                            ),
                          ),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()),
                              );
                            },
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0, // Adds spacing between letters
                                shadows: [
                                  Shadow(
                                    offset: Offset(1.0, 1.0), // Adds a subtle shadow
                                    blurRadius: 3.0,
                                    color: Colors.black38,
                                  ),
                                ],
                                fontStyle: FontStyle.italic, // Makes the text italic
                                decoration: TextDecoration.overline, // Adds an overline above the text
                                decorationColor: Colors.white38, // Sets the color of the overline
                                decorationThickness: 1.5, // Sets the thickness of the overline
                                height: 1.5, // Adjusts the line height for better spacing
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
