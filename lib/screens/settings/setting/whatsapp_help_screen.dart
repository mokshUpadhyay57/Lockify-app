import 'package:lockify/utils/colors.dart';
import 'package:lockify/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelpScreen extends StatefulWidget {
  const WhatsAppHelpScreen({super.key});

  @override
  _WhatsAppHelpScreenState createState() => _WhatsAppHelpScreenState();
}

class _WhatsAppHelpScreenState extends State<WhatsAppHelpScreen> {
  final TextEditingController _controller = TextEditingController();

  void _sendToWhatsApp() async {
    String message = _controller.text.trim();
    if (message.isEmpty) {
      AppSnackBar.warning(context, 'Please enter your query.');
      return;
    }

    const String phoneNumber = '919876543210'; // Professional support placeholder (E.164 format)
    final Uri whatsappUrl = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch WhatsApp';

      }
    } catch (e) {
      AppSnackBar.error(context, 'Could not open WhatsApp. Please ensure it is installed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FA),
      appBar: AppBar(
        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How can we help?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
            ),
            const SizedBox(height: 8),
            const Text(
              "Send us a message on WhatsApp and our team will get back to you as soon as possible.",
              style: TextStyle(fontSize: 16, color: AppColors.black54),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Describe your issue or question here...',
                      hintStyle: TextStyle(color: AppColors.grey400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: AppColors.purple100),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: AppColors.purple50),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                      ),
                      filled: true,
                      fillColor: AppColors.grey50,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sendToWhatsApp,
                      icon: const Icon(Icons.chat, color: AppColors.white),
                      label: const Text(
                        'OPEN WHATSAPP',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        shadowColor: AppColors.primaryPurple.withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

