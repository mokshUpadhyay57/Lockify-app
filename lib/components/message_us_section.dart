import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';


class MessageUsSection extends StatelessWidget {
  const MessageUsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.blue,
          child: TextButton(
            onPressed: () {
              // Open support chat or redirect
            },
            child: const Text(
              "Message Us",
              style: TextStyle(color: AppColors.white, fontSize: 16),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: const [
              Text("Powered by", style: TextStyle(fontSize: 12)),
              SizedBox(height: 2),
              Text(
                "freshworks",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

