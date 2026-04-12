import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:lockify/services/auth/auth_service.dart';
import 'package:lockify/utils/snackbar.dart';


class ResetPasswordScreen extends StatelessWidget {
  ResetPasswordScreen({super.key});

  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter your email to receive a password reset link.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  String email = _emailController.text.trim();
                  if (email.isEmpty) {
                    AppSnackBar.error(context, 'Please enter your email');
                    return;
                  } else {
                    _authService.emailExists(email).then((exists) {
                      if (!exists) {
                        AppSnackBar.error(context, 'User not found');
                      }
                    });
                  }
                  // Call the reset password function
                  _authService
                      .resetPassword(email)
                      .then((_) {
                        AppSnackBar.success(context, 'Reset email sent!');
                      })
                      .catchError((error) {
                        AppSnackBar.error(context, error.toString());
                      });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Send Reset Email'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

