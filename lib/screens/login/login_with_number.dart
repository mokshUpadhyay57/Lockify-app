import 'package:lockify/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lockify/screens/login/otp_screen.dart';
import 'package:lockify/utils/snackbar.dart';


class LoginWithPhoneNumberScreen extends StatefulWidget {
const LoginWithPhoneNumberScreen({super.key});

  @override
  State<LoginWithPhoneNumberScreen> createState() =>
      _LoginWithPhoneNumberScreenState();
}

class _LoginWithPhoneNumberScreenState
    extends State<LoginWithPhoneNumberScreen> {
  late final TextEditingController _phoneController;
  late final TextEditingController _otpController;
  bool _isOtpSent = false; // Track if OTP has been sent
  String? _verificationId; // Firebase verification ID

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhoneNumber() async {
     AppSnackBar.info(context, 'tapped');
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      AppSnackBar.error(context, 'Please enter a valid phone number.');
      return;
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Handle auto-verification (optional)
        },
        verificationFailed: (FirebaseAuthException e) {
          if (e.code == 'invalid-phone-number') {
            AppSnackBar.error(context, 'The provided phone number is not valid.');
          } else {
            AppSnackBar.error(context, e.message ?? 'Verification failed');
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isOtpSent = true; // OTP has been sent
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreen(verificationId: verificationId),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
      );
    } catch (e) {
      AppSnackBar.error(context, 'An error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              const Icon(Icons.lock, size: 80, color: AppColors.primaryPurple),

              const SizedBox(height: 30),

              // Welcome message
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlueAccent,
                ),
              ),

              const SizedBox(height: 30),

              // Phone number input field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Login button
              ElevatedButton(
                onPressed: _verifyPhoneNumber,
                child: const Text('Login'),
              ),

              const SizedBox(height: 25),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Not a member?'),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      // Navigate to register screen
                    },
                    child: const Text(
                      'Register now',
                      style: TextStyle(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.bold,
                      ),
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

