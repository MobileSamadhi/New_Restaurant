import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synnex_mobi/Authtentication/signup.dart';
import 'package:synnex_mobi/JsonModels/users.dart';
import 'package:synnex_mobi/SQLite/sqlite.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool isLoading = false;
  bool rememberMe = false;
  final db = DatabaseHelper();
  final formKey = GlobalKey<FormState>();

  // For password reset dialog
  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      rememberMe = prefs.getBool('rememberMe') ?? false;
      if (rememberMe) {
        username.text = prefs.getString('rememberedUsername') ?? '';
        password.text = prefs.getString('rememberedPassword') ?? '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background image with overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("lib/assets/bg.jpeg"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ),

          // Main content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo/Title
                      Text(
                        "Welcome Back",
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Login to continue",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Username field
                      _buildInputField(
                        controller: username,
                        icon: Icons.person_outline,
                        hintText: "Username",
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Username is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Password field
                      _buildInputField(
                        controller: password,
                        icon: Icons.lock_outline,
                        hintText: "Password",
                        obscureText: !isVisible,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Password is required";
                          }
                          return null;
                        },
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              isVisible = !isVisible;
                            });
                          },
                          icon: Icon(
                            isVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Remember me checkbox and forgot password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Animated toggle switch
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    rememberMe = !rememberMe;
                                  });
                                },
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, animation) {
                                    return ScaleTransition(scale: animation, child: child);
                                  },
                                  child: rememberMe
                                      ? Icon(
                                    Icons.toggle_on,
                                    key: ValueKey('on'),
                                    color: Colors.green,
                                    size: 36,
                                  )
                                      : Icon(
                                    Icons.toggle_off,
                                    key: ValueKey('off'),
                                    color: Colors.white.withOpacity(0.7),
                                    size: 36,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Text
                              Text(
                                "Remember me",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),

                          // Forgot password text
                          TextButton(
                            onPressed: () {
                              _showForgotPasswordDialog();
                            },
                            child: Text(
                              "Forgot Password?",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                            if (formKey.currentState!.validate()) {
                              _login();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF470404),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          )
                              : Text(
                            "LOGIN",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Sign up redirect
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SignUp()),
                              );
                            },
                            child: Text(
                              "Sign Up",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
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

          // Footer
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Powered by Synnex IT Solution © 2024',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white70),
          suffixIcon: suffixIcon,
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          filled: true,
          fillColor: Colors.transparent,
        ),
        validator: validator,
      ),
    );
  }

  Future<void> _login() async {
    print('[_login] Starting login process');
    setState(() {
      isLoading = true;
    });

    try {
      String normalizedUsername = username.text.trim().toLowerCase();
      print('[_login] Normalized username: $normalizedUsername');

      // Save or clear remembered credentials
      final prefs = await SharedPreferences.getInstance();
      if (rememberMe) {
        await prefs.setBool('rememberMe', true);
        await prefs.setString('rememberedUsername', username.text);
        await prefs.setString('rememberedPassword', password.text);
      } else {
        await prefs.setBool('rememberMe', false);
        await prefs.remove('rememberedUsername');
        await prefs.remove('rememberedPassword');
      }

      var response = await db.login(
        Users(
          usrName: normalizedUsername,
          usrPassword: password.text,
          usrPhone: '',
        ),
      );

      if (response == true) {
        print('[_login] Login successful');
        if (!mounted) return;

        await prefs.setString('currentUser', normalizedUsername);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Login Successful! Welcome ${username.text}!",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFF470404),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardPage()),
          );
        }
      } else {
        print('[_login] Login failed - incorrect credentials');
        _showErrorDialog(
          "Login Failed",
          "The username or password you entered is incorrect.",
        );
      }
    } catch (e) {
      print('[_login] Error during login: $e');
      _showErrorDialog(
        "Error",
        "An error occurred during login. Please try again.",
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "Reset Password",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF470404),
                ),
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Email/Username field
                    _buildDialogInputField(
                      controller: emailController,
                      icon: Icons.email_outlined,
                      hintText: "Enter your username",
                    ),
                    const SizedBox(height: 15),

                    // Old password field (for change password)
                    _buildDialogInputField(
                      controller: oldPasswordController,
                      icon: Icons.lock_outline,
                      hintText: "(optional) Current password",
                      obscureText: !_isOldPasswordVisible,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _isOldPasswordVisible = !_isOldPasswordVisible;
                          });
                        },
                        icon: Icon(
                          _isOldPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: const Color(0xFF470404),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // New password field
                    _buildDialogInputField(
                      controller: newPasswordController,
                      icon: Icons.lock_reset,
                      hintText: "New password",
                      obscureText: !_isNewPasswordVisible,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _isNewPasswordVisible = !_isNewPasswordVisible;
                          });
                        },
                        icon: Icon(
                          _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: const Color(0xFF470404),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Confirm new password field
                    _buildDialogInputField(
                      controller: confirmPasswordController,
                      icon: Icons.lock_reset,
                      hintText: "Confirm new password",
                      obscureText: !_isConfirmPasswordVisible,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          });
                        },
                        icon: Icon(
                          _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: const Color(0xFF470404),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF470404),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF470404),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () async {
                        if (emailController.text.isEmpty) {
                          _showErrorDialog("Error", "Please enter your username");
                          return;
                        }

                        if (oldPasswordController.text.isNotEmpty) {
                          if (newPasswordController.text.isEmpty ||
                              confirmPasswordController.text.isEmpty) {
                            _showErrorDialog("Error", "Please fill all password fields");
                            return;
                          }

                          if (newPasswordController.text != confirmPasswordController.text) {
                            _showErrorDialog("Error", "New passwords don't match");
                            return;
                          }

                          await _changePassword(
                            emailController.text,
                            oldPasswordController.text,
                            newPasswordController.text,
                          );
                        } else {
                          if (newPasswordController.text.isEmpty ||
                              confirmPasswordController.text.isEmpty) {
                            _showErrorDialog("Error", "Please fill all password fields");
                            return;
                          }

                          if (newPasswordController.text != confirmPasswordController.text) {
                            _showErrorDialog("Error", "New passwords don't match");
                            return;
                          }

                          await _resetPassword(
                            emailController.text,
                            newPasswordController.text,
                          );
                        }
                      },
                      child: Text(
                        "Submit",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.poppins(
          color: Colors.black87,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF470404)),
          suffixIcon: suffixIcon,
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey,
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  Future<void> _resetPassword(String username, String newPassword) async {
    try {
      setState(() {
        isLoading = true;
      });

      String normalizedUsername = username.trim().toLowerCase();

      bool userExists = await db.checkUserExists(normalizedUsername);
      if (!userExists) {
        if (mounted) {
          _showErrorDialog("Error", "Username not found");
        }
        return;
      }

      bool success = await db.updatePassword(normalizedUsername, newPassword);

      if (success) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Password reset successfully!",
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog("Error", "Failed to reset password. Please try again.");
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog("Error", "An error occurred: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _changePassword(String username, String oldPassword, String newPassword) async {
    try {
      setState(() {
        isLoading = true;
      });

      String normalizedUsername = username.trim().toLowerCase();

      bool valid = await db.login(
        Users(
          usrName: normalizedUsername,
          usrPassword: oldPassword,
          usrPhone: '',
        ),
      );

      if (!valid) {
        if (mounted) {
          _showErrorDialog("Error", "Current password is incorrect");
        }
        return;
      }

      bool success = await db.updatePassword(normalizedUsername, newPassword);

      if (success) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Password changed successfully!",
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );

          final prefs = await SharedPreferences.getInstance();
          if (rememberMe && prefs.getString('rememberedUsername')?.toLowerCase() == normalizedUsername) {
            await prefs.setString('rememberedPassword', newPassword);
          }
        }
      } else {
        if (mounted) {
          _showErrorDialog("Error", "Failed to change password. Please try again.");
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog("Error", "An error occurred: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String title, String message) {
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
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF470404),
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF470404),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "OK",
                  style: GoogleFonts.poppins(
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
}