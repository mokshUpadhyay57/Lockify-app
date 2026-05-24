import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:lockify/screens/settings/setting/whatsapp_help_screen.dart';

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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WhatsAppHelpScreen(),
                ),
              );
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

