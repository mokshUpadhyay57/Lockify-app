import 'package:lockify/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lockify/home_screen.dart';
import 'package:lockify/screens/login/login_screen.dart';


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
              ),
            );
          } else if (snapshot.hasError) {
            if (kDebugMode) {
              print('AuthGate Error: ${snapshot.error}');
            }
            return Center(child: Text('Something went wrong. Please try again.'));
          } else if (snapshot.hasData) {
            // User is signed in
            return LockifyHomePage(); // Redirect to the main screen
          } else {
            // User is not signed in
            return LoginScreen();
          }
        },
      ),
    );
  }
}

