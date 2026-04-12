import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';


class ReceivedGiftScreen extends StatelessWidget {
  const ReceivedGiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: AppColors.white,
        centerTitle: false,
        title: const Text("Super Thanks Gifts", style: TextStyle(fontSize: 18)),
      ),

      body: Center(
        child: Text("No gifts received yet.", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

