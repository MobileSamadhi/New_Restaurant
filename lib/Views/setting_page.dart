import 'package:flutter/material.dart';
import 'package:synnex_mobile/SQLite/sqlite.dart';
import 'package:synnex_mobile/JsonModels/users.dart';
import 'package:synnex_mobile/Authtentication/login.dart';
import 'package:synnex_mobile/Views/dashboard.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final DatabaseHelper dbHelper = DatabaseHelper(); // SQLite helper
  List<Users> users = []; // List to store all user accounts

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Fetch all users when the page loads
  }

  // Function to fetch all users from the SQLite database
  Future<void> _fetchUsers() async {
    final allUsers = await dbHelper.getAllUsers(); // Assuming getAllUsers is implemented
    setState(() {
      users = allUsers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF470404), // Same color as the dashboard
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            users.isEmpty
                ? Center(
              child: Text(
                'No users found.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            )
                : Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Color(0xFFe0e0e0),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      title: Text(
                        users[index].usrName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF414042),
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteAccountDialog(context, users[index]);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to show confirmation dialog before deleting account
  void _showDeleteAccountDialog(BuildContext context, Users user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Confirm Account Deletion',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF470404),
            ),
          ),
          content: Text(
            'Are you sure you want to permanently delete the account for "${user.usrName}"? This action cannot be undone.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF414042),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Delete',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                _deleteAccount(context, user);
              },
            ),
          ],
        );
      },
    );
  }

  // Function to delete a specific user account
  void _deleteAccount(BuildContext context, Users user) async {
    await dbHelper.deleteUserById(user.usrId!); // Delete user by ID
    Navigator.of(context).pop(); // Close the confirmation dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Account "${user.usrName}" has been deleted.',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        backgroundColor: Color(0xFF470404),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
    _fetchUsers(); // Refresh the user list after deletion
  }
}