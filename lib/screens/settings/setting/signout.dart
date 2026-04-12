import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:lockify/components/signout_card.dart';


class SignOutPage extends StatelessWidget {
  const SignOutPage ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryPurple, // Purple
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Sign Out',
          style: TextStyle(
            fontSize: 18,
          ),
        ),
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(child: SignOutCard()),
    );
  }
}

