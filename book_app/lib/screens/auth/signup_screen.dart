import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hasAccount = false; // Flag to track if the user already has an account

  void _signup() async {
    try {
      // Attempt to signup
      await Provider.of<AuthProvider>(context, listen: false).signup(
        _emailController.text,
        _passwordController.text,
      );

      // Check if the widget is still mounted before calling context-dependent functions
      if (mounted) {
        // If signup is successful, show the SnackBar and navigate
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup successful!')),
        );
        // Use `Navigator` safely within mounted check
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      // If an error occurs (e.g., user already has an account), show message
      if (mounted) {
        if (e.toString().contains('already exists')) {
          setState(() {
            _hasAccount = true; // Set the flag to show the login button
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User already exists. Please login.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Signup failed: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _goToLogin() {
    // Navigate to the login screen safely
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Signup')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signup,
              child: Text('Signup'),
            ),
            // Show the login button if the user already has an account

            TextButton(
              onPressed: _goToLogin,
              child: Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
