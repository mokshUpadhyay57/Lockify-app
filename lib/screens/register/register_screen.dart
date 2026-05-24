import 'package:lockify/utils/colors.dart';
import 'package:lockify/utils/snackbar.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lockify/services/auth/auth_service.dart';
import 'package:lockify/components/widgets/my_button.dart';
import 'package:lockify/components/widgets/my_textfield.dart';
import 'package:lockify/screens/login/login_screen.dart';
import 'package:lockify/utils/app_logger.dart';
import 'package:lockify/utils/app_ui.dart';
import 'package:lockify/utils/text_style.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // function to handle register
  void register(BuildContext context) async {
    String username = _usernameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        username.isEmpty ||
        name.isEmpty ||
        phone.isEmpty) {
      AppSnackBar.error(context, 'Please fill in all fields');
      return;
    }

    if (password != confirmPassword) {
      AppSnackBar.error(context, 'Passwords do not match');
      return;
    }

    try {
      await AuthService().signUpWithEmailAndPassword(
        username,
        email,
        password,
        name,
        phone,
      );
      AppLogger.info('User registered successfully');

      // Send email verification
      try {
        await AuthService().verifyEmail();
        AppSnackBar.success(
          null,
          'Verification email sent! Please check your inbox.',
        );
      } catch (e) {
        AppSnackBar.error(null, 'Could not send verification email: $e');
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await AppNavigation.pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        AppSnackBar.error(null, 'User not authenticated after registration');
      }
    } catch (e) {
      AppLogger.error('Registration failed', error: e);
      AppSnackBar.error(null, 'Registration failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 80, color: AppColors.primaryPurple),
              const SizedBox(height: 30),
              const Text(
                'Let create your account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlueAccent,
                ),
              ),
              const SizedBox(height: 30),
              MyTextField(
                icon: Icons.person,
                label: 'Username',
                controller: _usernameController,
              ),
              MyTextField(
                icon: Icons.email,
                label: 'Email',
                controller: _emailController,
              ),
              MyTextField(
                icon: Icons.lock,
                label: 'Password',
                controller: _passwordController,
              ),
              MyTextField(
                icon: Icons.lock,
                label: 'Confirm Password',
                controller: _confirmPasswordController,
              ),
              MyTextField(
                icon: Icons.person,
                label: 'Name',
                controller: _nameController,
              ),
              MyTextField(
                icon: Icons.phone,
                label: 'Phone',
                controller: _phoneController,
              ),
              const SizedBox(height: 10),
              MyButton(text: "REGISTER", onTap: () => register(context)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: AppStyles.regularTextStyle,
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Login Now',
                      style: AppStyles.linkTextStyle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
