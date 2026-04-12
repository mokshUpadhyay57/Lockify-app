import 'package:lockify/utils/colors.dart';
import 'package:lockify/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lockify/screens/login/login_screen.dart';


class SignOutCard extends StatelessWidget {
  const SignOutCard({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      // Sign out the user
      await FirebaseAuth.instance.signOut();

      // Show success message
      AppSnackBar.success(context, "Signed out successfully.");

      // Clear the navigation stack and send to LoginScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      // Show error message if sign-out fails
      AppSnackBar.error(context, "Error signing out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black12,
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Styled Logout Icon (Replacing missing image)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.purple50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.logout_rounded,
              size: 80,
              color: AppColors.purple700,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Ready to go?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Are you sure you want to log out of your account?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.black54,
            ),
          ),
          const SizedBox(height: 32),

          // Sign-out Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleSignOut(context),
              icon: const Icon(Icons.check_circle_outline, color: AppColors.white),
              label: const Text(
                'YES, SIGN OUT',
                style: TextStyle(color: AppColors.white, letterSpacing: 1.1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple700,
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CANCEL",
              style: TextStyle(
                color: AppColors.purple300,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

