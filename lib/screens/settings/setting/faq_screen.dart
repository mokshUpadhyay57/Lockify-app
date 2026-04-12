import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import '../../../components/faq_item.dart';
import '../../../components/faq_grid_item.dart';
import '../../../components/message_us_section.dart';


class FAQsPage extends StatelessWidget {
  const FAQsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final faqItems = [
      FAQItem("Profile", "assets/icons/profile.png"),
      FAQItem("Groups", "assets/icons/groups.png"),
      FAQItem("Channel", "assets/icons/channel.png"),
      FAQItem("Payments", "assets/icons/payments.png"),
      FAQItem("Withdraw/ Payouts", "assets/icons/withdraw.png"),
      FAQItem("Direct Messages", "assets/icons/direct.png"),
      FAQItem("Locked Messages", "assets/icons/locked.png"),
      FAQItem("General", "assets/icons/general.png"),
      FAQItem("RigiPay", "assets/icons/rigipay.png"),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQs'),
        backgroundColor: AppColors.black87,
        foregroundColor: AppColors.white,
        actions: const [Icon(Icons.search), SizedBox(width: 12)],
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: faqItems.length,
              itemBuilder: (context, index) {
                return FAQGridItem(faqItem: faqItems[index]);
              },
            ),
          ),
          const Divider(height: 1),
          const MessageUsSection(),
        ],
      ),
    );
  }
}

