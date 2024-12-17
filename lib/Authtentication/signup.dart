import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              "lib/assets/bg.jpeg", // Replace with your background image path
              fit: BoxFit.cover,
            ),
          ),
          // SingleChildScrollView to have a scroll in the screen
          Center(
            child: SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(), // Disable scrolling
              child: Form(
                key: formKey,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      const SizedBox(height: 10),
                      ListTile(
                        title: Center(
                        ),
                      ),

                      // Username field
                      Container(
                        margin: EdgeInsets.all(8),
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
                            hintStyle: TextStyle(
                              fontWeight: FontWeight.bold, // Bold hint text
                              color: Colors.black, // Dark Gray color for hint text
                            ),
                          ),
                        ),
                      ),

                      // Phone Number field
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white70.withOpacity(0.7), // Blue color with opacity
                        ),
                        child: TextFormField(
                          controller: phoneNumber,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            // Limit input length to 10
                            LengthLimitingTextInputFormatter(10),
                            // Allow only digits
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold, // Makes the text bold
                            color: Colors.black, // Text color (black in this case)
                            fontSize: 18,
                          ),
                          decoration: const InputDecoration(
                            icon: Icon(Icons.phone, color: Colors.black), // Blue color
                            border: InputBorder.none,
                            hintText: "Phone Number",
                            hintStyle: TextStyle(color: Colors.black), // Dark Gray color
                          ),
                        ),
                      ),



                      // Password field
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
                            if (value.length < 8) {
                              return "Password must be at least 8 characters";
                            }
                            // Check if password contains at least one symbol
                            if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                              return "Password must include at least one symbol";
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
                                color: Colors.black, // Dark Gray color
                              ),
                            ),
                          ),
                        ),

                      ),

                      // Confirm Password field
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white70.withOpacity(0.7), // Blue color with opacity
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold, // Makes the text bold
                            color: Colors.black, // Text color (black in this case)
                            fontSize: 18,
                          ),
                          obscureText: !isVisible,
                          decoration: InputDecoration(
                            icon: const Icon(Icons.lock, color: Colors.black), // Blue color
                            border: InputBorder.none,
                            hintText: "Confirm Password",
                            hintStyle: const TextStyle(color: Colors.black), // Dark Gray color
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  isVisible = !isVisible;
                                });
                              },
                              icon: Icon(
                                isVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.black, // Dark Gray color
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Sign up button
                      // Sign up button
                      // Sign up button
                      Container(
                        height: 55,
                        width: MediaQuery.of(context).size.width * .9,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Color(0xFF470404), // Blue color
                        ),
                        child: TextButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final db = DatabaseHelper();

                              // Normalize username to lowercase for consistent comparison
                              String normalizedUsername = username.text;

                              // Check if the username or phone number already exists
                              bool userExists = await db.doesUserExist(normalizedUsername);
                              bool phoneExists = await db.doesPhoneExist(phoneNumber.text);

                              if (userExists) {
                                // Show an error dialog if the username already exists
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      title: Text(
                                        "Username Already Taken",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                        ),
                                        textAlign: TextAlign.center, // Center the title
                                      ),
                                      content: Text(
                                        "The username '${username.text}' is already registered. Please choose a different one.",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                        textAlign: TextAlign.center, // Center the content
                                      ),
                                      actionsPadding: const EdgeInsets.only(bottom: 10), // Adjust bottom padding
                                      actions: [
                                        Center(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color(0xFF470404),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

                              } else if (phoneExists) {
                                // Show an error dialog if the phone number already exists
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      title: Text(
                                        "Phone Number Already Taken",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                        ),
                                        textAlign: TextAlign.center, // Center the title
                                      ),
                                      content: Text(
                                        "The phone number '${phoneNumber.text}' is already registered. Please use a different one.",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                        textAlign: TextAlign.center, // Center the content
                                      ),
                                      actionsPadding: const EdgeInsets.only(bottom: 10), // Adjust bottom padding
                                      actions: [
                                        Center(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color(0xFF470404),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

                              } else {
                                // Register the user if both username and phone number are unique
                                int? result = await db.signup(
                                  Users(
                                    usrName: normalizedUsername, // Store in lowercase
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
                                      backgroundColor: Color(0xFF470404), // Blue color
                                      duration: Duration(seconds: 3),
                                    ),
                                  );

                                  await Future.delayed(const Duration(seconds: 2));
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginScreen()),
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



                      // Login button
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account?",
                            style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold,), // Dark Gray color
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
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            child: const Text(
                              "Login",
                              style: TextStyle(color: Colors.white70, fontSize: 18,fontWeight: FontWeight.bold,), // Blue color
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