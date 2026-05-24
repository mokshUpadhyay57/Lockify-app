import 'package:lockify/utils/colors.dart';
import 'package:lockify/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:lockify/components/widgets/my_button.dart';
import 'package:lockify/components/widgets/my_textfield.dart';
import 'package:lockify/home_screen.dart';
import 'package:lockify/screens/login/password_reset_screen.dart';
import 'package:lockify/screens/register/register_screen.dart';
import 'package:lockify/services/auth/auth_service.dart';
import 'package:lockify/utils/app_ui.dart';
import 'package:lockify/utils/text_style.dart';
// Import the styles

class LoginScreen extends StatelessWidget {
  // Controllers for email and password fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  LoginScreen({super.key});

  // Function to handle login
  void login(BuildContext context) async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      AppSnackBar.error(context, 'Please fill in all fields');
      return;
    }

    try {
      final userCredential = await AuthService().signInWithEmailAndPassword(
        email,
        password,
      );
      final user = userCredential.user;

      await user?.reload(); // Refresh user data
      // if (user != null && !user.emailVerified) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Please verify your email before logging in.'), backgroundColor: AppColors.errorRed),
      // );
      // } else {
      // Navigate to home page
      AppNavigation.pushReplacement(
        MaterialPageRoute(builder: (context) => LockifyHomePage()),
      );
      // }
    } catch (e) {
      AppSnackBar.error(null, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App logo
            const Icon(Icons.lock, size: 80, color: AppColors.primaryPurple),

            const SizedBox(height: 30),

            // Welcome message
            const Text('Welcome Back', style: AppStyles.welcomeTextStyle),

            const SizedBox(height: 30),

            // Email and password text fields
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

            Padding(
              padding: const EdgeInsets.only(right: 35.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,

                children: [
                  const Text(
                    'Forgot Password?',
                    style: AppStyles.regularTextStyle,
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResetPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Reset Now',
                      style: AppStyles.linkTextStyle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Login button
            MyButton(text: "LOGIN WITH GMAIL", onTap: () => login(context)),
            // Login with phone number button
            // MyButton(
            //   text: "LOGIN WITH PHONE NUMBER",
            //   onTap:
            //       () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginWithPhoneNumberScreen())),
            // ),
            SizedBox(height: 30),
            Row(
              children: [
                const Expanded(child: Divider(indent: 45)),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'OR',
                    style: TextStyle(fontSize: 14, color: AppColors.grey),
                  ),
                ),
                SizedBox(height: 20),
                const Expanded(child: Divider(endIndent: 45)),
              ],
            ),
            const SizedBox(height: 20),
            MyButton(
              text: "LOGIN WITH GOOGLE",
              onTap: () async {
                try {
                  await AuthService().signInWithGoogle();
                  AppNavigation.pushReplacement(
                    MaterialPageRoute(builder: (context) => LockifyHomePage()),
                  );
                } catch (e) {
                  AppSnackBar.error(null, e.toString());
                }
              },
            ),

            const SizedBox(height: 10),

            // Register link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,

              children: [
                const Text('Not a member?', style: AppStyles.regularTextStyle),
                const SizedBox(width: 5),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterScreen()),
                    );
                  },
                  child: const Text(
                    'Register Now',
                    style: AppStyles.linkTextStyle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
